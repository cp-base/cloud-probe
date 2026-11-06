extends Node
class_name ProbeWorld
## The HTML probe's game state is kept separate from rendering and controls.
## The numeric values here are experimental parity values, not product requirements.

signal notice(message: String)
signal world_reset

const TAU_F := PI * 2.0
const WORLD_RADIUS := 10000.0
const STORAGE := "user://cloud_probe_godot_compare.json"
const BASE_COST := {"fuel": 12, "efficiency": 14, "speed": 16, "sensor": 14}
const UPGRADE_KEYS := ["fuel", "efficiency", "speed", "sensor"]

class Mulberry32:
    var state: int
    func _init(seed_value: int) -> void:
        state = seed_value & 0xffffffff
    func nextf() -> float:
        # Exact JS Math.imul/>>> based seeded generator, using 32-bit masking.
        state = (state + 0x6D2B79F5) & 0xffffffff
        var t: int = ((state ^ (state >> 15)) * (1 | state)) & 0xffffffff
        var mixed: int = ((t ^ (t >> 7)) * (61 | t)) & 0xffffffff
        t = (t ^ ((t + mixed) & 0xffffffff)) & 0xffffffff
        return float((t ^ (t >> 14)) & 0xffffffff) / 4294967296.0

var seed: int = 20261106
var nodes: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var discovered: Dictionary = {}
var visited: Dictionary = {}
var explored: Array[Vector2] = []

var position_xy: Vector2 = Vector2.ZERO  # x east, y north
var angle: float = 0.0                  # clockwise from north
var fuel: float = 100.0
var efficiency_distance: float = 0.0
var dist_travel: float = 0.0
var auto_forward: bool = false
var credits: int = 0
var upgrades: Dictionary = {"fuel": 0, "efficiency": 0, "speed": 0, "sensor": 0}
var best_range: float = 0.0
var paid_distance_step: int = 0
var sortie: int = 1
var events_done: int = 0
var battles: int = 0
var steps: int = 0
var nearest: Dictionary = {}
var last_message: String = ""
var elapsed: float = 0.0

func _ready() -> void:
    var stored := load_save()
    generate_world(false)
    if not stored.is_empty():
        for id_raw in stored.get("discoveries", []):
            var id := int(id_raw)
            if _has_node_id(id): discovered[id] = true
        discovered[0] = true
        _find_nearest()
        _set_notice("前回の資金と強化を復元。起点から再開します。")
        save_game()

func max_fuel() -> float:
    return 100.0 + 30.0 * int(upgrades["fuel"])
func fuel_cost() -> float:
    return 0.42 * pow(0.89, int(upgrades["efficiency"]))
func flight_speed() -> float:
    return 25.0 * (1.0 + 0.22 * int(upgrades["speed"]))
func sense_range() -> float:
    return 34.0 + 14.0 * int(upgrades["sensor"])
func upgrade_cost(which: String) -> int:
    if not BASE_COST.has(which): return -1
    return int(ceil(float(BASE_COST[which]) * pow(1.65, int(upgrades[which]))))
func at_base() -> bool:
    return position_xy.length() < 18.0
func distance_to(item: Dictionary) -> float:
    return position_xy.distance_to(Vector2(float(item["x"]), float(item["y"])))
func direction_to(item: Dictionary) -> float:
    return wrapf(atan2(float(item["x"]) - position_xy.x, float(item["y"]) - position_xy.y) - angle, -PI, PI)
func _set_notice(message: String) -> void:
    last_message = message
    notice.emit(message)
func _has_node_id(id: int) -> bool:
    for item in nodes:
        if int(item["id"]) == id: return true
    return false

