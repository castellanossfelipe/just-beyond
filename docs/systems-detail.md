> **Snapshot of the Project doc "Just Beyond – Era 3 Systems Detail", dated 26 Nov 2026.** The Project is the source of truth. Edit it there, then re-copy here (refresh at each milestone cool-down).

# Just Beyond – Era 3 Systems Detail

Draft 1 · 25 Nov 2026 (26 Nov: `maxStops` is a playtest setting, 5.1 and 14) · Companion to the Era 3 Crossroads Spec. The Spec says *what* each system is and *why*; this doc says **exactly how it behaves**, so it can be coded and tested. The Software Design doc says how it's built.

**How to read the numbers**

- **[tune]** = a starting value. The **Era 3 Balance Sheet is master for numbers**; where they differ, the sheet wins and this doc gets updated.
- **[V]** = checked against a source; **[U]** = unverified; *(verify)* = needs a source before it ships.
- **This doc is master for formulas and behaviour.** If code and this doc disagree, one of them is a bug: fix it or change the doc on purpose.
- Every rule here should become at least one test. Section 17 lists the golden tests.

---

## 1. Time

### 1.1 Units

| Quantity | Value | Notes |
| --- | --- | --- |
| Flight hour (fh) | 60 real seconds | The simulation's base unit of time |
| Game year at world pace | 2 real days = 2,880 fh | Also a real airliner's yearly utilization, so a plane that flies nonstop logs a realistic year |
| Game day (calendar) | 2,880 / 365 ≈ 7.9 fh ≈ 7.9 real minutes | Used only for per-day counts (flights per day) and dates |
| Real day/night on the globe | Real UTC time | Ambience only; never affects play |

Planes fly around the clock. There is no night grounding in Era 3.

### 1.2 Three clocks in code

- **Sim time** `t` (fh since the save began) moves with real time: 1 fh per real minute, foreground or background.
- **Calendar** `c` (fractional game years since 1 Jan 1946) moves at its own rate (section 11). Dated things read `c`.
- **Wall clock** is read only by the app shell, never by the simulation. The shell turns "now" into a target `t` and asks the simulation to advance to it.

### 1.3 Advancing the world (the same code for live play and time away)

The simulation never steps planes minute by minute. Between **breakpoints**, every rate is constant, so money, passengers and calendar progress are integrated exactly:

1. Compute each route's steady-state economics for the current state (section 6): passengers per fh by city pair, revenue per fh, cost per fh.
2. Find the next breakpoint, the earliest of: the target time; the calendar reaching a dated item (plane type, part, runway upgrade, event, history-airline route, game-year boundary); a city crossing a level threshold; a charter returning or a new charter arriving; cash reaching zero; the away-cap on the calendar (section 11.3).
3. Integrate everything to that breakpoint, apply its effect, emit events (for the morning edition and milestones), and repeat.

**Why:** a month away is a few hundred segments, not 40,000 minutes, so catch-up takes milliseconds; and live play and time away give identical results. Plane positions on the globe are a pure function of `t` and each route's schedule; they're drawn, not simulated.

**Invariant (tested):** advancing 10 h in one call gives the same state as ten 1-h calls, to the cent and the passenger.

### 1.4 Randomness

There is very little. Where needed (which charter arrives, which town it names), a seeded generator stored in the save is used, so the same save always produces the same world. Nothing random ever costs the player anything (Principle 8).

---

## 2. Geography

### 2.1 Distance and paths

- Great-circle distance on a sphere of radius 6,371 km (haversine). Legs are flown along the great circle.
- Points along a leg are sampled every 25 km for the over-water share, the 60-minute band and ocean membership; every 1/20 of the leg for wind.

### 2.2 Over-water distance and ocean membership

- A **land mask** at 0.25° (built from Natural Earth by script) says whether a sample point is land or water.
- An **ocean map** at 1° says which ocean a water point belongs to: Atlantic, Pacific, Indian, Arctic, Southern, or an inland sea (Mediterranean, Caribbean, etc., which count as their parent ocean except the Mediterranean, Black and Caspian seas, which count as none).
- **Over-water km** of a leg = 25 km × number of water samples. A leg's ocean = the ocean with the most samples, if over 1,000 km.

### 2.3 Surface link (fares and demand)

Each city pair has a surface link: `fastRail`, `slow` or `none`.

