extends SceneTree
# UI scene preview; sample labels, not a gameplay save or live scene.
const HUD=preload("res://ui/layouts/hud.tscn")
const MODAL=preload("res://ui/layouts/modal_shell.tscn")
const THEME=preload("res://ui/theme/cloud_probe_theme.tres")

func _init()->void:call_deferred("run")

func make_view(width:int,height:int)->SubViewport:
    var view:=SubViewport.new()
    view.name="Preview%d" % width
    view.size=Vector2i(width,height)
    view.disable_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    view.transparent_bg=false
    root.add_child(view)
    var bg:=ColorRect.new()
    bg.color=Color("071722")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    view.add_child(bg)
    return view

func sample_hud(view:SubViewport)->CanvasLayer:
    var hud:CanvasLayer=HUD.instantiate()
    view.add_child(hud)
    var frame:Control=hud.get_node("Frame")
    frame.theme=THEME
    frame.get_node("TopPanel/Content/Status").text="航行中　資金 12 C　最深 306 / 10000　速度 6.0"
    frame.get_node("BottomPanel/Content/Meters/Fuel").max_value=100
    frame.get_node("BottomPanel/Content/Meters/Fuel").value=62
    frame.get_node("BottomPanel/Content/Meters/HP").max_value=45
    frame.get_node("BottomPanel/Content/Meters/HP").value=38
    frame.get_node("BottomPanel/Content/Meters/Resources").text="回収 2　撃破 1　砲撃"
    frame.get_node("BottomPanel/Content/Notice").text="近くの信号を調べられます。"
    return hud

func capture(view:SubViewport,outfile:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:Image=view.get_texture().get_image()
    var err:Error=img.save_png(outfile)
    print("CAPTURE ",outfile," size=",img.get_size()," error=",err)

func run()->void:
    var view:=make_view(1180,760)
    var hud:=sample_hud(view)
    await capture(view,"res://research/ui/evidence/hud-1180.png")
    var frame:Control=hud.get_node("Frame")
    var modal:PanelContainer=MODAL.instantiate()
    modal.theme=THEME
    frame.add_child(modal)
    modal.get_node("Body/Header/Title").text="出発施設 / 準備・施設"
    var body:VBoxContainer=modal.get_node("Body")
    var summary:=Label.new();summary.text="資金 12 C　積載 1/4　燃料 62/100　耐久 38/45";body.add_child(summary)
    var tabs:=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(tabs)
    for tab_title:String in ["準備・施設","改修","装備","交易","調査派遣"]:
        var scroll:=ScrollContainer.new();scroll.name=tab_title;tabs.add_child(scroll)
    var page:=VBoxContainer.new();tabs.get_child(0).add_child(page)
    var label:=Label.new();label.text="この施設の機能：補給・改修・装備・交易・派遣・出発登録";page.add_child(label)
    var depart:=Button.new();depart.text="選んだ施設から出発";depart.custom_minimum_size=Vector2(310,43);page.add_child(depart)
    await capture(view,"res://research/ui/evidence/modal-1180.png")
    view.queue_free()
    await process_frame
    var small:=make_view(800,600)
    sample_hud(small)
    await capture(small,"res://research/ui/evidence/hud-800.png")
    small.queue_free()
    await process_frame
    quit()
