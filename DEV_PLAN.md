# Godspeed Ginny — Development Plan

Premium indie / AAA-adjacent mobile game, solo-built (systems/UX/code) with daughter-assisted art. Not studio-budget AAA — the target is a polished, intentional phone product in the *Slay the Spire* / *Balatro* class of craft.

---

## 1. Current state (what is built)

Faithful Flutter/Flame port of the lab webpage at `daddoodev/static/lab/godspeed-ginny/`.

### Systems
- Full run loop: office → cast off → forks → boulder → ducks → Nowhere → settle
- Content-driven engine (JSON): nodes, branches, jokes, cargo, profiles, telegrams, strings, config
- Career persistence (purse, chart notes, salvage, leopard-at-large, best room)
- Playtest telemetry (last N runs, joke/node/station reports)
- Bundle ID: `pro.daddoodev.godspeedginny`

### Presentation
- Chart-paper Flutter UI (office, passage, branch, choice, settle, telemetry)
- Flame river/boat as a thin backdrop under play screens (placeholder)
- Branding: `assets/branding/app_icon.png` (app icon), `assets/branding/splash.png` (native splash + title hero)
- Title / settings / credits shell; office is a destination

### Not yet a mobile product
- UI is the game; Flame is not the passage yet
- No real art pipeline, audio, haptics, store packaging, or retention meta
- First-run teach still thin

**Keep:** rules engine, JSON content pipeline, tone, branding seeds.  
**Do not:** rewrite the engine or chase open-world / multiplayer / heavy 3D early.

---

## 2. Product thesis

You are skipper of the *Godspeed Ginny* for McRiver Cruises & Cargo. Nowhere is always three days away; you always come back to Crazy. Comedy, chart lies, cargo risk, and keeping “the room” alive under boiler/water/hull pressure.

Fantasy must read in a **phone screenshot** and a **15-second trailer**, not only in prose.

**Inspiration (tone, not a copy):** Disney parks Jungle Cruise — a guided river tour where the **skipper is the entertainment** because that’s what the passengers have. Scenery, chart lies, and patter are the show.

---

## 3. Visual / presentation recommendation (agreed direction)

**Not 3D. Not a continuous free-sail sim. Not cabaret staging. Not instrument-peephole as the main view.**

### Spine: 2D ribbon + docked stage
- **Underway (between beats):** a simple 2D river ribbon carries Ginny to the next stretch (parallax water, landmark slides by). Sells “tour” without a sim.
- **Bit (on the beat):** the ribbon **docks** into a fuller stage composition — place art + bobbing boat + log/card + bottom actions. Sells the named stretch (hippo, Calliope, falls, etc.).
- **Actions:** thumb zone toward the bottom — clear primary verbs (Steer / Go below / Bail) as solid buttons; jokes as tickets/chips in a scroll strip (layout can iterate).

### Supporting layer: chart-table (player-selected overlay + office)
The river was surveyed once, by one cartographer, some years ago — **the chart is not right.** That stays diegetic.

- **Office / forks / settle:** desk, telegram, manifest, pencil annotations (bureaucracy mode).
- **During a run:** player can **open the chart** to see “where we are,” what the chart claims, and what they’ve annotated. Optional overlay — not the whole fantasy.
- Career already stores chart notes on discovery; the overlay should surface that.

Later uniqueness hook (optional): on replay, annotations can visibly change how landmarks read on the ribbon/chart.

### Garnish: comic strip (end of run)
- Not the live play surface.
- After settle, a short comic scrapbook built from the run record (panels per node / big moments). Shareable, on-brand, low constant UI cost.

### Mode summary

| Mode | Look | When |
|------|------|------|
| Office | Chart-table / telegram desk | Title → cargo → career |
| Underway | Short 2D ribbon transit | Between nodes |
| Bit | Docked stage + bobbing Ginny + bottom verbs/jokes | Hazards, falls, ducks, boulder, etc. |
| Chart | Player-opened overlay / sheet | Anytime during run (and office) |
| Recap | Comic strip of the run | After settle |

### Motion budget (solo-sane)
- Ribbon scroll between beats
- Gentle boat bob on stage
- Short reaction on beat spend (steam / list / splash)
- One punchline sting when a joke lands
- Prefer **shared boat rig + swap stage/landmark art** over bespoke animation per joke

