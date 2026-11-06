extends Node3D
## Optional visual layer; Foundation's world/session/map/save data remain untouched.
const SignalVisualShader = preload("res://research/visual/visual_signal.gdshader")
const MODES: PackedStringArray = ["BASE", "CONTOUR", "HAZE"]
var mode: int = 1
var bursts_enabled: bool = true
var originals: Dictionary = {} # key -> {instance_id, original_material, original_scale}
var seen_objects: Dictionary = {}
var sparks: Array[Dictionary] = []
var hud: Label
var panel: HBoxContainer
var fps_accum: float = 0.0
var marker_cost_ms: float = 0.0
var marked_count: int = 0
var last_applied_mode: int = -1
var burst_count: int = 0
var last_camera_position: Vector3 = Vector3.ZERO

func install(host: Node3D) -> void:
    var layer := CanvasLayer.new()
    layer.layer = 25
    add_child(layer)
    var box := VBoxContainer.new()
    box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    box.position = Vector2(-347.0, 107.0)
    box.custom_minimum_size = Vector2(335.0, 92.0)
    layer.add_child(box)
    hud = Label.new()
    hud.text = "VISUAL RESEARCH"
    hud.add_theme_color_override("font_color", Color("c8eaf2"))
    hud.add_theme_font_size_override("font_size", 13)
    box.add_child(hud)
    panel = HBoxContainer.new()
    box.add_child(panel)
    for i in range(3):
        var index := i
        var btn := Button.new()
        btn.text = MODES[i]
        btn.custom_minimum_size = Vector2(91.0, 33.0)
        btn.pressed.connect(func(): set_mode(index))
        panel.add_child(btn)
    var burst_button := Button.new()
    burst_button.text = "P: FX"
    burst_button.custom_minimum_size = Vector2(62.0, 33.0)
    burst_button.pressed.connect(toggle_bursts)
    panel.add_child(burst_button)
    for object: Dictionary in host.game.active_objects(host.game.sense()):
        seen_objects[object["id"]] = true
    _update_label(0.0)

func set_mode(next_mode: int) -> void:
    mode = posmod(next_mode, 3)
    last_applied_mode = -1
    if mode == 0:
        for key: String in originals.keys():
            var info: Dictionary = originals[key]
            if is_instance_valid(info["node"]):
                var n: MeshInstance3D = info["node"]
                n.material_override = info["material"]
                n.scale = info["scale"]
        originals.clear()
    _update_label(0.0)

func next_mode() -> void:
    set_mode(mode + 1)

func toggle_bursts() -> void:
    bursts_enabled = not bursts_enabled
    _update_label(0.0)

func sync(host: Node3D, delta: float) -> void:
    var start := Time.get_ticks_usec()
    var present: Dictionary = {}
    var camera_position: Vector3 = host.camera.global_position
    last_camera_position = camera_position
    var game = host.game
    marked_count = 0
    var mode_changed: bool = last_applied_mode != mode
    for key: String in host.markers.keys():
        var marker: MeshInstance3D = host.markers[key]
        if not is_instance_valid(marker):
            continue
        present[key] = true
        if mode == 0:
            marked_count += 1
            continue
        if not originals.has(key) or originals[key]["instance_id"] != marker.get_instance_id():
            var orig: Material = marker.material_override
            var color_value: Color = Color("81d8f6")
            var shape: int = 3
            var appearance: int = 2
            if orig is ShaderMaterial:
                color_value = orig.get_shader_parameter("signal_color")
                shape = int(orig.get_shader_parameter("kind"))
                appearance = int(orig.get_shader_parameter("appearance"))
            originals[key] = {"node": marker, "instance_id": marker.get_instance_id(), "material": orig, "scale": marker.scale,
                              "color": color_value, "kind": shape, "appearance": appearance}
            var shader_material := ShaderMaterial.new()
            shader_material.shader = SignalVisualShader
            shader_material.set_shader_parameter("signal_color", color_value)
            shader_material.set_shader_parameter("kind", shape)
            shader_material.set_shader_parameter("appearance", appearance)
            shader_material.set_shader_parameter("hostile", 1.0 if _is_enemy(game, key) else 0.0)
            shader_material.set_shader_parameter("style_mode", mode - 1)
            marker.material_override = shader_material
        var info: Dictionary = originals[key]
        var distance: float = camera_position.distance_to(marker.global_position)
        var near_factor: float = 1.0 - smoothstep(24.0, 170.0, distance)
        var m: ShaderMaterial = marker.material_override
        if key.begins_with("f:"):
            var facility_id: String = key.substr(2)
            if game.world.facilities.has(facility_id):
                info["color"] = Color("ffd18a") if game.facility_built(facility_id) else Color("a79ca3")
        if key.begins_with("f:"):
            m.set_shader_parameter("signal_color", info["color"])
        m.set_shader_parameter("proximity", near_factor)
        if mode_changed:
            m.set_shader_parameter("style_mode", mode - 1)
        var minimum_scale: float = 1.05 if _is_enemy(game, key) else 1.0
        # Distances beyond 100 get a modest floor for visibility; no changes to collision/detection.
        marker.scale = info["scale"] * clampf(distance / 130.0, minimum_scale, 1.80)
        marked_count += 1
    last_applied_mode = mode
    for key: String in originals.keys():
        if not present.has(key):
            originals.erase(key)
    if seen_objects.size() > 4096:
        seen_objects.clear() # prevent unbounded history in long sessions
    if mode != 0 and bursts_enabled:
        for item: Dictionary in game.active_objects(game.sense()):
            var id: String = item["id"]
            if not seen_objects.has(id):
                if item["kind"] != "enemy":
                    burst(Vector3(item["pos"].x, 0.0, item["pos"].y), Color("67dfff"), 0.7)
                seen_objects[id] = true
        for item: Dictionary in game.effects:
            if float(item.get("age", 1.0)) < 0.065:
                var id := "%s:%s:%d" % [item.get("kind", ""), str(item.get("pos", Vector2.ZERO)), game.campaign.sortie_sequence]
                if not seen_objects.has("effect:" + id):
                    burst(Vector3(item["pos"].x, 0.0, item["pos"].y), Color("93f6dc") if item["kind"] == "collect" else Color("ff9579"), 1.0)
                    seen_objects["effect:" + id] = true
    for i in range(sparks.size()-1, -1, -1):
        sparks[i]["ttl"] -= delta
        if sparks[i]["ttl"] <= 0.0:
            if is_instance_valid(sparks[i]["node"]):
                sparks[i]["node"].queue_free()
            sparks.remove_at(i)
    marker_cost_ms = float(Time.get_ticks_usec()-start) / 1000.0
    fps_accum += delta
    if fps_accum >= 0.25:
        _update_label(Engine.get_frames_per_second())
        fps_accum = 0.0

