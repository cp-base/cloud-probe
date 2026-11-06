extends SceneTree
# One-shot display inspection using the real game scene. Does not write campaign progress.
const Main=preload("res://Main.tscn")
const Catalog=preload("res://data/catalog.gd")
func _init()->void:call_deferred("run")
func run()->void:
    var main:Node3D=Main.instantiate();root.add_child(main)
    main.game.allow_save=false;main._clear_modal();main.modal_kind=""
    main.game.phase="travel";main.game.paused=true;main.game.position=Vector2.ZERO;main.game.yaw=0
    main.game.world.objects.clear();main.game.projectiles.clear()
    var behavior_view:bool="--patrol" in OS.get_cmdline_user_args()
    for i in range(2 if behavior_view else 4):
        var profile:Resource=Catalog.ENEMIES[i*2 if behavior_view else i]
        var point:=Vector2(-65+i*130,-125) if behavior_view else Vector2(-18+i*12,-35)
        var id:String="fixture-%d" % i
        main.game.world.objects[id]={"id":id,"kind":"enemy","pos":point,"home":point,"alive":true,"phase":0.0,"type":profile.id,"tier":0,"hp":profile.hp,"max_hp":profile.hp,"damage":profile.damage,"cooldown":0.5}
        main.game.world.objects[id].merge({"behavior":"patrol" if i%2==1 else "wait","patrol_heading":0.0,"patrol_leg":0})
    main.game.message="検査用の配置です。進行は保存しません。Spaceで戦闘を進められます。"
    main._sync_markers();main._visuals(0)
    DisplayServer.window_set_title("CLOUD PROBE - Validation fixture")
    print("VISUAL_FIXTURE_READY: injected wait/patrol pair; save disabled" if behavior_view else "VISUAL_FIXTURE_READY: injected four enemy types; save disabled")
    if behavior_view:print("BEHAVIOR_VIEW: waiting melee on left, patrolling fast on right; both outside detection")