1. If the great circle between them has over 50% water samples: `none`.
2. Else if either airport is an island, or the pair is listed in the data's `noSurface` table (closed borders, deserts, mountain barriers, the Berlin corridors): `none`.
3. Else if the pair is listed in `slowSurface` (poor rail or road): `slow`.
4. Else: `fastRail`.

The tables live in the airports data and are curated by hand; rule 1 is automatic.

### 2.4 Wind

- The wind grid gives an average wind vector (east, north components in km/h) at about 600 hPa for each 5° cell.
- **Tailwind on a leg in one direction** = mean, over 20 points, of the wind vector projected onto the direction of travel at that point. Stored per leg as `tailwindOut` and `tailwindBack`.
- **Ocean control effects** (Weather office, Pressure-pattern flying) apply to samples within 1,500 km of that city: headwind components × 0.5, or tailwind components × 1.5.

---

## 3. Planes, parts and designs

### 3.1 Types (Era 3)

| Type | Engines | Seats | Still-air range | Cruise | Runway need (sea level) | Pressurized | Arrives |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Dakota | 2 | 21 | 1,500 km | 270 km/h | 1,000 m [tune] | No | 1946 (start) |
| Skymaster | 4 | 44 | 3,400 km | 360 km/h | 1,600 m [tune] | No | 1946 |
| Connie | 4 | 60 | 3,900 km | 480 km/h | 1,800 m [tune] | Yes | 1946–47 |
| Liner | 2 | 40 | 1,200 km | 440 km/h | 1,300 m [tune] | Yes | 1948 |
| Whisper | 4 | 48 | 1,800 km | 510 km/h | 1,500 m [tune] | Yes | Apr 1953 |
| Seven Seas | 4 | 90 | 6,500 km | 550 km/h | 1,940 m [U] | Yes | Jun 1956 |

Prices and running costs per flight hour (fuel, crew) come from the balance sheet. The exact unlock day of each type is in the era file.

### 3.2 Part slots

Each plane has four slots. Each option is a trade-off; none is strictly better (Principle 3).

| Slot | Option | Effect [tune] | Key |
| --- | --- | --- | --- |
| Wings | Standard | — | Start |
| | Long-span | Range ×1.08, runway need ×1.15 | Start |
| | Short-field | Runway need ×0.75, cruise ×0.95, range ×0.95 | 1947 |
| Engines | Standard | — | Start |
| | Power | Cruise ×1.08, runway need ×0.90, fuel cost ×1.15 | 1947 |
| | Economy | Cruise ×0.95, range ×1.06, fuel cost ×0.90 | 1948 |
| Tanks | Standard | — | Start |
| | Extra tanks | Range ×1.12, seats ×0.90 | Start |
| | Ferry tanks | Range ×1.25, seats ×0.75 | 1949 |
| Cabin | Standard | — | Start |
| | Sleeper berths | Seats ×0.6; comfort +2 on legs over 8 fh | Start (pressurized types only) |
| | Tourist class | Seats ×1.2; comfort −1; fares ×0.8 | Milestone A10 |
| | Freighter | No passengers; cargo capacity = base seats × 0.1 t | Engineering "Conversion line", or 1950 |
| | Combi | Half seats, half cargo | 1950 |

- Multipliers stack by multiplying. Seats round down.
- **Extra tanks** gives the +11% on Wake–Tokyo the balance sheet found (−1% stock) [V against sheet].
- **Design works** (Engineering tier 3) unlocks one extra option for one slot, unique to the airline: the player picks one of three generated variants (each moves two numbers by 5–10% in opposite directions).

### 3.3 Designs

- A **design** = a type + one option per slot + a name the player gives it. Saved designs live in the hangar.
- **Buying a plane** = picking a design and paying the type's price plus the part prices. The plane is built to that design.
- **Refitting** an existing plane to another design costs the part price difference plus a fee, and takes the plane off its route for 2 fh [tune]. Only at a city with an Overhaul base or at the plane's home city.
- **War surplus (1946–47):** surplus Skymasters cost one third of the new price ($297,000 against $900,000). Surplus planes arrive in olive drab, bare metal or another airline's faded paint.

---

## 4. Range, runways and the engine rule

### 4.1 Range of a leg in one direction

