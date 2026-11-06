extends "res://ui/main.gd"
const ResearchSession=preload("res://research/combat/combat_session.gd")
const CombatHUD=preload("res://research/combat/combat_hud.gd")
var combat_hud:CanvasLayer
var pattern_toggle:Button

func _ready()->void:
    get_tree().auto_accept_quit=false
    game=ResearchSession.new()
    var args:PackedStringArray=OS.get_cmdline_user_args()
    var fixture:bool="--fixture" in args
    var loaded:String="fixture" if fixture else game.load_game()
    if fixture:
        _start_fixture()
    else:
        game.experimental_patterns="--patterns" in args
    _build_world();_build_ui();_sync_markers();_visuals(0.0)
    combat_hud=CombatHUD.new();combat_hud.session=game;add_child(combat_hud)
    if not fixture:
        if loaded=="error":_settings()
        elif game.phase=="docked":_facility(game.current_facility)
    print("COMBAT_RESEARCH_READY phase=%s fixture=%s patterns=%s" % [game.phase,fixture,game.experimental_patterns])

func _build_ui()->void:
    super._build_ui()
    pattern_toggle=_button("敵行動の実験：OFF",_toggle_patterns,196)
    pattern_toggle.position=Vector2(380,112)
    root.add_child(pattern_toggle)

func _toggle_patterns()->void:
    game.experimental_patterns=not game.experimental_patterns
    pattern_toggle.text="敵行動の実験：ON" if game.experimental_patterns else "敵行動の実験：OFF"

func _start_fixture()->void:
    game.new_campaign(71127)
    game.depart("base")
    game.world.objects.clear()
    game.allow_save=false
    game.experimental_patterns=true
    var profiles:Array=["melee","artillery","fast","heavy"]
    var points:Array=[Vector2(-22,-30),Vector2(22,-52),Vector2(-36,-69),Vector2(36,-86)]
    for i in range(profiles.size()):
        var type:String=profiles[i]
        var profile:Resource=Catalog.enemy(type)
        var point:Vector2=points[i]
        game.world.objects["combat-demo-%s" % type]={"id":"combat-demo-%s" % type,"kind":"enemy","pos":point,"home":point,"alive":true,"phase":float(i),"type":type,"tier":0,"max_hp":profile.hp,"hp":profile.hp,"damage":profile.damage,"cooldown":2.0,"behavior":"patrol" if i%2==0 else "wait","patrol_heading":0.4,"patrol_leg":0}
    game.position=Vector2.ZERO;game.yaw=0.0
