extends SceneTree
const Demo=preload("res://research/combat/CombatResearch.tscn")
var checks:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
    checks+=1
    if ok:print("PASS JOURNEY_UI ",label)
    else:failed+=1;push_error("FAIL JOURNEY_UI "+label)
func _init()->void:call_deferred("run")
func run()->void:
    var demo:Node=Demo.instantiate()
    root.add_child(demo)
    await process_frame
    var game:RefCounted=demo.game
    var enemy_id:String="%d:start-enemy" % game.world.sortie_id
    check(game.phase=="travel" and not game.allow_save,"journey scene uses normal exploration with save protected")
    check(game.world.objects.has(enemy_id) and not game.world.objects.has("combat-demo-heavy"),"normal starter enemy, not scripted fixture")
    check(demo.combat_hud.collapsed and not demo.combat_hud.details.visible,"normal exploration starts with compact HUD")
    demo.combat_hud.toggle_button.pressed.emit()
    check(not demo.combat_hud.collapsed and demo.combat_hud.details.visible,"HUD expands via real button")
    demo.combat_hud.toggle_button.pressed.emit()
    check(demo.combat_hud.collapsed,"HUD collapses via real button")
    check(demo.combat_hud.panel_bottom_for_height(540.0)<400.0,"compact HUD fits 540p vertical bounds")
    demo.held["forward"]=true
    var first:Vector2=game.position
    for i in range(25):await physics_frame
    demo.held["forward"]=false
    check(game.position.distance_to(first)>0.1,"UI held-forward control drives actual Foundation movement")
    check(game.phase=="travel" and not game.save_game(),"journey cannot overwrite normal save")
    print("JOURNEY_UI RESULT checks=%d failures=%d" % [checks,failed])
    quit(0 if failed==0 else 1)