```
designRange = type.range × wings.range × engines.range × tanks.range
designCruise = type.cruise × wings.cruise × engines.cruise
groundSpeed = designCruise + tailwind            (for that direction)
windRange   = designRange × groundSpeed / designCruise
takeoff     = runwayFactor(departure airport)     (4.2)
radio       = 1.05 if a Radio station of yours is within 1,000 km of the departure, else 1
effectiveRange = windRange × takeoff × radio
margin = effectiveRange / legDistance − 1
```

A leg works in that direction if `margin ≥ 0`. A route works only if every leg works in both directions. The route card shows the worst margin and the gap in km.

### 4.2 Runway factor (P7)

```
need = type.runway × wings.runway × engines.runway
       × (1 + 0.06 × elevationFeet / 1000)
       × (1.15 if airport.hot else 1)
available = airport.baseRunway(at calendar date) + playerExtensions
ratio = available / need
runwayFactor = 1            if ratio ≥ 1
             = ratio        if 0.7 ≤ ratio < 1     (takes off lighter)
             = unusable     if ratio < 0.7
```

- Only take-off is checked (landing is a simplification).
- `hot` is a data flag for lowland tropical and desert airports with average summer highs over about 30 °C. Highland airports such as Johannesburg and Nairobi are not hot.
- **Runway +500 m** (city level 2→3) adds 500 m to `playerExtensions`. Dated upgrades change `baseRunway`; extensions stay on top (Spec section 7).

### 4.3 The 60-minute band (twins, all of Era 3)

```
bandKm = designCruise × 1.0 h (+0.25 h near a Direction finder of yours, within 1,500 km of it)
```

For a twin, every 25-km sample along the leg must be within `bandKm` of at least one **usable diversion point**: any open landplane airport on the map (curated, regional or refuel-only) or an Ocean weather ship of yours. A leg that breaks the band is drawn red where it leaves the band, with the gap in minutes. Four-engine types ignore the band.

### 4.4 The range ring on the globe

For the selected plane at the selected airport: for each of 72 bearings, compute the distance at which `effectiveRange` (with the wind sampled along that bearing) runs out. Join the points. For twins, also draw the 60-minute band as a shaded corridor around usable diversion points. Recomputed only when the plane, design, airport or date changes.

---

## 5. Routes

### 5.1 Shape

- A route is an ordered list of 2–6 stops (`maxStops` is a playtest setting chosen when a game starts and stored with it: 2 for the "pairs" test, 6 for the "lines" test; gate G1). A route can't visit the same city twice.
- Planes fly the stops in order and back (A→B→C→B→A), then repeat.
- One or more planes are assigned to a route. Planes on a route can be different designs; the route works only if every assigned plane can fly every leg.

### 5.2 Timing [tune]

```
blockTime(leg, direction) = distance / groundSpeed + 0.3 fh   (taxi, climb, approach)
groundTime(stop) = 0.5 fh at every stop, ends included (0.25 fh with Engineering "Fuel farm" at that stop)
rotation = Σ blockTime over all legs both ways + Σ groundTime over every landing
departuresPerFh(route) = planes / rotation, per direction, per leg
```

### 5.3 City flight capacity

Each city allows a number of departures per game day by all your routes: `6 + 3 × level` [tune], ×1.5 with Terminal. If routes through a city need more, the route card says so before you commit and the extra planes can't be added. This is what makes Terminal a real choice.

### 5.4 Pausing

- A route can be paused by the player, or paused automatically by the cash floor (section 7.4). A paused route's planes stay on the ground at their home city, costing nothing.
- Resuming is one tap. Nothing is ever sold or removed.

---

## 6. Demand, passengers and fares

### 6.1 Yearly demand of a city pair

```
D(i,j,year) = K
            × sqrt(P_i × P_j)                       city size (P = demand population, 6.2)
            × distance^-0.8                          distance
            × airShare(surfaceLink, distance)        what you compete with
            × (2 if surfaceLink == none else 1)      saving days
            × world(year)                            1.0 in 1946 → 5.0 in 1957
            + tourism and identity terms (6.3)
```

- `K` is the calibration constant from the balance sheet.
- `airShare`: fastRail rises linearly from 0 at 0 km to 1 at 800 km; slow from 0 at 0 km to 1 at 400 km; none = 1.
- `world(year)` is a table in the era file, interpolated within the year.
- Demand is the same in both directions.
- Refuel-only (R) airports have `P = 0`.

