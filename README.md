# Just Beyond

**A light, beautiful airline tycoon on the real globe. Your planes are never quite long-legged enough. Fix that.**

Customize era-accurate aircraft (wings, engines, tanks, cabins) to reach the places just out of range. Six eras of aviation history are planned, from 1919 to today, starting with **Era 3 (1946–57)**: the post-war years when airliners learned to cross oceans.

- **The globe is the interface.** One card at a time, three taps, one hand.
- **Real geography stays real.** Great circles, headwinds, runways and open ocean decide what's possible.
- **Skill matters.** Growth brings new decisions, never chores.
- **No energy meters, no paid skips, no penalty for being away.** Your airline keeps flying while you're gone.
- **Nothing you build is ever destroyed.** And no combat: war years are skipped.

## Status

Early development: Milestone 0 (foundations and the globe spike). Not playable yet.

## How it's built

- **Swift 6 and SwiftUI** for the iPhone app, a thin shell over a pure, deterministic Swift package (`JBCore`): no clock, no randomness, no I/O inside the simulation, so time away gives exactly the same result as watching.
- **Tests first.** Every rule is proven by a test before it's coded, and expected numbers come from a Python reference model.
- **Content is data.** Airports, planes, parts and events are JSON built by Python scripts.
- Design and plans live in [`docs/`](docs/).

## Run it

You need a recent Xcode with the iOS 18+ SDK.

```
git clone https://github.com/castellanossfelipe/just-beyond.git
open just-beyond/JustBeyond.xcodeproj
```

Pick an iPhone simulator and press Run. Core tests (arriving with the first slice): `swift test --package-path Packages/JBCore`.

## License

Source-available, not open source. Licensed under the [PolyForm Strict License 1.0.0](LICENSE): you may read, run and study the code for noncommercial purposes, but you may not redistribute it or make derivative works. Copyright © 2026 Felipe Castellanos Suárez.
