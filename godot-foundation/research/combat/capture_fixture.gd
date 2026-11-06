extends SceneTree
func _init()->void:call_deferred("capture")
func capture()->void:
    var demo:PackedScene=load("res://research/combat/CombatResearch.tscn")
    var node:Node=demo.instantiate()
    root.add_child(node)
    for i in range(30):await process_frame
    var img:Image=root.get_viewport().get_texture().get_image()
    var output:="res://research/combat/evidence/fixture.png"
    var full:=ProjectSettings.globalize_path(output)
    DirAccess.make_dir_recursive_absolute(full.get_base_dir())
    var result:int=img.save_png(full)
    print("COMBAT_CAPTURE result=%d size=%dx%d path=%s" % [result,img.get_width(),img.get_height(),output])
    quit(0 if result==OK and img.get_width()>100 else 1)
