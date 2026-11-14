# How the CHO/FAT Metabolic Pro app works

This document explains how the data field is implemented, referencing the
theoretical basis described in
[`01-theoretical-basis.md`](01-theoretical-basis.md) and the source code in
[`source/CHOFATView.mc`](../source/CHOFATView.mc). It does not repeat the
scientific justification for each formula (that is already in document 01) — it
focuses on how the code is organized and why each engineering decision was made.

## 1. What it is and how it integrates with Garmin

It is a Connect IQ **Data Field** (not an app or a widget): it can only be added
as a field within an activity's data screen (Run, Bike, etc.), it does not appear
in the watch's app list. It works on both watches and Edge bike computers — the
manifest declares the compatible products, and the code adapts to each device's
screen shape (§4.2). It is written in Monkey C and implemented entirely in the
`CHOFATView` class, which Garmin instantiates once when the activity starts and
updates at two different moments:

- `compute(info)`: called ~once per second with the current activity data (HR,
  timer time...). This is where **all the computation** happens.
- `onUpdate(dc)`: called whenever the screen needs to be redrawn. This **only
  draws** what has already been computed in `compute()` — no physiological
  calculation happens here.

## 2. Resolving the physiological profile (`carregarPerfil()`)

When the data field is created, the 6 physiological parameters that feed the
model (weight, resting HR, max HR, LT2, LT1, VO2max) are resolved. For each one, the
priority is:

1. **Manual value** (`Properties`, in `resources/settings/properties.xml`) if the
   user has entered one > 0.
2. Otherwise, **automatic estimation** from the Garmin profile (`UserProfile`).
3. If there is no Garmin data either, a reasonable default value hardcoded in the
   class is used.

Important note (documented because it's hard to find): manual values can only be
edited from the Connect IQ Store's settings screen, which **does not work for
sideloaded apps** (see §7) — the settings UI is downloaded dynamically based on
the app's ID as registered in the Store, and a sideload has no access to it. So in
practice, a sideloaded build always runs in automatic mode.

For `HRmax` and `LT2`, since Garmin does not expose them directly, they are
inferred from the watch's `getHeartRateZones()`:
zone 5 ceiling → HRmax, zone 4 ceiling → LT2. This call is already aware of the
current sport (`UserProfile.getCurrentSport()`), so on an Edge bike computer it
correctly reads the **cycling** zones, not the running ones. Note that with
Garmin's default %HRmax zones the zone 4 ceiling is simply 90% of HRmax: close to
the population-average LT2 (about 90.6% of HRmax in recreational runners; Nuuttila
et al., 2025) but not a measurement. Zones built on a measured lactate threshold
line up much better. At the end of
`carregarPerfil()` there is a coherence check: if `HRmax` does not end up above
`HRrest`, or if `LT2` does not end up in between, it is corrected automatically
(absurd values are never allowed to silently break the HRR/RER calculation later
on).

The automatic `VO2max` is also sport-aware: Garmin stores running VO2max
(`profile.vo2maxRunning`) and cycling VO2max (`profile.vo2maxCycling`)
separately — the app picks one or the other depending on whether the current
sport is `UserProfile.HR_ZONE_SPORT_BIKING` (a real bug found while testing Edge support:
always reading `vo2maxRunning` meant an Edge would always fall back to the
default value, since a bike computer never produces a running VO2max). If the
sport-specific value is missing (common for cyclists without a power meter), the
other one is used before falling back to the default.

When an activity ends (`onTimerReset()`), the accumulated state (grams, EMA,
active time) is cleared and the profile is read again, so the next activity
does not inherit anything from the previous one. The session average CHO is
computed over the time actually accumulated, which stays consistent with the
grams even after a sensor dropout or a mid-activity restart.

The "onset of exercise" point $I_{onset}$ (theoretical document §6) is always
calculated as a fraction of `lt2`, with the constant `PCT_ACTIVACIO_CHO = 0.70` —
it has no laboratory equivalent, so it is not offered as a manual value (§6 of
the theoretical document).

$LT_1$, on the other hand, is a real physiological threshold that an athlete may
know from their own testing, so it follows the same pattern as the rest of the
profile: if the user enters a manual value (`lt1Manual`, property > 0) and it is
coherent (above `fcRepos` and above the CHO-onset point `0.70 * lt2`, and below
`lt2`), it is used directly; if not, it is silently discarded and the estimate
`PCT_LT1 * lt2` (`PCT_LT1 = 0.89`) is used instead.

## 3. Calculation cycle (`compute()`)

For each valid sample (with HR available):

1. **Time control**: `dtMs` is calculated since the last sample. If `dtMs <= 0`
   (activity paused) or `dtMs` exceeds `DT_MAX_MS` (5000 ms — typically an
   optical sensor dropout), the sample is discarded instead of accumulating
   anything. This prevents a sensor dropout of, say, 90 seconds, from being
   applied retroactively with the instantaneous rate at the moment of
   reconnection over the whole gap (a real bug found and fixed during
   development, and validated against a real `.FIT` file with a genuine sensor
   dropout).
2. **Current HR zone** (`zonaFCActual`): determined by comparing HR against the
   `zonesFC` thresholds (saved in `carregarPerfil()`), for the small Z1-Z5
   indicator.
3. **HRR → VO2** and **RER by zones** → grams of CHO/FAT per minute, following
   exactly the formulas described in the theoretical document (§3-7). The
   reference constants live at the top of the class: `RER_BASAL = 0.86`,
   `RER_LT1 = 0.91`, `RER_LT2 = 0.98`, `RER_MAX = 1.00`, `PCT_LT1 = 0.89` and
   `PCT_ACTIVACIO_CHO = 0.70`; the theoretical document explains where they come
   from (§5.1, §6) and for whom they are calibrated (§10). HRR is clamped to the
   0-1 range and negative CHO/FAT rates are floored at 0.
4. **Accumulation**: `totalChoGrams` and `totalFatGrams` add the grams from this
   tick (the discretization of the CHO_total/FAT_total integral, see theoretical
   document §8.2).
5. **Exponential moving average** (`choAvgEmaGH`): this is the specific smoothing
   technique this app uses for the displayed rate (theoretical document §8.3 —
   which technique and with what parameters is an implementation decision, not
   part of the model). It is updated with `alpha_tick = dtMin / TAU_EMA_MIN`
   (τ=15 min). The first valid sample initializes the EMA directly with the
   instantaneous value (it does not start at 0 and climb slowly).

### Saving results to the activity file (`FitContributor`)

At the end of every `compute()` cycle the app writes six custom fields into the
activity's `.FIT` file through `Toybox.FitContributor` (permission
`FitContributor`, fields created in `crearCampsFit()`). They are shown by
Garmin Connect once the activity is synced; the layout is defined in
`resources/fitcontributions/fitcontributions.xml`.