### 6.2 Demand population

```
P = population1950 × levelMultiplier(level) + catchment
levelMultiplier = 1.0, 1.15, 1.3, 1.45, 1.6, 1.8 for levels 1–6   [model value]
catchment (if Catchment chosen) = Σ population of regional towns within 150 km × 0.5   [tune]
```

### 6.3 Extra demand from identities [tune]

- **Holiday trade:** each of your 3 biggest cities gets an extra pair demand to this city equal to 30% of their base pair demand.
- **Grand hotel:** every city you serve gets an extra 20% of its base pair demand to this city.
- **Feeder:** a virtual pair from the nearest unserved regional town (by population) into the city, whose passengers only connect onward (they count as transfer passengers).
- **Free port:** cargo and mail demand (6.7).

### 6.4 Your share of a pair

If history's airline doesn't serve the pair: you get all of it. Otherwise:

```
base  = 0.70 if your first flight on the pair came before the rival's opening date, else 0.40
speed = clamp(0.10 × (rivalTripTime / yourTripTime − 1), −0.10, +0.10)
comfort = clamp(0.03 × (yourComfort − rivalComfort), −0.09, +0.09)
frequency = clamp(0.05 × log2(yourDeparturesPerDay / rivalDeparturesPerDay), −0.10, +0.10)
stops = −0.04 × (yourStops − rivalStops)
standing = +0.02 × standing stars (max +0.10)
share = clamp(base + speed + comfort + frequency + stops + standing, 0.15, 0.85)
```

Trip time includes ground time at intermediate stops and, for transfers, the connection time (1 fh, 0.5 fh with a Lounge).

**Pooling** (after milestone B16, per pair, by choice): share fixed at 0.50, and the pair's total demand ×1.1 because the combined timetable is better [tune].

### 6.5 Comfort

Per trip: +2 if pressurized; +2 with sleeper berths if any leg is over 8 fh; −1 per intermediate stop (0 at a stop with a Canteen); −1 tourist class. Comfort only moves share.

### 6.6 Filling seats

Each fh, for each leg and direction, seats offered = Σ over planes on the route of seats × departuresPerFh. Usable seats = 85% of that (the load factor cap). Passengers from your share of each pair are routed and loaded in this order:

1. **Nonstop** on a route that flies the pair directly.
2. **Same route through stops** (staying on board): at 90% of demand.
3. **One transfer** at a city where two of your routes meet, if the path is under 35% longer than the great circle: at 70% of demand (85% if the transfer city has a Lounge).
4. **Two transfers**, only if one of them is at a designated hub, same detour limit: at 50% of demand.

Within each step, pairs are loaded largest first. A passenger who doesn't fit is lost, not queued. This matches the Python network model (Findings doc, section 3), which is the reference for the parity tests.

### 6.7 Cargo and mail (light)

- Each pair also has a cargo-and-mail demand in tonnes per year: `0.02 t × passenger demand` [tune], ×2 if either end is a Free port with Bonded warehouses.
- Carried only by Freighter or Combi cabins, or in a small belly hold: every passenger plane carries 0.5 t per leg of mail [tune].
- Fare per tonne-km is in the sheet; Mail exchange raises mail fares through that city by 30%.
- Cargo exists so Free port, Combi, Freighter and special loads mean something. It is never a separate job list.

### 6.8 Fares

```
fare(pair) = base + rate × (landKm + 1.7 × waterKm)        if surfaceLink != none
           = (base + rate × distance) × 1.7                if surfaceLink == none
```

