# CLOUD / PROBE | World visual research: report

**Date:** 2026-11-07 JST  
**Source:** `main` at `f612435b7aa1c05be607bdb975d123367eaa4819`  
**Dedicated branch:** `research/visual-20261107`  
**Status:** independent visual prototype working in the test gallery; full Foundation integration pending actual game-scene run.

## 1. Base and objective

Foundation v0.3 runs a camera at Y=0 with floating objects represented as billboard QuadMesh nodes. `ui/main.gd` instantiates `ShaderMaterial` using `visuals/light.gdshader`, synchronizes markers within ~600 units and renders auto-collection effects through expanded quads. Active objects (enemy/light/signal) and world/facility state are owned by `core/session.gd`/`core/world.gd`. Baseline shader already uses `unshaded`, `blend_add` and ALBEDO; it is **not** being replaced in the main project.

Goal: prototype stronger signal illumination, distance-dependent reveal, collection/discovery feedback, enemy recognition and measure cost without assuming a final world style.

## 2. Three styles and actual visual comparison

| Style | Implementation | Evaluation in 60-object controlled gallery |
| --- | --- | --- |
| BASE | Unmodified `visuals/light.gdshader`; original node scale/material | Soft cyan lights, red enemy silhouettes, weaker persistent outline on non-enemies |
| CONTOUR | `visual_signal.gdshader` style 0, distinct ring/triangle/square/diamond, core, distance-based scaling | Enemy silhouettes and outer boundary clearly identifiable; dense clusters can overlap |
| HAZE | style 1, procedural noise, drifting filaments, closer = sharper outline | More atmospheric luminous matter; higher light coverage can compete with enemy accents |

For visual readability, base vs new styles changed **11.40%** of screen-region pixels for CONTOUR and **9.38%** for HAZE using RGB threshold 18, crop x=100..1080/y=260..540. The count of vividly colored pixels in that crop grew from **15,202** BASE to **20,811** CONTOUR and **24,147** HAZE. These are objective screenshot metrics, **not a human readability score**. Eyeballing the screenshots supports better category distinction in CONTOUR; HAZE trades some shape clarity for atmosphere.

`proximity` is set per marker from world distance (smooth transition 24..170); distant markers get a modest scale floor. This affects **only visuals**, not game sensing, hit radius or resource amounts. Facility marker hue is refreshed if built-state changes.

## 3. Motion, discovery and recovery effects

- Shader `TIME` drives subtle pulse, noise drift and ring oscillation; no extra textures.
- `CPUParticles3D` produces 14 short-lived particles per burst; up to 12 concurrent burst emitters.
- A short `Tween` scales and fades a billboard scan-ring alongside each burst.
- Detection triggers once on entering `sense()` for unseen non-enemy objects. The existing `game.effects` triggers collection/combat feedback; duplicate effects at identical kind/coordinate/sortie are coalesced for this prototype.
- The first rendered version exposed a real bug: emitter `emitting=true` at node insertion emitted particles before positioning, filling the camera. Corrected by setting `emitting=false` **before** adding it, setting its world position, then `restart()` and `emitting=true`. Before/after captures were inspected locally; only corrected screenshots appear in final evidence.

## 4. Runtime and tests (measured)

**Environment:** Linux x86_64 workspace, library-provided Godot **4.7.2 stable**. Xvfb display 1280×800×24. Requested `mobile` renderer but Vulkan surface extension unavailable; Godot **fell back to OpenGL Compatibility**, Mesa **llvmpipe** software adapter. This is not the Windows GPU result, and the renderer mismatch matters.

- Headless GDScript test `tests/test_shader.gd`: **PASS, 0 failures**, 60 generated markers, shader parameters, mode transition, original-material restoration, CPU particle instantiation.
- Visual gallery GUI: **8 final PNG captures**, all 1180×760, four styles/events × two fixture sizes. Shader compiled; no runtime script/shader error was reported during final capture.
- Local-only Foundation subclass parser smoke test: `VisualExperiment.tscn` launched using a **temporary gallery-based `ui/main.gd` stand-in**, then removed from deliverables; it is not proof of full-game integration.
- No modifications to core simulation, world generation, save schema, the base shader, global `STATUS.md`, `DECISIONS.md`, or `HISTORY.md`.

