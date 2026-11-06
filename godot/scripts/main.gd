extends Control
## Main scene composes standard Godot Control widgets, a CanvasItem scene,
## a mini-map, and a separate state model. The HTML original remains untouched.

const SCENE_VIEW := preload("res://scenes/SceneView.tscn")
const MINI_MAP := preload("res://scenes/MiniMap.tscn")
const BG := Color("05111d")
const PANEL := Color("0c2332")
const BORDER := Color("31546b")
const INK := Color("e9f8ff")
const MUTE := Color("9cbdce")
const AQUA := Color("73e9e3")
const GOLD := Color("ffd88c")

@onready var world: ProbeWorld = $World
var scene_view: ProbeSceneView
var mini_map: ProbeMiniMap
var fuel_amount: Label
var fuel_bar: ProgressBar
var wallet_text: Label
var best_text: Label
var distance_text: Label
var found_text: Label
var event_text: Label
var front_hint: Label
var notice_text: Label
var bearing_text: Label
var auto_button: Button
var action_button: Button
var shop_status: Label
var shop_buttons: Dictionary = {}
var shop_levels: Dictionary = {}
var shop_effects: Dictionary = {}
var pressed: Dictionary = {"forward": false, "backward": false, "left": false, "right": false}
var keyboard: Dictionary = {"forward": false, "backward": false, "left": false, "right": false}
var reset_dialog: ConfirmationDialog

func _ready() -> void:
    _build_ui()
    scene_view.world = world
    mini_map.world = world
    world.notice.connect(func(msg: String) -> void: notice_text.text = msg)
    world.world_reset.connect(_clear_input)
    notice_text.text = world.last_message
    _refresh()

func _process(delta: float) -> void:
    var fwd: bool = pressed["forward"] or keyboard["forward"]
    var back: bool = pressed["backward"] or keyboard["backward"]
    var left: bool = pressed["left"] or keyboard["left"]
    var right: bool = pressed["right"] or keyboard["right"]
    if back and world.auto_forward: world.auto_forward = false
    world.advance(delta, fwd, back, left, right)
    scene_view.queue_redraw()
    mini_map.queue_redraw()
    _refresh()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and not event.echo:
        var key := ""
        match event.keycode:
            KEY_UP, KEY_W: key = "forward"
            KEY_DOWN, KEY_S: key = "backward"
            KEY_LEFT, KEY_A: key = "left"
            KEY_RIGHT, KEY_D: key = "right"
        if key != "":
            keyboard[key] = event.pressed
            get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
        _clear_input()

func _clear_input() -> void:
    for k in pressed:
        pressed[k] = false
        keyboard[k] = false

func _panel(padding: int = 12, bg: Color = PANEL) -> PanelContainer:
    var p := PanelContainer.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = BORDER
    sb.set_border_width_all(1)
    sb.set_corner_radius_all(12)
    sb.set_content_margin_all(padding)
    p.add_theme_stylebox_override("panel", sb)
    return p

func _label(text_value: String, font_size: int = 14, color: Color = INK) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_color_override("font_color", color)
    label.add_theme_font_size_override("font_size", font_size)
    return label

func _button(caption: String, toggle: bool = false) -> Button:
    var b := Button.new()
    b.text = caption
    b.toggle_mode = toggle
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size", 14)
    b.add_theme_color_override("font_color", INK)
    b.add_theme_color_override("font_disabled_color", Color("728994"))
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("1d4355")
    normal.border_color = Color("4c8190")
    normal.set_border_width_all(1)
    normal.set_corner_radius_all(9)
    normal.set_content_margin_all(7)
    b.add_theme_stylebox_override("normal", normal)
    var hover := normal.duplicate()
    hover.bg_color = Color("28606b")
    hover.border_color = AQUA
    b.add_theme_stylebox_override("hover", hover)
    var pressed_box := hover.duplicate()
    pressed_box.bg_color = Color("1d6a72")
    b.add_theme_stylebox_override("pressed", pressed_box)
    var disabled_box := normal.duplicate()
    disabled_box.bg_color = Color("153344")
    b.add_theme_stylebox_override("disabled", disabled_box)
    return b

