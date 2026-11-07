# Combat Lab — Independent Godot Foundation v0.3 feature research

**Date:** 2026-11-07 JST. **Branch:** `research/combat`. **Baseline:** `main` commit `f612435b7aa1c05be607bdb975d123367eaa4819`. **Status:** natural-encounter second pass tested; **nothing adopted into main**.

## Purpose and source checks

Entrypoint: `Chappy.md`. Verified `godot-foundation/README.md`, `docs/godot-foundation/README.md`, the prototype guide, blueprint, build plan, validation summary, and the actual Foundation v0.3 implementation (`core/session.gd`, `core/world.gd`, `core/campaign.gd`, `core/storage.gd`, `data/*.tres`, `data/catalog.gd`, `ui/main.gd`, and baseline test scripts). Compared engine usage with the Godot official Resources, AnimationPlayer, Tween and CanvasLayer documentation.

Foundation already has four combat types independent of each enemy's wait/patrol behavior. It already handles auto-ranged/melee selection, common cooldown, projectiles, damage, defeat rewards, world depth, upgrade scaling, visual hits, active object streaming, and persistent session/world state. Those are **reused**, not reimplemented.

| Foundation enemy Resource | Baseline behavior and parameters | Research experiment |
| --- | --- | --- |
| melee / 近接型 | speed 4.8, HP 60, melee range 7, damage 14 | Show approach/range warning; AI unchanged |
| artillery / 砲撃型 | speed 2.4, HP 45, ranged 65, keep distance 26 | Distinguish enemy ranged threat from own weapon range; AI unchanged |
| fast / 高速型 | speed 9, HP 30, melee range 7 | Optional sideways movement, new profile speed 3.0 |
| heavy / 重装型 | speed 2.2, HP 140, ranged 35, interval 3.5 | Optional warning delay 1.1 s before attack |

The four baseline weapon Resources remain unchanged: standard/long cannon and standard/heavy melee. Experimental numbers and choices in this report are **not final combat rules**.

## Prototype implemented

- `CombatResearch.tscn` runs a research-only scene. `combat_main.gd` extends the **real** Foundation `ui/main.gd`. The scene keeps the native exploration, world graphics, maps, facilities, equipment, growth, save, and user-input handling.
- `combat_session.gd` extends the **real** `core/session.gd`; the experimental flag defaults OFF. For fast enemies it adjusts sideways movement before delegating to the original `_enemies(dt)`; for heavy enemies it delays a ready attack and exposes a `windup` indicator. Both types return to their base behavior when the flag is off. Follow-up research fixes a real travel-tick timing issue and now clears transient windup markers when disabling patterns or loading a save.
- `pattern_profile.gd` and two Resource files (`data/fast_pattern.tres` and `data/heavy_pattern.tres`) hold independent experimental tuning values. The existing enemy/weapon Resources remain authoritative for actual stats.
- `combat_readout.gd` computes read-only per-enemy distance, HP, type, wait/patrol status, reach, cooldown, and risk. It reads existing equipped weapon Resources and upgrade-adjusted stats. An incoming hostile shot increases **global** danger only: existing shot data cannot reliably identify which enemy fired.
- `combat_hud.gd` adds a CanvasLayer warning HUD showing the currently firing weapon, weapon ranges and damage, own attack cooldown, number of detected enemies, hostile shots, and closest enemies. It reuses `enemy_card.tscn` as a PackedScene for up to five enemy HP/range cards. `enemy_card.gd` demonstrates an AnimationPlayer warning pulse; the HUD uses a Tween to float and fade received-damage text.
- `--fixture` injects four enemy types at known nearby positions. This is a **visual test fixture**; it disables saving to protect normal progress. Without `--fixture`, the research scene uses the ordinary Foundation world and save. The enemy behavior toggle is interactive.

## Reproducible runs and evidence

Godot runtime: **4.7.2.stable.official.ed1daf0bf** on Linux. ChatGPT's isolated temporary workspace obtained the Godot binary from the user's Library and verified `--headless --version`. Local HTTPS `git clone` was not possible due to DNS isolation, so GitHub's connected API created the research branch and files. An **ephemeral GitHub Actions checkout dedicated to this branch** ran the complete original Foundation with the exact same Godot version, rather than using any investigator's PC/worktree.