- Tourist class ×0.8.
- Through and transfer passengers pay the fare of their own pair (the great-circle distance), split across the legs they fly in proportion to leg distance.
- **Hotel** (Hospitality tier 2): passengers who stop or connect there pay a stopover fare of 5% extra [tune], credited to that city.
- **Duty-free shop:** +$2 per transfer passenger at that city [tune].
- **Oceanic control:** a fee per flight (yours or the rival's) whose leg passes within 1,500 km of the city over water [tune].

---

## 7. Money

### 7.1 Costs

Per route, per fh: Σ planes × (fuel + crew per fh of their design) + Σ landings per fh × landing fee. Landing fee = sheet value × (1 + 0.1 × city level). Repair shed: −15% running cost for planes based there [tune]. Fuel farm: −20% fuel for legs departing there [tune].

### 7.2 Profit display

Each route line is colored by profit per fh: losing (coral), near zero (sand), earning (teal), with a small icon as well as color so it reads without color vision. Tapping shows the breakdown: passengers by pair, load per leg, revenue, costs.

### 7.3 Prices [tune]

| Purchase | Starting price |
| --- | --- |
| Level 1→2 choice | $40,000 |
| Level 2→3 choice | $120,000 |
| Identity (level 3→4) | $250,000 |
| Identity tier 1 / 2 / 3 | $400,000 / $800,000 / $1,600,000 |
| Hub terminal | $500,000 |
| Repaint | $5,000 per plane |
| Pride projects | $2,000,000+ |

### 7.4 The cash floor

- Cash can never go below zero.
- When integration shows cash reaching zero inside a segment, the simulation stops at that moment, pauses the route with the worst profit per fh, and continues. It repeats until total profit per fh is zero or positive.
- The morning edition lists paused routes with a "Resume" button. Resuming when the cash rate is still negative is allowed: the floor simply catches it again.
- Purchases that would take cash below zero are not offered.

---

## 8. History's airline (the rival)

- **Data per start:** a list of dated route openings: stops, plane type, departures per day, and optionally a closing date. The same list draws the heritage ghost.
- **Behaviour:** on each opening date the route starts and the morning edition reports it. It never changes because of anything you do.
- **Its service values** (trip time, comfort, frequency, stops) come from the data, for the share formula (6.4).
- **On the globe:** its routes are thin dashed lines in a muted color; its planes are small silhouettes. It is visible, never in the way.
- **Its name:** an invented period airline per region ("Southern Cross Airways" for Sydney), in the era file.

---

## 9. Cities

### 9.1 Levels [tune]

A city's level rises from passengers passing through it this era (starting, ending, or connecting there; through passengers who stay on board don't count).

| Level | Cumulative passengers through the city |
| --- | --- |
| 2 | 3,000 |
| 3 | 12,000 |
| 4 | 40,000 |
| 5 | 100,000 |
| 6 | 220,000 |

At New York–Montreal with one Dakota (about 6 passengers per fh at each end), level 2 arrives after about 8 real hours: the first level-up shows up in the second or third check-in, not the first session. The bots tune these.

- Reaching a level creates a **pending choice**. Pending choices never expire; the level's passive part (the population multiplier) applies at once, the chosen option applies when bought.
- Choices cost money (7.3). If you can't afford it yet, the card says how long your current profit takes to pay for it.

### 9.2 Which identities a city is offered

Each airport row has trait scores from data: `islandOrRemote`, `bigCityPort`, `wartimeBase`, `industrial`, `tourism` (0–3 each). Each trait adds its score to the two identities it offers (Spec 2.2). The two identities with the highest totals are offered; ties break in the order Ocean control, Hospitality, Free port, Engineering. The offer is shown on the airport card from level 1, so the player can plan.

### 9.3 Effects of every option

All option effects are rule modifiers looked up by the formulas above: Catchment (6.2), Terminal (5.3), Feeder (6.3), Runway (4.2), Canteen (6.5), Lounge (6.4, 6.6), Hotel (6.8), Holiday trade and Grand hotel (6.3), Hotel school (copies tier-1 effects), Duty-free and Customs-free (6.8; Customs-free adds +0.05 share on pairs that connect there), Bonded warehouses, Mail exchange, Free zone, Trade fair (6.7, 10.2), Repair shed and Fuel farm (5.2, 7.1), Overhaul base and Conversion line (3.3), Design works and Test field (3.2, 11.4), Radio station and Direction finder (4.1, 4.3), Weather office and Pressure-pattern flying (2.4), Oceanic control (6.8), Ocean weather ship (4.3). Each modifier has one test.

---

## 10. Charters

### 10.1 The board

- Holds 5 charters (7 after milestone F3). Event charters sit on a separate row and don't use slots.
- A new charter arrives every 4 real hours [tune] while there's a free slot. Arrival times come from the seed, so they're the same whether you're watching or away.
- Nothing on the board expires.

### 10.2 Types