func _row_gap(container: BoxContainer, separation: int) -> void:
    container.add_theme_constant_override("separation", separation)

func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = BG
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    move_child(background, 0)

    var margins := MarginContainer.new()
    margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for edge in ["left", "top", "right", "bottom"]:
        margins.add_theme_constant_override("margin_" + edge, 14)
    add_child(margins)
    var root := VBoxContainer.new()
    _row_gap(root, 11)
    margins.add_child(root)

    var header := HBoxContainer.new()
    _row_gap(header, 16)
    root.add_child(header)
    var brand := VBoxContainer.new()
    _row_gap(brand, 1)
    header.add_child(brand)
    brand.add_child(_label("CLOUD / PROBE 05", 21, AQUA))
    brand.add_child(_label("AIクラウド世界・探索と強化  /  半径10000の模型  •  Godot比較版", 12, MUTE))
    var header_spacer := Control.new()
    header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(header_spacer)
    var reset_btn := _button("世界と育成をリセット ↻")
    header.add_child(reset_btn)
    reset_btn.pressed.connect(func() -> void: reset_dialog.popup_centered())
    reset_dialog = ConfirmationDialog.new()
    reset_dialog.title = "リセットの確認"
    reset_dialog.dialog_text = "世界と育成を最初からやり直しますか？"
    reset_dialog.confirmed.connect(func() -> void: world.reset_new_world())
    add_child(reset_dialog)

    var play_row := HBoxContainer.new()
    _row_gap(play_row, 12)
    play_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(play_row)
    var scene_frame := _panel(0, Color("0e2736"))
    scene_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scene_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
    play_row.add_child(scene_frame)
    scene_view = SCENE_VIEW.instantiate() as ProbeSceneView
    scene_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scene_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scene_frame.add_child(scene_view)
    front_hint = _label("雲の向こうに未知の信号がある", 13, Color("d9eef4"))
    # Native Label is drawn over the custom world projection.
    scene_view.add_child(front_hint)
    front_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    front_hint.offset_left = 16
    front_hint.offset_top = 35
    front_hint.offset_right = -16
    front_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var color_key := _label("● 固定施設      ● 青の信号      ● 緑の信号      ● 赤の敵影", 11, Color("c5dfeb"))
    scene_view.add_child(color_key)
    color_key.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    color_key.offset_left = 16
    color_key.offset_right = -16
    color_key.offset_top = 58
    color_key.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var sidebar := _panel(10, Color("10293a"))
    sidebar.custom_minimum_size.x = 232
    play_row.add_child(sidebar)
    var side_col := VBoxContainer.new()
    _row_gap(side_col, 5)
    sidebar.add_child(side_col)
    side_col.add_child(_label("ENERGY / 移動燃料", 12, Color("7eafb8")))
    var fuel_row := HBoxContainer.new()
    side_col.add_child(fuel_row)
    fuel_row.add_child(_label("残量", 13))
    var fs := Control.new()
    fs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    fuel_row.add_child(fs)
    fuel_amount = _label("100 / 100", 17, GOLD)
    fuel_row.add_child(fuel_amount)
    fuel_bar = ProgressBar.new()
    fuel_bar.custom_minimum_size.y = 13
    fuel_bar.min_value = 0
    fuel_bar.max_value = 100
    fuel_bar.value = 100
    fuel_bar.show_percentage = false
    var bar_back := StyleBoxFlat.new()
    bar_back.bg_color = Color("18354a")
    bar_back.set_corner_radius_all(8)
    var bar_fill := StyleBoxFlat.new()
    bar_fill.bg_color = Color("8ee5d0")
    bar_fill.set_corner_radius_all(8)
    fuel_bar.add_theme_stylebox_override("background", bar_back)
    fuel_bar.add_theme_stylebox_override("fill", bar_fill)
    side_col.add_child(fuel_bar)
    side_col.add_child(_label("LOCAL MAP / 周辺地図", 12, Color("7eafb8")))
    var map_wrap := CenterContainer.new()
    side_col.add_child(map_wrap)
    mini_map = MINI_MAP.instantiate() as ProbeMiniMap
    map_wrap.add_child(mini_map)
    side_col.add_child(_label("周囲約250 / 北が上 / 自機は中央", 11, MUTE))
    side_col.add_child(_label("CREDITS / 探索資金", 12, Color("7eafb8")))
    wallet_text = _data_row(side_col, "所持資金", "0 C", GOLD)
    best_text = _data_row(side_col, "最高到達距離", "0")
    side_col.add_child(_label("TELEMETRY", 12, Color("7eafb8")))
    distance_text = _data_row(side_col, "起点からの距離", "0")
    found_text = _data_row(side_col, "発見した地点", "0")
    event_text = _data_row(side_col, "調査 / 戦闘", "0 / 0")
    notice_text = _label("信号に近づいて調べよう。", 12, Color("c8dce5"))
    notice_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    notice_text.custom_minimum_size.y = 38
    side_col.add_child(notice_text)

    var controls_row := HBoxContainer.new()
    controls_row.alignment = BoxContainer.ALIGNMENT_CENTER
    _row_gap(controls_row, 20)
    root.add_child(controls_row)
    var controls := GridContainer.new()
    controls.columns = 4
    controls.add_theme_constant_override("h_separation", 7)
    controls.add_theme_constant_override("v_separation", 7)
    controls_row.add_child(controls)
    _blank(controls)
    _hold_button(controls, "↑\n前進", "forward")
    _blank(controls)
    auto_button = _button("▶\n自動前進", true)
    auto_button.custom_minimum_size = Vector2(95, 53)
    controls.add_child(auto_button)
    auto_button.toggled.connect(func(on: bool) -> void: world.auto_forward = on)
    _hold_button(controls, "↶\n左旋回", "left")
    _hold_button(controls, "↓\n後退", "backward")
    _hold_button(controls, "↷\n右旋回", "right")
    action_button = _button("⌕\n調べる")
    action_button.custom_minimum_size = Vector2(95, 53)
    controls.add_child(action_button)
    action_button.pressed.connect(func() -> void: world.inspect())
    var explain := _label("操作：ボタン長押し、または矢印・WASD\n自動前進中も左右旋回できます。\n近くの青・緑信号は「調べる」。", 13, MUTE)
    controls_row.add_child(explain)

    var shop_frame := _panel(12, Color("112b3d"))
    root.add_child(shop_frame)
    var shop_col := VBoxContainer.new()
    _row_gap(shop_col, 7)
    shop_frame.add_child(shop_col)
    var shop_header := HBoxContainer.new()
    shop_col.add_child(shop_header)
    shop_header.add_child(_label("強化ターミナル / UPGRADES", 15, Color("d8f7f7")))
    var push := Control.new(); push.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shop_header.add_child(push)
    shop_header.add_child(_label("購入は起点（距離18以内）のみ", 12, MUTE))
    var shop_grid := HBoxContainer.new()
    _row_gap(shop_grid, 9)
    shop_col.add_child(shop_grid)
    _upgrade_card(shop_grid, "fuel", "燃料容量")
    _upgrade_card(shop_grid, "efficiency", "航行効率")
    _upgrade_card(shop_grid, "speed", "移動速度")
    _upgrade_card(shop_grid, "sensor", "探知能力")
    shop_status = _label("探索資金を集めると強化できます。", 11, Color("93b9c9"))
    shop_col.add_child(shop_status)

