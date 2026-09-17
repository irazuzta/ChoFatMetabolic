# Connect IQ Store listing (English)

Draft text for the app's public Store page (Connect IQ Developer Portal). This is
user-facing copy — no code or internal implementation details. Paste the relevant
sections into the corresponding fields when submitting the app.

## Short description (tagline)

> Real-time carb & fat burn tracking with science-based fueling guidance.

(74 characters — check the exact character limit in the submission form, as Garmin
may adjust it over time.)

## Long description

**Fuel smarter, not by guesswork.**

CHO/FAT Metabolic is a Data Field that estimates, second by second, how many grams of
carbohydrate and fat your body is burning during exercise — using only your heart
rate. No extra sensors, no manual logging. Works on watches and Edge bike computers.

**What you see on screen**
- **CHO (g)** — total carbohydrate burned so far this session.
- **CHO avg (g/h)** — a smoothed, real-time carbohydrate burn rate, color-coded as a
  fueling guide: green, orange, or red depending on how your current burn rate
  compares to standard sports-nutrition intake guidelines for that point in your
  workout.
- **FAT (g)** — total fat burned so far this session.
- A small **zone indicator (Z1-Z5)**, colored the same way Garmin Connect colors your
  heart rate zones, so you can see effort and fueling status at a glance.

**Built on established exercise science**

The underlying model is not a gimmick — it combines well-known methods from exercise
physiology:
- Heart-rate-based VO2 estimation (heart rate reserve method).
- The classic Frayn equations for calculating carbohydrate and fat oxidation from
  gas-exchange variables.
- Duration-aware carbohydrate fueling bands based on published sports-nutrition
  guidelines for endurance exercise.

**Works out of the box**

The app automatically reads your weight, resting heart rate, and heart rate zones
from your Garmin profile to personalize the calculation. If you know your own
physiological numbers (max heart rate, aerobic and lactate thresholds, VO2max), you
can enter them manually in the app settings for even more accurate results.

Tip: for best accuracy, set up your Garmin heart rate zones using the **Lactate
Threshold** method instead of %HRmax — modern Garmin watches estimate your lactate
threshold automatically during running/cycling activities (or you can enter it
manually). This app estimates your anaerobic threshold from your zone 4 ceiling, so
zones based on lactate threshold line up much more closely with the real value.

**A note on accuracy**

This app provides an estimate based on established exercise science models, calibrated
for endurance athletes. It is a training aid, not a medical or diagnostic device, and
should not replace professional medical or nutritional advice.

Tip: fat burning naturally takes a few minutes to ramp up at the start of exercise, so
readings in the first 10-20 minutes will lean more toward carbs than later in the
session — a short warm-up beforehand can reduce this delay.

**Want the details?** Full documentation — a plain-language user guide plus the
underlying science and references — is available at
https://irazuzta.github.io/ChoFatMetabolic/

## Additional Information

**Source Code URL**: `https://github.com/irazuzta/ChoFatMetabolic`

## Notes for the person submitting (not for the Store page)

- App name on the Store will follow whatever is set as `@Strings.AppName` in the
  manifest (currently "CHO/FAT Metabolic").
- Screenshots: take clean captures from the simulator (or a real device) showing the
  3-row layout with non-zero, readable values in each of the three fueling colors
  (green/orange/red) if possible, to showcase the color-coding feature.
- Consider adding a short privacy note if the submission form asks for one: the app
  does not collect, store, or transmit any personal data — all calculations happen
  locally on the device.
