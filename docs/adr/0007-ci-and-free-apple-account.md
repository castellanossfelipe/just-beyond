# ADR 0007: CI on GitHub Actions; no paid Apple services before the membership

Date: 26 Nov 2026 · Status: Accepted

## Context
Development uses a free Apple Account (Xcode's Personal Team) until late M7. Free accounts have no TestFlight, Xcode Cloud, iCloud, Game Center, push or In-App Purchase; builds expire after 7 days; 3 apps per device and 10 App IDs. The repo is public, so GitHub's standard hosted runners are free (checked 26 Nov 2026).

## Decision
- `scripts/check.sh` (core tests and an unsigned simulator build) runs before every push.
- `core.yml` runs `swift test` for JBCore on Linux, in the Swift container matching local Xcode, on every push to `main` and every pull request.
- `app.yml` builds the app on the standard `xcode-27` macOS runner, unsigned, on every push to `main`, every pull request, every `pt-*` tag and on demand.
- Workflows have read-only permissions and use no secrets.
- Free builds use the bundle ID `com.felipecastellanos.JustBeyond.dev`; the App Store bundle ID is registered only after enrolling.
- No paid-only capability is added before the membership; each arrives with its own ADR.
- The membership is bought at the pay point, after S7.1 and S7.3 and before S7.2, S7.4 and gate G3 (Development Plan 8). The former gate G2 becomes rehearsal R2 (free) plus G3's first wave. TestFlight upload tooling is decided then.

## Consequences
- CI costs nothing; signing never happens in CI.
- If the runner's Xcode lags local Xcode and can't open the project, `check.sh` remains the gate until the image catches up.
- Playtests before G3 are on Felipe's own iPhones, in person.
- Save export and import (ADR 0008, S2.7) bridges the move from the `.dev` ID to the App Store ID.