func _blank(parent: GridContainer) -> void:
    var n := Control.new()
    n.custom_minimum_size = Vector2(95, 53)
    parent.add_child(n)

func _hold_button(parent: GridContainer, title: String, which: String) -> void:
    var button := _button(title)
    button.custom_minimum_size = Vector2(95, 53)
    parent.add_child(button)
    button.button_down.connect(func() -> void: pressed[which] = true)
    button.button_up.connect(func() -> void: pressed[which] = false)
    button.mouse_exited.connect(func() -> void: pressed[which] = false)

func _data_row(parent: VBoxContainer, key: String, val: String, value_color: Color = INK) -> Label:
    var line := HBoxContainer.new()
    parent.add_child(line)
    line.add_child(_label(key, 12, MUTE))
    var space := Control.new()
    space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    line.add_child(space)
    var value := _label(val, 13, value_color)
    line.add_child(value)
    return value

func _upgrade_card(parent: HBoxContainer, key: String, title: String) -> void:
    var card := _panel(9, Color("0c2638"))
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(card)
    var column := VBoxContainer.new()
    _row_gap(column, 5)
    card.add_child(column)
    var lv := _label(title + " Lv.0", 14)
    column.add_child(lv)
    shop_levels[key] = lv
    var effect := _label("", 12, MUTE)
    column.add_child(effect)
    shop_effects[key] = effect
    var button := _button("強化する")
    button.custom_minimum_size.y = 37
    column.add_child(button)
    shop_buttons[key] = button
    button.pressed.connect(func() -> void: world.purchase(key))

