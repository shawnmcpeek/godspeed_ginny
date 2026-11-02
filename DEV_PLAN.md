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
- [ ] Decide: implement dormant JSON fields (callbacks, patience, chart ratings) **or** cut them from data
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
- [ ] Crash reporting (e.g. Sentry); minimal analytics
- [ ] Performance budget on mid-tier phones
- [ ] CI, release builds, QA checklist
- [ ] Privacy policy / store compliance

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

**Next:** finish M1 first-run teach if needed, then **art bible for M2** (ribbon + docked stage + chart sheet) and Flame ribbon → docked hazard bit.