func generate_world(reset_progress: bool = true) -> void:
    if reset_progress:
        credits = 0
        upgrades = {"fuel": 0, "efficiency": 0, "speed": 0, "sensor": 0}
        best_range = 0.0
        paid_distance_step = 0
    var r := Mulberry32.new(seed)
    nodes.clear(); enemies.clear()
    nodes.append({"id": 0, "x": 0.0, "y": 0.0, "type": "base"})
    nodes.append({"id": 1, "x": (r.nextf() - 0.5) * 25.0, "y": 118.0 + r.nextf() * 24.0, "type": "blue"})
    var idx := 2
    var stations := [
        [260.0, 0.10], [460.0, -0.82], [880.0, 1.16],
        [1450.0, 2.35], [2400.0, -2.10], [3700.0, 0.92],
        [5600.0, -0.34], [7800.0, 2.74], [9300.0, -1.48]
    ]
    for station in stations:
        nodes.append({"id": idx, "x": sin(station[1]) * station[0], "y": cos(station[1]) * station[0], "type": "station"})
        idx += 1
    for band in range(18):
        var t := float(band) / 17.0
        var inner := 140.0 + t * t * 9300.0
        var outer: float = minf(WORLD_RADIUS - 120.0, inner + 260.0 + t * 420.0)
        var count: int = 8 + band * 3 if band < 3 else 10 + int(floor(float(band) * 1.2))
        for i in range(count):
            var theta := (float(i) + (r.nextf() - 0.5) * 0.35) * TAU_F / count + band * 0.29 + (r.nextf() - 0.5) * 0.3
            var radius := inner + (outer - inner) * r.nextf()
            var node_type := "blue" if r.nextf() < (0.58 - 0.12 * t) else "green"
            nodes.append({"id": idx, "x": sin(theta) * radius, "y": cos(theta) * radius, "type": node_type})
            idx += 1
    var enemy_id := 1000
    for band in range(14):
        var t := float(band) / 13.0
        var count: int = 3 + band if band < 3 else 6 + int(floor(float(band) * 0.8))
        var inner := 210.0 + t * t * 8600.0
        var outer: float = minf(WORLD_RADIUS - 100.0, inner + 220.0 + t * 300.0)
        for i in range(count):
            var theta := (float(i) + r.nextf()) * TAU_F / count + band * 0.43
            var radius := inner + (outer - inner) * r.nextf()
            var home := Vector2(sin(theta) * radius, cos(theta) * radius)
            var overlaps := false
            for item in nodes:
                if home.distance_to(Vector2(item["x"], item["y"])) < 42.0:
                    overlaps = true
                    break
            if overlaps: continue
            enemies.append({"id": enemy_id, "x": home.x, "y": home.y, "hx": home.x, "hy": home.y,
                "dir": r.nextf() * TAU_F, "phase": r.nextf() * TAU_F,
                "speed": 5.0 + r.nextf() * 3.5, "alive": true})
            enemy_id += 1
    discovered = {0: true}; visited.clear(); explored = [Vector2.ZERO]
    sortie = 1; events_done = 0; battles = 0
    position_xy = Vector2.ZERO; angle = 0.0; fuel = max_fuel()
    efficiency_distance = 0.0; dist_travel = 0.0; steps = 0; auto_forward = false
    _find_nearest()
    _set_notice("広域世界を生成。信号を調査し、起点で航行能力を強化しよう。")
    world_reset.emit()
    save_game()

func reset_new_world() -> void:
    seed += 1
    generate_world(true)

func save_game() -> void:
    var out := {"seed": seed, "credits": credits, "upgrades": upgrades,
        "bestRange": best_range, "paidDistanceStep": paid_distance_step, "discoveries": discovered.keys()}
    var file := FileAccess.open(STORAGE, FileAccess.WRITE)
    if file != null: file.store_string(JSON.stringify(out))

func load_save() -> Dictionary:
    if not FileAccess.file_exists(STORAGE): return {}
    var file := FileAccess.open(STORAGE, FileAccess.READ)
    if file == null: return {}
    var parsed = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary) or not parsed.has("seed"): return {}
    seed = int(parsed["seed"])
    credits = maxi(0, int(parsed.get("credits", 0)))
    best_range = maxf(0.0, float(parsed.get("bestRange", 0)))
    paid_distance_step = maxi(0, int(parsed.get("paidDistanceStep", 0)))
    var saved_upgrades: Dictionary = parsed.get("upgrades", {})
    for k in UPGRADE_KEYS:
        upgrades[k] = clampi(int(saved_upgrades.get(k, 0)), 0, 40)
    return parsed

