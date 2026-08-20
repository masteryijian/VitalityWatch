# VitalityWatch

**Continuous heart-health & recovery tracking for Apple Watch — transparent, local-first, and subscription-free.**

![Swift](https://img.shields.io/badge/Swift-5.0-orange) ![watchOS](https://img.shields.io/badge/watchOS-10.0+-blue) ![iOS](https://img.shields.io/badge/iOS-17.0+-blue)

VitalityWatch is an open-source Apple Watch app that turns the sensors already on your wrist into a clear answer to one question most wearables never answer honestly: **how is my heart actually doing, and how recovered am I?**

---

## Why this exists

Existing wearables and health apps are built around activity: steps, streaks, workout volume, and notifications. They tell you how hard you trained — not whether your body has recovered from it, and not whether your heart is quietly sending signals that something is off.

The metrics that actually predict long-term health and recovery are usually buried:

- **Resting heart rate trends** — one of the strongest signals of cardiovascular strain and overtraining.
- **HRV (heart rate variability)** — the body's own recovery gauge; it drops under stress, poor sleep, and overtraining long before you feel it.
- **Sleep architecture** — not just "7 hours," but how much deep and REM sleep you actually got.
- **Wrist temperature deviation** — a slow, reliable early marker of physiological change.
- **Respiratory rate** — a quiet signal that trends with stress and recovery state.

VitalityWatch reads all of these **continuously in the background** — no opening the app, no starting a session, no manual logging — and combines them into a single, understandable recovery picture with transparent, documented math.

## What makes it different

| | Typical trackers / subscription apps | VitalityWatch |
|---|---|---|
| Hardware | Extra band or ring (€200–€400+), subscriptions (€30/mo) | The Apple Watch you already own — free |
| Measurement style | Periodic or workout-only snapshots | Continuous 24/7 background sampling via HealthKit |
| Focus | Steps, streaks, workout volume, notifications | Rest, recovery, heart-health signals that matter long-term |
| Scoring | Black-box proprietary "readiness" numbers | Open, documented heuristics — every formula is in the code |
| Data ownership | Locked behind membership, hard to export | Local-first; everything stays in HealthKit, one-tap CSV export |
| Health claims | Marketing-grade claims (cuffless BP, "biological age" as fact) | Honest estimates with clear labels — not medical claims |

### Real measurement, not snapshots

Apple Watch continuously samples heart rate in the background and periodically captures HRV (SDNN), oxygen saturation, wrist temperature, respiratory rate, and full sleep staging. VitalityWatch reads those **real sensor streams** — not one-off "check-ins" — and tracks them against your own 14-day personal baseline. The result is trend-based insight: *your HRV is 18% below your baseline this morning*, *your resting heart rate has crept up 6 bpm over two weeks*, *your deep-sleep ratio dropped below 20%*.

## What it tracks

- Heart rate & resting heart rate
- HRV (SDNN)
- Blood oxygen (SpO₂) — Apple Watch Series 6+
- Sleeping wrist temperature — Apple Watch Series 8+ / Ultra
- Sleep stages: deep, REM, core, awake — plus a sleep score
- Respiratory rate, VO₂ max, steps, distance, active energy
- **Recovery score (0–100)** — weighted from HRV (30%), resting HR (25%), sleep (30%), temperature deviation (10%), respiratory rate (5%)
- **Biological age estimate** — heuristic adjustment from RHR, HRV, respiration, sleep, VO₂ max; clearly labeled an estimate
- **Momentum** — linear-regression slope of your recovery score over the past 14 days, as a long-term trend index
- **Early-signal insights** — deviations from your personal baseline (e.g., HRV −15%, resting HR +8%, temperature ±0.5 °C)
- Nutrition & body-composition logging (manual or from a HealthKit-compatible scale) on the iPhone companion

Every score is a **documented heuristic**, not a black box. Read the exact formulas in [`Scores.swift`](VitalityCore/Scores.swift).

## Project structure

```
VitalityWatch/
├── project.yml                # XcodeGen project definition
├── VitalityCore/              # Shared core: HealthKit read/write, scoring, insights, CSV export
├── VitalityWatch/             # iPhone companion: permissions, logging, export
└── VitalityWatchWatch/        # watchOS app: Today, Sleep, Trends, Insights
```

## Requirements

- Xcode 15+ (built and verified with Xcode 26.6)
- watchOS 10.0+ / iOS 17.0+
- Apple Watch Series 6+ for SpO₂, Series 8+ / Ultra for wrist temperature
- HealthKit entitlement and your own signing team to run on device

## Build & run

```bash
xcodegen generate
open VitalityWatch.xcodeproj
```

Select a scheme (`VitalityWatch` for iPhone, `VitalityWatch Watch App` for watchOS), set your development team under Signing & Capabilities, and run. Simulators work without a team. On first launch the app requests health-data access; everything stays on-device in HealthKit.

## Honest limitations

- **No cuffless blood-pressure measurement** — the watch has no BP sensor. The app already reads HealthKit blood-pressure samples, so an external cuff that syncs to Health can feed the trend view.
- **No body composition** — 8-electrode BIA (muscle/fat/visceral) needs a scale. HealthKit-compatible scales can sync weight and body fat; visceral fat must be logged manually.
- **Continuous, not every-second** — Apple controls background sampling granularity. HRV SDNN samples arrive periodically throughout the day; true every-second HRV is only available during an active workout session via `HKWorkoutSession` (roadmap).
- **Wellness, not medicine** — scores and "biological age" are estimates for personal reference. This is not a medical device and makes no diagnostic claims.

## Roadmap

- Watch-face complications (recovery score at a glance)
- Morning recovery summary notification (background refresh)
- Real-time HRV during workouts via `HKWorkoutSession`
- Blood-pressure & body-composition integration from external HealthKit devices
- German / English localization

---

Your health data should belong to you. No subscription, no cloud silo, no black-box scores — just the continuous signals your body is already sending, made visible.
