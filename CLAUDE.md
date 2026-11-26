# Just Beyond — rules for Claude Code

A light airline tycoon for iPhone on the real globe, Era 3 (1946–57) first. Solo developer (Felipe). You implement; design decisions are made outside the repo and arrive as docs.

## Read before working
- `docs/development-plan.md`: current milestone, slices, framework. The task you're given names its slice (e.g. S2.2).
- `docs/software-design.md`: architecture, types, testing strategy. Follow it.
- `docs/systems-detail.md`: exact formulas and behaviours, by section number. **Master for behaviour.** If the task and this doc disagree, stop and ask.
- `NEXT.md`: where the last session stopped.
Read only the sections the task points to.

## Architecture (non-negotiable)
- `Packages/JBCore` is the functional core: pure Swift value types and functions.
  - Never import SwiftUI, UIKit or RealityKit there.
  - Never read the clock (`Date()`), call `random()`, or touch files or the network there. Time arrives as `FlightHours`; randomness only through the seeded RNG in `GameState`.
  - All core types: `Codable`, `Equatable`, `Sendable`.
- `App/` is the thin shell: SwiftUI views, `GameStore`, the globe renderer, files, sound. Logic belongs in the core.
- Player actions are `Command`s through `Engine.apply`; time moves only through `Engine.advance`.
- Never add code that removes something the player built (routes, planes, designs, liveries, city choices) except as the direct result of a player command.
- No new third-party dependencies without asking.
- Content is data: airports, planes, parts, milestones, events and text live in JSON under `data/` and are built into `App/Resources/World/` by `tools/`. Never hand-edit built files.

## How to work: strict TDD
1. Write the **test list** for the task (one line per behaviour) and show it to me. Wait for my OK.
2. Write the failing tests. Run them and show they fail for the right reason. Commit: `S<slice>: tests for <thing>`.
3. Write the least code that makes them pass. Run all core tests. Commit.
4. Refactor with tests green. Commit.
- One failing test at a time.
- **Never change a test, a fixture or an expected number to make code pass** without asking me first. Expected numbers come from `Tests/Fixtures/` (exported by `tools/export_fixtures.py`), not from the code.
- Fixing a bug starts with a failing test that reproduces it.
- Test names state the rule: `twinCannotCrossBermudaGap`.
- Use Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`); parameterized tests for tables of cases. XCUITest only for the UI flows listed in the plan.
- Use Plan mode for any change touching more than 3 files.

## Commands
- Core tests: `swift test --package-path Packages/JBCore`
- One suite: `swift test --package-path Packages/JBCore --filter <SuiteName>`
- App tests: `xcodebuild test -scheme JustBeyond -destination 'platform=iOS Simulator,name=iPhone 16'` (adjust the simulator name to one installed)
- Data build: `python3 tools/build_world.py && python3 -m pytest tools/tests`
- Bots (from M5): `swift run --package-path Packages/JBSimBots jb-bots --start NYC --player typical --days 40`

## Conventions
- Swift 6 language mode, strict concurrency. No force unwraps outside tests.
- Units as types (`FlightHours`, `GameYears`, `Money`, km as `Double` named `...Km`). Never mix them silently.
- IDs are stable string-backed structs; saves store them.
- Every save-format change bumps `schemaVersion`, adds a migration and a golden old-save fixture.
- Commit messages start with the slice: `S1.4: runway factor below 70% makes airport unusable`.
- Keep `main` green. Short branches, merged the same day.

## End of a session
- All tests green, or exactly one failing test that is the next step.
- Update `NEXT.md` with one line: where we stopped and the next test.
- Tell me if anything you built differs from `docs/systems-detail.md`.

## Design principles to respect (from the GDD)
Skill must show · growth adds decisions, not chores · every choice costs something · show the consequence before the commitment · respond to everything · waiting comes from the world, never a meter · never destroy what the player built · no random disasters · the globe is the interface (one card at a time, three taps, one-handed).
If a task seems to break one of these, say so before coding.