| Type | How it's generated | Pay [tune] | What it opens |
| --- | --- | --- | --- |
| **Pioneer** | An unserved curated city that at least one of your saved designs can reach from a city you serve, preferring cities near a history marker | 1.5 × your fleet's median profit per fh × the charter's flight hours | Reveals the city's exact demand; stamps your "first there" date (share 70% if before history's airline); keepsake. You can always open a city directly with a scheduled route without one |
| **Special load** | A load with a constraint your current fleet can't quite meet: a short runway with long range, a freighter cabin, a high airport. 3× more often from a city with Trade fair | 2 × median profit per fh × hours | A design puzzle and money |
| **Event** | Appears on its date (10.4) | 1.5 × median profit per fh × hours, plus a 3-month demand surge on that pair (×1.5) after it's flown | The surge, a keepsake, milestone F8 |

Before a city is served or pioneered, its demand shows as a band (low, medium, high) instead of a number.

### 10.3 Flying a charter

Three taps: the charter, a plane (eligible planes are listed with their margin), Fly. The plane leaves its route, flies out and back, and returns to its route by itself. The route keeps flying with its other planes; if it was the only plane, the route waits at no cost.

### 10.4 Event charter list (first draft, all *(verify)* dates)

| Event | Where | When | Natural start |
| --- | --- | --- | --- |
| Winter Olympics | St. Moritz (via Zurich) | 30 Jan–8 Feb 1948 | Amsterdam |
| Summer Olympics | London | 29 Jul–14 Aug 1948 | Amsterdam, New York |
| British Empire Games | Auckland | Feb 1950 | Sydney |
| Holy Year pilgrimages | Rome | 1950 | Any |
| FIFA World Cup | Rio de Janeiro | 24 Jun–16 Jul 1950 | Buenos Aires |
| Pan American Games | Buenos Aires | Feb–Mar 1951 | Buenos Aires, New York |
| Asian Games | New Delhi | Mar 1951 | Bangkok |
| Festival of Britain | London | May–Sep 1951 | Any |
| Winter Olympics | Oslo | 14–25 Feb 1952 | Amsterdam, Reykjavík |
| Summer Olympics | Helsinki | 19 Jul–3 Aug 1952 | Amsterdam |
| Coronation | London | 2 Jun 1953 | Any |
| Asian Games | Manila | May 1954 | Bangkok |
| FIFA World Cup | Switzerland (via Zurich) | 16 Jun–4 Jul 1954 | Amsterdam |
| British Empire and Commonwealth Games | Vancouver | Jul–Aug 1954 | New York, Sydney |
| Pan American Games | Mexico City | Mar 1955 | New York |
| Winter Olympics | Cortina (via Milan) | 26 Jan–5 Feb 1956 | Amsterdam |
| Equestrian Olympics | Stockholm | Jun 1956 | Amsterdam, Reykjavík |
| Summer Olympics | Melbourne | 22 Nov–8 Dec 1956 | Sydney |
| **Hajj** (every year) | Jeddah | Date from the Islamic calendar, about 11 days earlier each year | Cairo, Tehran, Karachi |

All are sporting, cultural or religious gatherings, none political. Each pair runs from the start's nearest big gateway that the player serves.

---

## 11. Calendar and era pacing

### 11.1 The calendar's speed

```
worldRate  = 1 game year / 2,880 fh
growthRate = (passengers carried per fh) / threshold(year)      game years per fh
rate = min(worldRate, growthRate)
threshold(year) = baseThreshold(year) × startScale
startScale = max(1, startNetworkSeatsPerFh / freshStartSeatsPerFh)
```

- `baseThreshold(year)` is passengers per game year, a table in the era file from the balance sheet, rising each year so a player who stops growing slows down.
- `startNetworkSeatsPerFh` is measured once, when the era begins. A fresh start has `startScale = 1`.

### 11.2 Dated content

The era file lists every dated item: plane types, parts, runway upgrades, airport openings (Moscow 1956), history-airline routes, events, history milestones. Each appears when `c` reaches its date and then waits. Everything dated that changes play is listed in "Coming next" and on the relevant card from the start of the era.

### 11.3 While you're away

**Stop dates** are the history milestone dates (section A of the Milestones doc) and the plane-type unlock dates. While the app is in the background, the calendar advances at its normal rate **up to the next stop date** after where it was when you left, then holds there. Routes keep flying and earning; only the calendar waits. When you return, the calendar resumes its normal rate.

### 11.4 Test field

Engineering tier 3 "Test field" lets the player buy the next plane type that hasn't arrived yet, once per type, at 1.5× price [tune].