func _find_nearest() -> void:
    nearest = {}
    var d_min := 15.0
    for item in nodes:
        var id: int = item["id"]
        if item["type"] != "base" and item["type"] != "station" and visited.has(id): continue
        var dist := distance_to(item)
        if dist < d_min:
            d_min = dist
            nearest = item

func _update_discovery() -> void:
    for item in nodes:
        var id: int = item["id"]
        if discovered.has(id) or distance_to(item) >= sense_range(): continue
        discovered[id] = true
        if item["type"] == "station":
            credits += 4
            _set_notice("固定施設を初発見！ 探索資金 +4 C。")
        else:
            _set_notice(_type_name(item["type"]) + "を発見。接近して「調べる」。")
        save_game()
    _find_nearest()

func _type_name(which: String) -> String:
    match which:
        "base": return "起点"
        "station": return "固定施設"
        "blue": return "青の信号"
        "green": return "緑の信号"
        _: return "信号"

func advance(dt: float, forward: bool, backward: bool, left: bool, right: bool) -> void:
    dt = clampf(dt, 0.0, 0.05)
    elapsed += dt
    var motion: int = int(forward or auto_forward) - int(backward)
    var turn: int = int(right) - int(left)
    if turn != 0: angle = wrapf(angle + turn * 1.8 * dt, -PI, PI)
    if motion != 0:
        var d: float = motion * flight_speed() * dt
        position_xy += Vector2(sin(angle), cos(angle)) * d
        dist_travel += absf(d)
        var discount := 0.5 if efficiency_distance > 0.0 else 1.0
        fuel = maxf(0.0, fuel - absf(d) * fuel_cost() * discount)
        efficiency_distance = maxf(0.0, efficiency_distance - absf(d))
        if fuel <= 0.0:
            return_to_base()
            return
        var reached := position_xy.length()
        if reached > best_range:
            best_range = reached
            var step := int(floor(best_range / 200.0))
            if step > paid_distance_step:
                var award := (step - paid_distance_step) * 2
                paid_distance_step = step; credits += award; save_game()
                _set_notice("最高到達距離 %d！ 資金 +%d C。" % [int(best_range), award])
        steps += 1
        if steps % 7 == 0 and explored[-1].distance_to(position_xy) > 8.0:
            explored.append(position_xy)
            if explored.size() > 500: explored.pop_front()
    _move_enemies(dt)
    _update_discovery()

func _move_enemies(dt: float) -> void:
    for e in enemies:
        if not e["alive"]: continue
        var home := Vector2(e["hx"], e["hy"])
        var enemy_pos := Vector2(e["x"], e["y"])
        var delta_home := home - enemy_pos
        var d := enemy_pos.distance_to(position_xy)
        var target: float = e["dir"] + sin(elapsed * 0.7 + e["phase"]) * 0.018
        if delta_home.length() > 28.0:
            target = atan2(delta_home.y, delta_home.x)
        elif d < 45.0 and d > 9.0:
            target = atan2(position_xy.y - enemy_pos.y, position_xy.x - enemy_pos.x)
        var turn_delta: float = wrapf(target - e["dir"], -PI, PI)
        e["dir"] = wrapf(e["dir"] + clampf(turn_delta, -1.6 * dt, 1.6 * dt), -PI, PI)
        e["x"] += cos(e["dir"]) * e["speed"] * dt
        e["y"] += sin(e["dir"]) * e["speed"] * dt
        if distance_to(e) < 9.0: _encounter(e)

func _encounter(e: Dictionary) -> void:
    if not e["alive"]: return
    e["alive"] = false; battles += 1; credits += 1; auto_forward = false
    var r := Mulberry32.new(seed ^ (int(e["id"]) * 8111) ^ (sortie * 1331))
    var loss := 15 + int(floor(r.nextf() * 12.0))
    fuel = maxf(0.0, fuel - loss)
    _set_notice("赤の敵影と接触！ 燃料 −%d、資金 +1 C。" % loss)
    save_game()
    if fuel <= 0.0: return_to_base("戦闘で燃料切れ")