### Art bible one-liner
Jungle Cruise postcard that *moves* between bits; desk and wrong chart for bureaucracy; comic scrapbook when you get home.

---

## 4. Target quality bar

| Area | Bar |
|------|-----|
| Feel | No jank; readable danger; jokes land with juice |
| Art | Coherent direction; daughter pipeline with clear briefs |
| UX | One-hand mobile; safe areas; teach without a manual |
| Audio | Music + SFX that sell comedy and river |
| Store | Looks intentional in listing; stable on mid phones |
| Scope | Deep one fantasy, not a thin open world |

---

## 4A. Gameplay design — the replayability spine

The M0 port is a faithful copy of the web proof of concept: one fixed run, a handful of jokes, a light meta. This section is the design for turning it into a run-based game people replay indefinitely. The engine stays; the **run structure, joke handling and meta** grow on top of it.

### Pillars
1. **Read the room.** Passengers have tastes; the skill is spending scarce beats where they pay off.
2. **The chart lies.** The river is never what the chart claims, and experience (annotations) is how you beat it.
3. **The skipper is the entertainment.** Jokes are the main verb, not a side action.
4. **Everything is a trade.** Entertaining costs steering, steering costs silence, silence costs the room.

### What exists today (facts from the code)
- Core loop: each stretch has a fixed number of beats; each beat is Patter / Steer / Wrench / Bail. Jokes heat the boiler, non-patter beats drain satisfaction (`silenceDrain` 3), unresolved threat damages hull/water/satisfaction.
- Joke scoring: passenger flavor weights × on-topic bonus (1.9) / off-topic penalty (0.45) × repeat fatigue (0.35 per repeat) × selling multiplier at the falls.
- Run structure: fixed `runPlan` in `config.json` (cast off → fork → node → wreck → boulder → fork → node → falls → ducks → Nowhere → settle). About 20 beats, two route choices.
- Hand: `startRun` gives the player every unlocked joke (31 jokes, all `attention_cost` 1). There is no scarcity, drafting or build.
- Unused data: `patience`, `fear_threshold`, `callback_to`, `fatigue_runs`, and risk on most jokes.
- Meta: purse, chart notes, salvage jokes, leopard-at-large, best room. The purse has nothing to spend it on.
- Randomness: one global unseeded `Random()` in `lib/engine/util.dart`.

### System 1 — Voice and material (the foundation)
There is no deck screen, draft screen or office step. The skipper's act develops over time, and the jokes arrive spontaneously during the cruise.
- **Collection:** every joke found (base set, salvage, gifts). All of it stays in the pool.
- **Spontaneous hand:** when the skipper patters, about 3 jokes "come to mind," drawn from the pool rather than chosen from the full list. Unplayed ones fade; the next patter draws fresh.
- **Voice:** a running profile of the flavors you've told (dry, pun, absurd, dark and so on). Every joke told nudges it, and the draw is weighted toward your voice. A skipper who goes dry keeps getting dry material, even when the room isn't laughing. Stubbornness is a real strategy and a real risk.
- **Momentum:** consecutive jokes in the same voice build a streak multiplier. With the right audience it is big; with the wrong one it amplifies the bombs, because negative scores multiply too.
- **Pivot:** spend 1 beat to "think of something else." It redraws from the full pool and halves your voice, at the cost of the beat and the silence drain.
- **Voice over the career:** part of your voice carries into the next run (about a quarter), so a style develops over many runs. Skipper types (System 3) seed the starting voice.
- **Bits mature:** a joke told across runs and landing becomes Rehearsed (lighter fatigue), then Signature (drawn more often, bigger payoff). Bits that keep bombing don't level up. The act grows the way a comedian's does.
- **Inspiration:** when the room laughs during a stretch, a new bit tied to that stretch joins the pool for the rest of the run, and joins the collection if it is salvaged. New material comes from the cruise itself, not from a shop.
- **Cost and risk:** cost is 1 or 2 beats (quick one-liners, long stories); risk uses the existing field.
- **Callbacks:** a joke with a `callback_to` target pays extra if the setup was told earlier in the run.
- **Reactions:** the room meter is the main read. The 1–2 notable passengers (goal passengers and the loudest critic) also show a named reaction after each joke. Per-passenger satisfaction is tracked underneath.

