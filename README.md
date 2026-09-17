# CHO/FAT Metabolic

A Garmin Connect IQ **Data Field** that estimates, in real time, how many grams of
carbohydrate (CHO) and fat (FAT) the body is oxidizing during exercise — from heart
rate alone. No extra sensors, no manual logging. Works on watches and Edge bike
computers.

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

The model combines established exercise physiology: heart-rate-reserve-based VO2
estimation, a piecewise RER model calibrated against metabolic thresholds (LT1/LT2),
and the Jeukendrup & Wallis (2005) substrate oxidation equations. Full derivation,
citations, and implementation details are in the
[documentation site](https://irazuzta.github.io/ChoFatMetabolic/).

## Project layout

```
source/       Monkey C source (the data field itself)
resources/    Strings, settings, drawables (app icon)
manifest.xml  Connect IQ app manifest (supported devices, permissions)
tools/        Build/deploy automation (PowerShell)
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

## License

Licensed under the [GNU General Public License v3.0](LICENSE) — see `LICENSE` for
the full text.
