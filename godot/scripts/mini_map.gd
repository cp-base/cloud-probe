extends Control
class_name ProbeMiniMap
## Player-centered north-up map, HTML's 250 world units across.
var world: ProbeWorld
const COLORS := {"base": Color("a6c3ff"), "station": Color("ffd88c"), "blue": Color("6bc9ff"), "green": Color("80f3aa")}

func _ready() -> void:
    custom_minimum_size = Vector2(180, 180)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    var width: float = minf(size.x, size.y)
    if width < 10.0 or world == null: return
    var center := Vector2(size.x * 0.5, size.y * 0.5)
    var scale := width / 250.0
    draw_rect(Rect2(Vector2.ZERO, size), Color("071d2b"))
    for i in range(-5, 6):
        var k := i * 25.0 * scale
        draw_line(Vector2(center.x + k, 0), Vector2(center.x + k, size.y), Color("70acbe", 0.15))
        draw_line(Vector2(0, center.y + k), Vector2(size.x, center.y + k), Color("70acbe", 0.15))
    for p in world.explored:
        var point := _map_xy(p, center, scale)
        draw_circle(point, 33.0 * scale, Color("3c7484", 0.12))
    for n in world.nodes:
        if not world.discovered.has(int(n["id"])): continue
        var point := _map_xy(Vector2(n["x"], n["y"]), center, scale)
        if point.x < 0 or point.y < 0 or point.x > size.x or point.y > size.y: continue
        var c: Color = COLORS[n["type"]]
        if world.visited.has(int(n["id"])) and n["type"] != "station": c.a = 0.3
        draw_circle(point, 5.0 if n["type"] == "base" else 4.5 if n["type"] == "station" else 3.8, c)
    for e in world.enemies:
        if not e["alive"] or world.distance_to(e) > 82.0: continue
        var point := _map_xy(Vector2(e["x"], e["y"]), center, scale)
        if point.x < 0 or point.y < 0 or point.x > size.x or point.y > size.y: continue
        draw_circle(point, 3.7, Color("ff5669"))
    draw_arc(center, 82.0 * scale, 0.0, TAU, 90, Color("84e0dc", 0.25), 1.0, true)
    var nose := Vector2(sin(world.angle), -cos(world.angle))
    var right := Vector2(cos(world.angle), sin(world.angle))
    var points := PackedVector2Array([center + nose * 11.0, center - nose * 8.0 - right * 6.0,
        center - nose * 4.0, center - nose * 8.0 + right * 6.0])
    draw_colored_polygon(points, Color("ffe29c"))
    draw_polyline(points + PackedVector2Array([points[0]]), Color("21374a"), 1.0, true)
    draw_string(ThemeDB.fallback_font, Vector2(9, 18), "N ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b1d7e1"))

func _map_xy(pos: Vector2, center: Vector2, scale: float) -> Vector2:
    return center + Vector2((pos.x - world.position_xy.x) * scale, -(pos.y - world.position_xy.y) * scale)
