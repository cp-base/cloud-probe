extends Control
# Research-only responsive layout controller. No Session state or gameplay logic.
const BREAKPOINT_W:float = 850.0
const BREAKPOINT_H:float = 650.0
const TINY_W:float = 700.0
const TINY_H:float = 530.0
var layout_mode:String = ""

func _ready()->void:
    resized.connect(_apply_layout)
    _apply_layout()

func _apply_layout()->void:
    if size.x<=0.0 or size.y<=0.0:
        return
    var narrow:bool=size.x<BREAKPOINT_W or size.y<BREAKPOINT_H
    var tiny:bool=size.x<TINY_W or size.y<TINY_H
    layout_mode="tiny" if tiny else ("compact" if narrow else "wide")
    var top:PanelContainer=$TopPanel
    var bottom:PanelContainer=$BottomPanel
    var map_panel:PanelContainer=$MapPanel
    var heading:Label=$TopPanel/Content/Heading
    var keys:Label=$BottomPanel/Content/Keys
    var hint:Label=$BottomPanel/Content/Hint
    var status_label:Label=$TopPanel/Content/Status
    top.offset_bottom=170.0 if tiny else (151.0 if narrow else 126.0)
    bottom.offset_top=-210.0 if tiny else (-192.0 if narrow else -204.0)
    bottom.offset_bottom=-10.0 if narrow else -14.0
    map_panel.visible=not narrow
    heading.visible=not tiny
    keys.visible=not tiny
    hint.visible=not narrow
    status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    status_label.clip_text=true
    $BottomPanel/Content/Notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