### System 2 — River map and the lying chart
**Run structure (decided, first version built):** a run is about **18 scenes**, like a ride with many short beats rather than a few long ones.
- **Hard-set:** Cast-off opens the run and Nowhere closes it. The landmark scenes (Calliope, boulder, falls, ducks and goose) and the two forks are always present, but their **order is shuffled** every run.
- **Wild pool:** 40 stretches (`"pool": "wild"` in `nodes.json`), of which 10 are drawn at random per run, never repeating. Sights are 2–3 beats; hazards are 3–4 beats.
- **Forks** still offer 2 of 7 chart-lie stretches and lead to one scene. Stretches offered at a fork are reserved so the run can't visit them twice.
- Run plan lives in `config.json` (`runPlan`): `{"kind": "shuffle", "units": [...]}` shuffles its units; a node step with `"pool"` is filled at random.
- **Balance not yet tested:** longer runs mean more beats, so the Nowhere abort thresholds were loosened (hull 18→26, crises 2→4). Tune from telemetry.

- Replace the fixed `runPlan` with a **branching map** (Slay the Spire style, 8–10 stretches, 2–3 choices per fork).
- The chart shows what each stretch *claims* to be. The real stretch is revealed on arrival and often differs. A run's cartographer errors are seeded, so every river is wrong in a different way.
- **Stretch types:** hazard, sight, selling (falls), port (shop and repairs), shrine, event, and the fixed Nowhere finale.
- **Event pool:** generalize Two Ducks and a Goose and the boulder into short choice events written in JSON (setup, 2–3 choices, outcomes using existing gauges).
- **Annotations pay off:** notes from past runs partially reveal the true stretch type on later maps.

### System 3 — Skipper types
- Each skipper has a starting kit and one rule twist:
  - **The Veteran:** starts with a bigger rehearsed deck; repeat fatigue is lighter.
  - **The Deadpan:** silence does not drain satisfaction, but jokes score lower.
  - **The Mechanic:** repairs are cheap; patter is weaker.
- Unlock skippers through career arcs (Calliope stages, goose, leopard) and milestones.

### System 4 — Props and relics
- Run-long modifiers found at ports, shrines and events: rubber chicken, pith helmet, cracked megaphone, a better whistle.
- Each is a trade, not a plain buff (e.g. louder whistle: +satisfaction on landed jokes, boiler heats faster).
- Data-driven in a `relics.json`, same pipeline as jokes and cargo.

### System 5 — Passengers with goals
- Each run has 3–5 passengers with hidden tastes (existing profiles) and an optional goal: make the honeymooners laugh, get the administrator to tip, keep the heckler quiet.
- Finish the dormant fields: `patience` sets how fast silence drains that passenger; `fear_threshold` sets the hazard level at which they panic and demand refunds.
- Per-passenger satisfaction, rolled up to the room meter. The room is the main read; only the 1–2 notable passengers show visible reactions.

### System 6 — The river remembers (saga)
- Repeat passengers recall jokes told to them in earlier runs ("heard that one"), applying extra fatigue or a callback bonus.
- Persistent world state: the Calliope keeps decaying, the leopard at large turns up as a random event, the goose arrives after 3 runs.
- Nowhere has multiple outcomes (passed, missed, abort) that feed unlocks and story beats.

### System 7 — Challenge and endgame
- **Charter levels:** unlocked after a good run, each adds a modifier (stricter inspector, hotter boiler, fewer beats, harsher refunds).
- **Daily river:** one seeded run per day, the same for everyone, no account needed. Results shared as a screenshot or a share card.
- **Joke templates:** jokes with slots (`{hazard}`, `{cargo}`, `{passenger}`) multiply the content without writing every line by hand.

### Purse and upgrades (deferred)
- Upgrades and purse sinks (boat upgrades, better cargo contracts, skipper unlocks) are to be designed later. Until then the purse is score and bragging rights.

