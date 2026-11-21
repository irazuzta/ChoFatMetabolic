# How the CHO/FAT Metabolic Pro app works

This document explains how the data field is implemented, referencing the theoretical
basis and the source code in [`source/CHOFATView.mc`](https://github.com/irazuzta/ChoFatMetabolic/blob/master/source/CHOFATView.mc). It
does not repeat the scientific justification for each formula — it focuses on how the
code is organized and why each engineering decision was made.

- **From version 1.0** the energy comes from Garmin and the app only splits it between
  carbohydrate and fat: [Theoretical basis (HR + Garmin energy)](04-theoretical-basis-garmin-energy.md).
- **Up to version 0.5** the whole calculation came from HR alone. That model is still
  used as a **fallback** when Garmin gives no energy (§3.4):
  [Theoretical basis (HR model)](01-theoretical-basis.md).


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

When the data field is created, the physiological parameters are resolved. Since
version 1.0 they do not all play the same role:

| Parameter | Used for | How important |
|---|---|---|
| $HR_{max}$, $LT_2$ (and $LT_1$ if known) | RER from HR → the split between CHO and fat | **Key** in every mode |
| Weight, resting HR, $VO_{2max}$ | $VO_2$ from HR, only in the fallback mode (§3.4) | Only if Garmin gives no energy |

The energy itself comes from Garmin, which computes it with the user profile on the
device (weight, age, maximum HR, $VO_{2max}$). So keeping the **Garmin profile and HR
zones up to date** is what matters most.

For each parameter, the priority is:

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
et al., 2025) but not a measurement. **Zones built on a measured lactate threshold
(%LTHR) line up much better**, and since $LT_2$ decides the split, this is the single
most useful thing a user can set up. At the end of `carregarPerfil()` there is a
coherence check: if `HRmax` does not end up above `HRrest`, or if `LT2` does not end
up in between, it is corrected automatically (absurd values are never allowed to
silently break the RER calculation later on).

The automatic `VO2max` (fallback mode only) is sport-aware: Garmin stores running
VO2max (`profile.vo2maxRunning`) and cycling VO2max (`profile.vo2maxCycling`)
separately — the app picks one or the other depending on whether the current sport is
`UserProfile.HR_ZONE_SPORT_BIKING`. If the sport-specific value is missing (common for
cyclists without a power meter), the other one is used before falling back to the
default.

The "onset of exercise" point $I_{onset}$ is always calculated as a fraction of `lt2`,
with the constant `PCT_ACTIVACIO_CHO = 0.70` — it has no laboratory equivalent, so it
is not offered as a manual value. $LT_1$, on the other hand, is a real physiological
threshold that an athlete may know from their own testing: if the user enters a manual
value (`lt1Manual`, property > 0) and it is coherent (above `fcRepos` and above the
CHO-onset point `0.70 * lt2`, and below `lt2`), it is used directly; if not, it is
silently discarded and the estimate `PCT_LT1 * lt2` (`PCT_LT1 = 0.89`) is used.

When an activity ends (`onTimerReset()`), all the accumulated state (grams, EMA,
active time, energy counter, fallback flag) is cleared and the profile is read again,
so the next activity does not inherit anything from the previous one.

## 3. Calculation cycle (`compute()`)

`compute(info)` runs about once per second. It only reads three values from
`Activity.Info` — the timer time, the cumulative energy (`info.calories`) and the
current HR — and passes them to `processa()`, which holds all the logic (this split
also lets the unit tests feed it synthetic data).

### 3.1. Every tick: time and RER

1. **Time control**: `dtMs` is calculated since the last sample. If `dtMs <= 0` the
   timer is stopped (pause, or before the activity starts) and nothing accumulates.
2. **Valid HR**: a sample has valid HR if `currentHeartRate` is not null and
   `dtMs <= DT_MAX_MS` (5000 ms; a longer gap is typically an optical sensor dropout).
3. **Current HR zone** (`zonaFCActual`), for the small Z1–Z5 indicator.
4. **RER from HR** (`rerPerFc()`): the piecewise interpolation with the constants at
   the top of the class: `RER_BASAL = 0.86`, `RER_LT1 = 0.91`, `RER_LT2 = 0.98`,
   `RER_MAX = 1.00`, `PCT_LT1 = 0.89`, `PCT_ACTIVACIO_CHO = 0.70`.

### 3.2. Garmin energy mode (normal)

`info.calories` is the **total** energy of the activity (resting included), as an
integer that goes up 1 kcal at a time (every ~5–7 s when running). The app does not
try to turn it into a per-second rate; it works with the **interval between two
increments** (theoretical basis §7):

**Open interval.** While the counter does not change, each tick adds to the current
interval: its duration, and the RER weighted by time (`intRerMin`, `intMinFc`, only
ticks with valid HR).

**Closing an interval.** When the counter goes up by $\Delta E$ kcal, the interval
closes. With the mean RER of the interval, $\overline{RER}$:

$$g_{CHO} = 4.210\cdot\overline{RER} - 2.962 \qquad g_{FAT} = 1.695 - 1.701\cdot\overline{RER} \qquad (\text{each floored at } 0)$$