The first-pass successful CI run was [GitHub Actions run #42288888905](https://github.com/cp-base/cloud-probe/actions/runs/42288888905). Direct logs are retained under `evidence/`, including editor import and all four test logs. The screenshot at `evidence/fixture.png` was captured from the actual Godot research scene with Xvfb/Mesa llvmpipe at **1180 × 760**. CI installed Noto CJK for correct Japanese glyphs; no font binaries are bundled into the repository.

| Check | Result | What was actually verified |
| --- | --- | --- |
| Godot import/parse | PASS | Scene and script parsing/import |
| Existing Foundation session tests | **42 / 42 PASS** | Exploration, world, auto-combat, upgrades, facilities, persistence, etc. |
| Existing Foundation UI tests | **6 / 6 PASS** | Native panels, navigation, map, persistence protection |
| New combat logic tests | **15 / 15 PASS** | Four profiles, range risks, auto-fire, weapon Resources, optional patterns, delay, OFF fallback, save/reload |
| New fixture UI tests | **8 / 8 PASS** | Research scene, no-save fixture, shared Session, four enemy instances/cards, pattern-button signals |
| GUI render/capture | **PASS** | Godot actually rendered `CombatResearch.tscn`, 1180×760 screenshot saved |

**First pass: 71 / 71 automated checks successful.** The screenshot and programmatic button signals establish integrated operation; they are not a human comprehension/playability study. The dense 4-enemy fixture is not representative of naturally generated encounter density.

Run from the checked-out `godot-foundation/` directory:

```sh
godot --path . res://research/combat/CombatResearch.tscn
godot --path . res://research/combat/CombatResearch.tscn -- --fixture
godot --headless --path . --script res://tests/test_combat_research.gd
godot --headless --path . --script res://tests/test_combat_ui.gd -- --fixture
```


## Second pass: naturally generated encounter and live combat timing (2026-11-07)

The first pass proved an injected four-enemy fixture. The second pass asks whether **actual Foundation travel** can approach naturally spawned enemies, fight with the existing weapon system, and expose optional heavy/fast behavior.

**Experimental extensions, isolated to this branch:**
- Added `--journey`: fresh deterministic campaign, ordinary `World.reset_sortie()` generated enemy and ordinary `Session.tick()` travel. No injected four-enemy fixture; saves intentionally disabled in this visual mode. Ordinary launch remains the unchanged normal save-based flow.
- Added autonomous steering via **test-only calls to `Session.tick(dt, forward, turn)`**. This simulates input/game logic, not actual human interactive play. Seed search found one naturally generated start encounter of each type, then tested experimental patterns both OFF and ON.
- HUD now starts compact in ordinary travel and expands into scrollable enemy cards using the `詳細` button. Four-enemy fixture stays expanded. Captured real Godot GUI with both presentation states at ~540p.
- **Important defect discovered:** an optional `CombatSession._enemies()` override passed the direct unit test, but the inherited Foundation `Session.tick()` did not invoke that override as originally expected. The real encounter timing check therefore caught a mismatch missed by first-pass fixture tests. Corrected by explicitly applying experimental patterns in the research `tick()` wrapper before `super.tick()`.
- **Additional edge case:** testing only the current distance and zero cooldown missed the frame in which the base tick moves an enemy into range or decrements its cooldown to zero. Corrected the warning trigger with a one-frame look-ahead, and added a regression test. Turning experiments OFF and loading an experimental mid-telegraph save now clear the transient `windup` flag; this is a research restore policy, not a settled production rule.

**Last verified CI:** [GitHub Actions #42295474200](https://github.com/cp-base/cloud-probe/actions/runs/42295474200), Godot **4.7.2** on a branch-only ephemeral Linux runner, **success**. Import, headless checks and graphical captures all succeeded.

| Verification | Checks | Result |
| --- | ---: | --- |
| Original Foundation session regression | 42 | PASS |
| Original Foundation UI regression | 6 | PASS |
| Combat research unit/integration | 19 | PASS |
| Fixture scene and toggles | 8 | PASS |
| 4 naturally generated start types × patterns OFF/ON (incl. timing/persistence) | 84 | PASS |
| Journey scene/UI, held move control, compact/expanded height | 9 | PASS |
| **Total** | **168** | **168 PASS / 0 FAIL** |
| Godot GUI captures | 1180×760, 838×540 compact & expanded | PASS |

**Normal starter-encounter sample, basic equipment, same auto-steering:** fixtures were *not* injected for these four trials. These numbers describe the particular seeds and driving strategy below, not general balance.

| Enemy type | Seed | OFF result | ON result |
| --- | ---: | --- | --- |
| melee | 71129 | Win; remaining player HP 3 / 45 | Win; HP 3 / 45 |
| artillery | 71130 | Win; HP 5 / 45 | Win; HP 5 / 45 |
| fast | 71127 | Win; HP 37 / 45 | Win; HP 37 / 45; slight positional deviation |
| heavy | 71131 | Loss; enemy HP 113 / 140 | Loss; enemy HP 104 / 140 |

Measured **heavy first hostile shot**: `21.05 s` with patterns OFF; `22.15 s` with patterns ON, a **1.10 s** delay. The ON trial recorded the warning condition for 44 physics steps. Both trials still ended in player defeat, so *a telegraph working* does not imply a balanced or fair encounter. The small fast-type sidestep was not sufficiently influential under this steering strategy to change the outcome.

**Reproduction from `godot-foundation/`:**

```sh
godot --path . res://research/combat/CombatResearch.tscn -- --journey
godot --path . res://research/combat/CombatResearch.tscn -- --journey --patterns
godot --headless --path . --script res://tests/test_combat_journey.gd
godot --headless --path . --script res://tests/test_combat_journey_ui.gd -- --journey
```

**Evidence:** `evidence/test_combat_journey.log`, `evidence/test_combat_research.log`, `evidence/test_combat_journey_ui.log`, `evidence/journey_540p.png`, `evidence/journey_detail_540p.png`, and `evidence/fixture.png` are retained in this research branch. GUI capture uses Xvfb/Mesa software rendering; the narrower internal width comes from the unchanged Godot viewport/stretch configuration. The CI had a temporary font-install stall; the branch-local workflow now has bounded installation times. That operational issue is separate from combat logic.

**Integration assessment:** the collapsible HUD can be ported with limited dependency changes; optional movement and telegraph timing need careful migration and tests against the production update loop. The strongest generalizable lesson from the follow-up is to test **real entry-point interactions and tick execution**, not only direct helper calls. No AI/balance rule or GUI layout has been proposed as a mandated game design.


## Third pass: opt-in automatic encounter / combat / route recovery (2026-11-07)

**Research hypothesis:** during the player's existing auto-forward exploration, a nearby enemy can be automatically acquired, confronted with the *unchanged* Foundation auto-weapon logic, and followed by resuming the previously held exploration heading. The experiment is not a new action-game dodge, mandatory navigation rule, or finished AI policy.

### Implementation isolated to research/combat

- `autopilot.gd`: state-machine `explore → battle → resume → explore`. Initial research constants (not final balancing): engagement within **78** units, drop target beyond **180** units, preferred ranged stand-off based on equipped weapon reach (capped at 36), hold still while turning toward target, and recover saved yaw after enemy defeat. These are provisional numbers for testability.
- `combat_session.gd`: when **both** the optional automatic-battle feature and existing auto-forward are enabled, delegates desired forward/turn to the state machine before the normal Foundation `tick()`. The existing damage, auto weapon selection, projectiles, drops, fuel and save rules are unchanged. Paused/docked/manual override cancels auto engagement.
- `combat_main.gd`: opt-in toggle **自動交戦：ON/OFF** (OFF by default). The existing **自動前進** UI is still the trigger; temporary manual steering/reversing overrides automatic battle. `--journey --autobattle --auto` is a deterministic no-save scene for instant repeatability.
- `combat_hud.gd`: labels the current state (探索 / 交戦 / 復帰), keeping the previous compact/details UI.

### Reproduced results on actual Foundation, not injected combat fixtures

A/B compared **unchanged straight auto-forward** (OFF) against the new **auto-forward with combat handover** (ON), using the same initial seeds, equipment and physics step. Normal chunk/start enemy generation and ordinary Session.tick() remain responsible for movement and attacking. Tests use scripted movement input, not a human play session.

| Start enemy | Seed | Straight auto-forward (OFF) | Auto-battle handover (ON) |
| --- | ---: | --- | --- |
| Fast | 71127 | Enemy defeated while cruising | Enemy defeated; **133 combat frames**; returned to original route and advanced at least 10 units |
| Melee | 71129 | Enemy defeated while cruising | Enemy defeated; **270 combat frames**; returned to route and advanced at least 10 units |
| Artillery | 71130 | **Enemy not defeated** in cruise run | **Enemy defeated**; **275 combat frames**; route-recovery phase observed; **later returned to station** |
| Heavy | 71131 | Enemy not defeated | Enemy not defeated; **200 combat frames**, player returned to station |

The baseline Fast/Melee victories are important: enemy AI may chase the explorer regardless of autopilot; this feature did **not** magically turn all missed enemies into wins. The Artillery trial is the clearest benefit of active acquisition and maintaining weapon range. The Heavy trial confirms that changing navigation cannot replace equipment/upgrade progression. Combat start and exit are functional; safety over long autonomous expeditions is **not** established.

### Validation

- Dedicated [successful GitHub Actions #42302688760](https://github.com/cp-base/cloud-probe/actions/runs/42302688760) ran **Godot 4.7.2** on the branch's ephemeral Linux checkout.
- Existing baseline and prior combat regression: **168/168 PASS**.
- New automatic-combat logic test `test_combat_autopilot.gd`: **36/36 PASS**, including eight real natural-cruise runs and artificial edge cases for cancellation, toggle-off, and target defeat.
- New scene/UI test `test_combat_autopilot_ui.gd`: **7/7 PASS**, including toggling and real auto-forward propagation.
- **Total: 211/211 passing checks.** Godot import and the 1180×760 automatic battle screenshot also succeeded.
- Branch evidence: `evidence/autobattle.png`, `evidence/test_combat_autopilot.log`, `evidence/test_combat_autopilot_ui.log`, `evidence/capture_autobattle.log`.

```sh
# Run standard research scene (optional toggle available; OFF by default)
godot --path . res://research/combat/CombatResearch.tscn

# Deterministic, no-save mode, auto-exploration and auto-battle both enabled
godot --path . res://research/combat/CombatResearch.tscn -- --journey --autobattle --auto

# Headless A/B and UI tests
godot --headless --path . --script res://tests/test_combat_autopilot.gd
godot --headless --path . --script res://tests/test_combat_autopilot_ui.gd -- --journey
```

### Limitations and next experiments (not decisions)

This is deliberately a **minimal** three-phase navigation state machine with no dodging, extra attacks, stamina modifiers, or forced player interaction. It currently tracks a single enemy, chooses it only in a circular vicinity, does not yet handle route waypoint recovery or groups, and does not automatically retreat on low HP/fuel. `resume` restores **heading**, not an exact plotted route; stopping and turning costs time/fuel. The game's built-in **自動前進** was inherited unchanged. Thresholds are test scaffolding, not established balance or a compulsory feature.

A later experiment could add an automatic *battle-end policy* (continue / retreat / reserve fuel) and test navigation between waypoints rather than headings. Need test UI at different window sizes before considering integration. Crucially **no changes were made to `main`, existing Foundation `core/`/`ui/` or shared decision documents**.


## Fourth pass: three independent movement policies, automatic weapons always ON (2026-11-07)

### User intent and scope

Player feedback from the opt-in automatic battle test: an unattended automatic encounter that ends in defeat can be an enjoyable exploration outcome; avoiding fights by passing through enemies can also be the right strategy. The central request is **movement choice**, not an attack-enable toggle. For this research, the existing Foundation weapon system remains entirely automatic in all three modes:

| Choice shown in Combat Lab | Movement control | What happens to automatic weapons |
| --- | --- | --- |
| **移動：手動航行** / manual | Direct input controls forward, reverse and heading | Existing automatic ranged/melee attacks still fire |
| **移動：自動航行** / cruise | Existing straight auto-forward, no enemy-specific pursuit | Same automatic attacks against foes in range; enemies may fight back |
| **移動：自動戦闘** / battle | Auto-forward plus the earlier 78-unit enemy acquisition, facing/weapon-range pursuit, and resume-heading after victory | Same automatic attacks; no new damage or target-attack logic |

These are **three movement policies, not three weapon modes**. They are an explicit selector in the research scene; the original dual `自動前進` and `自動交戦` controls are not shown in this isolated scene. The inherited Foundation auto-forward button and game control remain intact in source, with the new selector synchronizing their existing state. This is a prototype, not a main-branch rule.

### Code and execution

- `combat_main.gd`: exposes one OptionButton selector `manual/cruise/battle`. Mode switching updates existing `auto_forward` and optional `auto_battle_enabled` inputs. Reverse/stop/modal interruption resets the research selection to manual. Temporary manual steering overrides combat pursuit while the key is held; it does not alter firing.
- `combat_session.gd`, `autopilot.gd` and the original Foundation `_attack()` **need no edits** for this pass. In particular, no false requirement to add attack ON/OFF, projectile suppression, attack cooldown changes or new damage formulas.
- The selector and optional enemy-pattern experiment are stacked at x=380, y=146 and y=195, away from the inherited top buttons, combat readout and the 838-wide compact minimap; layout was inspected in actual Godot Xvfb screenshot.
- `--journey --auto` opens automatic cruise in the standard deterministic seed without save; `--journey --autobattle` starts automatic combat movement. Normal Combat Lab starts manual with automatic weapons retained.
- The automatic-combat controller itself still has **three internal phases** `explore/battle/resume` while the **player-facing selector** has `manual/cruise/battle`. These should not be conflated.

### Measured validation

[Dedicated GitHub Actions #42351783428](https://github.com/cp-base/cloud-probe/actions/runs/42351783428) **succeeded** on Godot 4.7.2 after UI clearance adjustment. The earlier first implementation CI [#42351587934](https://github.com/cp-base/cloud-probe/actions/runs/42351587934) also passed, but its screenshot showed controls overlapping the inherited top row; fixed in follow-up.

| Test | Checks | Result |
| --- | ---: | --- |
| Foundation original session | 42 | PASS |
| Foundation original UI | 6 | PASS |
| Previous combat logic | 19 | PASS |
| Previous natural encounter journey | 84 | PASS |
| Previous automatic encounter A/B | 36 | PASS |
| **Three-mode attack/movement logic**, `test_combat_movement_modes.gd` | **13** | **PASS** |
| Combat fixture UI | 8 | PASS |
| Natural journey UI | 9 | PASS |
| **Three-mode selector UI**, `test_combat_autopilot_ui.gd` | **19** | **PASS** |
| **Total** | **236** | **PASS** |

The new attack test built an ordinary Foundation Session with an enemy 27 units ahead, ran physics through `tick()` and confirmed **one ordinary ranged shot in each of manual, cruise and battle**. Capturing an offset enemy changed heading only in battle mode; ordinary cruise did not acquire a target. The UI test switched manual → cruise → battle, entered a natural generated battle, switched battle → cruise (target released), switched cruise → battle (target reacquired), then switched battle → manual and also tested the inherited stop/reset path. The no-save protection remained effective.

The previous natural-encounter A/B with four starter enemies remains relevant but **does not imply safety or universal win rates**: straight cruise defeated fast/melee while artillery was passed; battle pursuit defeated fast/melee/artillery and returned to travel after victory, but an unupgraded player still lost to heavy. It is intentional that **automatic combat may lose**.

Godot import and the GUI fixture, journey (actual 838×540), expanded HUD and 1180×760 battle screenshots all succeeded. The `evidence/autobattle.png` file in this branch shows the new selector visibly separate from other controls. The ephemeral Linux GUI runner had no physical audio device; it used Godot's dummy audio backend without affecting visual/test results. This is automated GUI inspection, **not** a claim of human playtesting.

### Remaining questions (not new rules)

- In this prototype, selecting cruise **during** an ongoing battle cancels target tracking immediately and continues from the **current** yaw. A normal successful battle still restores pre-fight heading. Whether manual cancellation should restore a saved route is a separate design decision.
- Manual steering while auto-forward is enabled temporarily overrides target pursuit rather than fully selecting manual; back/stop selects manual. Further usability feedback can guide whether left/right steering should also cancel cruise.
- Target acquisition is a short-radius single-target heuristic, not a route/path planner. Encountering multiple enemies, weak equipment, fuel constraints, and defeat still have the prior trial's limitations.
- Foundation's existing automatic weapon firing picks a nearby target whenever it enters weapon range, regardless of chosen movement mode. **Auto cruise is not invulnerability, pacifism, or guaranteed bypass.**
- No new forced retreat, safety logic, or compulsory automatic combat behavior was introduced; no decision was written to shared governance documents.

## How to add enemy and weapon types later

1. For a **new enemy**, add a `ProbeEnemyProfile` `.tres` to `data/`, register it in `data/catalog.gd`, add a type selection policy to `core/world.gd`, then verify `Session._enemies`, visuals/shapes and tests. Currently `world.gd` chooses among exactly 4 entries with `randi_range(0,3)`: simply adding a fifth Resource would not spawn it without changing selection logic. New movement patterns should be considered separately from combat stats.
2. For a **new weapon**, add a `ProbeWeaponProfile` `.tres`, register it in the catalog, ensure it has a supported ranged/melee slot, and verify pricing, equipment selection, automatic switching and persistence. Since the campaign keeps weapon IDs, existing saved IDs must remain valid.
3. For a **new warning presentation**, adjust pure `combat_readout.gd` first, add cards/presentation to `combat_hud.gd`, and add tests that verify per-enemy danger values separately from rendered output. Keep runtime HP and timer state in world/session dictionaries, **not** the shared Resource.

## Integration impact and costs

**Low complexity:** adopt only the reusable CanvasLayer HUD and enemy-card scene, instantiated from the existing `ui/main.gd` with its existing Session. No state schema change; adjust layout for different viewports.

**Medium complexity:** calibrate threat classification, longer-distance artillery warnings, multiple foes, HUD location and font size for normal play. Investigate external asset scene editing vs script construction and refine AnimationPlayer/Tween use. Resource + PackedScene separation reduces duplicated UI work as the number of types grows.

**Higher complexity:** adopt new fast/heavy movement/telegraphing. This changes player difficulty and enemy state; it requires new balance tests, enemy spawning tests, save compatibility (including mid-windup restore), and deliberation about experimental state keys. No such production decision was made in this study.

## Problems, limitations, and follow-up candidates

- Godot ran headlessly and with an Xvfb GUI; human manual movement and perception testing was **not performed**.
- Current warning is an approximation from ranges, cooldown and projectiles; it does not forecast every hit. Incoming projectiles are a **global** caution because base shot metadata does not identify their origin enemy.
- A `windup` entry is saved with experimental world state. The research `CombatSession` now clears it when disabling patterns and on successful load; before integration, the team should still decide whether a mid-windup save ought to resume the warning instead of clearing it.
- The HUD may cover floating labels when enemies appear behind its panel. The second pass added a collapsible/scrollable view and recorded both 1180×760 and an actual 838×540 viewport (requested as 960×540 due stretch settings). Visual reading tests with human players remain outstanding.
- Danger thresholds and the numbers in the two experimental `.tres` have not been play-balanced; `--fixture` positions are controlled/injected.
- The present warning animation is coded into an AnimationPlayer at runtime; an authored animation in `.tscn` may be easier for artists, whereas Tween is concise for one-shot hit numbers.
- Future tests: actual physical human pointer/key play, close-range repeated attacks, hostile projectile attribution, viewport scaling across more sizes, deterministic restored-windup policy, and player usability study.

## Exact change boundary

**Added under this branch only:** `godot-foundation/research/combat/` (research scene, scripts, Resources, README, report and evidence); `godot-foundation/tests/test_combat_research.gd`; `godot-foundation/tests/test_combat_ui.gd`; `godot-foundation/tests/test_combat_journey.gd`; `godot-foundation/tests/test_combat_journey_ui.gd`; `.github/workflows/combat-research.yml`.

**Not changed:** `main`, `index.html`, old `godot/`, original Foundation `Main.tscn`, `project.godot`, `core/`, `ui/`, `data/`, shared `STATUS.md`, `DECISIONS.md`, or `HISTORY.md`. No merge or production adoption has been performed.
