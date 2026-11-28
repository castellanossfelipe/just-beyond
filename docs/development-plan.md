> **Snapshot of the Project doc "Just Beyond – Development Plan", dated 27 Nov 2026.** The Project is the source of truth. Edit it there, then re-copy here (refresh at each milestone cool-down).

# Just Beyond – Development Plan (Era 3 test rollout)

Draft 5 · 27 Nov 2026 (G0 measurement; S0.2 tasks; globe math in JBGeo; S0.5 globe feel; S1.5 drags from the selected airport) · Solo developer, working when there's time, coding with Claude Sonnet, designing with Claude Opus, on a free Apple Account until late M7 (section 8). **Replaces Draft 1** (the phase plan), keeping its ground rules and art approach. How the code is built is in the **Software Design** doc; exact behaviours are in the **Era 3 Systems Detail**. Copy this doc into the repo as `docs/development-plan.md`.

**Scope of this rollout:** from an empty repo to an **external TestFlight of Era 3 on the whole globe** (gate G3). Weekly challenges with Game Center, the timelapse, the App Store page and launch come after this plan. Everything through M6, and M7's challenges and accessibility work, is built and tested with a free Apple Account; the paid membership is bought after S7.3, before S7.2, S7.4 and gate G3 (section 8).

**The plan is measured in hours, not weeks.** Every slice has an appetite in hours; whenever you have a free hour or two, you pick up the next task. About **262 hours** to gate G3 (M0–M7 add up to about 262).

---

## 1. The framework: shaped slices, test first

Built from four proven practices, cut down for one person:

| Practice | Where it comes from | What we use |
| --- | --- | --- |
| **Walking skeleton** | Alistair Cockburn: a tiny implementation of the whole system that performs a small end-to-end function | Milestone M0 ends with a thin end-to-end game on your phone, then everything grows from it |
| **Shape Up** | Basecamp (Ryan Singer): fixed time, variable scope; shape work before betting on it; a circuit breaker; cool-down between cycles | Every slice has an **appetite** in hours and a short **pitch**. Hit the appetite and you stop, never extend by default. A cool-down after each milestone. Basecamp itself says a tiny team can drop the six-week cycles and formal pitches, but should still cap its downside with a circuit breaker |
| **Canon TDD** | Kent Beck: write a test list, then red, green, refactor, one test at a time | Every task starts from its test list; no production code without a failing test |
| **Functional core, imperative shell** | Gary Bernhardt | The game rules are pure and tested without the app; the app is thin (Software Design) |

### 1.1 Three sizes of work

| Size | What it is | Length | Lives in |
| --- | --- | --- | --- |
| **Milestone** | A playable build that ends at a **gate** (a decision or playtest) or a cool-down | 20–40 h | This doc |
| **Slice** | A shaped bet: one vertical piece of the game, core and screen together where it makes sense | 3–12 h appetite | A GitHub issue with a pitch |
| **Task** | One sitting, one test list, ends green | ≤ 2 h | A checklist item in the slice's issue |

### 1.2 Shaping a slice (before building it)

Each slice issue has a pitch of about ten lines:

- **Problem:** what the player can't do yet.
- **Appetite:** hours. This is a budget, not an estimate.
- **Spec:** the Systems Detail sections it implements.
- **Test list:** the behaviours to prove, one line each. Golden tests named.
- **No-gos:** what this slice won't do.
- **Done when:** what you'll see on your phone.

Shape with Opus in the project when a slice is new territory; Sonnet builds from the shaped issue. Opus writes every pitch in this format, ready to paste as the issue.

### 1.3 The circuit breaker

When a slice hits its appetite and isn't done, stop and choose one:

1. **Ship it cut down:** finish the part that works, move the rest to a new slice in Later.
2. **Reshape it:** the problem was misunderstood; write a new pitch with a new appetite.
3. **Drop it:** it wasn't worth this much.

Never "just a few more hours". Extending is a decision you make at the board, not by default.

### 1.4 One thing at a time

A GitHub Projects board with four columns: **Later**, **Next** (shaped, ready), **Now** (one slice, never two), **Done**. Bugs found mid-slice go to Later unless they block the current test list.

### 1.5 The session ritual (any free hour)

**Start (5 minutes)**
1. Read `NEXT.md` (one line from last time).
2. Open the current task; read its test list.
3. Run the tests. They should be green, or show exactly the one failing test `NEXT.md` names.

