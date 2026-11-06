extends "res://ui/main.gd"

# Research-only UI adapter. Inherits every gameplay method from Foundation.
# The baseline ui/main.gd remains intact for one-file rollback.
const HudScene:PackedScene = preload("res://ui/layouts/hud.tscn")
const ModalScene:PackedScene = preload("res://ui/layouts/modal_shell.tscn")
const UiTheme:Theme = preload("res://ui/theme/cloud_probe_theme.tres")

func _build_ui()->void:
    var layer:CanvasLayer = HudScene.instantiate()
    add_child(layer)
    root = layer.get_node("Frame") as Control
    root.theme = UiTheme
    flash = root.get_node("Flash") as ColorRect
    status = root.get_node("TopPanel/Content/Status") as Label
    guide = root.get_node("Guide") as Label
    access_button = root.get_node("TopPanel/Content/Actions/Access") as Button
    pause_button = root.get_node("TopPanel/Content/Actions/Pause") as Button
    access_button.pressed.connect(_access)
    (root.get_node("TopPanel/Content/Actions/Map") as Button).pressed.connect(_map)
    (root.get_node("TopPanel/Content/Actions/Save") as Button).pressed.connect(_save)
    pause_button.pressed.connect(_toggle_pause)
    (root.get_node("TopPanel/Content/Actions/Settings") as Button).pressed.connect(_settings)
    hp_bar = root.get_node("BottomPanel/Content/Meters/HP") as ProgressBar
    fuel_bar = root.get_node("BottomPanel/Content/Meters/Fuel") as ProgressBar
    resources_label = root.get_node("BottomPanel/Content/Meters/Resources") as Label
    notice = root.get_node("BottomPanel/Content/Notice") as Label
    mini_map = root.get_node("MapPanel/MapContent/MiniMap") as Control
    mini_map.set_script(MapView)
    mini_map.session = game
    var controls:Control = root.get_node("BottomPanel/Content/Controls")
    for pair:Array in [["Left", "left"], ["Back", "back"], ["Forward", "forward"], ["Right", "right"]]:
        var button:Button = controls.get_node(pair[0]) as Button
        button.button_down.connect(_hold.bind(pair[1], true))
        button.button_up.connect(_hold.bind(pair[1], false))
    auto_button = controls.get_node("Auto") as Button
    auto_button.toggled.connect(func(value:bool): auto_forward=value)
    for i:int in range(5):
        var label:Label = _label("",14)
        label.modulate=Color("ffa1b6")
        root.add_child(label)
        enemy_labels.append(label)
    reset_dialog = root.get_node("ResetDialog") as ConfirmationDialog
    reset_dialog.confirmed.connect(_new_campaign)

func _open_modal(title:String)->VBoxContainer:
    _stop_auto()
    game.paused=true
    _clear_modal()
    modal = ModalScene.instantiate() as PanelContainer
    root.add_child(modal)
    modal.theme = UiTheme
    var body:VBoxContainer = modal.get_node("Body") as VBoxContainer
    (modal.get_node("Body/Header/Title") as Label).text = title
    (modal.get_node("Body/Header/Close") as Button).pressed.connect(_close_modal)
    return body
