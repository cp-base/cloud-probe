extends SceneTree
## Standalone deterministic checks. Run with:
## godot --headless --path . --script res://tests/test_world.gd

var results: Array[Dictionary] = []
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func check(label: String, ok: bool, details: String = "") -> void:
    results.append({"test": label, "passed": ok, "details": details})
    if not ok: failures += 1
    print(("PASS " if ok else "FAIL ") + label + (" — " + details if details != "" else ""))

func approx(a: float, b: float, eps: float = 0.001) -> bool:
    return absf(a - b) <= eps

func _run() -> void:
    var w: ProbeWorld = load("res://scripts/world.gd").new()
    root.add_child(w)
    w.seed = 20261106
    w.generate_world(true)
    check("seeded first HTML signal X", approx(w.nodes[1]["x"], -12.161510676378384, 0.000001), str(w.nodes[1]["x"]))
    check("seeded first HTML signal Y", approx(w.nodes[1]["y"], 139.3228100631386, 0.000001), str(w.nodes[1]["y"]))
    check("base and 9 station nodes", w.nodes[0]["type"] == "base" and w.nodes.filter(func(n): return n["type"] == "station").size() == 9)
    check("world radius 10000", w.nodes.all(func(n): return Vector2(n["x"], n["y"]).length() <= 10000.0))
    check("signals and enemies populated", w.nodes.size() > 250 and w.enemies.size() > 60, "nodes=%d enemies=%d" % [w.nodes.size(), w.enemies.size()])
    check("starting resources", approx(w.fuel, 100.0) and w.credits == 0 and w.discovered.has(0))

    # One second of manual forward motion, in identical 0.05s frame steps.
    for i in range(20): w.advance(0.05, true, false, false, false)
    check("forward 25 units in 1 second", approx(w.position_xy.x, 0.0) and approx(w.position_xy.y, 25.0), str(w.position_xy))
    check("fuel drain 0.42/unit", approx(w.fuel, 89.5, 0.01), str(w.fuel))
    for i in range(20): w.advance(0.05, false, false, false, true)
    check("clockwise turn 1.8 radians/second", approx(w.angle, 1.8), str(w.angle))
    w.auto_forward = true
    var prev := w.position_xy
    w.advance(0.05, false, false, false, false)
    check("auto forward moves without held button", w.position_xy.distance_to(prev) > 1.0)
    w.auto_forward = false

    # In tests only, position is injected to reach cases without a 5-minute trip.
    w.position_xy = Vector2(w.nodes[1]["x"], w.nodes[1]["y"])
    w.advance(0.0, false, false, false, false)
    var first_signal_active: bool = w.nearest.get("id", -1) == 1
    var fuel_before := w.fuel
    var inspected := w.inspect()
    check("near signal enabled and inspectable", first_signal_active and inspected and w.visited.has(1))
    check("inspection grants 1-3 credits", w.credits >= 1 and w.credits <= 3, "credits=%d" % w.credits)
    check("used signal cannot be inspected again", not w.inspect())
    check("inspection result modifies state", not approx(w.fuel, fuel_before) or w.discovered.size() > 1)

    w.position_xy = Vector2(w.nodes[2]["x"], w.nodes[2]["y"])
    w.fuel = 2.0
    w.advance(0.0, false, false, false, false)
    check("station full refill", w.inspect() and approx(w.fuel, w.max_fuel()))
    w.position_xy = Vector2.ZERO
    w.advance(0.0, false, false, false, false)
    w.fuel = 40.0
    check("base refill", w.inspect() and approx(w.fuel, w.max_fuel()))

    w.credits = 100
    check("speed purchase at base", w.purchase("speed") and w.upgrades["speed"] == 1 and approx(w.flight_speed(), 30.5))
    check("fuel purchase expands tank", w.purchase("fuel") and approx(w.max_fuel(), 130.0) and approx(w.fuel, 130.0))
    var remaining := w.credits
    w.position_xy = Vector2(50, 0)
    check("purchase away from base rejected", not w.purchase("sensor") and w.credits == remaining)

    w.fuel = 0.01
    w.advance(0.05, true, false, false, false)
    check("fuel exhaustion returns to origin", w.position_xy == Vector2.ZERO and w.sortie == 2)
    check("credits / upgrades persist through return", w.credits == remaining and w.upgrades["speed"] == 1)
    check("return refills upgraded tank", approx(w.fuel, 130.0))

    w.save_game()
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(w.STORAGE))
    check("progress JSON saved", parsed is Dictionary and int(parsed["credits"]) == remaining and int(parsed["upgrades"]["fuel"]) == 1)
    var old_seed := w.seed
    w.reset_new_world()
    check("reset creates fresh world with incremented seed", w.seed == old_seed + 1 and w.credits == 0 and w.upgrades["fuel"] == 0)
    check("reset world independent from original HTML storage", w.STORAGE.begins_with("user://") and not w.STORAGE.contains("cloud-probe05-v1"))

    var report := {"suite": "CLOUD / PROBE Godot independent comparison", "engine": Engine.get_version_info().get("string", "unknown"),
        "tests": results, "passed": results.size() - failures, "failed": failures, "total": results.size()}
    var file := FileAccess.open("res://evidence/TEST_RESULTS.json", FileAccess.WRITE)
    if file != null: file.store_string(JSON.stringify(report, "  "))
    print("TOTAL %d / %d, failures=%d" % [report["passed"], results.size(), failures])
    quit(1 if failures else 0)
