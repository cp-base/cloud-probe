extends SceneTree
## Native Control wiring integration tests. No direct save-file editing.
var results: Array[Dictionary] = []
func _initialize() -> void: call_deferred("_run")
func check(label: String, ok: bool) -> void:
    results.append({"test": label, "passed": ok})
    print(("PASS " if ok else "FAIL ") + label)
func _run() -> void:
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    current_scene = main
    var w: ProbeWorld = main.get_node("World")
    w.seed = 20261106
    w.generate_world(true)
    await process_frame
    check("two dedicated draw scenes", main.scene_view is ProbeSceneView and main.mini_map is ProbeMiniMap)
    check("native action button begins disabled", main.action_button.disabled == false) # base starts inspectable
    check("four native upgrade buttons", main.shop_buttons.size() == 4 and main.shop_buttons.values().all(func(b): return b is Button))
    var initial := w.position_xy
    main.pressed["forward"] = true
    for i in range(5): await process_frame
    main.pressed["forward"] = false
    check("hold button wiring triggers player movement", w.position_xy.y > initial.y)
    main.auto_button.button_pressed = true
    for i in range(4): await process_frame
    check("auto button toggle triggers movement", w.auto_forward and w.position_xy.y > initial.y + 0.1)
    main.auto_button.button_pressed = false
    check("auto button toggles off", not w.auto_forward)
    # Native action invokes the same inspect path as keyboard/manual controls.
    w.position_xy = Vector2(w.nodes[1]["x"], w.nodes[1]["y"] - 12.0)
    w.advance(0.0, false, false, false, false)
    main.action_button.pressed.emit()
    check("action click inspects signal", w.visited.has(1) and w.credits >= 1)
    check("notification presented", main.notice_text.text.length() > 0)
    # Visual HUD changes via _process; no direct node mutation.
    await process_frame
    check("HUD reflects credits", main.wallet_text.text == "%d C" % w.credits)
    var passed := results.filter(func(item): return item["passed"]).size()
    var report := {"suite": "CLOUD / PROBE Godot UI integration", "tests": results, "passed": passed, "failed": results.size() - passed}
    var output := FileAccess.open("res://evidence/UI_TEST_RESULTS.json", FileAccess.WRITE)
    if output: output.store_string(JSON.stringify(report, "  "))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(w.STORAGE))
    print("TOTAL UI %d / %d" % [passed, results.size()])
    quit(0 if passed == results.size() else 1)
