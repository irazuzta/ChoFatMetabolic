# Missatges de llançament de la 1.0 (Reddit i fòrum de Garmin)

Textos en anglès per publicar a mà. Cada comunitat té la seva versió (Reddit filtra
com a spam els missatges idèntics en diversos subreddits).

Abans de publicar:
- Llegir les normes de cada subreddit (autopromoció, flair, dia permès).
- Adjuntar imatges: la capçalera (`store-assets/hero_image.png`) i una captura del camp
  al rellotge.
- Respondre els comentaris les primeres hores.

Enllaços:
- Store: https://apps.garmin.com/en-US/apps/d1d623e2-36e9-42c9-a673-fb37d8e8830e
- Site: https://irazuzta.github.io/ChoFatMetabolic/
- Paper 1.0: https://doi.org/10.5281/zenodo.24424749
- Codi: https://github.com/irazuzta/ChoFatMetabolic

---

## 1. r/Garmin

**Title**

I made a free Connect IQ data field that splits your Garmin calories into carbs and fat burned (v1.0, open source)

**Body**

Hi all! I'm the developer of **CHO/FAT Metabolic Pro**, a free data field for Garmin
watches and Edge bike computers. I've just released version 1.0 and I'd love some
feedback from people who use it in real workouts.

**What it shows, in real time**

- **CHO (g):** grams of carbohydrate burned so far.
- **CHO avg (g/h):** your current carb burn rate (about the last 15 min), colour-coded as
  a fuelling guide: green, orange or red compared to how much carb you can absorb
  (about 60–90 g/h).
- **FAT (g):** grams of fat burned so far.
- Everything is saved to the activity, so you get charts in Garmin Connect.

**How it works**

- **How much energy:** Garmin's own estimate, the same calories you see in Garmin
  Connect.
- **Where it comes from:** the field splits that energy between carbs and fat with a
  continuous model based on your heart rate and your thresholds (Jeukendrup & Wallis
  equations). Not a fixed % per zone. The grams always add up to exactly Garmin's
  calories.

**What you need:** just the watch. No power meter, no chest strap required, no account,
no subscription, no payment.

**Setup:** nothing to set up if your Garmin profile and HR zones are right. Best results
with HR zones based on lactate threshold (%LTHR).

**Open:** the method is fully documented, with papers on Zenodo and the source code on
GitHub.

- Store: https://apps.garmin.com/en-US/apps/d1d623e2-36e9-42c9-a673-fb37d8e8830e
- Docs and papers: https://irazuzta.github.io/ChoFatMetabolic/

It's an estimate, not a lab measurement: the energy is Garmin's, and the carb/fat split
is a model based on published science. If you try it, I'd really appreciate your
comments (and a review on the Store if you find it useful).

---

## 2. r/trailrunning (o r/ultrarunning, r/AdvancedRunning)

**Title**

Free Garmin data field that shows how many grams of carbs you burn per hour, to help plan fuelling on long runs

**Body**

On long runs and races I always wondered how many carbs I was actually burning, compared
to what I was eating. So I built a free Connect IQ data field for Garmin watches:
**CHO/FAT Metabolic Pro**. Version 1.0 is out.

During the run it shows:

- **CHO avg (g/h):** your carb burn rate right now, in green, orange or red depending on
  whether you can realistically replace it by eating (about 60–90 g/h).
- **CHO (g)** and **FAT (g):** total grams burned so far.

It only uses your watch: Garmin's own calories, split between carbs and fat with a model
based on your heart rate and your thresholds. No power meter, no account, no
subscription. Nothing to set up if your HR zones are right (ideally based on lactate
threshold).

A few honest notes: it is calibrated for trained recreational athletes who train after
eating. If you run fasted or low-carb, it will overestimate carb burn. And it's a guide,
not a lab test.

- Store: https://apps.garmin.com/en-US/apps/d1d623e2-36e9-42c9-a673-fb37d8e8830e
- How it works: https://irazuzta.github.io/ChoFatMetabolic/

I'm the developer and it's a free hobby project. Feedback from real long runs and races
is very welcome!

---

## 3. r/Velo (o r/cycling, r/gravelcycling)

**Title**

Carbs and fat burned on your Edge without a power meter: free Connect IQ data field (v1.0)

**Body**

I've released version 1.0 of **CHO/FAT Metabolic Pro**, a free Connect IQ data field
that works on Edge bike computers and Garmin watches. It estimates, in real time, the
grams of carbohydrate and fat you burn, and your carb burn rate per hour as a fuelling
guide.

Most tools that do this need a power meter, a lab test or a subscription. This one uses
only what the Edge already has: Garmin's calories and your heart rate. The energy is
split between carbs and fat with a continuous model based on your heart rate and your
thresholds (Jeukendrup & Wallis equations), and the grams always add up to Garmin's
calories.

One tip for cyclists: Garmin doesn't auto-detect lactate threshold on the bike. Set your
cycling HR zones from your threshold HR, or enter your LT2 in the app settings (the HR
of your FTP test is a good value).

- Store: https://apps.garmin.com/en-US/apps/d1d623e2-36e9-42c9-a673-fb37d8e8830e
- Method and papers: https://irazuzta.github.io/ChoFatMetabolic/

It's a model, not a lab measurement, so read it as a guide. I'm the developer (free,
open source, no ads); I'd love feedback from long rides.

---

## 4. Fòrum de Garmin: Connect IQ → Showcase

**Title**

[Data Field] CHO/FAT Metabolic Pro 1.0: carbs and fat burned from Garmin's own calories

**Body**

Hi everyone,

I've just released **CHO/FAT Metabolic Pro 1.0**, a free data field that estimates
carbohydrate and fat oxidation in real time.

**What it shows:** total CHO (g), CHO burn rate (g/h, colour-coded as a fuelling guide),
total FAT (g) and an HR zone indicator. Totals, rate and charts are saved to the FIT file
and shown in Garmin Connect.

**What's new in 1.0:** the energy now comes from the device itself
(`Activity.Info.calories`, the same calories shown in Garmin Connect). The field splits
it between carbohydrate and fat with a respiratory exchange ratio estimated from heart
rate and the thresholds, and the Jeukendrup & Wallis equations. The energy per litre of
oxygen is computed with the same coefficients, so CHO and fat always add up to exactly
Garmin's calories. If the device gives no calories, the field falls back automatically
to the previous HR-only model.

**Requirements:** just the watch or Edge. No power meter, no account, no subscription.
Works out of the box if the user profile and HR zones are set; %LTHR zones recommended.

**Open method and code:**
- Documentation: https://irazuzta.github.io/ChoFatMetabolic/
- Paper (Zenodo): https://doi.org/10.5281/zenodo.24424749
- Source (GPLv3): https://github.com/irazuzta/ChoFatMetabolic

**Store:** https://apps.garmin.com/en-US/apps/d1d623e2-36e9-42c9-a673-fb37d8e8830e

Feedback is very welcome, especially from devices I haven't tested on real hardware.
Thanks!
