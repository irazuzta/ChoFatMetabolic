# Estimating carbohydrate and fat oxidation from heart rate

!!! info "Model used up to version 0.5"
    This page describes the original model, which estimates **everything from heart
    rate**, including the energy. Since **version 1.0** the energy comes from Garmin
    and the app only splits it between carbohydrate and fat:
    [Theoretical basis (HR + Garmin energy)](04-theoretical-basis-garmin-energy.md).

    This model is still used in 1.0 in two ways: the RER from HR (§5–6) is the same,
    and the whole model is the **fallback** when Garmin gives no energy.

    Papers (PDF): [English](paper/model-fc.en.pdf) · [Català](paper/model-fc.ca.pdf)
    (DOI: [10.5281/zenodo.24425095](https://doi.org/10.5281/zenodo.24425095)).

This document describes a model for estimating the oxidation rate of carbohydrate
(CHO) and fat (FAT) during exercise from a single, non-invasively measurable
variable: heart rate (HR). The physiology and mathematics
of the model are presented together with their scientific references, deriving it
step by step from the objective to its final form.

> **Scope.** The reference values of this model are chosen for **recreational-to-trained
> endurance athletes** (roughly $VO_{2max}$ 45-60 ml·kg⁻¹·min⁻¹) who eat a **normal
> mixed diet** and exercise in a **fed state**, at a steady effort. For other
> profiles — elite or fat-adapted athletes, fasted or low-carbohydrate training,
> untrained people — the estimate is biased in a known direction (see §10).

## 1. Objective

We want to know, at any instant $t$ during an activity, the **oxidation rate** of
carbohydrate and fat:

$$CHO(t),\ FAT(t) \quad \text{[g/min]}$$

and, from these instantaneous rates, the **cumulative total** over the whole
activity (from $0$ to the total duration $T$):

$$CHO_{total}(T) = \int_0^T CHO(t)\,dt \qquad\qquad FAT_{total}(T) = \int_0^T FAT(t)\,dt$$

The rest of the document introduces the necessary background concepts (§2), and
then answers, in order, two questions: **how $CHO(t)$/$FAT(t)$ is calculated**
(§3-7), and **how this instantaneous rate relates to a cumulative total** (§8).

## 2. Background concepts

Before getting into the model, it is worth clearly defining the physiological
variables that will be used throughout.

### 2.1. Oxygen consumption ($VO_2$) and CO2 production ($VCO_2$)

$VO_2$ is the volume of oxygen the body consumes per unit of time. It is measured
in litres/minute (absolute value) or in ml·kg⁻¹·min⁻¹ (relative to body weight,
useful for comparing people of different sizes). $VCO_2$ is, analogously, the
volume of carbon dioxide produced per unit of time. Both are the basis of
**indirect calorimetry**: since oxidizing fat or oxidizing carbohydrate consumes O2
and produces CO2 in different proportions (due to the different chemical
composition of both molecules), measuring $VO_2$ and $VCO_2$ allows deducing which
fuel is being burned, without having to measure it directly.

### 2.2. Maximal oxygen consumption ($VO_{2max}$)

$VO_{2max}$ is the highest $VO_2$ value a person can reach during maximal effort —
the classic reference measure of cardiorespiratory fitness (how much blood/oxygen
the cardiovascular and muscular system can pump and use per unit of time). It is
used as the upper end of the scale in this model (§4):

> Bassett DR Jr, Howley ET. **Limiting factors for maximum oxygen uptake and
> determinants of endurance performance.** *Medicine & Science in Sports & Exercise*.
> 2000;32(1):70-84.

### 2.3. Respiratory Exchange Ratio (RER)

$$RER(t) = \displaystyle\frac{VCO_2(t)}{VO_2(t)}$$

A single number, typically between $\sim 0.7$ and $\sim 1.0$ at rest/submaximal
exercise, that indicates the mix of substrates being oxidized: $RER=0.7$
corresponds to almost exclusively fat oxidation; $RER=1.0$, to almost exclusively
carbohydrate oxidation. It is the central variable of the model, since it relates
directly to the percentage of energy coming from each substrate (§5).

### 2.4. Relative heart rate: %HRmax and Heart Rate Reserve (%HRR)

Absolute heart rate (HR, beats/min) is not comparable between people — it must be
expressed relatively. Two common ways:

- **%HRmax**, the simplest, but physiologically less precise:

$$\%HR_{max} = \displaystyle\frac{HR}{HR_{max}}$$

- **%HRR** (heart rate reserve), which relativizes HR against the **full available
  range** (from rest to maximum), not only against the maximum:

$$\%HRR = \displaystyle\frac{HR - HR_{rest}}{HR_{max} - HR_{rest}}$$

  This is the one used by this model (§4.1). The conceptual origin of the
  "reserve method" is found in:

> Karvonen MJ, Kentala E, Mustala O. **The effects of training on heart rate; a
> longitudinal study.** *Annales Medicinae Experimentalis et Biologiae Fenniae*.
> 1957;35(3):307-315.

### 2.5. Relative oxygen consumption and VO2 Reserve (%VO2R)

Analogously to §2.4, $VO_2$ can be expressed relative to its own range, between the
resting value and $VO_{2max}$ (§2.2):

$$\%VO_2R = \displaystyle\frac{VO_2 - VO_{2,rest}}{VO_{2max} - VO_{2,rest}}$$

This model estimates $\%VO_2R$ from $\%HRR$ (§2.4), thanks to the empirical
equivalence between the two, discussed in detail in §4.2.

## 3. The starting point: the Jeukendrup & Wallis equations

The relationship between oxygen consumption, CO2 production, and grams of
substrate oxidized per minute has been known in exercise physiology since the
classic non-protein (i.e., ignoring the small contribution of protein oxidation)
indirect calorimetry equations of:

> Frayn KN. **Calculation of substrate oxidation rates in vivo from gaseous exchange.**
> *Journal of Applied Physiology*. 1983;55(2):628-634.

This model specifically uses the **modification of these equations for exercise**
(Frayn derived them with rest in mind, assuming glucose as the CHO substrate;
during exercise the predominant substrate is glycogen, which slightly changes the
coefficients):

> Jeukendrup AE, Wallis GA. **Measurement of substrate oxidation during exercise by
> means of gas exchange measurements.** *International Journal of Sports Medicine*.
> 2005;26(Suppl 1):S28-S37.

$$CHO(t) = 4.210\ VCO_2(t) - 2.962\ VO_2(t)$$

$$FAT(t) = 1.695\ VO_2(t) - 1.701\ VCO_2(t)$$

**What do we need to use this equation?** The two continuous variables defined in
§2.1: $VO_2(t)$ and $VCO_2(t)$. Neither can be measured without a laboratory gas
analyzer, so indirect methods of estimating them are needed (§4-7).

### 3.1. Rewriting the equation in terms of RER

Instead of estimating $VO_2$ and $VCO_2$ separately, it is more practical to
estimate $VO_2$ and the respiratory exchange ratio $RER$ (§2.3). Substituting
$VCO_2(t) = RER(t)\cdot VO_2(t)$:

$$CHO(t) = VO_2(t)\cdot\big(4.210\cdot RER(t) - 2.962\big)$$

$$FAT(t) = VO_2(t)\cdot\big(1.695 - 1.701\cdot RER(t)\big)$$

Now two independent estimates are needed: $VO_2(t)$ (§4) and $RER(t)$ (§5-6).

## 4. Estimating $VO_2(t)$ from heart rate

### 4.1. Heart rate reserve (%HRR)

$$\%HRR(t) = \displaystyle\frac{HR(t) - HR_{rest}}{HR_{max} - HR_{rest}}$$

(definition introduced in §2.4).

### 4.2. From %HRR to %VO2 reserve

The estimate is based on the empirical equivalence $\%HRR \approx \%VO_2R$ (§2.5;
$VO_2$ reserve, not $\%VO_{2max}$, which is less precise):

> Swain DP, Leutholtz BC. **Heart rate reserve is equivalent to %VO2 reserve, not to
> %VO2max.** *Medicine & Science in Sports & Exercise*. 1997;29(3):410-414.

$$VO_{2,relative}(t) = VO_{2,rest} + \%HRR(t)\cdot\big(VO_{2max} - VO_{2,rest}\big)$$

where $VO_{2,rest} = 3.5\ \text{ml}\cdot\text{kg}^{-1}\cdot\text{min}^{-1}$ (1 MET,
the standard resting oxygen consumption).

### 4.3. From relative to absolute

$$VO_2(t)\ [\text{L/min}] = \displaystyle\frac{VO_{2,relative}(t)\cdot weight\ (\text{kg})}{1000}$$

**Model limitations**: $\%HRR\approx\%VO_2R$ is a statistical approximation
(population average, with individual variability). The result depends directly on
the quality of $HR_{rest}$, $HR_{max}$ and $VO_{2max}$ as model inputs — in
practice, these three values are themselves often estimates too (not direct
laboratory measurements), which introduces an additional source of accumulated
uncertainty in the final result. Heart rate also drifts upwards at a constant
workload in the heat, with dehydration, or during long efforts (cardiac drift),
which the model reads as a higher intensity (see §10).

## 5. Estimating $RER(t)$: metabolic thresholds

Real RER is not constant: it rises non-linearly with intensity, especially around
the **metabolic thresholds** ($LT_1$, aerobic threshold; $LT_2$,
anaerobic/lactate threshold). The threshold concepts themselves, and how valid
each way of defining them is, are reviewed in:

> Faude O, Kindermann W, Meyer T. **Lactate threshold concepts: how valid are they?**
> *Sports Medicine*. 2009;39(6):469-490.

The way RER rises with intensity has been measured directly. In 61 trained
cyclists exercising after an overnight fast, mean RER was $0.82$ at rest and rose
to $0.86$, $0.90$ and $0.98$ at 41%, 63% and 80% of $VO_{2peak}$, with a standard
deviation of about $0.04$ between individuals at each intensity (Goedecke et al.,
2000).

$LT_1$ is physiologically defined as the point where blood lactate starts to rise
above resting level, usually at roughly 65-73% of $VO_{2max}$ in recreational
runners and cyclists. The point where the energy contribution is exactly 50% fat /
50% CHO is a related but **different** concept, known in the literature as the
**"crossover point"**:

> Brooks GA, Mercier J. **Balance of carbohydrate and lipid utilization during
> exercise: the "crossover" concept.** *Journal of Applied Physiology*.
> 1994;76(6):2253-2261.

According to the classic non-protein respiratory quotient table (Lusk 1924,
updated by Péronnet & Massicotte 1991), the 50%/50% point corresponds to
$RER\approx 0.85$. For a recreational-to-trained athlete eating a normal diet this
crossover happens at a fairly low intensity: peak fat oxidation ("Fatmax") occurs
at around 48% of $VO_{2max}$ on average (Venables et al., 2005; 300 healthy men and
women), and at $LT_1$ RER is already around $0.90$ — carbohydrate predominates
well before the first lactate threshold. $LT_2$, in turn, marks the **maximal
lactate steady state**: the limit intensity at which the body can still clear
lactate at the same rate it is being produced. Reported RER values at this point
range from about $0.90$ (steady state at the maximal lactate steady state itself)
to about $0.99$ (at the second ventilatory threshold in ramp tests), and fat
oxidation becomes marginal (from about $15\%$ of energy at $RER=0.95$ to
practically none at $RER=1.00$). Above $LT_2$, RER can exceed $1.00$ (peak values
around $1.2$ are measured at maximal effort; Edvardsen et al., 2014), but that
excess is CO2 released by the bicarbonate buffering of lactic acid, not additional
carbohydrate oxidation — so the model caps RER at $1.00$.

### 5.1. Interpolation model

Since lactate or gases cannot be measured without laboratory equipment, this curve
can be **approximated** with a piecewise linear interpolation, based on four HR
reference points: an **onset** point ($I_{onset}$, §6), $LT_1$, $LT_2$ and
$HR_{max}$:

$$
RER(t) =
\begin{cases}
R_{basal} & \text{if } HR(t) \le I_{onset} \\[6pt]
R_{basal} + \displaystyle\frac{HR(t) - I_{onset}}{LT_1 - I_{onset}}\big(R_{LT_1}-R_{basal}\big) & \text{if } I_{onset} < HR(t) \le LT_1 \\[10pt]
R_{LT_1} + \displaystyle\frac{HR(t) - LT_1}{LT_2 - LT_1}\big(R_{LT_2}-R_{LT_1}\big) & \text{if } LT_1 < HR(t) \le LT_2 \\[10pt]
R_{LT_2} + \displaystyle\frac{HR(t) - LT_2}{HR_{max} - LT_2}\big(R_{max}-R_{LT_2}\big) & \text{if } LT_2 < HR(t) \le HR_{max}
\end{cases}
$$

with the reference values chosen for this model:

| Point | Reference RER | Evidence (§5) |
|---|---|---|
| $R_{basal}$ (at and below the onset point; light effort, roughly 50% $VO_{2max}$) | $0.86$ | Fasted trained cyclists: $0.82$ at rest and $0.86$ at 41% $VO_{2peak}$ (Goedecke et al., 2000); eating raises RER at low intensity (Bergman & Brooks, 1999; Achten & Jeukendrup, 2003). Plausible range $0.82$-$0.90$ |
| $R_{LT_1}$ | $0.91$ | $\approx 0.90$ at 63% $VO_{2peak}$ even when fasted (Goedecke et al., 2000); $\approx 0.90$-$0.93$ at the first ventilatory threshold in fed amateur cyclists (estimated from the substrate oxidation rates reported by Martínez-Noguera et al., 2020). Plausible range $0.88$-$0.94$ |
| $R_{LT_2}$ | $0.98$ | $0.976$ at 80% $VO_{2peak}$ (Goedecke et al., 2000); $\approx 0.99$ at the second ventilatory threshold but $0.90$ at the maximal lactate steady state itself in amateur cyclists (Peinado et al., 2016). Plausible range $0.93$-$1.00$ |
| $R_{max}$ (at $HR_{max}$) | $1.00$ | Ceiling: the measured $RER>1.00$ near maximal effort is bicarbonate-derived CO2, not substrate oxidation, and the equations of §3 are only valid for $RER\le 1$ (§10.3) |

These values describe the typical first 30-60 minutes of a steady effort in the
profile defined in §10.1. The resulting curve rises slowly below $LT_1$ and faster
above it, which is the shape measured in trained athletes. The flat value below
the onset point is a simplification: real RER keeps creeping up with intensity
there too (fasted resting RER is about $0.80$-$0.82$, fed resting and light-exercise
RER about $0.85$-$0.90$).

**Model limitations**: this interpolation assumes that $RER(t)$ responds
instantaneously to HR and stays the same for the whole effort. In reality, fat
mobilization takes a few minutes to activate at the start of exercise, and RER
tends to fall as the effort goes on (§10.2). Prior exercise has been shown to raise
fat oxidation more than an overnight fast did in elite endurance athletes:

> Andersson Hall U, Edin F, Pedersen A, Madsen K. **Whole-body fat oxidation
> increases more by prior exercise than overnight fasting in elite endurance
> athletes.** *Applied Physiology, Nutrition, and Metabolism*. 2016;41(4):430-437.

## 6. Estimating the model's parameters

The model needs four HR reference points ($I_{onset}$, $LT_1$, $LT_2$,
$HR_{max}$, §5.1) and $VO_{2max}$ (§2.2). Often, an athlete who has undergone
specific testing (a lactate threshold test, a maximal exercise test with gas
analyzer) already knows the real values of $LT_1$, $LT_2$, $HR_{max}$ and
$VO_{2max}$ directly, in which case these are simply used as-is — no
approximation is needed. When this direct data is not available, the parameters
must be estimated indirectly; there are several reasonable ways to do this, but
they are outside the scope of this document (it will depend on what indirect
information is available in each specific case).

**Special case — $LT_1$ as a fraction of $LT_2$**: when $LT_1$ is not known
directly but (an estimate of) $LT_2$ is, it is common to approximate it as a
fraction of $LT_2$. Group studies that measured the heart rate at both thresholds
give ratios of about $0.88$-$0.91$:

| Study | Population | Method | $LT_1 / LT_2$ (heart rate) |
|---|---|---|---|
| Nuuttila et al. (2025) | 165 recreational runners | blood lactate | $\approx 0.89$ ($80.7\pm4.9\%$ vs $90.6\pm2.5\%$ of $HR_{max}$) |
| Esteve-Lanao et al. (2026) | 1,411 runners | ventilatory thresholds | $\approx 0.91$ |
| Lucía et al. (2000) | elite cyclists | ventilatory thresholds | $\approx 0.88$-$0.90$ |

The model therefore uses:

$$LT_1 \approx 0.89 \cdot LT_2$$

Individual variation around this ratio is large (a standard deviation of about 5%
of $HR_{max}$, roughly 9 bpm), and it showed only weak relationships with fitness
level, so a fixed fraction is a population estimate: a measured $LT_1$ is always
better when available. In the same study, fixed-%HR anchors estimated $LT_1$ with a
mean absolute error of roughly 5-7 bpm (Nuuttila et al., 2025).

**Special case — $I_{onset}$ (onset of exercise)**: this point differs from the
other three because **it cannot be measured directly, not even with a laboratory
test** — there is no test that reveals "the point where RER starts rising
gradually before $LT_1$", because it is not a discrete physiological event but a
smoothing device of the model itself (§5.1: no biological system switches
metabolic regime with a sharp step, so the model introduces this gradual
transition instead of an abrupt change of slope exactly at $LT_1$). This is why
$I_{onset}$ is **more arbitrary** than the other parameters: even an athlete with
all their laboratory data known would not have a "real" value for this point. The
following relationship is used:

$$I_{onset} \approx 0.70 \cdot LT_2$$

where the specific $0.70$ **does not come from any scientific article** — it is a
design choice of the model to make the transition gradual, not the value of a
measurement.

## 7. Complete point-in-time model

Putting §3-6 together: given HR at an instant $t$ and the personal parameters
(weight, resting HR, max HR, $LT_2$, $VO_{2max}$ and, optionally, a measured
$LT_1$), the model calculates, in this order:

$$\%HRR(t) \;\xrightarrow{\text{§4.1}}\; VO_2(t) \;\xrightarrow{\text{§4.2-4.3}}\; \Big(VO_2(t),\ RER(t)\Big) \;\xrightarrow{\text{§3.1}}\; CHO(t),\ FAT(t)$$

where $RER(t)$ is obtained in parallel from HR, by piecewise interpolation (§5-6).

This is the **point-in-time model**: given an isolated instant $t$ (and only the
HR at that instant), it calculates an oxidation rate — not a total, nor anything
that depends on what happened before. The result, $CHO(t)$ and $FAT(t)$, is always
expressed in **g/min** (§3), regardless of how often this calculation is used in
practice: the model does not know or care whether it is evaluated once per second,
once per minute, or a single isolated time — it always answers the same question
("at what rate would CHO/FAT be oxidized if HR stayed constant at this value"), in
the same unit.

The question of how to **link** this rate (g/min) to real measurements taken at
any other frequency (per second, per minute...) without needing to convert the
rate itself is precisely what the discretization in §8 solves: instead of
changing the units of $CHO(t)$/$FAT(t)$, the elapsed interval $\Delta t$ is
expressed in minutes (the same unit as the rate), whatever the actual interval
between samples.

## 8. From instantaneous rate to cumulative total: the integral and its discretization

### 8.1. Continuous formulation

As stated in §1, what really matters is the cumulative total, not just the rate
at one instant:

$$CHO_{total}(T) = \int_0^T CHO(t)\,dt \qquad\qquad FAT_{total}(T) = \int_0^T FAT(t)\,dt$$

This integral cannot be solved analytically because $CHO(t)$ depends on $HR(t)$,
which is an arbitrary function (whatever the person's heart actually does during
the activity) — not a closed-form mathematical formula.

### 8.2. Discretization: Riemann sum

With data available only in **discrete samples** ($t_0=0, t_1, t_2, \ldots, t_n$),
the simplest numerical approximation of an integral is the **Riemann sum**: hold
the rate constant from the last sample to the current one and multiply it by the
elapsed interval:

$$\Delta t_i = t_i - t_{i-1} \quad \text{(in minutes, since } CHO(t)/FAT(t) \text{ are in g/min)}$$

$$CHO_{total}(t_n) \approx \sum_{i=1}^{n} CHO(t_i)\cdot \Delta t_i \qquad\qquad FAT_{total}(t_n) \approx \sum_{i=1}^{n} FAT(t_i)\cdot \Delta t_i$$

This is a first-order (rectangular) numerical integration, valid when $\Delta t$
is much smaller than the speed at which the real physiological state changes. If
$\Delta t_i$ were large, the Riemann sum would apply the *instantaneous rate at
the moment of the sample* retroactively over the whole interval — a real
integration error, which grows with the size of the gap.

### 8.3. Instantaneous rate vs. smoothed rate

The cumulative total (§8.2) is, by definition, an exact sum with no smoothing —
it is the plain sum of the point estimates, so it carries all the uncertainty of
the model (§10). But as a **point-in-time reference value** for decisions during the effort
(e.g., fueling), instantaneous $CHO(t)$ and the cumulative total give two very
different kinds of information:

- **The point-in-time calculation** $CHO(t)$ answers "at what rate am I oxidizing
  CHO *right now*?" — it is very sensitive to momentary HR fluctuations (a short
  spike, a bend in the road, a scare), and therefore noisy to interpret at a
  glance, but it is the only one that reacts instantaneously to a real intensity
  change.
- **The cumulative total** answers "how much have I oxidized in total so far?" —
  useful for the session's final balance, but says nothing about the *current*
  rate.

There is a middle ground between the two: a **moving average** of $CHO(t)$, which
answers "at what rate have I been oxidizing CHO *lately*?" — more stable than the
instantaneous rate (because it integrates several recent samples), but still
sensitive to sustained real intensity changes (unlike the cumulative total, which
dilutes them more and more as time passes).

A common way of computing this moving average, when samples arrive at
not-necessarily-regular intervals, is the **exponential moving average (EMA)**,
with a time constant $\tau$ that determines how much "weight" recent samples get
relative to older ones:

$$\alpha_i \approx \displaystyle\frac{\Delta t_i}{\tau} \quad \left(\text{first-order approximation of } 1-e^{-\Delta t_i/\tau}\right)$$

$$CHO_{avg}(t_i) = CHO_{avg}(t_{i-1}) + \alpha_i\cdot\big(CHO(t_i) - CHO_{avg}(t_{i-1})\big)$$

> Hunter JS. **The exponentially weighted moving average.** *Journal of Quality
> Technology*. 1986;18(4):203-210.

The larger $\tau$ is, the more $CHO_{avg}$ resembles the cumulative total (very
stable, not very reactive); the smaller, the more it resembles the instantaneous
rate (very reactive, noisier). The specific choice of $\tau$ is a tradeoff
between stability and reactivity, not a physiological property of the model.

## 9. Carbohydrate intake guidelines during exercise (fueling)

Practical recommendations exist for carbohydrate intake during endurance
exercise, which **depend on the duration** of the effort (and not directly on
body weight, since the limiting factor is intestinal absorption capacity —SGLT1/
GLUT5 transporters— rather than body mass):

> Jeukendrup AE. **A step towards personalized sports nutrition: carbohydrate intake
> during exercise.** *Sports Medicine*. 2014;44(Suppl 1):S25-S33.
> DOI: 10.1007/s40279-014-0148-z

This source broadly establishes:
- Short efforts ($<45$-$60$ min): no significant CHO intake needed.
- Efforts of 1 to 2-3 hours: $\sim 30$-$60$ g/h.
- Long efforts ($>2.5$-$3$h): up to $\sim 90$ g/h, provided
  **multiple-transportable carbohydrates** are used (glucose + fructose blends),
  since a single carbohydrate source cannot be absorbed at such a high rate.

These are **intake** guidelines, not oxidation targets: during moderate-to-hard
exercise the rate of carbohydrate oxidation normally exceeds what can be ingested
and absorbed, and the difference is covered by muscle and liver glycogen.
Comparing the estimated oxidation rate with these intake limits (about 60 g/h with
a single carbohydrate source, up to about 90 g/h with multiple-transportable
carbohydrates) is a rough way of seeing how much of the effort is being drawn from
the body's glycogen stores — a guide, not a prescription.

## 10. Assumptions, scope and accuracy

### 10.1. Who the model is calibrated for

The reference RER values (§5.1) and the $LT_1/LT_2$ ratio (§6) describe a **typical
recreational-to-trained endurance athlete** (running or cycling, $VO_{2max}$
roughly 45-60 ml·kg⁻¹·min⁻¹) who:

- eats a **normal mixed diet** (about 50-55% of energy from carbohydrate);
- exercises in a **fed state** (not after an overnight fast or a long gap since the
  last meal) and without carbohydrate loading;
- is doing **steady-state exercise** at a moderate temperature;
- and is in the **first hour or so** of the effort.

### 10.2. What moves the real RER away from the model

| Factor | Effect on real RER | Effect on the estimate |
|---|---|---|
| Fasted, low-carbohydrate, ketogenic or fat-adapted | Lower (fasting lowers RER at light-to-moderate intensity; Bergman & Brooks, 1999; Achten & Jeukendrup, 2003) | CHO overestimated, FAT underestimated |
| Large high-carbohydrate meal shortly before | Higher | CHO slightly underestimated |
| Carbohydrate ingested during the effort | Higher | CHO slightly underestimated (the model does not know about intake) |
| Elite or very well trained athletes | Lower at the same relative intensity (about $0.88$ vs $0.95$ in well-trained vs recreational runners during 4-min bouts at roughly 89% $VO_{2max}$; Hetlelid et al., 2015) | CHO overestimated |
| Untrained people | Higher; the HR-$VO_2$ relationship and the thresholds are also less reliable | CHO underestimated, with larger error |
| Women | Lower on average (about $0.03$; Rothschild et al., 2022; Venables et al., 2005) | CHO slightly overestimated |
| Duration of the effort | RER tends to fall as glycogen is depleted (roughly $0.0004$-$0.0006$ per minute; Rothschild et al., 2022) | CHO increasingly overestimated in the second hour and beyond |
| Heat, dehydration, cardiac drift | HR rises at constant workload, while real RER tends to fall | VO2 and CHO overestimated |
| Running vs cycling | Fat oxidation is reported to be higher in running (Achten et al., 2003); most reference data come from cycling | CHO somewhat overestimated when running |

### 10.3. Intensity range

The equations of §3 were derived for moderate exercise (roughly 50-75% of
$VO_{2max}$) with $RER<1$; outside that range they are an extrapolation. Above
$LT_2$ the model only counts **oxidative** carbohydrate use: anaerobic glycolysis
also draws on glycogen but does not appear in gas-exchange-based oxidation, so total
glycogen use in hard intervals is underestimated.

### 10.4. Accuracy

The individual spread of RER at a given relative intensity (standard deviation about
$0.04$; Goedecke et al., 2000) translates, for a reference athlete (70 kg,
$VO_{2max}$ 50) at 140 bpm, into roughly $\pm 24$ g/h of CHO (about $\pm 20\%$).
On top of that comes the error of the $VO_2$ estimate (§4.3), which depends on how
good the inputs ($HR_{max}$, $HR_{rest}$, $VO_{2max}$, $LT_2$) are. Treat the result as
a **useful indication of the order of magnitude and of trends within a session**,
not as a measurement.

## 11. Reference summary table

| Ref. | Use in the model | Citation |
|---|---|---|
| Bassett & Howley (2000) | Definition/context of $VO_{2max}$ | *Med Sci Sports Exerc* 32(1):70-84 |
| Frayn (1983) | Conceptual basis of the non-protein CHO/FAT oxidation equations | *J Appl Physiol* 55(2):628-634 |
| Jeukendrup & Wallis (2005) | Target equation: exact coefficients for $CHO(t)$/$FAT(t)$ (Frayn's modified for exercise) | *Int J Sports Med* 26(Suppl 1):S28-S37 |
| Swain & Leutholtz (1997) | $\%HRR \approx \%VO_2R$ to estimate $VO_2(t)$ from HR | *Med Sci Sports Exerc* 29(3):410-414 |
| Faude, Kindermann & Meyer (2009) | Lactate threshold concept ($LT_1$/$LT_2$) for the $RER(t)$ model | *Sports Med* 39(6):469-490 |
| Brooks & Mercier (1994) | "Crossover concept": 50/50 fat/CHO crossover point | *J Appl Physiol* 76(6):2253-2261 |
| Karvonen, Kentala & Mustala (1957) | Conceptual origin of the HR zone / heart rate reserve method | *Ann Med Exp Biol Fenn* 35(3):307-315 |
| Jeukendrup (2014) | CHO intake guidelines during exercise (fueling) | *Sports Med* 44(Suppl 1):S25-S33 |
| Hunter (1986) | Exponential moving average (EMA) as a smoothing technique | *J Quality Technology* 18(4):203-210 |
| Andersson Hall et al. (2016) | Warm-up/prior exercise shortens the fat-mobilization delay | *Appl Physiol Nutr Metab* 41(4):430-437 |
| Péronnet & Massicotte (1991) | Table of non-protein respiratory quotient (50/50 split at $RER\approx 0.85$) | *Can J Sport Sci* 16(1):23-29 |
| Goedecke et al. (2000) | Measured RER at rest and at 41-80% $VO_{2peak}$ in trained cyclists; between-individual variability | *Am J Physiol Endocrinol Metab* 279(6):E1325-E1334 |
| Venables, Achten & Jeukendrup (2005) | Peak fat oxidation at about 48% $VO_{2max}$ in 300 men and women | *J Appl Physiol* 98(1):160-167 |
| Bergman & Brooks (1999) | RER in fed vs fasted trained and untrained men | *J Appl Physiol* 86(2):479-487 |
| Achten & Jeukendrup (2003) | Pre-exercise carbohydrate shifts substrate use towards carbohydrate | *J Sports Sci* 21(12):1017-1024 |
| Achten, Venables & Jeukendrup (2003) | Fat oxidation is higher in running than in cycling | *Metabolism* 52(6):747-752 |
| Martínez-Noguera et al. (2020) | Substrate oxidation rates at ventilatory thresholds in amateur cyclists (data from a supplementation study) | *Nutrients* 12(12):3911 |
| Peinado et al. (2016) | $VCO_2/VO_2$ at the ventilatory thresholds and at the maximal lactate steady state in amateur cyclists | *Biol Sport* 33(4):373-380 |
| Hetlelid et al. (2015) | RER in recreationally trained vs well-trained runners | *BMJ Open Sport Exerc Med* 1(1):e000047 |
| Rothschild et al. (2022) | Modelling analysis of diet, duration, sex and other factors on substrate oxidation in cycling | *Sports Med* 52(11):2775-2795 |
| Edvardsen, Hem & Anderssen (2014) | Peak RER values at maximal effort | *PLoS One* 9(1):e85276 |
| Nuuttila et al. (2025) | $LT_1$ and $LT_2$ as %$HR_{max}$ and accuracy of fixed-%HR anchors in recreational runners | *Eur J Appl Physiol* 125(8):2161-2171 |
| Esteve-Lanao et al. (2026) | Heart rate at the ventilatory thresholds in 1,411 runners | *Sports (Basel)* 14(1):29 |
| Lucía et al. (2000) | Heart rate at the ventilatory thresholds in elite cyclists | *Med Sci Sports Exerc* 32(10):1777-1782 |