| Id | Field | Message | Unit | Shown in Garmin Connect as |
|---|---|---|---|---|
| 0 | `cho_acum_g` | RECORD | g | chart: accumulated CHO |
| 1 | `fat_acum_g` | RECORD | g | chart: accumulated FAT |
| 2 | `cho_rate_gh` | RECORD | g/h | chart: CHO rate (EMA) |
| 3 | `cho_total_g` | SESSION | g | activity summary |
| 4 | `fat_total_g` | SESSION | g | activity summary |
| 5 | `cho_avg_gh` | SESSION | g/h | activity summary |

The ids must stay stable once published. SESSION fields are refreshed every
second, so the value written at the end is the last one.

## 4. Visual interface (`onUpdate()`)

### 4.1. 3-row × 2-column grid

The screen is divided into 3 equal horizontal bands (1/3 of the height each):

```
[ CHO (g)        | 123    ]
[ CHO avg (g/h)  | 45  Z3 ]   <- colored + zone indicator
[ FAT (g)        | 67     ]
```

Each row is split into a label column (40%) and a value column (60%), with no
vertical separator line (only horizontal lines between rows). The middle row
additionally reserves a small extra strip on the far right for the zone
indicator, so it never ends up under the number (the real width of the "Z1".."Z5"
text is calculated and subtracted before splitting the 40/60 columns).

### 4.2. Safe width on a round screen (`amplaSeguraFila`)

On a round screen, the usable width is not constant: it is maximal at the
vertical center and shrinks towards the top/bottom (it is the chord of a circle
at a given height). If fixed-width columns were used for every row equally, the
labels of the top/bottom rows would get clipped by the bezel (a real bug found
visually and fixed). The `amplaSeguraFila()` function calculates, for each row,
the width actually available at the most extreme height of that row:

```
edge_distance = |cy - center_Y| + row_height/2
safe_width = 2 · √(radius² - edge_distance²)
```

and all the columns of that row are calculated based on this safe width, not on
the screen's total width.

**Rectangular-screen devices (Edge)**: this chord calculation only makes sense on
round or semi-round screens — a rectangular screen has no curved bezel clipping
anything, and applying the same formula would leave unnecessary margins.
`calcularGeometria()` queries `System.getDeviceSettings().screenShape` once and
stores it in `esRodona`; `amplaSeguraFila()` checks it and, on a non-round
device, simply returns 96% of the total width with no chord calculation at all.

### 4.3. Adaptive font size (`ajustaFont`)

