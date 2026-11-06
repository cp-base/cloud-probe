extends SceneTree
# Mouse events through a real SubViewport, not synthetic pressed.emit_signal().
const HUD=preload("res://ui/layouts/hud.tscn")
var checks:int=0
var failures:int=0

func check(ok:bool,label:String)->void:
    checks+=1
    if ok:print("PASS UI_MOUSE ",label)
    else:failures+=1;push_error("FAIL UI_MOUSE "+label)

func _init()->void:call_deferred("run")

func _mouse(view:SubViewport,where:Vector2,down:bool)->void:
    var event:=InputEventMouseButton.new()
    event.button_index=MOUSE_BUTTON_LEFT
    event.position=where
    event.global_position=where
    event.pressed=down
    view.push_input(event,true)
    await process_frame

func run()->void:
    for size:Vector2i in [Vector2i(640,480),Vector2i(1180,760)]:
        var view:=SubViewport.new()
        view.size=size
        view.disable_3d=true
        view.handle_input_locally=true
        root.add_child(view)
        var hud:CanvasLayer=HUD.instantiate()
        view.add_child(hud)
        await process_frame
        await process_frame
        var frame:Control=hud.get_node("Frame")
        var map_button:Button=frame.get_node("TopPanel/Content/Actions/Map")
        var forward:Button=frame.get_node("BottomPanel/Content/Controls/Forward")
        var counters:={"map":0,"down":0,"up":0}
        map_button.pressed.connect(func():counters["map"]+=1)
        forward.button_down.connect(func():counters["down"]+=1)
        forward.button_up.connect(func():counters["up"]+=1)
        var bounds:Rect2=map_button.get_global_rect()
        var control_bounds:Rect2=forward.get_global_rect()
        check(bounds.has_point(bounds.get_center()) and bounds.position.x>=0 and bounds.end.x<=size.x,"%s map position valid" % size)
        check(control_bounds.position.x>=0 and control_bounds.end.x<=size.x and control_bounds.end.y<=size.y,"%s forward within screen" % size)
        await _mouse(view,bounds.get_center(),true)
        await _mouse(view,bounds.get_center(),false)
        check(counters["map"]==1,"%s real mouse click fires map" % size)
        await _mouse(view,control_bounds.get_center(),true)
        check(counters["down"]==1,"%s forward hold-down received" % size)
        await _mouse(view,control_bounds.get_center(),false)
        check(counters["up"]==1,"%s forward release received" % size)
        view.queue_free()
        await process_frame
    print("UI_MOUSE_RESULT checks=%d failures=%d" % [checks,failures])
    quit(0 if failures==0 else 1)