### Technical prerequisites
- **Seedable RNG (do first):** replace the global `_rng` in `util.dart` with an injected, seedable generator. Needed for the daily river, reproducible bug reports and balance tests.
- **Run state in data:** keep `RunState` serializable so an interrupted run can resume (phones get killed).
- **Content stays JSON:** new files `events.json`, `relics.json`, `skippers.json`; map generation parameters in `config.json`.
- **Telemetry:** extend the existing reports to joke pick rate, win rate by skipper, and stretch lethality. Balance from numbers.

### Build phases and milestones
| Phase | Deliverable | Done when |
|-------|-------------|-----------|
| P0 | Seedable RNG | Same seed gives the same run; existing tests pass |
| P1 | Voice and material: spontaneous hand, voice drift, momentum, pivot, reactions, callbacks, bit maturity | Two runs with different voices play differently; a bombing voice can be ridden out or abandoned |
| P2 | River map + lying chart + event pool | No two runs have the same route; at least 10 events |
| P3 | Props/relics, skippers, passenger goals | 3 skippers, 12 relics, goals on every manifest |
| P4 | Saga: repeat passengers, persistent world, Nowhere outcomes | A returning player sees earlier runs referenced |
| P5 | Charter levels, daily river, joke templates | Daily seed works offline; levels 1–5 playable |

### Risks and non-goals
- **Scope:** P1 and P2 alone are a big step; ship them before adding P3+. Do not start P5 until P1–P3 feel good.
- **Writing load:** the deck needs 60+ jokes to feel fresh. Templates and variants (already supported) cut this.
- **Keep:** the engine, tone and JSON pipeline. **Do not:** rewrite the engine, add multiplayer, or require accounts.

### Decisions made
1. No deck screen; the deck develops over time and jokes are spontaneous during the cruise (System 1).
2. Room meter first, with visible reactions for a few notable individuals.
3. Upgrades and purse sinks come later.

---

## 5. Workstreams

### A. Product shell (must)
- [ ] Title / main menu with splash art as hero
- [ ] Continue / new run / settings / credits
- [ ] First-run onboarding (beats, silence, chart lies)
- [ ] Pause, confirm quit, soft fail states
- [ ] Portrait-first layout, safe areas, thumb-reach actions

### B. Presentation / Flame (biggest leap)
- [ ] Ribbon transit between beats + docked stage for bits
- [ ] Bobbing boat rig over place/landmark art
- [ ] Flutter HUD over Flame (gauges, log, bottom actions)
- [ ] Player-opened chart overlay (position, chart claims, annotations)
- [ ] Beat spend + joke landing feedback
- [ ] End-of-run comic recap (after settle)
- [ ] Art pipeline: boat, ribbon layers, stage landmarks, cargo, passengers, UI, chart sheet

### C. Feel / juice
- [ ] Haptics on crises, joke landings, salvage
- [ ] SFX + music stems (even temp early)
- [ ] Gauge danger readability; threat-clear celebration
- [ ] Touch targets; scroll vs gesture clarity
- [ ] Accessibility: text scale, reduce motion, colorblind-safe gauges

### D. Content depth
- [ ] More jokes, stretches, cargo, passengers
- [ ] Career arcs (Calliope stages, goose, leopard, salvage)
- [ ] Dormant JSON fields: implement callbacks, patience and fear threshold per §4A; cut `fatigue_runs` and any others §4A does not use
- [ ] Balance from telemetry, not vibes alone

### E. Meta / retention (mobile expectation)
- [ ] Light daily/weekly or season hook (optional, late)
- [ ] Collection: salvage jokes, chart annotations
- [ ] Achievements
- [ ] Cloud save later if needed
- [x] Monetization direction (agreed): **B + C**
  - **B:** ~2 free full runs, then paid unlock for unlimited career
  - **C:** optional ads only in safe seams (post-settle / back to office) — **not AdMob** (account closed); use another network later
  - Never interrupt mid-joke / mid-beat
  - Soft ask after settle; prefer unlocking career continuity over gutting shown content

