# CLOUD / PROBE | World Visual Research (independent branch)

- Target: **Foundation v0.3** from `cp-base/cloud-probe/main`, fixed baseline commit `f612435b7aa1c05be607bdb975d123367eaa4819`.
- Branch: `research/visual-20261107`.
- Scope: rendering experiments only. No changes to `Main.tscn`, `ui/main.gd`, `visuals/light.gdshader`, gameplay, maps, saves, `index.html`, or `godot/`.
- All appearances are **research presets**, not approved art direction.

## Run against the real Foundation

Open `godot-foundation/project.godot` in Godot 4.7.2; open `res://research/visual/VisualExperiment.tscn`, then **F6** (play current scene), or from a shell:

```sh
godot --path godot-foundation --scene res://research/visual/VisualExperiment.tscn
```

This research scene subclasses `res://ui/main.gd`; it retains the original game and installs `visual_overlay.gd` after Foundation's `_ready`. In this scene only, `game.allow_save=false` prevents writing play progress. Existing saves might still be read on startup; use an isolated clone/worktree if preserving a separate play state matters.

The overlay provides **BASE** (original `visuals/light.gdshader`, restored on toggle), **CONTOUR** (silhouette-first), and **HAZE** (soft glowing material). Click the upper-right buttons, or use **V** to cycle and **P** for bursts. Existing W/S/A/D and other Foundation controls remain unchanged. During travel, new detections and collection effects can trigger bursts.

## Deterministic gallery (without game progression)

Open `res://research/visual/VisualGallery.tscn` with F6, or:

```sh
godot --path godot-foundation --scene res://research/visual/VisualGallery.tscn
```

The gallery uses Foundation's **unchanged** `visuals/light.gdshader` as BASE. It places 60 controlled markers at various distances, with red enemy-like shapes, cyan lights and amber facility-like signals. `V` cycles presets, `P` toggles effects, **Space** or `SIMULATE PICKUP BURST` plays particle + Tween effects, and W/S/A/D moves the camera. This is a visual test fixture **not the actual game's world generation**.

For reproducible captures, launch with user args after `--`:

```sh
godot --path godot-foundation --scene res://research/visual/VisualGallery.tscn -- --capture-dir=/absolute/writable/output
# add --stress to use 250 objects, not 60
```

The gallery automatically writes four images and mode-specific timing measurements, then exits. Never direct this capture option to shared project evidence when multiple researchers run simultaneously; use a private directory.

## Tests

```sh
godot --headless --path godot-foundation --script res://research/visual/tests/test_shader.gd
```

In the isolated research workspace, the unit/logic test passed and **real rendered** gallery screenshots were captured through Xvfb + Mesa llvmpipe. The full Foundation game scene was *not* executable locally because a complete repository clone could not be downloaded in the sandbox; the subclass parser was checked with a local-only stand-in for `ui/main.gd`. **Real Foundation integration remains to be checked before adoption**. See [`REPORT.md`](REPORT.md) and screenshots in [`evidence/`](evidence/).

## External references

- Godot spatial shader reference: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html
- Godot 3D particle system: https://docs.godotengine.org/en/stable/tutorials/3d/particles/creating_a_3d_particle_system.html
- Existing source: `godot-foundation/ui/main.gd` `_marker`, `_sync_markers`, `_visuals`; `visuals/light.gdshader`; `core/session.gd` effects; `tests/visual_fixture.gd`.
