extends PanelContainer
# UI-only modal margins and title size; dynamic Foundation tab contents are unchanged.
func _ready()->void:
    resized.connect(_adapt)
    _adapt()

func _adapt()->void:
    var view_size:Vector2=get_viewport_rect().size
    var compact:bool=view_size.x<850.0 or view_size.y<650.0
    offset_left=10.0 if compact else 22.0
    offset_right=-10.0 if compact else -22.0
    offset_top=10.0 if compact else 23.0
    offset_bottom=-10.0 if compact else -23.0
    var heading:Label=$Body/Header/Title
    heading.add_theme_font_size_override("font_size",19 if compact else 23)
    heading.clip_text=true
    ($Body/Header/Close as Button).custom_minimum_size=Vector2(84,38) if compact else Vector2(98,38)