### 11.5 Era goals and the era-end card

| Goal | Test |
| --- | --- |
| C3 Two continents | A route with stops on two continents carries passengers |
| E2 Identity | Any city has chosen an identity |
| C9 Every ocean | For each of the Atlantic, Pacific and Indian oceans, a four-engine route with a leg having 1,000+ km over that ocean |
| A16 Nonstop Atlantic both ways | A route with exactly two stops, one in North America and one in Europe, whose leg works in both directions |
| A18 Beat the liners | In a completed game year, your passengers on legs crossing the North Atlantic exceed the liner curve (11.6) |

The card appears when `c ≥ December 1957` and 3 goals are done. In the first edition it offers the era front page, the timelapse, and "Keep flying in 1957".

### 11.6 The liner curve

The era file holds the ships' Atlantic passengers per game year, in game units. It's tuned (by the bots) so that a strong player can pass it around 1955–57 and history's airline alone would pass it in 1957, matching the real crossover. Each January the morning edition prints "Air vs sea" with both numbers.

---

## 12. Milestones engine

- Every milestone is a **condition on the state** (a pure function), checked after each breakpoint that could change it.
- When true, it's earned once: its rewards are granted and an event is emitted with the calendar date.
- **History milestones (A)** compare that date with the real date: earlier = gold keepsake and "World first"; later = standard keepsake and "History did it in 1954".
- **Lifetime firsts** check the airline's lifetime record first; if already held, they show as earned and grant nothing new.
- **Display:** the hangar shows the next 3 per category, ranked by a progress fraction each condition reports (0–1).

---

## 13. The morning edition

- **Opens** when the app comes to the foreground after 1 real hour or more since it was last open.
- **Headline:** the highest-priority event since then: era goal > history milestone > city reaches identity tier 3 > new plane type > other milestone > level-up waiting > record month > route paused > history's airline opens a route > calendar reaches a year.
- **Three items:** money earned since last time; the busiest route; then the next two highest events not used as the headline.
- **One prompt:** the single most valuable waiting decision: the oldest pending city choice, else a newly affordable plane type, else a pioneer charter.
- **Coming next:** the nearest future dated item from 11.2.
- **Text** comes from templates with slots ("{city} has grown. Choose: {optionA} or {optionB}."). Templates live in the era file so each era has its own voice.
- Dismissed with one swipe. Shareable as an image.

---

## 14. The first session (Era 3, New York)

What the player does, what the game shows, and what it teaches. Times are real time from launch.

| Time | What happens | It teaches |
| --- | --- | --- |
| 0:00 | Globe in mid-century style, seven start cities glowing. One card: pick a start. | The globe is the interface |
| 0:30 | Camera flies to LaGuardia, 1946. A surplus Dakota in olive drab, already named. One line on the card: "Drag to a city to start a route." | Ownership from minute one |
| 0:45 | Player drags New York → Montreal. The range ring, trip time and expected profit show while dragging; releasing opens the route card; "Fly". | Show the consequence before the commitment |
| ~3:00 | The Dakota lands in Montreal (about 2.3 fh); cash ticks up with a sound. | Respond to everything |
| 3:30 | A pioneer charter appears for Bermuda. The Dakota's ring reaches it, but the 60-minute band leaves a red gap over open water. The card shows the surplus Skymaster ($297,000) and a bar filling toward it. | The engine rule, without a tutorial |
| 5:00 | (Lines setting) a hint shows that dragging the route onto Boston adds a stop. | Stops are a decision |
| ~60:00 | (Usually a second session) the Skymaster is affordable. The workshop opens on purchase. Gander and Shannon glow. Shannon → Gander falls short westbound into the westerlies; the gap shows in km. | Wind shapes range |
| +2 min | Player fits extra tanks; the ring stretches; the route New York–Gander–Shannon–London works both ways. Front page teaser: "Coming next: Idlewild opens, July 1948." | The "aha" and something to look forward to |

