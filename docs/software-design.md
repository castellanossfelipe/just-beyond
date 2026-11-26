> **Snapshot of the Project doc "Just Beyond – Software Design", dated 25 Nov 2026.** The Project is the source of truth. Edit it there, then re-copy here (refresh at each milestone cool-down).

# Just Beyond – Software Design (Era 3 test rollout)

Draft 1 · 25 Nov 2026 · For Felipe and Claude Sonnet while coding. **What the game does** is in the GDD, the Era 3 Crossroads Spec and the **Era 3 Systems Detail** (formulas). **What gets built when** is in the Development Plan. This doc is **how it's built**. Copy it into the repo as `docs/software-design.md`; the repo copy is what Sonnet reads.

---

## 1. Goals that shape every choice

| Goal | Why | What it forces |
| --- | --- | --- |
| **Deterministic simulation** | Time away must give exactly the same result as watching; leaderboards must be fair | No clock, randomness or I/O inside the simulation |
| **Testable without the app** | TDD, fast feedback, safer AI-written code | The rules live in a plain Swift package with no UI imports |
| **Data, not code, for content** | Eras 1, 2, 4–6 later should be mostly new data | Airports, planes, parts, milestones, events and text templates are JSON |
| **Never destroy what the player built** | Principle 7 | Saves are versioned with migrations; the simulation has no "delete" for player-built things except by player command |
| **Offline, no server** | Cost and simplicity | Everything runs on the phone; saves are local (iCloud later) |
| **One person, a few hours at a time** | Real constraint | Few moving parts, no third-party runtime dependencies, every task ≤ 2 hours |

---

## 2. Architecture: functional core, imperative shell

Following Gary Bernhardt's "functional core, imperative shell" pattern: the core is pure functions over plain values; the shell reads the clock, touches files and draws the screen, and has as little logic as possible.

```
┌───────────────────────────── App (imperative shell, SwiftUI) ─────────────────────────────┐
│  Wall clock → target sim time      Files ↔ save bytes      Touches → Commands             │
│  GameStore (@Observable, @MainActor): holds GameState + World, calls the core             │
│  GlobeView · Cards · Workshop · Hangar · MorningEdition · Theme · Sound/Haptics           │
└───────────────────────────────────────────────┬───────────────────────────────────────────┘
                                                │ values only (GameState, Command, Event, Preview)
┌───────────────────────────────────────────────▼───────────────────────────────────────────┐
│  JBCore (Swift package, functional core: no UIKit/SwiftUI, no Date(), no random(), no I/O) │
│   JBGeo     great circles, sampling, land mask, oceans, wind projection                    │
│   JBWorld   immutable world data: airports, types, parts, era file; JSON decoding          │
│   JBRules   range, runway, 60-minute band, comfort, share, fares, demand (pure formulas)    │
│   JBSim     GameState, Commands, Engine.apply / advance / preview, economics, calendar,    │
│             cities, charters, history's airline, cash floor                                │
│   JBStory   milestones engine, morning edition builder, templates                          │
│   JBSave    encode/decode save bytes, schema versions, migrations                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
        ▲ built JSON + grids                                   ▲ fixtures (expected numbers)
┌───────┴────────────────────────────┐            ┌────────────┴─────────────────────────────┐
│ tools/ (Python): data pipeline     │            │ tools/balance: Python network model and   │
│ OurAirports, Natural Earth, NOAA,  │            │ balance-sheet export → test fixtures      │
│ curated CSV → App/Resources/World  │            └──────────────────────────────────────────┘
└────────────────────────────────────┘
        JBSimBots (command-line tool using JBCore): plays whole eras as bot players
```

**Dependency direction:** JBGeo ← JBWorld ← JBRules ← JBSim ← JBStory; JBSave depends on JBSim. The app depends on everything. Nothing in JBCore depends on the app.

---

## 3. Repository layout

```
JustBeyond/                         (git root, GitHub)
├─ CLAUDE.md                        rules for Claude Code (Sonnet)
├─ NEXT.md                          one line: where the last session stopped
├─ JustBeyond.xcodeproj
├─ App/                             the iPhone app target (shell)
│  ├─ JustBeyondApp.swift
│  ├─ Store/GameStore.swift
│  ├─ Globe/                        projection, renderer, gestures, hit testing
│  ├─ Cards/  Workshop/  Hangar/  Edition/  Start/  Challenges/  Settings/
│  ├─ Theme/                        EraTheme (palette, type, line styles)
│  ├─ Feedback/                     sound and haptics
│  └─ Resources/World/              built data (never edited by hand)
├─ AppTests/                        a few shell tests; AppUITests/ for XCUITest flows
├─ Packages/JBCore/
│  ├─ Package.swift
│  ├─ Sources/JBGeo|JBWorld|JBRules|JBSim|JBStory|JBSave/
│  └─ Tests/<module>Tests/ + Tests/Fixtures/
├─ Packages/JBSimBots/              executable: era bots → CSV reports
├─ tools/
│  ├─ build_world.py  build_wind.py  build_landmask.py  build_coastlines.py
│  ├─ export_fixtures.py            balance sheet + model → JSON fixtures
│  ├─ balance/                      net.py, tests.py, starts.py (the reference model)
│  └─ tests/                        pytest data checks
├─ data/                            hand-curated sources (airports_era3.csv, era3/*.json, text templates)
└─ docs/                            copies of the design docs + adr/ (decision records)
```