$$\text{litres of O}_2 = \frac{\Delta E}{4.1\cdot g_{CHO} + 9.3\cdot g_{FAT}} \qquad \Delta CHO = \text{litres}\cdot g_{CHO} \qquad \Delta FAT = \text{litres}\cdot g_{FAT}$$

(`KCAL_G_CHO = 4.1`, `KCAL_G_FAT = 9.3`). By construction
$4.1\cdot\Delta CHO + 9.3\cdot\Delta FAT = \Delta E$: the grams always add up to
exactly Garmin's energy.

**Special cases:**

- **First reading**: the first value of the counter is only a **base**. The energy
  Garmin had already counted (for example, if the data field is added mid-activity)
  is not split.
- **No valid HR in an interval**: the last valid RER is used, because Garmin's energy
  for that time is still real. If there has never been valid HR, the increment only
  moves the base.
- **Pauses**: if Garmin counts energy while the timer is stopped, it is not split; the
  base just moves on.
- **Counter going down** (should not happen): it becomes a new base, never negative
  grams.

### 3.3. Displayed rate: `CHO avg (g/h)`

In Garmin mode the grams arrive in jumps (zero most seconds, a spike at each
increment), so a per-second rate is useless on its own. The displayed value is an
**exponential moving average** with τ = 15 min (`TAU_EMA_MIN`), updated each tick with
`alpha_tick = dtMin / TAU_EMA_MIN` (theoretical basis §10).

The first interval is partial (the field starts reading at some point between two
increments) but carries a whole kilocalorie, so its rate can be several times too
high. That is why, **during the first minute** of active time (`EMA_INIT_MS = 60000`),
the field shows the real mean (total grams / time), and only then does the EMA start,
from that value.

### 3.4. Fallback mode: the HR model

If Garmin gives no energy, the field computes exactly as version 0.5 did, from HR alone
([HR model](01-theoretical-basis.md)): %HRR → $VO_2$ (weight, resting HR, $VO_{2max}$),
RER from HR, and the Jeukendrup & Wallis equations, accumulating `rate × dt` each
second. It switches to fallback when:

- `info.calories` is `null` (the device or the situation does not provide it), or
- the counter **has not moved for 120 s** with the timer running
  (`CAL_STALL_MS = 120000`).

In fallback mode, ticks without valid HR accumulate nothing (as in 0.5). When the
counter comes back (or changes for the first time after being stuck), that value is a
**new base**: the energy counted meanwhile is not split again, so nothing is counted
twice. The final version shows the usual `Z1`–`Z5` indicator in both modes; the active
mode is not shown on screen.

### 3.5. Accumulation

- `totalChoGrams` and `totalFatGrams` add the grams of each tick (zero most ticks in
  Garmin mode, the interval's grams when it closes).
- `tempsActiuMs` counts the active time used for the session mean (`cho_avg_gh`). In
  Garmin mode it also counts seconds without HR, because their energy is included.


### 3.6. Saving results to the activity file (`FitContributor`)

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
can realistically absorb while exercising ([HR model](01-theoretical-basis.md) §9: about 60 g/h
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

[`tools/Run-Simulator.ps1`](https://github.com/irazuzta/ChoFatMetabolic/blob/master/tools/Run-Simulator.ps1) automates building and
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

- **The amount of energy is Garmin's estimate.** It is as good as Garmin's
  calculation and the user profile on the device (weight, age, maximum HR,
  $VO_{2max}$); wearables have known errors in energy expenditure. If Garmin's
  estimate improves, the result improves without changing anything in the app.
- **The split between CHO and fat is the app's own estimate, and it has not been
  validated** against a gas analyser. It depends on the RER estimated from HR,
  calibrated for recreational-to-trained athletes on a normal mixed diet in a fed
  state ([HR model](01-theoretical-basis.md) §10). It does not capture the effect of
  duration (RER tends to fall as the effort goes on, so CHO is increasingly
  overestimated in long sessions), nor diet, fasting, sex or heat. Elite or
  fat-adapted athletes will see CHO overestimated and untrained people
  underestimated. As a rule of thumb, at 12 kcal/min each 0.01 of RER error is about
  6 g/h of CHO ([theoretical basis](04-theoretical-basis-garmin-energy.md) §6). Treat
  the numbers as an indication of order of magnitude and trends, not as a
  measurement.
- `HRmax` and `LT2` are estimates based on configured HR zones, not direct
  measurements — their accuracy depends on how the user (or Garmin) has
  configured those zones. With Garmin's default %HRmax zones, the zone 4 ceiling is
  just 90% of HRmax. Since they decide the split, this is the main thing to get
  right.
- In the fallback mode (§3.4) the energy also comes from HR, as in version 0.5, and
  tends to be higher than Garmin's.
- Results are saved in the activity (custom FIT fields) and shown by Garmin
  Connect after syncing, but services that ignore developer fields (e.g. Strava)
  will not display them; the values are still in the `.FIT` file.
