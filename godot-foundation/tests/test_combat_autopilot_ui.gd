extends SceneTree
const Demo=preload("res://research/combat/CombatResearch.tscn")
var checks:int=0
var failures:int=0
func check(ok:bool,label:String)->void:
    checks+=1
    if ok:print("PASS AUTO_UI ",label)
    else:failures+=1;push_error("FAIL AUTO_UI "+label)
func _init()->void:call_deferred("run")
func run()->void:
    var demo:Node=Demo.instantiate();root.add_child(demo)
    await process_frame
    check(demo.auto_battle_toggle!=null and not demo.game.auto_battle_enabled,"UI auto-battle toggle defaults OFF")
    demo.auto_battle_toggle.pressed.emit()
    check(demo.game.auto_battle_enabled and demo.auto_battle_toggle.text.contains("ON"),"UI enables optional auto battle")
    demo.auto_battle_toggle.pressed.emit()
    check(not demo.game.auto_battle_enabled and demo.auto_battle_toggle.text.contains("OFF"),"UI disables auto battle")
    check(not demo.game.auto_explore_requested,"autobattle only engages during auto-forward")
    demo.game.set_auto_battle_enabled(true)
    demo.auto_forward=true;demo.auto_button.set_pressed_no_signal(true)
    for i in range(6):await physics_frame
    check(demo.game.auto_explore_requested,"real UI auto-forward requests battle controller")
    demo._stop_auto()
    for i in range(3):await physics_frame
    check(not demo.game.auto_explore_requested,"stop auto-forward releases battle controller")
    check(not demo.game.save_game(),"journey mode still blocks save overwrites")
    print("AUTO_UI SUMMARY checks=%d failures=%d" % [checks,failures])
    quit(0 if failures==0 else 1)
