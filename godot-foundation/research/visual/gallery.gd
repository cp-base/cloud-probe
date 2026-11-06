extends Node3D
## Deterministic, directly playable visual comparison fixture.
## No campaign, save file, or external asset. Can also run inside Foundation.
const BaselineShader = preload("res://visuals/light.gdshader")
const Overlay = preload("res://research/visual/visual_overlay.gd")

class FakeWorld extends RefCounted:
    var objects: Dictionary = {}
class FakeCampaign extends RefCounted:
    var sortie_sequence: int = 1
class FakeGame extends RefCounted:
    var world := FakeWorld.new()
    var campaign := FakeCampaign.new()
    var effects: Array[Dictionary] = []
    var allow_save: bool = true
    func active_objects(_radius: float = 1000.0) -> Array[Dictionary]:
        var result: Array[Dictionary] = []
        for object: Dictionary in world.objects.values():
            if object["alive"]:
                result.append(object)
        return result
    func sense() -> float:
        return 120.0

var game: RefCounted = FakeGame.new()
var camera: Camera3D
var markers: Dictionary = {}
var overlay: Node3D
var items: int = 60
var frame_index: int = 0
var stats: Dictionary = {0:[], 1:[], 2:[]}
var capture_dir: String = ""
var auto_capture: bool = false
var stress: bool = false
var info: Label
var static_only: bool = false

func _ready() -> void:
    for arg: String in OS.get_cmdline_user_args():
        if arg.begins_with("--capture-dir="):
            capture_dir = arg.substr(14)
            auto_capture = true
        elif arg == "--stress":
            stress = true
        elif arg == "--static":
            static_only = true
    if stress:
        items = 250
    _world()
    _make_objects()
    overlay = Overlay.new()
    add_child(overlay)
    overlay.install(self)
    overlay.set_mode(0)
    _control_ui()
    print("VISUAL_GALLERY_READY items=%d mode=BASE renderer=%s adapter=%s" % [items, str(ProjectSettings.get_setting("rendering/renderer/rendering_method")), RenderingServer.get_video_adapter_name()])

func _world() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("081823")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)
    camera = Camera3D.new()
    camera.fov = 76.0
    camera.far = 900.0
    camera.position = Vector3.ZERO
    camera.current = true
    add_child(camera)

func _make_objects() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 73021
    for i in range(items):
        var hostile: bool = i % 4 == 0
        var special: bool = i % 9 == 3
        var color: Color = Color("ff6485") if hostile else (Color("ffcc83") if special else Color("66e6ed"))
        var pos := Vector2(0.0, 0.0)
        if not stress:
            var row: int = i / 12
            var col: int = i % 12
            pos = Vector2((col - 5.5) * (5.2 + row * 2.4), -(37 + row * 24))
        else:
            pos = Vector2(rng.randf_range(-110, 110), rng.randf_range(-25, -580))
        var key := "fixture-%03d" % i
        game.world.objects[key] = {"id":key, "pos":pos, "kind":"enemy" if hostile else ("signal" if special else "light"), "alive":true}
        var marker := MeshInstance3D.new()
        var quad := QuadMesh.new()
        quad.size = Vector2(8.0 if hostile else 6.0, 8.0 if hostile else 6.0)
        marker.mesh = quad
        marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        var material := ShaderMaterial.new()
        material.shader = BaselineShader
        material.set_shader_parameter("signal_color", color)
        material.set_shader_parameter("appearance", 1 if hostile or special else 2)
        material.set_shader_parameter("kind", (i / 4) % 4 if hostile else 3)
        material.set_shader_parameter("phase", rng.randf_range(0.0, 6.283))
        marker.material_override = material
        marker.position = Vector3(pos.x, sin(float(i)*2.1)*1.8, pos.y)
        add_child(marker)
        markers[key] = marker

