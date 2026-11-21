# Connect IQ Store listing (English)

Draft text for the app's public Store page (Connect IQ Developer Portal). This is
user-facing copy — no code or internal implementation details. Paste the relevant
sections into the corresponding fields when submitting the app.

## Store name (version 1.0)

The current name ("CHO/FAT Metabolic Pro") has none of the words people search for
("carbs", "fat", "burn"). Proposals, best first:

1. `CHO/FAT Metabolic – Carbs & Fat Burned` (38 characters)
2. `CHO/FAT Metabolic: Carbs & Fat` (30 characters) — if the form does not accept 38.

The exact limit is not documented; check it in the developer portal form. Other Store
apps use names of at least 34 characters. The name shown on the watch
(`@Strings.AppName`) can stay "CHO/FAT Metabolic Pro".

## Short description (tagline)

> Carbs & fat burned in real time, from your watch's own calories and heart rate.

(79 characters — check the exact limit in the submission form.)

## Long description

**Your watch tells you how much energy you burn. This field estimates where it comes
from.**

CHO/FAT Metabolic Pro is a Data Field that shows, in real time, how many grams of
carbohydrate and fat you are burning during exercise — using only your watch or Edge.
No power meter, no extra sensors, no account, no subscription, no manual logging.

**What you see on screen**
- **CHO (g)** — total carbohydrate burned so far this session.
- **CHO avg (g/h)** — how fast you are burning carbohydrate right now (roughly the
  last 15 minutes), color-coded as a fueling guide: green, orange or red depending on
  how your burn rate compares to how much carbohydrate you can realistically absorb
  while exercising (about 60 g/h, up to about 90 g/h with multiple-transportable carbs).
- **FAT (g)** — total fat burned so far this session.
- A small **zone indicator (Z1-Z5)**, colored the same way Garmin Connect colors your
  heart rate zones.

**How it works**
- **How much energy**: Garmin's own estimate — the same calories you see in Garmin
  Connect. Carbohydrate and fat always add up to exactly that number.
- **How it is split** between carbohydrate and fat: a continuous model based on your
  heart rate and your metabolic thresholds, using the Jeukendrup & Wallis equations
  from exercise physiology. Not a fixed percentage per zone: the split changes smoothly
  as your intensity changes.
- The full method is open: documentation and papers (English and Catalan) explain every
  formula and reference.

**Works out of the box**

There is nothing to set up if your Garmin profile and heart rate zones are right:
- Your **heart rate zones** decide the split. For best results, set them up with the
  **Lactate Threshold** method (%LTHR) instead of %HRmax: the app reads your lactate
  threshold (LT2) from the top of zone 4.
- Your **Garmin profile** (weight, age, max HR) decides the calories, so keep it up to
  date.
- Cyclists on an Edge: Garmin does not auto-detect lactate threshold for cycling. Set
  cycling zones based on your lactate threshold heart rate, or enter your LT2 in the
  app settings (the heart rate of your FTP test effort is a good value).

If you know your own thresholds (LT1, LT2, max HR), you can enter them in the app
settings.

**A note on accuracy**

The energy is Garmin's estimate: if it is off, it is also off in Garmin Connect. The
split between carbohydrate and fat is this app's own estimate, based on published
science but not validated with a gas analyser. It is calibrated for
recreational-to-trained endurance athletes eating a normal mixed diet and training
after a meal. If you train fasted, follow a low-carb or ketogenic diet, or are an elite
athlete, it will tend to overestimate carbohydrate burn; if you are untrained, to
underestimate it. In very long sessions it also tends to overestimate it. Read the
numbers as a guide, not as a lab measurement. It is a training aid, not a medical or
diagnostic device.

**Review it after your workout.** The results are saved in the activity: once your
watch syncs, Garmin Connect shows charts of accumulated CHO, accumulated FAT and CHO
rate, plus total CHO, total FAT and average CHO in the activity summary.

**Want the details?** User guide, theory and papers:
https://irazuzta.github.io/ChoFatMetabolic/

## What's New (version 1.0.0 — this version)

```
New energy model. The calories now come from your Garmin watch itself - the same
calories you see in Garmin Connect - and the app splits them between carbohydrate
and fat with its heart-rate model. Carbohydrate and fat always add up to exactly
Garmin's calories. Before, the app estimated the energy from heart rate alone and it
usually came out higher than Garmin's, so CHO figures are now somewhat lower (about
5-10% in our tests). If Garmin gives no calories, the field automatically uses the
previous heart-rate model. Your HR zones (ideally based on lactate threshold) and
your Garmin profile matter most; weight and VO2max in the app settings are now only
used as a fallback. No changes to the screen, the settings or the data saved in
Garmin Connect. New documentation and papers on the website.
```

## What's New (version 0.5.0)

```
Improved carbohydrate/fat estimate for athletes on a normal diet. The previous
version assumed a fat-adapted or fasted profile, so it underestimated carbohydrate
burn at low and moderate intensity. The model now assumes you have eaten: at a
steady moderate effort the CHO figures are noticeably higher (roughly two thirds
higher around 140 bpm for a typical athlete), while at and above your lactate
threshold they are unchanged. The default aerobic threshold (LT1) is now 89% of
LT2, based on published data. The CHO color bands now compare your burn rate with
how much carbohydrate you can actually absorb: after the first 45 minutes, green
under 60 g/h, orange 60-90 g/h, red above. The documentation explains the profile
the estimate is calibrated for (diet, fed state, training level) and its limits.
```

## What's New (version 0.4.1)

```
Reliability fixes. Starting a new activity now always begins from zero (previously
a second activity on devices that keep the field loaded, such as Edge, could carry
over the previous totals). Cyclists without a power meter now use their running
VO2max estimate instead of a generic default. The average CHO rate is now more
accurate after sensor dropouts, and the field keeps working even on devices that
cannot record custom data. No changes to the screen layout.
```

## What's New (version 0.4.0)

```
Your results are now saved with the activity. After syncing, Garmin Connect shows
charts of accumulated CHO, accumulated FAT and CHO rate (g/h), plus total CHO,
total FAT and average CHO (g/h) in the activity summary — so you can review your
fueling after the workout, not just during it. No changes to the calculation or
to the on-screen layout.
```

## What's New (previous version)

```
Added compatibility with Garmin Edge bike computers — a small adaptation of the
original running-focused model to also work for cycling, using your cycling HR
zones and VO2max automatically. No changes to the underlying calculation.

Also added guidance for cyclists on setting your anaerobic threshold (LT2)
manually, since Garmin doesn't auto-detect lactate threshold for cycling the
way it does for running — see the description above and the user guide.
```

## Additional Information

**Source Code URL**: `https://github.com/irazuzta/ChoFatMetabolic`

## Notes for the person submitting (not for the Store page)

- App name on the Store will follow whatever is set as `@Strings.AppName` in the
  manifest (currently "CHO/FAT Metabolic Pro").
- Screenshots: take clean captures from the simulator (or a real device) showing the
  3-row layout with non-zero, readable values in each of the three fueling colors
  (green/orange/red) if possible, to showcase the color-coding feature.
- Consider adding a short privacy note if the submission form asks for one: the app
  does not collect, store, or transmit any personal data — all calculations happen
  locally on the device.