**Work (up to 2 hours)**
4. One test from the list → red → green → refactor. Commit at every green.
5. New behaviours you discover go onto the test list, not into the code.

**End (10 minutes)**
6. Tests green, or one failing test that is the next step.
7. Commit and push.
8. Write one line in `NEXT.md`: where you stopped and the next test to write. Stop with the next step obvious.
9. If the slice is done: run the on-device checklist (section 4) and move the card to Done.

### 1.6 Cool-down after each milestone (1–2 sessions)

No new features. Fix the bugs in Later that matter; refactor what hurt; update the docs from what you learned (a behaviour that differs from the Systems Detail is either a bug or a doc change, decided on purpose); write ADRs; regenerate fixtures; reshape the next milestone's slices. **Refresh the repo's `docs/` snapshots:** Opus hands over each project doc that changed since the last refresh (Systems Detail, Development Plan, Software Design), with the snapshot line redated, and you commit them as `docs: refresh snapshots`. (Decided 27 Nov 2026; at the M1 cool-down, revisit whether the repo should become the master copy, synced into the project.)

### 1.7 Every ~5 sessions: a 15-minute review

Look at the board. Hours spent against appetites. Is the next slice still the right one? Has anything in the design changed that needs a GDD edit in the project?

### 1.8 Git

- `main` always builds and passes its tests. One short branch per task, merged the same day.
- Commit messages start with the slice: `S2.2: transfers respect the 35% detour limit`.
- Tag `pt-<n>` for every build installed for anyone but you (playtests); CI builds it and the playtest journal records it. TestFlight uploads arrive with the membership (section 8).

### 1.9 Definition of done (a slice)

- [ ] Every item on the test list is a passing test; golden tests where the Systems Detail lists them.
- [ ] `scripts/check.sh` passes (core tests, app build and tests) and CI is green; no compiler warnings.
- [ ] On-device checklist done on your iPhone.
- [ ] If the behaviour differs from the Systems Detail, the doc is updated or a bug is filed.
- [ ] `NEXT.md` points to the next slice.

---

## 2. Working with Sonnet and Opus

**Sonnet builds** (Claude Code, in the repo, guided by `CLAUDE.md`). Anthropic's own recommended workflow for changes that tests can verify is: write tests from expected inputs and outputs, run them and confirm they fail, commit the tests, then write code until they pass, then commit the code.

For each task:
1. Paste the slice pitch and the task. Point to the Systems Detail section by number; don't paste whole docs.
2. Ask for the **test list first**. Read it. This is your main review: wrong tests mean wrong code.
3. Sonnet writes the failing tests and shows them failing. Commit.
4. Sonnet implements until green, then refactors. Commit.
5. You run the app on your phone if the task touched the screen.

**Rules for Sonnet** (also in `CLAUDE.md`): never edit a test or fixture to make code pass without asking; nothing in JBCore imports SwiftUI or UIKit, reads the clock, uses `random()` or touches files; no new dependencies; one task per conversation (clear between tasks); use Plan mode for anything touching more than three files.

**Opus designs** (here, in the project): shaping new slices, design questions, reviewing a slice's approach before a big build, reading bot reports and tuning, and every doc change. Opus proposes each doc edit and applies it after your OK. If something changes the GDD, it goes through the project first.

---

## 3. The roadmap

Hours are appetites. Each milestone lists its slices, what gets tested, and how it ends.

### M0 — Foundations and the walking skeleton (~25 h)

