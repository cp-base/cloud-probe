extends SceneTree
const SignalShader = preload("res://research/visual/visual_signal.gdshader")
const Overlay = preload("res://research/visual/visual_overlay.gd")
const Gallery = preload("res://research/visual/VisualGallery.tscn")
func _init() -> void:
    call_deferred("run_tests")
func run_tests() -> void:
    var fail: int = 0
    var material := ShaderMaterial.new()
    material.shader = SignalShader
    material.set_shader_parameter("style_mode", 1)
    material.set_shader_parameter("proximity", 0.5)
    if material.shader != SignalShader:
        push_error("shader not attached")
        fail += 1
    if int(material.get_shader_parameter("style_mode")) != 1:
        push_error("style mode uniform not retained")
        fail += 1
    var scene := Gallery.instantiate()
    root.add_child(scene)
    await process_frame
    if scene.markers.size() != 60:
        push_error("fixture size mismatch: %d" % scene.markers.size())
        fail += 1
    if scene.overlay.mode != 0:
        push_error("baseline default not selected")
        fail += 1
    scene.overlay.set_mode(1)
    scene.overlay.sync(scene, 0.016)
    if scene.overlay.originals.size() != 60:
        push_error("marker integration mismatch: %d" % scene.overlay.originals.size())
        fail += 1
    scene.overlay.set_mode(2)
    scene.overlay.sync(scene, 0.016)
    if scene.overlay.mode != 2:
        fail += 1
    scene.overlay.burst(Vector3(0,0,-20), Color.WHITE)
    if scene.overlay.sparks.size() != 1:
        push_error("particle burst failed")
        fail += 1
    scene.overlay.set_mode(0)
    if not scene.overlay.originals.is_empty():
        push_error("original marker material not restored")
        fail += 1
    print("VISUAL_TEST_END failures=%d" % fail)
    quit(0 if fail == 0 else 1)
