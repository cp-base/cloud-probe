extends PanelContainer
var headline:Label
var meta:Label
var health:ProgressBar
var animation:AnimationPlayer
var danger_level:int=-1

func _ready()->void:
    custom_minimum_size=Vector2(298,68)
    var layout:=VBoxContainer.new();add_child(layout)
    headline=Label.new();layout.add_child(headline)
    meta=Label.new();meta.add_theme_font_size_override("font_size",13);layout.add_child(meta)
    health=ProgressBar.new();health.show_percentage=false;health.custom_minimum_size=Vector2(260,8);layout.add_child(health)
    animation=AnimationPlayer.new();add_child(animation)
    var library:=AnimationLibrary.new()
    var pulse:=Animation.new();pulse.length=0.55;pulse.loop_mode=Animation.LOOP_NONE
    var track:=pulse.add_track(Animation.TYPE_VALUE)
    pulse.track_set_path(track,NodePath(".:self_modulate"))
    pulse.track_insert_key(track,0.0,Color(1,1,1,1))
    pulse.track_insert_key(track,0.16,Color(1,0.48,0.52,1))
    pulse.track_insert_key(track,0.55,Color.WHITE)
    library.add_animation("warning",pulse)
    animation.add_animation_library("",library)

func set_data(data:Dictionary)->void:
    headline.text="%s   %s" % [data["title"],data["state"]]
    meta.text="%s  |  距離 %.0f / 攻撃圏 %.0f  |  HP %.0f/%.0f" % [data["behavior"],data["distance"],data["reach"],data["hp"],data["max_hp"]]
    health.max_value=maxf(1.0,data["max_hp"]);health.value=data["hp"]
    var level:int=int(data["danger"])
    if level!=danger_level and level>=2:animation.play("warning")
    danger_level=level
    headline.modulate=Color("ff8996") if level>=3 else (Color("ffcca1") if level==2 else Color("c7f0ff"))
