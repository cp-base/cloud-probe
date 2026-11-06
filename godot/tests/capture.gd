extends SceneTree
## Real rendered GUI capture under Xvfb. Movement is tested separately.
func _initialize() -> void:
    call_deferred("_capture")

func _save(target: String) -> void:
    await RenderingServer.frame_post_draw
    var img := root.get_texture().get_image()
    var code := img.save_png(target)
    print("SCREENSHOT:", target, " ", img.get_width(), "x", img.get_height(), " err=", code)

func _capture() -> void:
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    current_scene = main
    var world: ProbeWorld = main.get_node("World")
    world.seed = 20261106
    world.generate_world(true)
    for i in range(7): await process_frame
    await _save("res://evidence/godot_initial.png")
    # Evidence-specific travel shortcut: inspect a reachable state, not gameplay automation.
    world.position_xy = Vector2(world.nodes[1]["x"], world.nodes[1]["y"] - 12.0)
    world.angle = 0.0
    world.advance(0.0, false, false, false, false)
    for i in range(4): await process_frame
    await _save("res://evidence/godot_near_signal.png")
    world.inspect()
    for i in range(4): await process_frame
    await _save("res://evidence/godot_inspected.png")
    # Do not leave test snapshots as a real player's save.
    DirAccess.remove_absolute(ProjectSettings.globalize_path(world.STORAGE))
    quit()