func inspect() -> bool:
    _find_nearest()
    if nearest.is_empty(): return false
    var item := nearest.duplicate()
    if item["type"] == "base":
        auto_forward = false; fuel = max_fuel()
        _set_notice("起点で燃料を最大まで補給。")
        return true
    var kind: String = item["type"]
    var id: int = item["id"]
    var r := Mulberry32.new(seed ^ (id * 74831) ^ (sortie * 103483))
    var p := r.nextf()
    visited[id] = true
    events_done += 1
    var message := ""
    if kind == "station":
        fuel = max_fuel(); efficiency_distance = 0.0
        message = "固定施設：完全補給。遠征の中継拠点として使える。"
    elif kind == "blue":
        if p < 0.56:
            var gain := 26 + int(floor(r.nextf() * 24.0))
            fuel = minf(100.0, fuel + gain)  # HTML05 known parity bug, intentionally retained.
            message = "青の信号：燃料 ＋%d。" % gain
        elif p < 0.83:
            var gain := 50 + int(floor(r.nextf() * 21.0))
            fuel = minf(100.0, fuel + gain)
            message = "青の信号：大きな補給 ＋%d！" % gain
        else:
            message = "青の信号：周囲を索敵。新たに%d地点を発見！" % scan_signals(160.0)
    else:
        if p < 0.36:
            var gain := 15 + int(floor(r.nextf() * 19.0))
            fuel = minf(100.0, fuel + gain)
            message = "緑の信号：予備エネルギー ＋%d。" % gain
        elif p < 0.66:
            efficiency_distance = 155.0
            message = "緑の信号：省エネ効果！ 移動155の間、燃料消費が半減。"
        elif p < 0.89:
            message = "緑の信号：広域スキャン！ 新たに%d地点を発見。" % scan_signals(190.0)
        else:
            var loss := minf(fuel, 7.0 + floor(r.nextf() * 10.0))
            fuel -= loss
            message = "緑の信号：ノイズ障害。燃料 −%d。" % int(ceil(loss))
    if kind != "station":
        var money := 1 + int(floor(r.nextf() * 3.0))
        credits += money
        message += " 資金 +%d C。" % money
    auto_forward = false
    _set_notice(message)
    _find_nearest()
    save_game()
    if fuel <= 0.0: return_to_base("調査中の燃料切れ")
    return true

func scan_signals(radius: float) -> int:
    var count := 0
    for item in nodes:
        if distance_to(item) < radius and not discovered.has(int(item["id"])):
            discovered[int(item["id"])] = true
            if item["type"] == "station": credits += 4
            count += 1
    if count != 0: save_game()
    return count

func return_to_base(reason: String = "燃料切れ") -> void:
    auto_forward = false
    sortie += 1; visited.clear()
    for e in enemies:
        e["x"] = e["hx"]; e["y"] = e["hy"]; e["alive"] = true
    position_xy = Vector2.ZERO; angle = 0.0; fuel = max_fuel()
    efficiency_distance = 0.0; steps = 0
    explored.append(Vector2.ZERO)
    _set_notice(reason + "！ 起点へ帰還。資金・強化・発見記録は維持。")
    _update_discovery()
    save_game()

func purchase(which: String) -> bool:
    if not BASE_COST.has(which): return false
    if not at_base():
        _set_notice("強化は起点で購入できます。")
        return false
    var cost := upgrade_cost(which)
    if credits < cost:
        _set_notice("資金が足りません。必要資金 %d C。" % cost)
        return false
    credits -= cost
    upgrades[which] += 1
    if which == "fuel": fuel += 30.0
    auto_forward = false
    save_game()
    var names := {"fuel": "燃料容量", "efficiency": "航行効率", "speed": "移動速度", "sensor": "探知能力"}
    _set_notice("%sを Lv.%d に強化！ %d Cを使用。" % [names[which], upgrades[which], cost])
    return true
