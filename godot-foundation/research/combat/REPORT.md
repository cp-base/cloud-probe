# Combat Lab — Independent Godot Foundation v0.3 feature research

**Date:** 2026-11-07 JST. **Branch:** `research/combat`. **Baseline:** `main` commit `f612435b7aa1c05be607bdb975d123367eaa4819`. **Status:** working research prototype and tests complete; **nothing adopted into main**.

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
- `combat_session.gd` extends the **real** `core/session.gd`; the experimental flag defaults OFF. For fast enemies it adjusts sideways movement before delegating to the original `_enemies(dt)`; for heavy enemies it delays a ready attack and exposes a `windup` indicator. Both types return to their base behavior when the flag is off, except that an already-set experimental windup marker is not automatically cleared.
- `pattern_profile.gd` and two Resource files (`data/fast_pattern.tres` and `data/heavy_pattern.tres`) hold independent experimental tuning values. The existing enemy/weapon Resources remain authoritative for actual stats.
- `combat_readout.gd` computes read-only per-enemy distance, HP, type, wait/patrol status, reach, cooldown, and risk. It reads existing equipped weapon Resources and upgrade-adjusted stats. An incoming hostile shot increases **global** danger only: existing shot data cannot reliably identify which enemy fired.
- `combat_hud.gd` adds a CanvasLayer warning HUD showing the currently firing weapon, weapon ranges and damage, own attack cooldown, number of detected enemies, hostile shots, and closest enemies. It reuses `enemy_card.tscn` as a PackedScene for up to five enemy HP/range cards. `enemy_card.gd` demonstrates an AnimationPlayer warning pulse; the HUD uses a Tween to float and fade received-damage text.
- `--fixture` injects four enemy types at known nearby positions. This is a **visual test fixture**; it disables saving to protect normal progress. Without `--fixture`, the research scene uses the ordinary Foundation world and save. The enemy behavior toggle is interactive.

## Reproducible runs and evidence

Godot runtime: **4.7.2.stable.official.ed1daf0bf** on Linux. ChatGPT's isolated temporary workspace obtained the Godot binary from the user's Library and verified `--headless --version`. Local HTTPS `git clone` was not possible due to DNS isolation, so GitHub's connected API created the research branch and files. An **ephemeral GitHub Actions checkout dedicated to this branch** ran the complete original Foundation with the exact same Godot version, rather than using any investigator's PC/worktree.

The final successful CI run is [GitHub Actions run #42288888905](https://github.com/cp-base/cloud-probe/actions/runs/42288888905). Direct logs are retained under `evidence/`, including editor import and all four test logs. The screenshot at `evidence/fixture.png` was captured from the actual Godot research scene with Xvfb/Mesa llvmpipe at **1180 × 760**. CI installed Noto CJK for correct Japanese glyphs; no font binaries are bundled into the repository.

| Check | Result | What was actually verified |
| --- | --- | --- |
| Godot import/parse | PASS | Scene and script parsing/import |
| Existing Foundation session tests | **42 / 42 PASS** | Exploration, world, auto-combat, upgrades, facilities, persistence, etc. |
| Existing Foundation UI tests | **6 / 6 PASS** | Native panels, navigation, map, persistence protection |
| New combat logic tests | **15 / 15 PASS** | Four profiles, range risks, auto-fire, weapon Resources, optional patterns, delay, OFF fallback, save/reload |
| New fixture UI tests | **8 / 8 PASS** | Research scene, no-save fixture, shared Session, four enemy instances/cards, pattern-button signals |
| GUI render/capture | **PASS** | Godot actually rendered `CombatResearch.tscn`, 1180×760 screenshot saved |

**Total: 71 / 71 automated checks successful.** The screenshot and programmatic button signals establish integrated operation; they are not a human comprehension/playability study. The dense 4-enemy fixture is not representative of naturally generated encounter density.

Run from the checked-out `godot-foundation/` directory:

```sh
godot --path . res://research/combat/CombatResearch.tscn
godot --path . res://research/combat/CombatResearch.tscn -- --fixture
godot --headless --path . --script res://tests/test_combat_research.gd
godot --headless --path . --script res://tests/test_combat_ui.gd -- --fixture
```

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
- A `windup` entry created under experimental behavior may remain in a saved world when that experiment is subsequently disabled; baseline code ignores it but a formal save contract would be necessary before merging AI changes.
- The HUD covers some floating labels when enemies appear behind its translucent panel. It does not remove the map, but 1180×760 is the only captured resolution. Compare smaller windows and real encounter density.
- Danger thresholds and the numbers in the two experimental `.tres` have not been play-balanced; `--fixture` positions are controlled/injected.
- The present warning animation is coded into an AnimationPlayer at runtime; an authored animation in `.tscn` may be easier for artists, whereas Tween is concise for one-shot hit numbers.
- Future tests: actual pointer/key input, close-range repeated attacks, hostile projectile attribution, viewport scaling, reload during windup, and player usability study.

## Exact change boundary

**Added under this branch only:** `godot-foundation/research/combat/` (research scene, scripts, Resources, README, report and evidence); `godot-foundation/tests/test_combat_research.gd`; `godot-foundation/tests/test_combat_ui.gd`; `.github/workflows/combat-research.yml`.

**Not changed:** `main`, `index.html`, old `godot/`, original Foundation `Main.tscn`, `project.godot`, `core/`, `ui/`, `data/`, shared `STATUS.md`, `DECISIONS.md`, or `HISTORY.md`. No merge or production adoption has been performed.
