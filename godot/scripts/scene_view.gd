extends Control
class_name ProbeSceneView
## CanvasItem pseudo-first-person projection from the original HTML Canvas 2D.

const FIELD_OF_VIEW := PI * 0.47
const PALETTE := {
    "base": Color("a6c3ff"), "station": Color("ffd88c"),
    "blue": Color("6bc9ff"), "green": Color("80f3aa"), "enemy": Color("ff5669")}
var world: ProbeWorld

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    var width := size.x
    var height := size.y
    if width < 4.0 or height < 4.0: return
    _backdrop(width, height)
    if world == null: return
    var projected: Array[Dictionary] = []
    for n in world.nodes:
        var projection := _project(n, width, height)
        if not projection.is_empty():
            projected.append({"object": n, "projection": projection, "enemy": false})
    for e in world.enemies:
        if not e["alive"]: continue
        var projection := _project(e, width, height)
        if not projection.is_empty():
            projected.append({"object": e, "projection": projection, "enemy": true})
    projected.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a["projection"]["distance"]) > float(b["projection"]["distance"]))
    for entry in projected:
        _draw_signal(entry["object"], entry["projection"], entry["enemy"])
    _draw_crosshair(width, height)
    _draw_compass(width, height)
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(16, 25), "SIGNAL SPACE / LIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a3e8e5"))
    draw_string(font, Vector2(16, height - 18), "方位 %03d°" % posmod(int(round(rad_to_deg(world.angle))) + 3600, 360), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("b7d7e3"))

func _backdrop(width: float, height: float) -> void:
    var horizon := height * 0.495
    var colors := [Color("07121f"), Color("174558"), Color("23465b"), Color("061b2b")]
    for i in range(70):
        var u := float(i) / 70.0
        var c: Color
        if u < 0.48: c = colors[0].lerp(colors[1], u / 0.48)
        elif u < 0.52: c = colors[1].lerp(colors[2], (u - 0.48) / 0.04)
        else: c = colors[2].lerp(colors[3], (u - 0.52) / 0.48)
        draw_rect(Rect2(0.0, height * u, width, height / 70.0 + 1.0), c)
    for i in range(14):
        var phase := float(i) * 317.13
        var ang := world.angle if world != null else 0.0
        var x := fposmod(phase - ang * 180.0 + width * 20.0, width + 280.0) - 140.0
        var y := horizon + (i % 6 - 2) * 14.0
        var mist: Color = Color("acdce4", 0.035 + (i % 3) * 0.016)
        _draw_mist_ellipse(Vector2(x, y), 60.0 + (i % 5) * 23.0, 5.0 + (i % 3) * 4.0, mist)
    for i in range(-9, 10):
        var offset := sin((world.angle if world != null else 0.0) * 1.3 + i * 0.22) * 8.0
        draw_line(Vector2(width * 0.5 + offset, horizon), Vector2(width * 0.5 + i * width * 0.13, height), Color(0.40, 0.73, 0.80, 0.13), 1.0)
    for i in range(12):
        var dist := 17.0 + i * i * 4.4
        var y := horizon + 1300.0 / (dist + 8.0)
        if y <= height: draw_line(Vector2(0, y), Vector2(width, y), Color(0.36, 0.69, 0.76, 0.03 + i * 0.008), 1.0)
    for i in range(40):
        var x := fposmod(i * 73.1 + sin(world.angle if world != null else 0.0) * 25.0, width)
        var y := fposmod(i * 47.3, maxf(1.0, horizon - 20.0)) + 12.0
        draw_circle(Vector2(x, y), 1.1, Color(0.71, 0.95, 0.99, 0.12 + 0.15 * (i % 4) / 4.0))
    draw_line(Vector2(0, horizon), Vector2(width, horizon), Color("73e3de", 0.38), 1.0)

func _draw_mist_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(25):
        var a := TAU * float(i) / 24.0
        points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
    draw_colored_polygon(points, color)

func _project(item: Dictionary, width: float, height: float) -> Dictionary:
    var delta := Vector2(float(item["x"]), float(item["y"])) - world.position_xy
    var dist := delta.length()
    var relative := wrapf(atan2(delta.x, delta.y) - world.angle, -PI, PI)
    if absf(relative) > FIELD_OF_VIEW * 0.58 or dist > 300.0 + int(world.upgrades["sensor"]) * 90.0 or dist < 2.5:
        return {}
    return {"x": width * 0.5 + tan(relative) / tan(FIELD_OF_VIEW * 0.5) * width * 0.5,
        "y": height * 0.495 + clampf(4200.0 / (dist + 15.0), 7.0, 177.0) * 0.10,
        "radius": clampf(4200.0 / (dist + 15.0), 7.0, 177.0) * 0.5, "distance": dist}

