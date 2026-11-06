extends SceneTree
const Demo=preload("res://research/combat/CombatResearch.tscn")
var checks:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
    checks+=1
    if ok:print("PASS COMBAT_UI ",label)
    else:failed+=1;push_error("FAIL COMBAT_UI "+label)
func _init()->void:call_deferred("run")
func run()->void:
    var demo:Node=Demo.instantiate()
    root.add_child(demo)
    await process_frame
    check(demo.game.phase=="travel" and not demo.game.allow_save,"fixture is playable travel state with writes disabled")
    var fixture_count:int=0
    for key:String in demo.game.world.objects:
        if key.begins_with("combat-demo-"):fixture_count+=1
    check(fixture_count==4,"four actual Foundation enemy objects injected")
    check(demo.combat_hud!=null and demo.combat_hud.session==demo.game,"HUD and scene share the same session")
    check(demo.pattern_toggle.text.contains("ON") and demo.game.experimental_patterns,"experimental mode shows true initial state")
    demo.pattern_toggle.pressed.emit()
    check(not demo.game.experimental_patterns and demo.pattern_toggle.text.contains("OFF"),"button turns experiments off")
    demo.pattern_toggle.pressed.emit()
    check(demo.game.experimental_patterns and demo.pattern_toggle.text.contains("ON"),"button turns experiments back on")
    for i in range(20):await process_frame
    check(demo.combat_hud.cards.size()==4,"four enemy cards are instantiated from PackedScenes")
    check(demo.game.phase=="travel" and demo.game.campaign.credits==0,"no fixture reward or departure side effect")
    print("COMBAT_UI RESULT checks=%d failures=%d" % [checks,failed])
    quit(0 if failed==0 else 1)
