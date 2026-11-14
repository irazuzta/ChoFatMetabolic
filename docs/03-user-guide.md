# User guide

This document explains, in plain language and without formulas, what the data
field shows on screen, what each profile parameter means, and how to configure
it. If you want to know how everything is calculated under the hood, see
[Theoretical basis](01-theoretical-basis.md) (the scientific model) or
[How the app works](02-app-implementation.md) (how it's implemented).

> **Who is it for?** The estimates are calibrated for recreational-to-trained
> endurance athletes (roughly VO2max 45-60) who eat a normal mixed diet and train
> after eating. If you train fasted, follow a low-carb or ketogenic diet, or are an
> elite athlete, the app will tend to **overestimate** carbohydrate burn; if you are
> untrained, it will tend to **underestimate** it. Long sessions, heat and
> dehydration also push the estimate up. Think of the numbers as a good indication
> of order of magnitude and trends, not as a lab measurement.

## 1. What you see on screen

```
[ CHO (g)        | 123    ]
[ CHO avg (g/h)  | 45  Z3 ]
[ FAT (g)        | 67     ]
```

- **CHO (g)** — total carbohydrate you've burned since you started the
  activity.
- **CHO avg (g/h)** — the rate at which you're burning carbohydrate right now
  (a smoothed average, not the raw instantaneous value). It's colored
  depending on whether this rate is low, medium, or high (see §4).
- **FAT (g)** — total fat you've burned since you started the activity.
- **Z1..Z5** (on the right of the middle row) — your current heart rate zone,
  colored the same way Garmin Connect colors heart rate zones.

## 2. How to add the field to an activity

1. On the watch, enter the activity you want (Run, Bike...) without starting
   it yet.
2. Press and hold the "Menu" button / swipe to access the activity's options.
3. Look for **"Edit Data Screens"** or similar, and pick a screen.
4. Select the field you want to replace and, under the **Connect IQ** field
   category, pick **"CHO/FAT Metabolic Pro"**.

## 3. Your profile parameters

The app uses 6 values to personalize the calculation. By default they are all
in **automatic mode** (the watch estimates them on its own); you only need to
touch them if you know the real value and want more accuracy.

| Parameter | What it is, in plain terms | How it's estimated in automatic mode |
|---|---|---|
| **Weight** | Your body weight | Read from your Garmin profile |
| **Resting HR** | Your heart rate at complete rest | Read from your Garmin profile |
| **Max HR** | Your maximum heart rate | Taken from the ceiling of zone 5 configured for your current sport (running, cycling...) |
| **LT2 Threshold** | Your anaerobic threshold (the intensity above which you start accumulating fatigue quickly) | Taken from the ceiling of zone 4 configured for your current sport |
| **LT1 Threshold** | Your aerobic threshold (a bit below the previous one) | Calculated as 89% of LT2 |
| **VO2max** | Your maximum aerobic capacity | Read from your Garmin profile — the running or cycling estimate, matching your current activity |

On a Garmin watch, "current sport" is usually Running; on an **Edge bike
computer**, it's Cycling — the field automatically uses your cycling zones and
cycling VO2max estimate in that case, no extra setup needed.

## 4. How to edit them manually

1. Open the **Connect IQ Store** app directly — or, just as well, open the
   **Garmin Connect** app and go to your watch → **Connect IQ Store** (or
   **My Apps**).
2. Find "CHO/FAT Metabolic Pro" and open it.
3. Tap **Settings/Configure** and enter any values you know.
4. Leave any parameter at **0** if you want it to keep being estimated
   automatically.

**Why LT2 matters most — especially for cyclists**: of the 6 values, `LT2
Threshold` has by far the biggest impact on accuracy — `LT1` and the point where
carb burning starts ramping up are both calculated as a percentage of it, not
set independently. If you only enter one value manually, make it this one. This
matters even more if you ride with an Edge: Garmin auto-detects lactate
threshold for running, but not for cycling — the automatic cycling equivalent
is FTP, a power number, not a heart rate. So if you're a cyclist, it's worth
setting `LT2 Threshold` by hand: use the heart rate from your FTP test (the
steady effort, not the wattage itself), or your cycling Lactate Threshold Heart
Rate from Garmin Connect's Physiological Metrics if you've set one.

**Finding your LT1 (optional)**: if you leave `LT1 Threshold` at 0, the app uses
89% of your LT2, which is the average found in published studies of recreational
runners and cyclists — but individual values vary by roughly ±9 bpm around it. If
you want a better value, in order of reliability:

1. A **lab test** (lactate step test or gas-exchange test): enter the heart rate at
   your first lactate rise, or at your first ventilatory threshold (VT1).
2. A **home test with a chest strap and an HRV-based method** (the "DFA-alpha1 =
   0.75" ramp test, offered by some training apps): do it fresh, repeat it on two
   different days, and check it against the highest heart rate at which you can
   still speak in full sentences. Fatigue makes this method read too low.
3. If you are not sure, **leave it at 0**. Please don't use "180 minus age" — it
   has no validation for this purpose.

## 5. What the colors mean

### CHO avg color (fueling guidance)

During the first 45 minutes it's always green (your glycogen stores are still
full). After that:

| Green | Orange | Red |
|---|---|---|
| under 60 g/h | 60-90 g/h | 90 g/h or more |

These limits follow how much carbohydrate a person can realistically absorb while
exercising: about 60 g/h from a single source, up to about 90 g/h with glucose +
fructose blends.

Red doesn't mean "alarm" — it means you are burning carbohydrate faster than you
can replace it while exercising, so the difference is coming out of your glycogen
stores. That is normal at moderate-to-hard intensity. It's a hint to fuel early and
keep eating during long efforts.

### Zone color (Z1..Z5)

Same scheme as Garmin Connect: grey (Z1), blue (Z2), green (Z3), orange (Z4),
red (Z5). It's independent of the CHO color — one indicates effort intensity,
the other carbohydrate consumption.

## 6. Your data after the activity

The app saves its results inside the activity, so you can review them once the
workout is over. After your watch syncs, open the activity in Garmin Connect:

- **Charts**: accumulated CHO (g), accumulated FAT (g) and the CHO rate (g/h,
  smoothed) over the whole activity.
- **Summary**: total CHO (g), total FAT (g) and average CHO (g/h) for the activity.

Nothing needs to be configured — it is recorded automatically whenever the field
is on screen during an activity. Services that ignore custom data fields (such as
Strava) may not display it, but the values are stored in the activity's `.FIT`
file.
