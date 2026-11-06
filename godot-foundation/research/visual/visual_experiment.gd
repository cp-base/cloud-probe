extends "res://ui/main.gd"
## Research-only launch scene that subclasses Foundation without editing ui/main.gd.
const VisualOverlay = preload("res://research/visual/visual_overlay.gd")
var visual_overlay: Node3D

func _ready() -> void:
    super._ready()
    # Allow viewing/reproducing experiments without writing .local/campaign.json.
    game.allow_save = false
    visual_overlay = VisualOverlay.new()
    visual_overlay.name = "VisualOverlay"
    add_child(visual_overlay)
    visual_overlay.install(self)
    print("VISUAL_EXPERIMENT_READY: launch via research/visual/VisualExperiment.tscn; game saving disabled")

func _physics_process(dt: float) -> void:
    super._physics_process(dt)
    if visual_overlay != null:
        visual_overlay.sync(self, dt)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and visual_overlay != null:
        if event.keycode == KEY_V:
            visual_overlay.next_mode()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_P:
            visual_overlay.toggle_bursts()
            get_viewport().set_input_as_handled()
