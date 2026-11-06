extends SceneTree
const Demo=preload("res://research/combat/CombatResearch.tscn")
func _init()->void:call_deferred("capture")
func capture()->void:
    var demo:Node=Demo.instantiate();root.add_child(demo)
    demo.set_physics_process(false)
    var s:RefCounted=demo.game
    if s.allow_save or not s.auto_battle_enabled:
        push_error("Use -- --journey --autobattle");quit(1);return
    s.auto_explore_requested=true
    var entered:bool=false
    var close:float=INF
    for i in range(1500):
        if s.phase!="travel":break
        s.tick(0.05,1.0,0.0)
        if s.autopilot.mode=="battle":
            entered=true
            var target:Dictionary=s.world.objects.get(s.autopilot.target_id,{})
            if not target.is_empty():close=minf(close,s.position.distance_to(target["pos"]))
            if close<37.0:break
    demo._sync_markers();demo._visuals(0.0)
    for i in range(20):await process_frame
    var path:="res://research/combat/evidence/autobattle.png"
    var dest:String=ProjectSettings.globalize_path(path)
    DirAccess.make_dir_recursive_absolute(dest.get_base_dir())
    var img:Image=root.get_viewport().get_texture().get_image()
    var code:int=img.save_png(dest)
    print("AUTO_CAPTURE result=%d size=%dx%d entered=%s mode=%s closest=%.2f file=%s" % [code,img.get_width(),img.get_height(),entered,s.autopilot_mode,close,path])
    quit(0 if code==OK and entered and close<60.0 else 1)