### F. Store / shipping
- [x] Android upload keystore → `secrets/` + `android/key.properties` (gitignored)
- [ ] iOS signing, listings, screenshots, trailer
- [x] Sentry project `godspeed-ginny` (org `daddoo-dev`) — crashes, sessions, light traces
- [ ] Minimal product analytics beyond Sentry (optional later)
- [ ] Performance budget on mid-tier phones
- [ ] CI, release builds, QA checklist
- [x] Store listing copy + Fastlane upload lanes (`fastlane/metadata`, Bottled Star ASC + Play credentials under `secrets/`)
- [ ] Privacy policy page for Ginny support/marketing URLs if not live yet
- [ ] Screenshots / feature graphic

**Codemagic → Google Play:** reuse **Bottled Star**’s Play service-account JSON  
(`Documents/github/bottled_star/secrets/google/play-store.json`).  
Service account: `codemagic-play@bottled-star.iam.gserviceaccount.com`  
Invite that email on the Godspeed Ginny Play listing; do not invent a second JSON unless rotating keys.

### G. Live ops discipline
- [ ] Content versioning that doesn’t break careers
- [ ] Patch path for balance and copy
- [ ] Remote config only if clearly needed

---

## 6. Build order (solo-sane)

1. **Main menu + splash hero** — stop jumping into the office.
2. **Art bible + sprite list** for daughter (boat, ribbon layers, 6–8 stage landmarks, chart sheet, 4 cargo, UI chrome).
3. **Flame prototype** — ribbon → one docked hazard bit with HUD; chart overlay stub.
4. **Audio pass** (temp OK) — silence kills comedy games.
5. **Expand content** once the fantasy reads on a phone screenshot.
6. **Comic recap** after settle once stages exist.
7. **Store shell** when a ~5-minute demo looks intentional.

---

## 7. Art brief (daughter)

Deliverables, not vibes:

| Set | Examples |
|-----|----------|
| Boat | Ginny hull, stack steam, list/damage states (shared rig) |
| Ribbon | Reusable water/bank layers; simple transit |
| Stages | Cast-off, hippo, narrows, wreck, falls, ducks, Nowhere board |
| Chart | Survey sheet that looks authoritative and wrong; annotation space |
| Cargo | Ice, piano, leopard crate, mail |
| People | 3–5 passenger silhouettes / portraits |
| UI | Gauge frames, joke ticket, telegram, buttons/chips |
| Brand | Already have icon + splash; keep consistent palette |

Pipeline: named assets → `assets/art/` → Flame sprites / Flutter HUD. Prefer atlases and consistent silhouette scale.

---

## 8. Explicit non-goals (early)

- Full open-world river sim
- Multiplayer
- Heavy 3D
- Cabaret / showboat staging as the main fantasy
- Instrument-cluster / peephole as the main view
- Comic strip as the live play surface
- Engine rewrite
- Feature parity with every unused JSON field “just because”

---

## 9. Definition of done (milestones)

### M0 — Playable port (done)
Webpage loop in Flutter; content loads; icons/splash; placeholder Flame.

### M1 — Mobile shell
- [x] Title screen (splash hero)
- [x] Settings + credits
- [x] Resume / cast off into office (office not boot)
- [ ] First-run teach

### M2 — Graphical passage
Ribbon transit + at least one docked hazard bit with HUD; chart overlay openable; art for that node near-final.

### M3 — Demo vertical slice
5-minute run looks intentional on device: audio, juice, menu, comic recap stub, no debug chrome.

### M4 — Soft launch candidate
Content depth + balance pass, crash reporting, store assets, mid-phone performance.

### M5 — 1.0
Retention light-touch, polished career arcs, ship.

---

## 10. Working agreements

- Content stays JSON-driven; code does not hardcode the river.
- Styling stays in global theme / shared widgets — no one-off inline sprawl.
- Release/profile for player-facing runs; no debug banner / debug overlays in player builds.
- Prefer simple structures; split components when screens grow.
- Ask for missing art/copy rather than inventing placeholders as “final.”

---

## 11. Immediate next step

**Next:** finish M1 first-run teach if needed, then gameplay phases **P0 (seedable RNG) and P1 (voice and material)** from §4A, since the map, relics and saga all build on them. Art bible for M2 (ribbon + docked stage + chart sheet) and the Flame ribbon → docked hazard bit can run in parallel, because P0–P2 need no new art.
