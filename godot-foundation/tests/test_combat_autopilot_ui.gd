extends SceneTree
const Demo=preload("res://research/combat/CombatResearch.tscn")
var checks:int=0
var failures:int=0
func check(ok:bool,label:String)->void:
    checks+=1
    if ok:print("PASS MODE_UI ",label)
    else:failures+=1;push_error("FAIL MODE_UI "+label)
func _init()->void:call_deferred("run")
func run()->void:
    var demo:Node=Demo.instantiate();root.add_child(demo)
    await process_frame
    check(demo.movement_select!=null and demo.movement_select.item_count==3,"one explicit three-choice movement selector")
    check(demo.movement_mode=="manual" and not demo.auto_forward and not demo.game.auto_battle_enabled,"startup defaults to manual navigation")
    check(not demo.auto_button.visible,"old dual-toggle UI hidden without changing Foundation code")
    check(demo.pattern_toggle.position.y>=140.0 and demo.movement_select.position.y>demo.pattern_toggle.position.y+40.0,"movement selectors do not overlap Foundation top buttons or each other")
    check(demo.movement_select.position.x>=370.0 and demo.movement_select.position.x+demo.movement_select.size.x<658.0,"movement selector clears combat side panel and 838px minimap")

    check(demo.game.phase=="travel" and not demo.game.allow_save,"natural journey no-save fixture")
    demo.movement_select.item_selected.emit(1)
    check(demo.movement_mode=="cruise" and demo.auto_forward and not demo.game.auto_battle_enabled,"choice cruise enables auto-forward without target pursuit")
    check(demo.movement_select.selected==1 and demo.auto_button.button_pressed,"selector and inherited controls stay synchronized in cruise")
    for i in range(6):await physics_frame
    check(demo.game.auto_explore_requested and demo.game.autopilot.mode=="explore","cruise uses ordinary movement without enemy autopilot")
    demo.movement_select.item_selected.emit(2)
    check(demo.movement_mode=="battle" and demo.auto_forward and demo.game.auto_battle_enabled,"choice battle enables auto-forward plus target pursuit")
    check(demo.movement_select.selected==2,"selector shows battle")
    var game:RefCounted=demo.game
    var enemy:Dictionary={}
    for i in range(800):
        if game.phase!="travel":break
        game.auto_explore_requested=true
        game.tick(0.05,1.0,0.0)
        if game.autopilot.mode=="battle":break
    check(game.autopilot.mode=="battle","real naturally generated enemy enters automatic combat")
    var completed_before:int=game.autopilot.completed_count
    demo.movement_select.item_selected.emit(1)
    check(demo.movement_mode=="cruise" and game.autopilot.mode=="explore" and not game.auto_battle_enabled,"switching battle to cruise immediately releases target")
    for i in range(4):
        game.auto_explore_requested=true
        game.tick(0.05,1.0,0.0)
    check(game.autopilot.mode=="explore" and game.autopilot.completed_count==completed_before,"cruise does not re-acquire nearby target")
    demo.movement_select.item_selected.emit(2)
    game.auto_explore_requested=true
    game.tick(0.05,1.0,0.0)
    check(game.autopilot.mode=="battle","switching cruise to battle immediately re-acquires nearby enemy")
    demo.movement_select.item_selected.emit(0)
    check(demo.movement_mode=="manual" and not demo.auto_forward and game.autopilot.mode=="explore","switching battle to manual cancels target and automatic movement")
    check(demo.movement_select.selected==0 and not demo.auto_button.button_pressed,"selector and inherited controls stay synchronized in manual")
    demo.movement_select.item_selected.emit(2)
    demo._stop_auto()
    check(demo.movement_mode=="manual" and demo.movement_select.selected==0,"reverse/stop common handler returns selector to manual")
    check(not game.save_game(),"movement-mode study cannot overwrite normal save")
    print("MODE_UI SUMMARY checks=%d failures=%d" % [checks,failures])
    quit(0 if failures==0 else 1)
