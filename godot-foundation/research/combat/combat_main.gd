extends "res://ui/main.gd"
const ResearchSession=preload("res://research/combat/combat_session.gd")
const CombatHUD=preload("res://research/combat/combat_hud.gd")
var combat_hud:CanvasLayer
var pattern_toggle:Button
var auto_battle_toggle:Button

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
    if journey and "--auto" in args:
        auto_forward=true;auto_button.set_pressed_no_signal(true)
    if "--autobattle" in args:
        game.set_auto_battle_enabled(true)
        auto_battle_toggle.text="自動交戦：ON"
    if not fixture:
        if loaded=="error":_settings()
        elif game.phase=="docked":_facility(game.current_facility)
    print("COMBAT_RESEARCH_READY phase=%s fixture=%s patterns=%s" % [game.phase,fixture,game.experimental_patterns])

func _build_ui()->void:
    super._build_ui()
    pattern_toggle=_button("敵行動の実験：OFF",_toggle_patterns,196)
    pattern_toggle.position=Vector2(380,112)
    root.add_child(pattern_toggle)
    auto_battle_toggle=_button("自動交戦：OFF",_toggle_autobattle,170)
    auto_battle_toggle.position=Vector2(595,112)
    root.add_child(auto_battle_toggle)

func _physics_process(dt:float)->void:
    if game!=null:
        var steering:bool=bool(held["left"]) or bool(held["right"]) or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT)
        var reverse:bool=bool(held["back"]) or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
        game.auto_explore_requested=auto_forward and modal==null and not steering and not reverse
    super._physics_process(dt)

func _toggle_autobattle()->void:
    game.set_auto_battle_enabled(not game.auto_battle_enabled)
    auto_battle_toggle.text="自動交戦：ON" if game.auto_battle_enabled else "自動交戦：OFF"

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
