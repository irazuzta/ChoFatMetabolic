# CHO/FAT Metabolic Pro

A Garmin Connect IQ **Data Field** that estimates, in real time, how many grams of
carbohydrate (CHO) and fat (FAT) the body is oxidizing during exercise, using only the
watch: Garmin's energy estimate and your heart rate. No power meter, no extra
sensors, no manual logging. Works on watches and Edge bike computers.

*Your watch tells you how much energy you burn; this field estimates where it comes
from.*

📖 **Documentation**: [irazuzta.github.io/ChoFatMetabolic](https://irazuzta.github.io/ChoFatMetabolic/)
⌚ **Get it on the Connect IQ Store**: [apps.garmin.com](https://apps.garmin.com/es-ES/apps/d1d623e2-36e9-42c9-a673-fb37d8e8830e)

## What it shows

- **CHO (g)** — total carbohydrate burned so far this session.
- **CHO avg (g/h)** — a smoothed, real-time carbohydrate burn rate, color-coded as a
  fueling guide (green/orange/red) against duration-aware sports-nutrition intake
  guidelines.
- **FAT (g)** — total fat burned so far this session.
- A small **HR zone indicator (Z1-Z5)**, colored the same way Garmin Connect colors
  heart rate zones.

## How it works

Since version 1.0:

- **How much energy**: Garmin's own estimate (`Activity.Info.calories`, the same
  calories shown in Garmin Connect).
- **How it is split**: a piecewise RER model from heart rate, anchored at the metabolic
  thresholds (LT1/LT2), and the Jeukendrup & Wallis (2005) substrate oxidation
  equations. The energy per litre of oxygen is computed with the same coefficients, so
  the grams of CHO and fat always add up to exactly Garmin's energy.
- **Fallback**: if Garmin gives no energy, the field switches automatically to the
  original HR-only model (heart-rate-reserve-based VO2), used up to version 0.5.

Full derivation, citations, papers (English and Catalan) and implementation details
are in the [documentation site](https://irazuzta.github.io/ChoFatMetabolic/).

## Project layout

```
source/       Monkey C source (the data field itself, and unit tests)
resources/    Strings, settings, drawables (app icon)
manifest.xml  Connect IQ app manifest (supported devices, permissions)
tools/        Build/deploy automation (PowerShell) and a desktop .FIT analyzer (Python)
docs/         Public documentation site source (English, built with Zensical)
notes/        Working documents (Catalan) and Connect IQ Store submission notes
```

## Building

Requires the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and a
developer signing key.

```powershell
tools\Run-Simulator.ps1        # build + run in the simulator
tools\Build-Release.ps1        # build the signed .iq package for all devices
```

Unit tests (`source/Tests.mc`) are only compiled with `--unit-test` and run in the
simulator with `monkeydo <prg> <device> /t`.

`tools/analitzador_fit.py` is a desktop tool (Catalan UI) that applies the HR-only model to a
Garmin `.fit` file and plots CHO/fat rates, % of energy by source and model vs Garmin
calories. Requires `pip install fitparse matplotlib numpy`.

## License

© 2026 Jordi Irazuzta.

- **Code** (`source/`, `resources/`, `tools/`): [GNU General Public License v3.0](LICENSE).
- **Documentation and papers** (`docs/`, including the PDFs in `docs/paper/`):
  [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).
  You may share and adapt them, also commercially, as long as you give appropriate
  credit.

## How to cite

See [`CITATION.cff`](CITATION.cff) (GitHub shows a "Cite this repository" button).