For each piece of text (label or value), a list of candidate fonts is tried from
largest to smallest, and the first one that fits both the available width **and**
height is kept. For numeric values, the list includes Monkey C's large
digit-specific fonts (`FONT_NUMBER_HOT/MEDIUM/MILD`), which look noticeably
larger than generic text fonts for the same space — they are the font type
Garmin's native data fields use for their main numbers.

### 4.4. Geometry and font caching (performance)

Since `onUpdate()` is called very often (typically ~once/second), the geometry of
the 3 rows (positions, column widths, label font) is calculated once in
`calcularGeometria()` and stored in class fields, instead of recalculating it on
every call — it is only recalculated if the screen size changes from the cached
value (in practice, never during an actual activity).

Likewise, the numeric value's font for each row is only looked up again
(`ajustaFont`) when the text's **length** changes (e.g. from 2 to 3 digits), not
every frame — the vast majority of calls reuse the already-computed font instead
of retesting every candidate. This avoids unnecessary repeated work, although the
real impact on battery life is small compared to the GPS or HR sensor's
consumption, which is the same regardless of which data field is shown.

## 5. Color coding

### 5.1. CHO consumption (fueling)

The `CHO avg (g/h)` value is colored with `colorPerCho(value, sessionMinutes)`.
The thresholds compare the CHO oxidation rate with how much carbohydrate a person
can realistically absorb while exercising (theoretical document §9: about 60 g/h
from a single source, up to about 90 g/h with multiple-transportable carbohydrates):

| Elapsed time | Green | Orange | Red |
|---|---|---|---|
| < 45 min | (always green, glycogen stores are full) | — | — |
| ≥ 45 min | < 60 g/h | 60-90 g/h | ≥ 90 g/h |

Red therefore means "burning more carbohydrate than can be replaced", which is
normal at moderate-to-hard intensity: the difference comes from glycogen stores.

### 5.2. HR zone

The "Z1".."Z5" text is painted with `colorPerZona(zone)`, reproducing Garmin
Connect's standard HR zone color scheme: dark grey (Z1), blue (Z2), green (Z3),
orange (Z4), red (Z5). It is independent of the CHO value's color — both can show
different colors at the same time (e.g. "green" for fueling and "Z4" for zone),
and this is intentional: one represents carbohydrate consumption and the other
effort intensity.

## 6. Development tools

[`tools/Run-Simulator.ps1`](../tools/Run-Simulator.ps1) automates building and
launching the app in the Connect IQ simulator: it auto-detects the active SDK (by
reading `current-sdk.cfg`), lets you pick the device (interactive menu or
`-Device <id>`), and reuses the simulator if one is already open.

## 7. Deployment to a real watch (sideload)

Tested and confirmed working on a Garmin Epix 2 Pro (47mm). An important
particularity of this model (and likely of other devices with equivalent modern
firmware): the classic sideload method (copying the `.prg` to an uppercase
`GARMIN/APPS` folder) **does not work**, because the device already has a
`GARMIN/Apps` folder (lowercase) for the firmware's internal use, and the watch's
filesystem is not case-sensitive — a separate folder cannot be created whose name
differs only by letter case.

**Method that works**: copy the `.prg` directly inside the already-existing
`GARMIN/Apps` folder (without creating a new one), connecting the watch via USB
(it appears as an MTP device, not as a disk drive — it must be navigated with
`Shell.Application` from PowerShell, not with `Copy-Item`). When the watch is
disconnected, the firmware detects the new file and processes it into its
internal app database.

Paths ruled out during the investigation (documented so they don't need to be
tried again): `monkeydo`'s *native pairing* mode (`/n`) is for pairing ANT/BLE
sensors with the app, not for installing it; the simulator's *adb Connection*
menu is a debug bridge for the companion mobile app (Android), not for the watch;
Garmin Express only allows browsing/managing the Connect IQ Store, not manual
sideloading from a local file.

## 8. Known limitations

- The model is an approximation based exclusively on HR, calibrated for
  recreational-to-trained athletes on a normal mixed diet in a fed state
  (theoretical document §10). It does not capture the effect of duration (RER
  tends to fall as the effort goes on, so CHO is increasingly overestimated in
  long sessions), nor diet, fasting, sex, heat or cardiac drift. Elite or
  fat-adapted athletes will see CHO overestimated and untrained people
  underestimated. Treat the numbers as an indication of order of magnitude and
  trends, not as a measurement.
- `HRmax` and `LT2` are estimates based on configured HR zones, not direct
  measurements — their accuracy depends on how the user (or Garmin) has
  configured those zones. With Garmin's default %HRmax zones, the zone 4 ceiling is
  just 90% of HRmax.
- Results are saved in the activity (custom FIT fields) and shown by Garmin
  Connect after syncing, but services that ignore developer fields (e.g. Strava)
  will not display them; the values are still in the `.FIT` file.