### Mean overlay-update CPU cost (not GPU time)

| Fixture | BASE | CONTOUR | HAZE |
| --- | ---: | ---: | ---: |
| 60 visual markers | **0.0532 ms** | **0.3625 ms** | **0.3220 ms** |
| 250 visual markers | **0.1597 ms** | **1.2621 ms** | **1.2331 ms** |

Raw period-based observed FPS, 60: 136/154/153; 250: 118/110/107 (BASE/CONTOUR/HAZE). The FPS observations are *sequential time slices in a software renderer*, so they should **not** be interpreted as controlled GPU performance or a guaranteed improvement/slowdown. The CPU update cost measures script time only. The extra frame cost at 250 markers argues for fewer per-frame `set_shader_parameter` operations or MultiMesh batching when scale increases.

### Evidence

- `evidence/01-base-60.jpg` through `04-burst-60.jpg`: same camera/settings fixture; basis for visual comparison.
- `evidence/02-contour-250.jpg`, `evidence/03-haze-250.jpg`: visual-density stress samples.
- Full-resolution PNGs (1180×760), complete run logs and numerical metrics are included in the accompanying workspace ZIP.

## 5. Files and integration impact

| New branch file | Role |
| --- | --- |
| `visual_signal.gdshader` | Additive, unshaded animated contour/haze options; compatible color/kind/uniforms |
| `visual_overlay.gd` | Material swap/cache/restore, proximity scaling, scene HUD, CPU particles, Tween ring, simple CPU timing |
| `visual_experiment.gd` + `VisualExperiment.tscn` | Research-only subclass that launches original Foundation scene behavior with overlay, and disables writes to game progress |
| `gallery.gd` + `VisualGallery.tscn` | Standalone visual fixture; cycles styles and captures screenshots/stress data |
| `tests/test_shader.gd` | Headless mode/restore/particle tests |
| `README.md`, `REPORT.md`, `evidence/` | Reproduction instructions, findings and screen records |

**Adoption complexity:** low-to-medium for a selectable prototype (separate scene; no data migration or new plugin); medium for real-game performance polish and final UI/art integration. Recommended next step: launch `VisualExperiment.tscn` against the full Foundation on Windows Vulkan Mobile, check saved-state protection, live collection, all enemy types, modal/map overlap, and compare GPU frame-time + occlusion on the target phone/PC. A visual preset should be selected *only after* that test and a side-by-side user review.

## 6. Open issues and candidate experiments

- No direct full Foundation scene execution locally because Git checkout was blocked by network/DNS; source and docs were reviewed through the GitHub connector, and test gallery is real Godot. This limitation must not be disguised as a full integration pass.
- Software rasterization / Compatibility fallback differs from the intended Mobile renderer. Glow and particle behavior may look different on the final renderer and device.
- At 250 markers per-frame update overhead becomes material; optimize with thresholds, update throttling, `MultiMeshInstance3D`, LOD and profiling.
- HAZE saturation, additive overlap and fast enemy recognition need playtesting. The `seen_objects` set is capped and may replay discovery bursts in very long sessions.
- The subclass disables saves only after its parent's `_ready`; the Foundation loader may read a preexisting save. Keep this test in a separate worktree and do not merge as-is without deciding the correct save isolation behavior.
- Alternatives for later comparison: additive vs alpha blending, screen-space outline, occlusion-aware distance colors, GPU particles vs CPU, Tween ring alone on low-end devices, sprite- or SDF-based icon variants.

## 7. Reference material

- Existing `godot-foundation/README.md`, `ui/main.gd`, `visuals/light.gdshader`, `core/session.gd`, `core/world.gd`, `tests/visual_fixture.gd`, `docs/godot-foundation/cloud-probe-validation.md` at source commit.
- Godot spatial shader specification: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html
- Godot 3D particle creation: https://docs.godotengine.org/en/stable/tutorials/3d/particles/creating_a_3d_particle_system.html

**This report describes a tested research implementation, not an approved production design.**
