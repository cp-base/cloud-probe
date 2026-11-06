extends CanvasLayer
const Readout=preload("res://research/combat/combat_readout.gd")
const Card=preload("res://research/combat/enemy_card.tscn")
var session:RefCounted
var title:Label
var weapon:Label
var threat:Label
var feedback:Label
var entries:VBoxContainer
var cards:Dictionary={}
var previous_hp:float=-1.0
var elapsed:float=0.0
var feedback_tween:Tween

func _ready()->void:
    layer=15
    var layer_root:=Control.new();add_child(layer_root)
    layer_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var side:=PanelContainer.new();layer_root.add_child(side)
    side.anchor_left=0.0;side.anchor_right=0.0
    side.offset_left=14;side.offset_right=360;side.offset_top=115;side.offset_bottom=562
    var style:=StyleBoxFlat.new();style.bg_color=Color(0.025,0.08,0.13,0.9)
    style.border_color=Color("456b81");style.set_border_width_all(1)
    style.set_content_margin_all(12)
    side.add_theme_stylebox_override("panel",style)
    side.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var stack:=VBoxContainer.new();side.add_child(stack)
    title=Label.new();title.text="戦闘観測 | Combat Lab";title.add_theme_font_size_override("font_size",19);stack.add_child(title)
    weapon=Label.new();weapon.add_theme_font_size_override("font_size",14);stack.add_child(weapon)
    threat=Label.new();threat.add_theme_font_size_override("font_size",15);stack.add_child(threat)
    stack.add_child(HSeparator.new())
    entries=VBoxContainer.new();stack.add_child(entries)
    feedback=Label.new();feedback.position=Vector2(375,115)
    feedback.add_theme_font_size_override("font_size",28)
    feedback.modulate=Color("ff8194");layer_root.add_child(feedback)

func _process(dt:float)->void:
    if session==null:return
    elapsed+=dt
    if previous_hp>=0.0 and session.hp<previous_hp:
        _damage_feedback(previous_hp-session.hp)
    previous_hp=session.hp
    if elapsed<0.12:return
    elapsed=0.0
    var equip:Dictionary=Readout.weapon_state(session)
    weapon.text="砲 %s  %.0f/%.0f\n近 %s  %.0f/%.0f\n発動 %s  待機 %.1fs" % [equip["ranged"],equip["ranged_reach"],equip["ranged_damage"],equip["melee"],equip["melee_reach"],equip["melee_damage"],equip["mode"] if equip["mode"]!="" else "射程外",equip["cooldown"]]
    var nearby:Array[Dictionary]=Readout.nearest(session)
    var highest:int=0
    for item:Dictionary in nearby:highest=maxi(highest,int(item["danger"]))
    threat.text="敵反応 %d　危険度 %s" % [nearby.size(),["安全","探知","射程内","警戒！"][highest]]
    threat.modulate=Color("ff8494") if highest>=3 else Color("ffdeb4") if highest==2 else Color("bce8f0")
    var active:Dictionary={}
    for item:Dictionary in nearby.slice(0,5):
        var key:String=item["id"];active[key]=true
        if not cards.has(key):
            cards[key]=Card.instantiate();entries.add_child(cards[key])
        cards[key].set_data(item)
    for key:String in cards.keys():
        if not active.has(key):cards[key].queue_free();cards.erase(key)

func _damage_feedback(amount:float)->void:
    if feedback_tween!=null:feedback_tween.kill()
    feedback.text="被弾 −%.0f" % amount
    feedback.position=Vector2(375,115)
    feedback.modulate.a=1.0
    feedback_tween=create_tween().set_parallel(true)
    feedback_tween.tween_property(feedback,"position:y",75.0,0.65)
    feedback_tween.tween_property(feedback,"modulate:a",0.0,0.65)