---

## 4. The core's main types (sketch)

Swift 6 language mode, strict concurrency. All core types are value types, `Codable`, `Equatable` and `Sendable`.

```swift
// Units: keep them as distinct types so km never gets added to hours.
public struct FlightHours: Codable, Comparable, Sendable { public var value: Double }
public struct GameYears: Codable, Comparable, Sendable { public var value: Double }   // since 1 Jan 1946
public struct Money: Codable, Comparable, Sendable { public var dollars: Double }

public struct GameState: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var era: EraID
    public var simTime: FlightHours
    public var calendar: GameYears
    public var awayAnchor: GameYears?          // set while backgrounded (away cap)
    public var cash: Money
    public var cities: [AirportID: CityState]   // level, pending choices, options bought, extensions
    public var designs: [DesignID: Design]
    public var fleet: [PlaneID: Plane]
    public var routes: [RouteID: Route]         // stops: [AirportID], planes: [PlaneID], paused
    public var hubs: [Continent: AirportID]
    public var pools: Set<CityPair>
    public var charters: CharterBoard
    public var record: AirlineRecord            // milestones, lifetime firsts, first-there dates, logbooks
    public var liveries: LiveryState
    public var rng: SeededRNG
    public var startNetwork: StartNetworkSnapshot
}

public enum Command: Codable, Sendable {
    case createRoute(stops: [AirportID], planes: [PlaneID])
    case editRoute(RouteID, stops: [AirportID])
    case assignPlane(PlaneID, to: RouteID?)
    case saveDesign(Design)
    case buyPlane(DesignID, name: String)
    case refit(PlaneID, to: DesignID)
    case chooseCityOption(AirportID, OptionID)
    case pauseRoute(RouteID), resumeRoute(RouteID)
    case flyCharter(CharterID, plane: PlaneID)
    case repaint(PlaneID, Livery)
    case designateHub(AirportID)
    case setPooling(CityPair, Bool)
}

public enum Event: Codable, Sendable { /* milestoneEarned, levelReached, routePaused,
    planeTypeAvailable, runwayUpgraded, rivalRouteOpened, charterArrived, yearReached, ... */ }

public enum Engine {
    /// Player actions. Fails with a reason the UI can show; never half-applies.
    public static func apply(_ command: Command, to state: GameState, world: World)
        -> Result<(GameState, [Event]), CommandError>

    /// Moves the world forward. Same code for live play and time away.
    public static func advance(_ state: GameState, by dt: FlightHours, world: World,
                               mode: AdvanceMode /* .foreground or .background */)
        -> (GameState, [TimedEvent])

    /// "Show the consequence before the commitment": what a command would do, without doing it.
    public static func preview(_ command: Command, on state: GameState, world: World) -> Preview
}
```

- **Money** is a `Double` in dollars; tests compare to within $0.01. Integer cents would make the integration step awkward and gains nothing at these sizes.
- **IDs** are small string-backed structs (`AirportID("CYQX")`), stable across versions because saves store them.
- **World** is loaded once at launch and never changes during play.

---

## 5. Time and the simulation loop

Exactly as Systems Detail section 1.3:

```swift
static func advance(_ s: GameState, by dt: FlightHours, world: World, mode: AdvanceMode) -> (GameState, [TimedEvent]) {
    var state = s; var events: [TimedEvent] = []; var remaining = dt
    while remaining.value > 0 {
        let rates = Economics.rates(for: state, world: world)            // cached by network revision
        let next  = Breakpoints.next(after: state, rates: rates, world: world, mode: mode, limit: remaining)
        state     = Integrator.integrate(state, rates: rates, for: next.delay)
        let (s2, e) = next.apply(state, world)                           // level-up, date item, cash floor...
        state = s2; events += e; remaining = remaining - next.delay
    }
    return (state, events)
}
```

