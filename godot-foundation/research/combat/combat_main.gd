extends "res://ui/main.gd"
const ResearchSession=preload("res://research/combat/combat_session.gd")
const CombatHUD=preload("res://research/combat/combat_hud.gd")
var combat_hud:CanvasLayer
var pattern_toggle:Button
var movement_select:OptionButton
var movement_mode:String="manual"

func _ready()->void:
    get_tree().auto_accept_quit=false
    game=ResearchSession.new()
    var args:PackedStringArray=OS.get_cmdline_user_args()
    var fixture:bool="--fixture" in args
    var journey:bool="--journey" in args
    var loaded:String="fixture" if fixture else ("journey" if journey else game.load_game())
    if fixture:
        _start_fixture()
    elif journey:
        game.new_campaign(71127)
        game.depart("base")
        game.allow_save=false
        game.set_patterns_enabled("--patterns" in args)
    else:
        game.experimental_patterns="--patterns" in args
    _build_world();_build_ui();_sync_markers();_visuals(0.0)
    pattern_toggle.text="敵行動の実験：ON" if game.experimental_patterns else "敵行動の実験：OFF"
    combat_hud=CombatHUD.new();combat_hud.session=game;add_child(combat_hud)
    combat_hud.set_collapsed(not fixture)
    _set_movement_mode("battle" if "--autobattle" in args else ("cruise" if "--auto" in args else "manual"))
    if not fixture:
        if loaded=="error":_settings()
        elif game.phase=="docked":_facility(game.current_facility)
    print("COMBAT_RESEARCH_READY phase=%s fixture=%s patterns=%s move=%s" % [game.phase,fixture,game.experimental_patterns,movement_mode])

func _build_ui()->void:
    super._build_ui()
    pattern_toggle=_button("敵行動の実験：OFF",_toggle_patterns,196)
    pattern_toggle.position=Vector2(380,146)
    root.add_child(pattern_toggle)
    # The original Foundation auto-forward button stays available to inherited code,
    # but the research UI has one explicit three-way movement selector instead.
    auto_button.hide()
    movement_select=OptionButton.new()
    movement_select.position=Vector2(380,195)
    movement_select.custom_minimum_size=Vector2(220,40)
    movement_select.size=Vector2(220,40)
    movement_select.focus_mode=Control.FOCUS_NONE
    movement_select.add_item("移動：手動航行",0)
    movement_select.add_item("移動：自動航行",1)
    movement_select.add_item("移動：自動戦闘",2)
    movement_select.select(0)
    root.add_child(movement_select)
    movement_select.item_selected.connect(_select_movement_mode)

func _physics_process(dt:float)->void:
    if game!=null:
        var steering:bool=bool(held["left"]) or bool(held["right"]) or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT)
        var reverse:bool=bool(held["back"]) or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
        game.auto_explore_requested=movement_mode!="manual" and auto_forward and modal==null and not game.paused and not steering and not reverse
    super._physics_process(dt)

func _select_movement_mode(index:int)->void:
    _set_movement_mode(["manual","cruise","battle"][index])

func _set_movement_mode(value:String)->void:
    if value not in ["manual","cruise","battle"]:return
    movement_mode=value
    auto_forward=value!="manual"
    if auto_button!=null:auto_button.set_pressed_no_signal(auto_forward)
    if game!=null:
        game.set_auto_battle_enabled(value=="battle")
        game.auto_explore_requested=auto_forward and game.phase=="travel" and not game.paused and modal==null
    if movement_select!=null:
        movement_select.select(["manual","cruise","battle"].find(value))

func _stop_auto()->void:
    super._stop_auto()
    if movement_mode!="manual":_set_movement_mode("manual")

func _toggle_patterns()->void:
    game.set_patterns_enabled(not game.experimental_patterns)
    pattern_toggle.text="敵行動の実験：ON" if game.experimental_patterns else "敵行動の実験：OFF"

func _start_fixture()->void:
    game.new_campaign(71127)
    game.depart("base")
    game.world.objects.clear()
    game.allow_save=false
    game.set_patterns_enabled(true)
    var profiles:Array=["melee","artillery","fast","heavy"]
    var points:Array=[Vector2(-22,-30),Vector2(22,-52),Vector2(-36,-69),Vector2(36,-86)]
    for i in range(profiles.size()):
        var type:String=profiles[i]
        var profile:Resource=Catalog.enemy(type)
        var point:Vector2=points[i]
        game.world.objects["combat-demo-%s" % type]={"id":"combat-demo-%s" % type,"kind":"enemy","pos":point,"home":point,"alive":true,"phase":float(i),"type":type,"tier":0,"max_hp":profile.hp,"hp":profile.hp,"damage":profile.damage,"cooldown":2.0,"behavior":"patrol" if i%2==0 else "wait","patrol_heading":0.4,"patrol_leg":0}
    game.position=Vector2.ZERO;game.yaw=0.0
