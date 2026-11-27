# ADR 0001: Functional core in a Swift package, imperative shell in SwiftUI

Date: 26 Nov 2026 · Status: Accepted

## Context
The simulation must be deterministic (time away gives exactly the same result as watching), testable without the app, and safe to write with AI help under TDD.

## Decision
All game rules live in `Packages/JBCore` (JBGeo, JBWorld, JBRules, JBSim, JBStory, JBSave): value types and pure functions, no SwiftUI/UIKit/RealityKit, no clock, no randomness except the seeded RNG in `GameState`, no file or network access. The app is a thin SwiftUI shell that turns touches into `Command`s, calls `Engine.apply` / `advance` / `preview`, draws, plays feedback and saves.

## Consequences
- Core tests run in seconds with `swift test` and need no simulator.
- `JBCoreArchitectureTests` fails the build if a UI framework is imported in the core.
- The core also builds and tests on Linux in CI (ADR 0007), which keeps it free of Apple-only APIs.
- Anything that needs the clock, files or the screen must be passed in or done in the shell.