func _control_ui() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 26
    add_child(layer)
    var text_box := VBoxContainer.new()
    text_box.position = Vector2(25, 22)
    layer.add_child(text_box)
    info = Label.new()
    info.add_theme_font_size_override("font_size", 23)
    info.add_theme_color_override("font_color", Color("d4ecf2"))
    info.text = "CLOUD / PROBE  —  Visual Gallery"
    text_box.add_child(info)
    var subtitle := Label.new()
    subtitle.text = "Cyan: signal    Red: enemy    Amber: facility-like marker  |  V: style / P: particles / Space: burst"
    subtitle.add_theme_color_override("font_color", Color("9bc1cb"))
    text_box.add_child(subtitle)
    var notes := Label.new()
    notes.text = "Near to far: 37 / 61 / 85 / 109 / 133 units   •   W/S/A/D: camera position   •   comparison fixture, not gameplay"
    notes.add_theme_color_override("font_color", Color("9bc1cb"))
    text_box.add_child(notes)
    var bottom := Button.new()
    bottom.text = "SIMULATE PICKUP BURST"
    bottom.position = Vector2(24, 687)
    bottom.custom_minimum_size = Vector2(230, 45)
    bottom.pressed.connect(_pickup)
    layer.add_child(bottom)

func _pickup() -> void:
    if overlay.mode == 0:
        overlay.set_mode(1)
    overlay.burst(Vector3(0.0, 0.0, -28.0), Color("90ffe0"), 2.5)
    print("VISUAL_BURST_CLICK fired=%d" % overlay.burst_count)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_V: overlay.next_mode()
            KEY_P: overlay.toggle_bursts()
            KEY_SPACE: _pickup()

func _process(delta: float) -> void:
    frame_index += 1
    if not static_only:
        var speed := delta * 14.0
        if Input.is_key_pressed(KEY_W): camera.position.z -= speed
        if Input.is_key_pressed(KEY_S): camera.position.z += speed
        if Input.is_key_pressed(KEY_A): camera.position.x -= speed
        if Input.is_key_pressed(KEY_D): camera.position.x += speed
    for marker: MeshInstance3D in markers.values():
        if marker.global_position.distance_squared_to(camera.global_position) > 0.01:
            marker.look_at(camera.global_position, Vector3.UP, true)
    if overlay == null: return
    overlay.sync(self, delta)
    stats[overlay.mode].append({"delta": delta, "update_ms":overlay.marker_cost_ms})
    if auto_capture:
        if frame_index == 85:
            _capture("01-base")
        if frame_index == 105:
            overlay.set_mode(1)
        if frame_index == 205:
            _capture("02-contour")
        if frame_index == 225:
            overlay.set_mode(2)
        if frame_index == 325:
            _capture("03-haze")
        if frame_index == 345:
            overlay.burst(Vector3(0,0,-28), Color("90ffe0"), 2.5)
            pass
        if frame_index == 356:
            _capture("04-burst")
        if frame_index == 395:
            _write_stats()
            get_tree().quit(0)

func _capture(name_value: String) -> void:
    var path := capture_dir.path_join(name_value + ("-250" if stress else "-60") + ".png")
    _capture_next_frame(path)

func _capture_next_frame(path: String) -> void:
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    var err := image.save_png(path)
    print("VISUAL_CAPTURE %s err=%d size=%dx%d" % [path, err, image.get_width(), image.get_height()])

func _write_stats() -> void:
    for mode_key: int in stats.keys():
        var count: int = stats[mode_key].size()
        var delta_total: float = 0.0
        var update_total: float = 0.0
        for measurement: Dictionary in stats[mode_key]:
            delta_total += measurement["delta"]
            update_total += measurement["update_ms"]
        var mean_ms: float = 0 if count == 0 else update_total / count
        var frame_fps: float = 0 if delta_total <= 0 else count / delta_total
        print("VISUAL_BENCH mode=%d items=%d frames=%d mean_overlay_ms=%.4f estimated_fps=%.2f" % [mode_key, items, count, mean_ms, frame_fps])
    print("VISUAL_BENCH_END bursts=%d" % overlay.burst_count)