| Slice | Appetite | What | Key tests |
| --- | --- | --- | --- |
| S0.1 Repo and tooling | 3 h | `Packages/JBCore` with its six targets and test targets, linked to the app; `CLAUDE.md`, `NEXT.md`, `docs/` copies, `docs/adr/0001` and `0007`; `scripts/check.sh`; GitHub Actions on every push and pull request: core tests on Linux, app build on macOS | One trivial test per target; core tests green on Linux; app job green |
| S0.2 Globe spike | 6 h (breaker 8 h) | Natural Earth 110m coastlines → `coastlines.json`; SwiftUI Canvas orthographic globe; drag to rotate, pinch to zoom; one great-circle arc; one range ring; switch between two color themes | Projection math unit tests in JBGeo (Linux CI); the G0 stress scene measured on your iPhone |
| S0.5 Globe feel (built between S0.2b and S0.2c) | 5 h (breaker 6 h) | The place you touch stays under your finger, north up; coast like a scroll view; pinch about the fingers; one-finger zoom; Reduce Motion (Systems Detail 16.1). Reshaped out of S0.2 after the S0.2b phone test felt clunky (decided 27 Nov 2026) | Golden: the grabbed place stays within 0.5 pt of the finger; no jumps near the poles; coast matches the scroll-view curve; screen point ↔ place round trip |
| S0.3 Data v0 | 4 h | `build_world.py` for 60 North Atlantic airports; `build_landmask.py`; JBWorld decodes them | pytest data checks; decode test |
| S0.4 Walking skeleton | 6 h | Tap two airports → `createRoute` → a dot flies the great circle → cash ticks by a placeholder profit through `Engine.advance` → save and reload | `apply(createRoute)`; `advance` raises cash; save round trip; split-advance invariant |

**Gate G0 (decision):** does the Canvas globe hold 60 fps (≤ 8 ms per frame) on your test iPhone (iPhone 13) with coastlines, 20 arcs and a ring? Measured in a Release build on the phone with a stress scene (coastlines, 20 arcs, ring, auto-spin, at 1x and 4x zoom) plus a 30 s Instruments Animation Hitches run, during which you also drag, flick and pinch (S0.5). Pass: p95 draw time ≤ 8 ms and no hitches [tune]. iPhone model, refresh rate and iOS version go in ADR 0002. (Decided 27 Nov 2026.) Yes → ADR 0002 accepts Canvas. No → up to 4 h trying Metal, then decide. Also confirm the minimum iOS version.

### M1 — The range puzzle, grey box, North Atlantic (~35 h)

| Slice | Appetite | What | Key tests |
| --- | --- | --- | --- |
| S1.1 Geography | 5 h | Great circles, 25-km sampling, over-water km, ocean map (Systems Detail 2.1–2.2) | Known distances; Gander–Shannon is all water; New York–Montreal is all land |
| S1.2 Wind | 6 h | `build_wind.py` (NOAA long-term mean, ~600 hPa, 5°); tailwind per leg both ways; wind-shaped ring (2.4, 4.4) | Westbound North Atlantic has a headwind; ring is longer east than west at Gander |
| S1.3 Planes and designs | 7 h | Dakota and Skymaster; wings, engines, tanks (cabin comes in M3); designs; workshop v0 with live ring and numbers (3) | Every part multiplier; design save and buy |
| S1.4 Rules | 7 h | Runway factor, 60-minute band, route validation both ways (4.1–4.3) | Golden: Bermuda inside Dakota range but outside the band; Wake–Tokyo −1% / +11% once global data lands (M3) |
| S1.5 Planning on the globe | 8 h | Drag from the selected airport to draw a route (other drags turn the globe; near the edge the globe turns toward the finger; Systems Detail 16.1 item 9); ring, gap in km, worst margin, band drawn red where broken; route card | UI flow test: draw a route, including one to a city on the far side of the globe |

**Ends with:** a cool-down. You can crack Shannon–Gander westbound by fitting extra tanks.

### M2 — Money, time away, and the first fun test (~48 h)

| Slice | Appetite | What | Key tests |
| --- | --- | --- | --- |
| S2.0 Balance model | 6 h | Rebuild `tools/balance/` (`net.py`, `tests.py`, `starts.py`) in Python from Systems Detail 6–7 and the Findings doc's rules; reproduce the Findings tables (Sydney, Cairo, first hour) within 5% before changing anything, then apply ×1.7 fares, 1.0→5.0 and the history-airline share; `export_fixtures.py`; ADR 0009. The original model was lost with the session that made it | pytest: the Findings tables reproduce; fixtures export and load in JBCore tests |
| S2.1 Demand and fares | 7 h | Pair demand, surface links, world multiplier, fares (6.1, 6.2, 6.8) | Golden values from the balance-model fixtures |
| S2.2 Filling seats | 10 h (breaker 14 h) | Nonstop, through and transfer allocation; 85% cap (6.6) | **Parity** with `net.py` on the Sydney and Cairo scenarios |
| S2.3 Costs and the cash floor | 4 h | Running costs, landing fees, pause worst route first, resume (7.1, 7.4) | Cash never below zero; New York–Philadelphia 1 vs 3 Dakotas |
| S2.4 The integrator and time away | 7 h | Breakpoints, exact integration, background mode (1.3) | One big advance = many small ones; 30 days away ≤ 200 ms |
| S2.5 Route card | 5 h | Profit by color and icon; breakdown by pair and leg (7.2) | Snapshot of the numbers shown against the core's |
| S2.6 Morning edition v0 | 4 h | Plain text from events: headline, three items, coming next (13) | Priority order |
| S2.7 Playtest kit | 5 h | One build: a hidden playtest menu sets `maxStops` (2 or 6) for a new game; save export and import through the share sheet; playtest journal (Software Design 7) and `jb-bots replay` | Both settings pass all tests; export → import round trip; a replayed journal reaches the same `GameState` |