func _refresh() -> void:
    fuel_amount.text = "%d / %d" % [int(ceil(world.fuel)), int(world.max_fuel())]
    fuel_bar.max_value = world.max_fuel()
    fuel_bar.value = world.fuel
    wallet_text.text = "%d C" % world.credits
    best_text.text = "%d" % int(floor(world.best_range))
    distance_text.text = "%d" % roundi(world.position_xy.length())
    found_text.text = "%d" % maxi(0, world.discovered.size() - 1)
    event_text.text = "%d / %d" % [world.events_done, world.battles]
    auto_button.set_pressed_no_signal(world.auto_forward)
    auto_button.text = "■\n自動前進" if world.auto_forward else "▶\n自動前進"
    action_button.disabled = world.nearest.is_empty()
    var ahead: Dictionary = {}
    var nearest_distance := INF
    for e in world.enemies:
        if not e["alive"]: continue
        var d := world.distance_to(e)
        if d < 95.0 and d < nearest_distance and absf(world.direction_to(e)) < PI * 0.47 * 0.45:
            nearest_distance = d; ahead = e
    if not ahead.is_empty():
        front_hint.text = "警戒：前方に赤い敵影 · %d" % roundi(nearest_distance)
    else:
        nearest_distance = INF
        for n in world.nodes:
            if n["type"] == "base" or world.visited.has(int(n["id"])): continue
            var d := world.distance_to(n)
            if d < nearest_distance and absf(world.direction_to(n)) < PI * 0.47 * 0.45:
                nearest_distance = d; ahead = n
        front_hint.text = "前方の信号 · %d" % roundi(nearest_distance) if not ahead.is_empty() and nearest_distance < 260.0 + int(world.upgrades["sensor"]) * 90.0 else "進路を選んで信号を探そう"
    for k in world.UPGRADE_KEYS:
        var lv: int = world.upgrades[k]
        var cost := world.upgrade_cost(k)
        shop_levels[k].text = {"fuel": "燃料容量", "efficiency": "航行効率", "speed": "移動速度", "sensor": "探知能力"}[k] + " Lv.%d" % lv
        shop_buttons[k].text = "%d Cで強化" % cost
        shop_buttons[k].disabled = not world.at_base() or world.credits < cost
    shop_effects["fuel"].text = "最大 %d → %d" % [int(world.max_fuel()), int(world.max_fuel()) + 30]
    shop_effects["efficiency"].text = "消費 %.3f → %.3f / 距離" % [world.fuel_cost(), world.fuel_cost() * 0.89]
    shop_effects["speed"].text = "速度 %.1f → %.1f" % [world.flight_speed(), world.flight_speed() + 5.5]
    shop_effects["sensor"].text = "探知 %d → %d" % [int(world.sense_range()), int(world.sense_range()) + 14]
    if not world.at_base(): shop_status.text = "起点から離れています。帰還すると購入できます。"
    elif world.credits < mini(world.upgrade_cost("fuel"), mini(world.upgrade_cost("efficiency"), mini(world.upgrade_cost("speed"), world.upgrade_cost("sensor")))):
        shop_status.text = "探索資金を集めると強化できます。"
    else: shop_status.text = "購入できる強化があります。"