- **Economics.rates** runs the passenger allocation (Systems Detail 6.6) and is the expensive step. It is cached by a `networkRevision` that changes only when routes, planes, city options, the year or shares change. Target: under 20 ms for 60 routes on the target iPhone.
- **The shell** calls `advance` once per second while the app is open (for the cash ticker and the calendar stamp), and once with the whole gap when the app returns to the foreground. Plane icons are drawn from `simTime` and each route's schedule at 60 fps without calling the core.
- **Background mode** applies the away cap (Systems Detail 11.3). The shell records when the app went to the background in the save, so a force-quit doesn't lose it.

---

## 6. Data pipeline and file formats

Python 3 scripts in `tools/`, run by hand when data changes; outputs are committed to `App/Resources/World/`.

| Output | Built from | Format | Size target |
| --- | --- | --- | --- |
| `airports.json` | OurAirports + `data/airports_era3.csv` (curated: tags, traits, dated runways and names, populations, successor, hot flag) + regional towns | JSON array | < 1 MB |
| `pairs.json` | Curated `noSurface` and `slowSurface` tables | JSON | small |
| `era3.json` | `data/era3/*.json`: years, rules switched on, types, parts and keys, world multiplier, thresholds, liner curve, milestones, events, history-airline networks, starts and their kits, text templates, theme ID | JSON | < 500 KB |
| `wind.bin` | NOAA NCEP/NCAR long-term mean, ~600 hPa, 5° cells | Little-endian Float32 u,v grid with a small header | < 50 KB |
| `landmask.bin` | Natural Earth land polygons, 0.25° | Bitset with header | ~130 KB |
| `oceans.bin` | Natural Earth marine areas, 1° | UInt8 grid with header | ~65 KB |
| `coastlines.json` | Natural Earth 110m (and 50m for zoom), simplified | Arrays of [lon, lat] | < 2 MB |
| `manifest.json` | All of the above | Versions and SHA-256 per file | — |

**Why JSON, not a database:** 166 curated airports plus a few thousand regional towns fit in memory; JSON is diffable in git, readable by Sonnet, and decodes with `Codable` in a few lines. Revisit only if load time passes 300 ms.

**Data checks (pytest, run on every build):** every curated airport has every field; dated runway entries are in order; every airport that can close has a successor; every start passes rules 3–5 of the Airports doc (two roads per ocean, three gateways per continent, ≤ 25 curated airports in any 2,000 km circle); every milestone references things that exist; every text template's slots exist.

---

## 7. Saves

- One JSON file `save.json` in Application Support, written atomically (write to a temp file, then replace), after every command and when the app goes to the background. The last 3 versions are kept as backups.
- **`schemaVersion`** in every save. Each version bump comes with a migration function `v(n) → v(n+1)` in JBSave and a **golden save file** of the old version in the test fixtures. A test loads every old golden save and checks it migrates and runs. No save is ever discarded because it's old (Principle 7).
- **iCloud:** after the internal TestFlight (milestone M7), using the iCloud Documents container with last-writer-wins plus a "choose which save" card on conflict.

---

## 8. The app shell

- **SwiftUI**, one window: the globe fills the screen and one bottom card sits over it. Navigation is by card, never by stacked screens.
- **GameStore** (`@Observable`, `@MainActor`) holds `GameState` and `World`, turns gestures into `Command`s, calls `Engine.apply`, plays the feedback for each `Event`, and saves.
- **Globe renderer behind a protocol** (`GlobeRenderer`) so the drawing technology can change without touching the rest:
  - **First candidate (spike in M0): 2D orthographic projection drawn with SwiftUI `Canvas`.** Coastlines, routes as projected great-circle polylines, range ring and band as polygons, airports as symbols. Rotation by drag, zoom by pinch. Every era style is flat illustration, so a flat drawn globe suits the art and keeps line widths crisp.
  - **Fallback: Metal (`MTKView`) or RealityKit** if Canvas can't hold 60 fps with the full coastline and 60 routes on the oldest target iPhone.
  - Decision recorded as ADR 0002 at gate G0.
- **Theme:** `EraTheme` holds palette, fonts, line styles and paper texture; the mid-century theme is the only one for this rollout. Grey-box theme for prototypes.
- **Feedback:** short sounds via `AVAudioEngine` and haptics via SwiftUI's sensory feedback, one per `Event` kind, so "respond to everything" is a table, not scattered code.
- **Accessibility:** Dynamic Type in cards, VoiceOver labels, a list view of airports and routes as the accessible alternative to the globe, Reduce Motion.
- **Minimum iOS:** 18, confirmed in M0 (raise it if the globe spike needs a newer API).
- **No third-party runtime dependencies.** Test-only dependencies are allowed with a reason in an ADR.

---

## 9. Testing strategy

Testing is how the work moves forward, not a phase at the end. Kent Beck's canon TDD: write a **test list**, turn one item into a failing test, make it pass, refactor, repeat.

