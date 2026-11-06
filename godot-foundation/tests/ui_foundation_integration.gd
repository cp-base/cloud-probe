extends SceneTree
# Real Foundation smoke test for the UI research branch. No progress writes intended.
const MAIN=preload("res://Main.tscn")
var checks:int=0
var failures:int=0
func check(condition:bool,title:String)->void:
    checks+=1
    if condition:print("PASS UI_INTEGRATION ",title)
    else:failures+=1;push_error("FAIL UI_INTEGRATION "+title)
func _init()->void:call_deferred("run")
func run()->void:
    var main:Node3D=MAIN.instantiate()
    root.add_child(main)
    main.set_physics_process(false)
    main.game.allow_save=false
    check(main.get_script().resource_path=="res://ui/research_ui_main.gd","Main uses research adapter")
    check(main.root.theme!=null,"shared theme attached to HUD")
    check(main.root.get_node("TopPanel/Content/Actions") is HFlowContainer,"scene-authored header actions")
    check(main.root.get_node("BottomPanel/Content/Controls") is HFlowContainer,"scene-authored movement controls")
    check(main.mini_map.session==main.game,"minimap still uses the game session")
    var forward:Button=main.root.get_node("BottomPanel/Content/Controls/Forward")
    forward.emit_signal("button_down")
    check(main.held["forward"],"button_down sets forward state")
    forward.emit_signal("button_up")
    check(not main.held["forward"],"button_up clears forward state")
    main.game.phase="docked"
    main.game.current_facility="base"
    main._facility("base")
    await process_frame
    check(main.modal!=null and main.modal.get_node("Body/Header/Title")!=null,"modal scene loads")
    var tabs:TabContainer=null
    for child:Node in main.modal.get_child(0).get_children():
        if child is TabContainer:tabs=child
    check(tabs!=null and tabs.get_tab_count()==5,"all five facility tabs remain")
    (main.modal.get_node("Body/Header/Close") as Button).emit_signal("pressed")
    await process_frame
    check(main.modal==null,"modal Close uses baseline closure")
    main._map()
    await process_frame
    check(main.modal_kind=="map" and main.game.paused,"map opens and pauses")
    main._settings()
    await process_frame
    check(main.modal_kind=="settings" and not main.game.allow_save,"settings retains protected-save state")
    print("UI_INTEGRATION_RESULT checks=%d failures=%d" % [checks,failures])
    main.queue_free();await process_frame
    quit(0 if failures==0 else 1)
