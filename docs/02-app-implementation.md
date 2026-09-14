# How the CHO/FAT Metabolic app works

This document explains how the data field is implemented, referencing the
theoretical basis described in
[`01-theoretical-basis.md`](01-theoretical-basis.md) and the source code in
[`source/CHOFATView.mc`](../source/CHOFATView.mc). It does not repeat the
scientific justification for each formula (that is already in document 01) — it
focuses on how the code is organized and why each engineering decision was made.

## 1. What it is and how it integrates with Garmin

It is a Connect IQ **Data Field** (not an app or a widget): it can only be added
as a field within an activity's data screen (Run, Bike, etc.), it does not appear
in the watch's app list. It is written in Monkey C and implemented entirely in the
`CHOFATView` class, which Garmin instantiates once when the activity starts and
updates at two different moments:

- `compute(info)`: called ~once per second with the current activity data (HR,
  timer time...). This is where **all the computation** happens.
- `onUpdate(dc)`: called whenever the screen needs to be redrawn. This **only
  draws** what has already been computed in `compute()` — no physiological
  calculation happens here.

## 2. Resolving the physiological profile (`carregarPerfil()`)

When the data field is created, the 5 physiological parameters that feed the
model (weight, resting HR, max HR, LT2, VO2max) are resolved. For each one, the
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
practice, as long as the app is not published, it will always run in automatic
mode.

For `HRmax` and `LT2`, since Garmin does not expose them directly (see §5 of the
theoretical document), they are inferred from the watch's `getHeartRateZones()`:
zone 5 ceiling → HRmax, zone 4 ceiling → LT2. At the end of `carregarPerfil()`
there is a coherence check: if `HRmax` does not end up above `HRrest`, or if `LT2`
does not end up in between, it is corrected automatically (absurd values are
never allowed to silently break the HRR/RER calculation later on).

The "onset of exercise" point $I_{onset}$ (theoretical document §6) is always
calculated as a fraction of `lt2`, with the constant `PCT_ACTIVACIO_CHO = 0.70` —
it has no laboratory equivalent, so it is not offered as a manual value (§6 of
the theoretical document).

$LT_1$, on the other hand, is a real physiological threshold that an athlete may
know from their own testing, so it follows the same pattern as the rest of the
profile: if the user enters a manual value (`lt1Manual`, property > 0) and it is
coherent (between `fcRepos` and `lt2`), it is used directly; if not, it is
silently discarded and the estimate `PCT_LT1 * lt2` (`PCT_LT1 = 0.85`) is used
instead.

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
   exactly the formulas described in the theoretical document (§3-7).
4. **Accumulation**: `totalChoGrams` and `totalFatGrams` add the grams from this
   tick (the discretization of the CHO_total/FAT_total integral, see theoretical
   document §8.2).
5. **Exponential moving average** (`choAvgEmaGH`): this is the specific smoothing
   technique this app uses for the displayed rate (theoretical document §8.3 —
   which technique and with what parameters is an implementation decision, not
   part of the model). It is updated with `alpha_tick = dtMin / TAU_EMA_MIN`
   (τ=15 min). The first valid sample initializes the EMA directly with the
   instantaneous value (it does not start at 0 and climb slowly).

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

The `CHO avg (g/h)` value is colored with `colorPerCho(value, sessionMinutes)`
following the time-staggered bands described in the theoretical document (§9):

| Elapsed time | Green | Orange | Red |
|---|---|---|---|
| < 45 min | (always green) | — | — |
| 45 min - 2h | < 30 g/h | 30-60 g/h | > 60 g/h |
| > 2h | < 60 g/h | 60-90 g/h | > 90 g/h |

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

- The model is an approximation based exclusively on HR; it does not capture the
  effect of duration on relative substrate expenditure (glycogen being depleted
  at the same relative intensity as time passes), since it is inherently a
  point-in-time model.
- `HRmax` and `LT2` are estimates based on configured HR zones, not direct
  measurements — their accuracy depends on how the user (or Garmin) has
  configured those zones.
- Data is not saved visibly to Garmin Connect (no `FitContributor` has been
  implemented); for later analysis, the activity's standard `.FIT` file must be
  reprocessed with an external tool (the app already has a reference Python
  script, used during development to validate the algorithm against real data).