func _draw_signal(n: Dictionary, p: Dictionary, enemy: bool) -> void:
    var id: int = n["id"]
    var kind: String = "enemy" if enemy else n["type"]
    var c: Color = PALETTE[kind]
    var dist: float = p["distance"]
    var r: float = p["radius"]
    var center := Vector2(p["x"], p["y"])
    var alpha: float = 1.0 if enemy else clampf((300.0 + int(world.upgrades["sensor"]) * 90.0 - dist) / 140.0, 0.24, 1.0)
    if world.visited.has(id) and kind != "station" and not enemy: alpha *= 0.28
    var pulse := 1.0 + sin(world.elapsed * (4.0 if enemy else 1.9) + id) * (0.13 if enemy else 0.04)
    r *= pulse
    var stroke: Color = c
    stroke.a = alpha
    # Soft light is rendered in CanvasItem without shaders or external assets.
    draw_circle(center, r * 1.25, Color(c.r, c.g, c.b, alpha * 0.035))
    draw_circle(center, r * 0.97, Color(c.r, c.g, c.b, alpha * 0.05))
    draw_arc(center, r * (0.77 if enemy else 0.80), 0.0, TAU, 48, stroke, clampf(r * 0.10, 1.3, 3.0), true)
    if enemy:
        _line_loop([center + Vector2(0, -r * 0.9), center + Vector2(r * 0.7, 0), center + Vector2(0, r * 0.9), center + Vector2(-r * 0.7, 0)], stroke, 2.0)
        draw_arc(center, r * 0.23, 0.0, TAU, 30, stroke, 2.0, true)
    else:
        draw_arc(center, r * 1.16, world.elapsed * 0.28, world.elapsed * 0.28 + PI * 1.15, 36, Color(c.r, c.g, c.b, alpha * 0.5), 1.2, true)
        match kind:
            "station":
                draw_arc(center, r * 0.56, 0.0, TAU, 36, stroke, 1.8, true)
                draw_line(center + Vector2(-r * 0.68, 0), center + Vector2(r * 0.68, 0), stroke, 1.8)
                draw_line(center + Vector2(0, -r * 0.68), center + Vector2(0, r * 0.68), stroke, 1.8)
            "blue":
                draw_rect(Rect2(center - Vector2.ONE * r * 0.47, Vector2.ONE * r * 0.94), stroke, false, 1.8)
                draw_line(center + Vector2(-r * 0.2, 0), center + Vector2(r * 0.2, 0), stroke, 1.5)
                draw_line(center + Vector2(0, -r * 0.2), center + Vector2(0, r * 0.2), stroke, 1.5)
            "green":
                _line_loop([center + Vector2(0, -r * 0.74), center + Vector2(r * 0.65, r * 0.40), center + Vector2(-r * 0.65, r * 0.40)], stroke, 1.8)
            _:
                _line_loop([center + Vector2(0, -r * 0.6), center + Vector2(r * 0.5, 0), center + Vector2(0, r * 0.6), center + Vector2(-r * 0.5, 0)], stroke, 1.8)
    if dist < (130.0 if enemy else 86.0):
        var label := "敵影" if enemy else "調査済み" if world.visited.has(id) and kind != "station" else world._type_name(kind) if world.discovered.has(id) else "未知の信号"
        draw_string(ThemeDB.fallback_font, center + Vector2(-100, r + 20), "%s · %d" % [label, roundi(dist)], HORIZONTAL_ALIGNMENT_CENTER, 200, 12, Color("d9f5ff"))

func _line_loop(pts: Array[Vector2], color: Color, width: float) -> void:
    for i in range(pts.size()):
        draw_line(pts[i], pts[(i + 1) % pts.size()], color, width, true)

func _draw_crosshair(width: float, height: float) -> void:
    var center := Vector2(width * 0.5, height * 0.49)
    var line_color := Color("9bece0", 0.48)
    draw_arc(center, 8.0, 0.0, TAU, 30, line_color, 1.0, true)
    draw_line(center + Vector2(-12, 0), center + Vector2(-4, 0), line_color)
    draw_line(center + Vector2(4, 0), center + Vector2(12, 0), line_color)
    draw_line(center + Vector2(0, -12), center + Vector2(0, -4), line_color)
    draw_line(center + Vector2(0, 4), center + Vector2(0, 12), line_color)

func _draw_compass(width: float, height: float) -> void:
    if world == null: return
    var by := height - 75.0
    for delta in range(-60, 61, 15):
        var x := width * 0.5 + delta / 75.0 * width * 0.5
        draw_line(Vector2(x, by), Vector2(x, by + (12.0 if delta % 30 == 0 else 6.0)), Color("b4eff0", 0.4))
        if delta % 30 == 0:
            draw_string(ThemeDB.fallback_font, Vector2(x - 22.0, by + 25.0), "%d°" % posmod(int(rad_to_deg(world.angle) + delta + 3600), 360), HORIZONTAL_ALIGNMENT_CENTER, 44, 10, Color("b2e1e6"))