Each start has its own data for steps 3–4: its first good route and its first "just beyond" gap (Cairo: Athens, then the desert to Baghdad; Reykjavík: its Skymaster's Atlantic line, then Narsarsuaq; Sydney: Melbourne, then the Tasman).

---

## 15. Heritage challenges

### 15.1 How a challenge plays

- A challenge is a **planning puzzle with a fixed scenario**: a map subset, a frozen date, a budget, a fleet or a shopping list, and a target network.
- The player builds routes and designs, then taps **Run a month**. The simulation computes one game month of operations instantly (the same code as the main game), and the result card shows the stars.
- No waiting: challenges are where the game is fast, because they're puzzles, not your airline. Run as often as you like; the best result counts.
- Results are deterministic, so the global board is fair.

### 15.2 The three Era 3 challenges

| Challenge | Scenario | ★ Coverage | ★ Budget | ★ Beat history |
| --- | --- | --- | --- | --- |
| **The airlift, 1948** | Bases at Frankfurt-area fields and Hamburg-area fields; Berlin's three fields with landing slots per hour; Skymasters and Dakotas; cargo only | Deliver the minimum daily tonnage the city needs *(verify the figure)* | Within the budget | More than 12,900 t on the best day (the real peak, 16 Apr 1949) |
| **Crossroads, 1950** | New York, Gander, Goose Bay, Shannon, Prestwick, London; $3M; Skymasters and Connies | Daily New York–London service both ways | At a profit | One fewer stop at the same cost |
| **The Kangaroo road, 1947** | London to Sydney on the real road's airports; Connies and Skymasters; a fixed budget | One-ticket service London–Sydney both ways | Within the budget | Fewer stops than the real 1947 through service *(verify the stop list)* |

---

## 16. Screens

| Screen | What it is |
| --- | --- |
| **Globe** (home) | The whole interface: airports, routes (colored by profit), planes, range ring and band while planning, history's airline faintly, history markers, the date stamp |
| **Bottom card** | One at a time: airport, route (planning and live), plane, charter board, level-up choice, purchase, paused routes |
| **Workshop** | Design a plane: four slots, the ring and the numbers updating live, save as a named design |
| **Hangar** | Fleet, saved designs, liveries, keepsake wall, airline charter with titles, next 3 milestones per category |
| **Morning edition** | Full screen on return; one swipe to dismiss |
| **Front page** | Big moments and the era end |
| **Start picker** | The seven starts with difficulty and a one-line identity |
| **Challenges** | List, scenario map, result card |
| **Settings** | Sound, haptics, reduce motion, data credits |

**Accessibility:** cards support Dynamic Type; every airport, route and plane has a VoiceOver label and a list fallback for the globe; profit uses icon plus color; Reduce Motion replaces camera flights with fades.

---

## 17. Golden tests

These come straight from the research and the balance sheet, and must pass in the Swift code. Expected values are exported from the sheet and the Python model into test fixtures, so when the sheet changes, the fixtures are regenerated, not hand-edited.

| Test | Expected (current sheet) |
| --- | --- |
| Recife–Dakar, stock Skymaster, worst direction | +4% margin |
| Aden–Bombay, stock Skymaster, worst direction | +10% |
| Wake–Tokyo, stock Skymaster, into the wind | −1%; with extra tanks +11% |
| Nairobi–Salisbury, Dakota / Skymaster | −24% / +72% |
| Seven Seas at Kai Tak (1,664 m), before 1958 | About 79% range (Runways tab) |
| Connie at Johannesburg Palmietfontein, 1950 | Usable, lighter (between 70% and 100%) |
| Bermuda from New York, Dakota | Inside range, outside the 60-minute band |
| New York–Philadelphia: 1 Dakota vs 3 Dakotas | Profit falls to a loss per plane (sheet: $149/h vs −$89/h before the new rules; refresh) |
| Sydney: Skymaster Sydney–Auckland alone vs Melbourne–Sydney–Auckland line | Loss vs profit (model: −$60/h vs +$412/h; refresh) |
| Every start, 1946, starting plane | At least 2 routes earning $100+ per fh |
| Advancing 10 h at once vs ten 1-h steps | Identical state |
| 30 days away | Calendar holds at the next stop date; cash ≥ 0; nothing sold |

---

## 18. Open items

- [ ] Prices and running costs per type: confirm the sheet values and export them
- [ ] Level thresholds, flight capacity, charter pay and the liner curve: tune with the bots
- [ ] Airlift minimum daily tonnage and the 1947 Kangaroo stop list *(verify)*
- [ ] Hot-airport flags for all 166 airports
- [ ] `noSurface` and `slowSurface` tables for the curated pairs
- [ ] Event charter dates *(verify)*
- [ ] History-airline networks for the seven starts
