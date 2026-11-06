extends SceneTree

const HUD=preload("res://ui/layouts/hud.tscn")
const MODAL=preload("res://ui/layouts/modal_shell.tscn")
const THEME=preload("res://ui/theme/cloud_probe_theme.tres")
var checks:int=0
var failures:int=0

func check(value:bool,title:String)->void:
    checks+=1
    if value:print("PASS UI_RESEARCH ",title)
    else:failures+=1;push_error("FAIL UI_RESEARCH "+title)

func _init()->void:call_deferred("run")

func run()->void:
    var hud:CanvasLayer=HUD.instantiate()
    root.add_child(hud)
    var frame:Control=hud.get_node("Frame")
    frame.theme=THEME
    await process_frame
    check(hud.layer==10 and frame.mouse_filter==Control.MOUSE_FILTER_IGNORE,"HUD scene uses CanvasLayer and transparent input root")
    check(frame.get_node("TopPanel/Content/Actions") is HFlowContainer,"header actions use wrapping HFlowContainer")
    check(frame.get_node("BottomPanel/Content/Controls") is HFlowContainer,"movement controls use wrapping HFlowContainer")
    check(frame.get_node("BottomPanel/Content/Meters") is HFlowContainer,"meters use wrapping HFlowContainer")
    var access:Button=frame.get_node("TopPanel/Content/Actions/Access")
    var called:={"count":0}
    access.pressed.connect(func():called["count"]+=1)
    access.emit_signal("pressed")
    check(called["count"]==1,"scene button is connectable and emits action")
    var modal:PanelContainer=MODAL.instantiate()
    frame.add_child(modal)
    var body:VBoxContainer=modal.get_node("Body")
    var tabs:=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
    body.add_child(tabs)
    for item:String in ["準備・施設","改修","装備","交易","調査派遣"]:
        var page:=ScrollContainer.new();page.name=item;tabs.add_child(page)
    await process_frame
    check(tabs.get_tab_count()==5,"reusable modal shell supports Foundation five-tab menu")
    check(modal.get_child(0)==body,"modal keeps existing baseline test traversal convention")
    check(frame.theme.has_stylebox("panel","PanelContainer"),"shared Theme supplies panel style")
    modal.queue_free()
    await process_frame
    for resolution:Vector2i in [Vector2i(800,600),Vector2i(1180,760),Vector2i(1920,1080)]:
        var view:=SubViewport.new()
        view.size=resolution
        view.disable_3d=true
        root.add_child(view)
        var view_hud:CanvasLayer=HUD.instantiate()
        view.add_child(view_hud)
        var test_frame:Control=view_hud.get_node("Frame")
        test_frame.theme=THEME
        await process_frame
        await process_frame
        var top:Control=test_frame.get_node("TopPanel")
        var bottom:Control=test_frame.get_node("BottomPanel")
        var map_panel:Control=test_frame.get_node("MapPanel")
        var rect:Rect2=test_frame.get_global_rect()
        var tr:Rect2=top.get_global_rect()
        var br:Rect2=bottom.get_global_rect()
        var mr:Rect2=map_panel.get_global_rect()
        check(tr.position.x>=rect.position.x-1 and tr.end.x<=rect.end.x+1 and br.end.x<=rect.end.x+1,"%dx%d horizontal HUD inside viewport" % [resolution.x,resolution.y])
        check(tr.end.y<br.position.y,"%dx%d header does not overlap bottom controls" % [resolution.x,resolution.y])
        check(mr.end.y<br.position.y,"%dx%d minimap stays clear of movement controls" % [resolution.x,resolution.y])
        var controls:Control=test_frame.get_node("BottomPanel/Content/Controls")
        check(controls.get_rect().size.y>=39.0,"%dx%d movement buttons remain visible" % [resolution.x,resolution.y])
        check(rect.size.is_equal_approx(Vector2(resolution)),"%dx%d actual viewport size is tested" % [resolution.x,resolution.y])
        print("LAYOUT ",resolution," root=",rect," top=",tr," bottom=",br," map=",mr)
        view.queue_free()
        await process_frame
    print("UI_RESEARCH_RESULT checks=%d failures=%d" % [checks,failures])
    hud.queue_free();await process_frame
    quit(0 if failures==0 else 1)