**Gate G1 (playtest): is the range puzzle fun, and pairs or lines?**
- 5 or more people, 20 minutes each, grey boxes, no help beyond one sentence.
- Each plays both settings (`maxStops` 2 and 6, from the playtest menu), half starting with each (so order doesn't decide it). They play on your iPhone, in person; export the journal after each session.
- **Fun bar (from Draft 1):** at least 3 of 5 want to keep going and can describe a route they're proud of. If not, rework the puzzle before any art.
- **Engine rule:** ask "why can't the Dakota reach Bermuda?" At least 4 of 5 should answer it without help (GDD open question).
- **Pairs or lines:** which they preferred, whether they built a thin ocean leg that paid, time to their first profitable ocean route, and every moment of confusion. **Decision rule:** lines, unless testers were confused by them or preferred pairs by 2 or more votes. Record it in the GDD (via the project) and ADR 0004. If pairs win, add mail contracts (Findings doc, section 6) to M3.

### M3 — The world and the era (~35 h)

| Slice | Appetite | What | Key tests |
| --- | --- | --- | --- |
| S3.1 Global data | 8 h | All 166 airports, regional towns, surface tables, dated runways and names, coverage checks | pytest rules 3–5; Kai Tak and Johannesburg goldens |
| S3.2 Calendar | 7 h | Rate, dated items, away cap, "Coming next" (11) | Away cap holds; dated items wait; growth measured from the start network |
| S3.3 Starts | 7 h | Six types, surplus kit (Skymaster for Reykjavík), seven starts and the start picker | **First-hour golden: every start has 2+ routes at $100+/fh** |
| S3.4 History's airline | 8 h | Dated openings, share formula, pooling, ghost drawing (6.4, 8) | First-there 70/40; clamps; service terms |
| S3.5 Cabins and comfort | 5 h | Fourth slot; sleeper, tourist, freighter, combi; comfort (3.2, 6.5) | Comfort table; seat rounding |

### M4 — Cities and charters (~30 h)

| Slice | Appetite | What | Key tests |
| --- | --- | --- | --- |
| S4.1 City levels | 6 h | Thresholds, pending choices, the level-up card (9.1) | Pending choices never expire |
| S4.2 Identities | 12 h | Offers from traits; four identities × three tiers as modifiers (9.2–9.3) | One test per option (24) |
| S4.3 Charters | 8 h | Board, seeded arrivals, pioneer, special load, event; dispatch in three taps (10) | Same board whether watched or away; nothing expires |
| S4.4 Cargo and mail | 4 h | Light cargo model (6.7) | Free port and Combi effects |

### M5 — The story (~30 h)

| Slice | Appetite | What | Key tests |
| --- | --- | --- | --- |
| S5.1 Milestones engine | 10 h | Conditions for all 87, lifetime firsts, history comparison, next 3 per category (12) | One test per milestone category, plus every era goal |
| S5.2 Era goals and the end | 4 h | Liner curve, the era-end card (11.5, 11.6) | The card needs both conditions |
| S5.3 Morning edition, full | 5 h | Priorities, templates, prompt, sharing (13) | Template slots exist |
| S5.4 Hangar v1 | 5 h | Fleet, designs, generated stamps, airline charter | Keepsake generation is deterministic |
| S5.5 Bots | 6 h | `JBSimBots` and the first tuning pass (Software Design 10) | Bot targets met |

**Rehearsal R2 (free, 1–2 weeks; replaces the former gate G2):** only after the bots hit their targets. The friends' two-week test needs their own phones, so it moves into G3's first wave (section 8). Here you play the build on your own iPhones as an ordinary player, with the playtest journal on, then replay the journals. Measure: check-ins with nothing worth deciding; crashes and save problems; pacing against the typical bot; anything on screen that contradicts the route card. It can't measure unprompted return, because you're the player. **Decision rule:** if more than 1 check-in in 10 had nothing worth deciding (the fast bot's target), or the calendar stalled, reshape in the cool-down before any art (M6). Then a cool-down.

### M6 — Look, sound and the first session (~31 h)

| Slice | Appetite | What |
| --- | --- | --- |
| S6.1 Style bible and theme | 6 h | Mid-century style bible (Draft 1 art rules below); `EraTheme` |
| S6.2 Globe art pass | 9 h | Coastlines, airports as symbols, route lines, the ring, the date stamp in style; app icon draft from the style bible (AI art, section 7) |
| S6.3 Card and screen art pass | 6 h | Cards, workshop, hangar, morning edition, front pages |
| S6.4 Sound and haptics | 4 h | One sound and one haptic per event kind |
| S6.5 First session | 6 h | The first session for all seven starts (Systems Detail 14) |

### M7 — Challenges, saves and polish (~28 h)

| Slice | Appetite | What |
| --- | --- | --- |
| S7.1 Challenges | 12 h | Challenge mode ("Run a month") and the three Era 3 challenges (15) |
| S7.3 Accessibility and performance | 6 h | VoiceOver list view, Dynamic Type, Reduce Motion; all performance budgets; app icon exported at every size |
| **Pay point** | 2 h | Buy the membership (section 8): enrol a week ahead, run the ready-to-pay checklist, set the team, register the App Store bundle ID, first TestFlight upload from a `pt-<n>` tag |
| S7.2 iCloud saves | 5 h | iCloud Documents (needs the membership), conflict card, migration tests; the S2.7 export stays as the manual backup |
| S7.4 External beta prep | 3 h | The five UI flow tests; beta description and review notes; first external build to Beta App Review |

S7.1 and S7.3 come first because they need no membership; S7.2 and S7.4 follow the pay point.

**Gate G3 (TestFlight, a whole era: 4–5 weeks, in two waves; it absorbs the former G2):**
- **Wave A (from day 1):** 5–10 friends, as internal testers or a small external group. Submit the external build for Beta App Review when wave A starts, so wave B can begin on day 7.
- **Circuit breaker on day 7:** no crashes, no broken or lost saves and no blocker in their journals → widen. Otherwise pause, fix in a short cool-down, and widen with the fixed build (testers carry their game across with save export and import if needed).
- **Wave B:** widen to about 20 testers.
- **Measure:** day-7 and day-14 return without prompts; share who reach December 1957; days with nothing to decide (asked, and counted from the journals); whether they describe routes as their own; which systems they talk about; crashes. Read wave A separately too, so the old G2 questions still get their own answer. This is the GDD's playtest goal, and the end of this plan.

### Running alongside the code (not in the hours above)

These are research and design tasks, mostly with Opus in the project. Each must be done before the slice that needs it:

| Track | Needed by |
| --- | --- |
| Shape S2.0 from the Findings doc's tables and the Systems Detail numbers | S2.0 |
| Timetable pass on the *(verify)* airports | S3.1 |
| History-airline networks for the seven starts | S3.4 |
| FAA runway curves for real take-off lengths | S3.1 |
| Event charter dates, airlift tonnage, the 1947 Kangaroo stop list | S4.3, S7.1 |
| Mid-century style bible | S6.1 |

---

## 4. When to test: the whole picture

| When | What | Who |
| --- | --- | --- |
| Every few minutes | The test you're writing, then all core tests | You and Sonnet |
| Every commit | `swift test` on JBCore | You |
| Every push | Core tests on Linux and the app build on macOS (GitHub Actions); `scripts/check.sh` locally before pushing | Automatic, and you |
| End of every slice | **On-device checklist:** runs on your iPhone; one-handed; the globe stays under your thumb (Systems Detail 16.1); every action has a sound or visual response; common actions in three taps or fewer; no text cut off at large text size; nothing on screen contradicts the route card | You |
| End of every milestone | Invariants at 5,000 networks; performance budgets; bots (from M5); cool-down | You |
| Before every tester build | The five UI flow tests; a fresh install, an upgrade install from the last build's save, and a save import from the last build | You |
| G0, G1, R2, G3 | Decisions, the rehearsal and playtests (section 3) | You and testers |

---

## 5. The first sessions

1. **S0.1a:** add `Packages/JBCore` with six library targets and test targets; one trivial test each; link the package to the app; add `CLAUDE.md`, `NEXT.md` and `docs/`. Push.
2. **S0.1b:** project fixes (iOS 18, Swift 6, `.dev` bundle ID, shared scheme, untrack `xcuserdata`); `scripts/check.sh`; GitHub Actions `core.yml` (Linux) and `app.yml` (macOS) on every push and pull request; ADRs 0001 and 0007; first green runs.
3. **S0.2a:** `build_coastlines.py` (Natural Earth 110m → simplified `coastlines.json`); orthographic projection and camera in JBGeo with unit tests; draw the coastlines in a Canvas.
4. **S0.2b:** drag to rotate, pinch to zoom, one great-circle arc New York–London, one range ring; measure frame time on your iPhone.
5. **S0.5 (three tasks):** the globe feel (Systems Detail 16.1): grab and zoom math in JBGeo; coast and UIKit gestures; an on-phone tuning pass.
6. **S0.2c:** theme switch between two palettes; 20 arcs; decide gate G0 (or start the Metal fallback).
7. **S0.3:** `build_world.py` for 60 North Atlantic airports, pytest checks, JBWorld decoding test.

Items 3, 4 and 6 are the three 2 h tasks of S0.2 (6 h, breaker 8 h). (Decided 27 Nov 2026.) S0.5 was reshaped out of S0.2 when the S0.2b phone test showed the drag mapping itself was wrong, which is the circuit breaker's "reshape" (1.3), not an extension. (Decided 27 Nov 2026.)

---

## 6. Risks and how the plan handles them

| Risk | Handling |
| --- | --- |
| The globe can't hold 60 fps | Found in session 4, not month 4 (gate G0); the renderer sits behind a protocol |
| Passenger allocation balloons | Circuit breaker on S2.2; the Python model is the reference, so the target is known |
| Data research is the long pole | It runs alongside the code, owned in the project, with "needed by" dates |
| Design changes keep arriving | Only during cool-downs; mid-slice ideas go to Later |
| AI-written code drifts from the design | Tests first, reviewed by you; fixtures from the balance model; `CLAUDE.md` rules |
| Motivation dips on long stretches | Every slice ends with something visible on your phone; gates give real people's reactions often |
| Free signing: builds expire after 7 days, 3 apps per device | Reinstall over the app, never delete it; the away cap makes a lapse harmless; export a save before each reinstall |
| The bundle ID stays stuck on the Personal Team after enrolling, so saves start empty | Free builds use `.dev`; the App Store ID is never used before enrolling; save export and import bridges any change |
| Art and polish (M6–M7) built before any outside retention signal, because G2 moved into G3 | The bots and rehearsal R2 gate M6; G3's day-7 circuit breaker on wave A catches the rest before wave B |
| Numbers drift between the sheet, the docs and the code | One master at a time (GDD, Where numbers live); fixtures come only from the balance model |
| The CI runner's Xcode lags your local Xcode | `scripts/check.sh` is the gate; the app job can run manually until the runner image catches up |

---

## 7. Kept from Draft 1

**Ground rules:** ambitious design, disciplined order; test the fun before the beauty; content is data, not code; keep the simulation separate from the screens; draw in code first, illustrate second; every session ends with something running; playtest early.

**AI art without losing the soul**

- Write a style bible per era before generating anything: palette with exact colors, line weight, type, mood references. Start from the era styles table in the GDD.
- Generate inside the style bible and curate hard. Repaint or vectorize the key pieces so everything looks like one artist made it.
- Use AI art for posters, newspaper front pages, plane side portraits, town vignettes and the app icon draft. Not for the UI or the globe: those are drawn in code so they stay sharp and can be themed.
- Keep every prompt in the repo so styles can be reproduced later.
- No real airline logos or manufacturer branding in generated art.
- Before launch, check Apple's current App Review Guidelines on AI-generated content and any disclosure they require.

**After this plan:** weekly challenge and Game Center, timelapse and share card, the App Store page, launch of Era 3 as the first chapter, then eras in order of how much fun they add (Era 4, Era 2, then Eras 1, 5 and 6). Bring in an artist once there's revenue or traction.

## 8. Working without the paid Apple membership

Decided 26 Nov 2026. Felipe builds with a free Apple Account (Xcode's Personal Team) for as long as the plan allows. Limits checked 26 Nov 2026:

| Free Apple Account | What it means here |
| --- | --- |
| Builds expire 7 days after signing; rebuild and reinstall from Xcode | Reinstall over the app, never delete it (deleting it deletes the save). The away cap means a lapsed week costs nothing |
| 3 apps per device; 3 registered devices per platform; 10 App IDs, each expiring after 7 days | Your own iPhones only. One bundle ID for every playtest variant, so variants are a playtest setting, not separate builds |
| Free provisioning is for personal use | Free builds aren't installed on testers' phones |
| No TestFlight, Xcode Cloud or App Store Connect | CI on GitHub Actions (Software Design 11); playtests on your own iPhones until G3 |
| No iCloud, remote push, In-App Purchase or Sign in with Apple; Game Center needs App Store Connect | Saves are local with export and import; nothing before S7.2 needs these |

**What this changes**
- **CI:** GitHub Actions, not Xcode Cloud (ADR 0007). The repo is public, so GitHub's standard hosted runners are free; the docs in `docs/` are public too, under the PolyForm Strict licence.
- **Tester builds:** `pt-<n>` tags; every playtest journal names its build.
- **One build, a playtest switch:** `maxStops` is chosen in a hidden playtest menu at new game (S2.7, ADR 0004).
- **Save export and import, and the playtest journal,** arrive in S2.7 (Software Design 7).
- **Bundle IDs:** free builds use `com.felipecastellanos.JustBeyond.dev`. The App Store ID is registered only after enrolling. If Apple reports it as taken by the Personal Team, ask Developer Support to release it or choose another; testers carry their saves across with export.
- **G2 moved into G3.** A friends' test over two weeks needs their own phones, so it needs TestFlight. Rather than pay before the art, rehearsal R2 checks the loop for free at the end of M5, and G3 starts with the old G2 group as wave A, with a day-7 circuit breaker.

**The pay point:** once S7.1 and S7.3 are done (about 252 hours in), enrolling about a week before you want S7.2 and G3 to start (enrolment and the first Beta App Review can take days). From then on it's needed for S7.2 (iCloud), S7.4 and G3 (TestFlight), and everything after this plan (Game Center, In-App Purchase, App Store). Buying it then starts the $99 year when it's used: it covers G3 and launch.

**What nothing before G3 can measure:** whether people come back unprompted. Rehearsal R2 and the bots cover pacing, crashes and days with nothing to decide; only G3's wave A answers the return question.

**Ready to pay (by the end of S7.3):** final bundle ID chosen and unused; export and import tested across two bundle IDs; journal replay working; signing team in one build setting; `ITSAppUsesNonExemptEncryption = NO` and a privacy manifest in place; icons at every size; beta and review notes drafted; App Store name checked; enrol a week ahead.

## Sources

- [Shape Up, Ryan Singer (Basecamp)](https://basecamp.com/shapeup/0.3-chapter-01), and its [appendix on adjusting for team size](https://basecamp.com/shapeup/4.1-appendix-02)
- [Walking skeleton, Alistair Cockburn](https://alistaircockburn.com/Bio)
- [Canon TDD, Kent Beck](https://newsletter.kentbeck.com/p/canon-tdd) and [Test Driven Development, Martin Fowler](https://www.martinfowler.com/bliki/TestDrivenDevelopment.html)
- [Functional Core, Imperative Shell, Gary Bernhardt](https://www.destroyallsoftware.com/screencasts/catalog/functional-core-imperative-shell)
- [Claude Code best practices, Anthropic](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Swift Testing, Apple](https://developer.apple.com/xcode/swift-testing)
- [Xcode Cloud, Apple](https://developer.apple.com/xcode-cloud/get-started) and [TestFlight, Apple](https://developer.apple.com/help/app-store-connect/test-a-beta-version/overview-of-testflight/)
- [Choosing a Membership (free Apple Account limits), Apple](https://developer.apple.com/support/compare-memberships)
- [Supported capabilities (iOS), Apple](https://developer.apple.com/help/account/reference/supported-capabilities-ios/)
- [How use of GitHub Actions is measured, GitHub](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
