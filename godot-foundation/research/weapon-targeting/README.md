# Weapon Targeting Lab — isolated prototype

Branch: `research/weapon-targeting`. Forked from `main`. No changes to Foundation's original `core/session.gd`, `data/*.tres`, UI, world generation, or original combat research branch.

## Research question

Compare two lightweight weapon patterns **without inventing tactical AI**:

- `single`: current Foundation attack (nearest enemy; melee priority; one homing ranged shot).
- `area`: one ranged projectile, then damage every live enemy within 14 world units of its **actual impact target**. Shot travels using Foundation-compatible homing and range rules.
- `multi`: one firing event sends ordinary Foundation-style homing shots to up to 3 live, distinct enemies within weapon reach (primary nearest enemy first, then the nearest remaining). One shared cooldown.

Both prototype patterns reuse `Catalog.weapon()`, `weapon_reach()`, `weapon_damage()`, `fire()`, `damage_enemy()` and Foundation single-shot projectile processing. Close-range melee always retains priority. The two patterns only affect ranged weapons for this experiment.

They do **not** implement improved aim, cluster optimization, independently cycling weapon cooldowns, changes to enemy AI, altered procedural spawn density, or production balance.

## Run

```sh
godot --headless --editor --path godot-foundation --import --quit
godot --headless --path godot-foundation --script res://tests/test_weapon_targeting.gd
```

Run the existing `test_session.gd` regression separately. The tests construct deterministic enemy positions and **execute real Godot Foundation session methods**, not a browser-only numerical approximation.

## What the test establishes

Same 4-target cluster: baseline 1 hit, splash 3 hits, multi 3 hits. Spread targets: splash 1 hit, multi 3 hits. No optimization required. Existing shared firing cooldown unchanged. Separate tests cover melee-first selection, range, dead targets, no repeated firing during cooldown, and projectile cleanup.

Current implementation limitation: the experimental subclass is test-accessible, not connected to `Main.tscn` or a player equipment menu. Multi-shot fires 3 full-strength shots on one cooldown (balance not studied); splash explosion centered at the homing target's current position, not an independently simulated impact obstacle. This is a **mechanical feasibility study**, not a merged feature.

## Verified outcome

Godot 4.7.2 isolated CI [#42369253194](https://github.com/cp-base/cloud-probe/actions/runs/42369253194): **24/24 new targeting checks and 42/42 original Foundation checks PASS**. See [REPORT.md](REPORT.md) for results, initial radius-boundary fixture issue, and limitations.
