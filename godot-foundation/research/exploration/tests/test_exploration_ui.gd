extends SceneTree
const Lab=preload("res://research/exploration/ExplorationLab.tscn")
var count:int=0
var failures:int=0
func check(ok:bool,text_value:String)->void:
    count+=1
    if not ok:failures+=1
    print(("PASS" if ok else "FAIL")+" UI #"+str(count)+" "+text_value)
func _initialize()->void:call_deferred("run")
func run()->void:
    var scene:=Lab.instantiate()
    root.add_child(scene)
    await process_frame
    check(scene.world.sortie_id==1 and scene.ledger.visited.size()==1,"lab starts with Foundation world and writes visited origin")
    var buttons:=scene.get_children().filter(func(item):return item is Button)
    check(buttons.size()==9,"navigation controls are instantiated")
    var marker_before:int=scene.ledger.waypoints.size()
    var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=Vector2(530,270)
    scene._gui_input(click)
    check(scene.ledger.waypoints.size()==marker_before+1 and scene.ledger.route.size()==1,"map click adds a route waypoint")
    scene.ship_pos=Vector2(500,-500);scene.update_exploration()
    check(scene.ledger.visited.size()>=2,"moving to another area expands observed map")
    scene.wide_scan()
    check(scene.ledger.surveyed.size()>0,"scan visual state has surveyed cells")
    var before:Dictionary=scene.ledger.to_dict().duplicate(true)
    check(scene.save_state("res://.local/exploration_lab_ui_test.json"),"save button logic serializes ledger")
    scene.new_sortie()
    check(scene.world.sortie_id==2 and scene.ledger.route==before["route"],"new sortie regenerates world but preserves route")
    check(scene.load_state("res://.local/exploration_lab_ui_test.json") and scene.world.sortie_id==1 and scene.ship_pos==Vector2(500,-500),"reload restores coordinates and earlier sortie")
    root.remove_child(scene);scene.queue_free()
    print("UI RESULT ",count-failures,"/",count," failures=",failures)
    quit(0 if failures==0 else 1)