func _is_enemy(game: RefCounted, key: String) -> bool:
    return not key.begins_with("f:") and game.world.objects.has(key) and game.world.objects[key]["kind"] == "enemy"

func burst(location: Vector3, color_value: Color, strength: float = 1.0) -> void:
    if not bursts_enabled or mode == 0 or sparks.size() >= 12:
        return
    var particles := CPUParticles3D.new()
    particles.name = "VisualBurst"
    particles.emitting = false # avoid initial emission at origin before placement
    particles.amount = 14
    particles.lifetime = 0.55
    particles.one_shot = true
    particles.explosiveness = 1.0
    particles.direction = Vector3.UP
    particles.spread = 180.0
    particles.initial_velocity_min = 2.0 * strength
    particles.initial_velocity_max = 6.0 * strength
    particles.gravity = Vector3.ZERO
    particles.scale_amount_min = 0.24
    particles.scale_amount_max = 0.40
    var sphere := SphereMesh.new()
    sphere.radius = 0.38
    sphere.height = 0.76
    sphere.radial_segments = 6
    sphere.rings = 3
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = color_value
    material.emission_enabled = true
    material.emission = color_value
    sphere.material = material
    particles.mesh = sphere
    add_child(particles)
    particles.global_position = location
    particles.restart()
    particles.emitting = true
    sparks.append({"node":particles, "ttl": 0.90})
    # A short procedural scan ring animates with built-in Tween, no texture asset.
    var pulse := MeshInstance3D.new()
    var quad := QuadMesh.new()
    quad.size = Vector2(2.8, 2.8)
    pulse.mesh = quad
    pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var pulse_mat := ShaderMaterial.new()
    pulse_mat.shader = SignalVisualShader
    pulse_mat.set_shader_parameter("signal_color", color_value)
    pulse_mat.set_shader_parameter("kind", 3)
    pulse_mat.set_shader_parameter("appearance", 1)
    pulse_mat.set_shader_parameter("style_mode", 0)
    pulse_mat.set_shader_parameter("proximity", 1.0)
    pulse.material_override = pulse_mat
    add_child(pulse)
    pulse.global_position = location
    if location.distance_squared_to(last_camera_position) > 0.01:
        pulse.look_at(last_camera_position, Vector3.UP, true)
    pulse.scale = Vector3.ONE * 0.7
    var tween := create_tween().set_parallel(true)
    tween.tween_property(pulse, "scale", Vector3.ONE * 5.0, 0.55)
    tween.tween_method(func(value: float): pulse_mat.set_shader_parameter("gain", value), 1.2, 0.0, 0.55)
    tween.chain().tween_callback(func(): if is_instance_valid(pulse): pulse.queue_free())
    burst_count += 1

func _update_label(fps: float) -> void:
    if hud == null:
        return
    hud.text = "%s   %d nodes   FX:%s   %.2f ms   %.0f fps" % [MODES[mode], marked_count, "ON" if bursts_enabled else "OFF", marker_cost_ms, fps]
