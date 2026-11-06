extends SceneTree
const HUD=preload("res://ui/layouts/hud.tscn")
const MODAL=preload("res://ui/layouts/modal_shell.tscn")
var checks:int=0
var failures:int=0
func check(value:bool,name:String)->void:
    checks+=1
    if value:print("PASS UI_COMPACT ",name)
    else:failures+=1;push_error("FAIL UI_COMPACT "+name)
func _init()->void:call_deferred("run")
func run()->void:
    for resolution:Vector2i in [Vector2i(640,480),Vector2i(800,600),Vector2i(1180,760),Vector2i(1920,1080)]:
        var view:=SubViewport.new()
        view.size=resolution
        view.disable_3d=true
        root.add_child(view)
        var scene:CanvasLayer=HUD.instantiate()
        view.add_child(scene)
        await process_frame
        await process_frame
        var frame:Control=scene.get_node("Frame")
        frame._apply_layout()
        await process_frame
        var top:Control=frame.get_node("TopPanel")
        var bottom:Control=frame.get_node("BottomPanel")
        var map:Control=frame.get_node("MapPanel")
        var rect:Rect2=frame.get_global_rect()
        var tr:Rect2=top.get_global_rect()
        var br:Rect2=bottom.get_global_rect()
        var compact:bool=resolution.x<850 or resolution.y<650
        var tiny:bool=resolution.x<700 or resolution.y<530
        check(frame.ui_size_mode==("tiny" if tiny else ("compact" if compact else "wide")),"%s breakpoint mode" % resolution)
        check(rect.size.is_equal_approx(Vector2(resolution)),"%s full viewport anchoring" % resolution)
        check(tr.position.x>=-1.0 and tr.end.x<=float(resolution.x)+1.0,"%s header horizontal bounds" % resolution)
        check(br.position.x>=-1.0 and br.end.x<=float(resolution.x)+1.0,"%s footer horizontal bounds" % resolution)
        check(tr.end.y<br.position.y,"%s no header/footer overlap" % resolution)
        check(map.visible==not compact,"%s mini-map compact visibility" % resolution)
        check(frame.get_node("TopPanel/Content/Heading").visible==not tiny,"%s title visibility" % resolution)
        check(frame.get_node("BottomPanel/Content/Hint").visible==not compact,"%s helper text visibility" % resolution)
        var actions:Control=frame.get_node("TopPanel/Content/Actions")
        check(actions is HFlowContainer and actions.get_child_count()==5,"%s 5 header actions remain" % resolution)
        var buttons:Control=frame.get_node("BottomPanel/Content/Controls")
        check(buttons is HFlowContainer and buttons.get_child_count()==5,"%s 5 movement actions remain" % resolution)
        check(buttons.get_rect().size.y>=39.0,"%s movement button height" % resolution)
        print("UI_COMPACT_LAYOUT ",resolution," mode=",frame.ui_size_mode," top=",tr," bottom=",br," controls=",buttons.get_rect())
        view.queue_free()
        await process_frame
    var compact_view:=SubViewport.new()
    compact_view.size=Vector2i(640,480)
    root.add_child(compact_view)
    var modal:PanelContainer=MODAL.instantiate()
    compact_view.add_child(modal)
    await process_frame
    check(modal.offset_left==10.0 and modal.offset_right==-10.0,"modal narrow width margins")
    check(modal.get_node("Body/Header/Close") is Button,"modal close remains a Button")
    var tab:=TabContainer.new()
    tab.size_flags_vertical=Control.SIZE_EXPAND_FILL
    modal.get_node("Body").add_child(tab)
    for label:String in ["準備・施設","改修","装備","交易","調査派遣"]:
        var item:=ScrollContainer.new()
        item.name=label
        tab.add_child(item)
    await process_frame
    check(tab.get_tab_count()==5,"facility menu retains five tabs")
    compact_view.queue_free()
    await process_frame
    print("UI_COMPACT_RESULT checks=%d failures=%d" % [checks,failures])
    quit(0 if failures==0 else 1)