| Layer | Tool | What it covers | When it runs |
| --- | --- | --- | --- |
| **Unit** | Swift Testing (`@Test`, `#expect`) | Every formula and rule in the Systems Detail | Every TDD cycle (seconds) |
| **Golden** | Swift Testing, parameterized over fixtures | Research numbers (Systems Detail 17): route margins, runway factors, first-hour routes | Every test run |
| **Parity** | Fixtures exported from the Python model | Passenger allocation and route economics match `net.py` | Every test run |
| **Invariants** | Swift Testing over 200 seeded random networks (fast mode) | Cash never below 0; same input gives same output; one big advance = many small ones; nothing the player built disappears without a command; the away cap holds | Every test run; 5,000 networks nightly or before a TestFlight |
| **Save compatibility** | Golden old saves | Every old schema loads and runs | Every test run |
| **Data** | pytest | Data validity and coverage rules | Every data build |
| **Simulation bots** | `JBSimBots` | Pacing over a whole era for slow, typical and fast players (section 10) | End of each milestone and after any tuning change |
| **UI flows** | XCUITest | 5 flows: pick a start; draw a route; buy and design a plane; choose a level-up; fly a charter | Before each TestFlight |
| **Snapshots** (optional) | swift-snapshot-testing | Cards at large text sizes | Once cards stop changing (M6+) |
| **Performance** | XCTest `measure`, Instruments | Globe frame time; `advance` for 30 days away; launch time | End of each milestone |
| **On-device check** | A checklist on your iPhone | Feel, sound, one-handed reach, the three-tap rule | End of every slice |
| **Playtests** | People | Is it fun? (Development Plan gates) | G1, G2, G3 |

**Rules for tests**

- The core is tested through its public functions with real values. No mocks inside JBCore: there is nothing to mock, which is the point of the functional core.
- **Expected numbers come from fixtures, not from the code.** When the balance sheet changes, run `tools/export_fixtures.py`; never edit a fixture to make a failing test pass.
- Test names say the rule: `twinCannotCrossBermudaGap`, `extensionsStayAfterRunwayUpgrade`.
- A bug is fixed only after a failing test reproduces it.

**Performance budgets**

| Thing | Budget |
| --- | --- |
| Globe frame time | ≤ 8 ms (60 fps with headroom) |
| `Economics.rates`, 60 routes | ≤ 20 ms |
| `advance` over 30 days away | ≤ 200 ms |
| Launch to interactive globe | ≤ 2 s |
| Save write | ≤ 50 ms |

---

## 10. Simulation bots

A command-line tool (`swift run jb-bots --start NYC --player fast --days 40`) that plays the real core against a simulated wall clock and writes CSV.

- **Players:** *slow* (one check-in a day, one decision), *typical* (three check-ins a day), *fast* (hourly while awake, best decision each time), *greedy* (always buys the most profitable next thing).
- **Decisions** come from a simple strategy: try candidate commands with `Engine.preview` and pick by a score. The bots don't need to be clever, only consistent.
- **Report:** calendar date against real day; cash; cities by level; goals done; and **"dead check-ins"**: check-ins where no decision was worth taking.
- **Targets for gate G2:** every start reaches its first ocean-capable plane within 2 real hours (typical bot); a typical bot reaches December 1957 in 24–35 real days; the fast bot has under 10% dead check-ins; nobody's cash curve flattens for more than a game year with nothing to buy.

---

## 11. CI and builds

- **Locally, always:** `swift test --package-path Packages/JBCore` before every commit (seconds), and the app's tests before every push.
- **Xcode Cloud** (25 compute hours a month are included with the Apple Developer Program): one workflow builds and tests on every push to `main`; a second, started by a tag `tf-*`, archives and uploads to TestFlight for internal testers.
- **TestFlight:** internal testers (up to 100 App Store Connect users) first; external testers (up to 10,000) need the first build of each version to pass Beta App Review, so allow a few days.

---

## 12. Decision records (ADRs)

Short files in `docs/adr/`, one per architectural decision: context, decision, consequences. Written when the decision is made, never rewritten (a new ADR supersedes an old one).

| # | Decision | Status |
| --- | --- | --- |
| 0001 | Functional core in a Swift package, imperative shell in SwiftUI | Accepted |
| 0002 | Globe drawn in 2D with Canvas (fallback Metal/RealityKit) | Decided at gate G0 |
| 0003 | World data as JSON built by Python scripts | Accepted |
| 0004 | A route is an ordered list of stops; `maxStops` is a build setting | Accepted |
| 0005 | Time advances by integrating between breakpoints | Accepted |
| 0006 | No third-party runtime dependencies | Accepted |
