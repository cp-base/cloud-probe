extends SceneTree
const Main=preload("res://Main.tscn")
var checks:int=0
var failures:int=0
func check(value:bool,title:String)->void:
    checks+=1
    if value:print("PASS UI ",title)
    else:failures+=1;push_error("FAIL UI "+title)
func _init()->void:call_deferred("run")
func run()->void:
    var main:Node3D=Main.instantiate();root.add_child(main)
    main.set_physics_process(false)
    # No test action may write the live campaign. All following state is a fixture.
    main.game.allow_save=false
    main.game.phase="docked";main.game.current_facility="base";main.game.position=Vector2.ZERO
    main._facility("base")
    await process_frame
    var tabs:TabContainer=main.modal.find_child("*",false,false) as TabContainer
    # The container is intentionally obtained by type, independent of display names.
    for node:Node in main.modal.get_child(0).get_children():
        if node is TabContainer:tabs=node
    check(tabs!=null and tabs.get_tab_count()==5,"one facility exposes preparation, upgrades, equipment, trade and survey")
    for i in range(tabs.get_tab_count()):tabs.current_tab=i;await process_frame
    main.game.phase="travel";main.game.world.objects.clear();main.game.yaw=0
    main._target("facility_0");main._visuals(0)
    check(main.guide.text.begins_with("交易施設"),"selected map destination takes priority over light guidance")
    main._map();await process_frame
    check(main.modal_kind=="map" and main.game.paused,"map opens against same session and pauses travel")
    main.game.position=Vector2(100,100)
    main.game.world.objects["ui-signal"]={"id":"ui-signal","kind":"signal","pos":main.game.position,"home":main.game.position,"alive":true,"phase":0.0}
    main._clear_modal();main._access();await process_frame
    check(main.modal_kind=="signal" and main.modal_id=="ui-signal","signal access opens optional choices")
    main._settings();await process_frame
    check(main.modal_kind=="settings" and not main.game.allow_save,"settings can display a protected save without enabling writes")
    print("UI_RESULT checks=%d failures=%d" % [checks,failures])
    main.queue_free();await process_frame
    quit(0 if failures==0 else 1)
