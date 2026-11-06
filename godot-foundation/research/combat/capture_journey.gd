extends SceneTree
const Demo=preload("res://research/combat/CombatResearch.tscn")
func _init()->void:call_deferred("capture")
func capture()->void:
    var demo:Node=Demo.instantiate()
    root.add_child(demo)
    demo.set_physics_process(false)
    var game:RefCounted=demo.game
    if game.phase!="travel" or game.allow_save:
        push_error("Journey mode required; pass -- --journey")
        quit(1);return
    var enemy_id:String="%d:start-enemy" % game.world.sortie_id
    var enemy:Dictionary=game.world.objects.get(enemy_id,{})
    if enemy.is_empty():
        push_error("No naturally generated enemy")
        quit(1);return
    var closest:float=INF
    var steps:int=0
    for i in range(1000):
        if game.phase!="travel" or not bool(enemy.get("alive",false)):break
        var delta:Vector2=enemy["pos"]-game.position
        var distance:float=delta.length()
        closest=minf(closest,distance)
        if distance<53.0:break
        var yaw:float=atan2(-delta.x,-delta.y)
        var turn:float=clampf(wrapf(yaw-game.yaw,-PI,PI)*3.0,-1.0,1.0)
        game.tick(0.05,1.0,turn)
        steps+=1
        if i%25==0:await process_frame
    demo._sync_markers();demo._visuals(0.0)
    for i in range(20):await process_frame
    var img:Image=root.get_viewport().get_texture().get_image()
    var relative:="res://research/combat/evidence/journey_540p.png"
    var full:String=ProjectSettings.globalize_path(relative)
    DirAccess.make_dir_recursive_absolute(full.get_base_dir())
    var code:int=img.save_png(full)
    print("JOURNEY_CAPTURE result=%d size=%dx%d steps=%d closest=%.2f enemy=%s enemy_hp=%.0f mode=%s path=%s" % [code,img.get_width(),img.get_height(),steps,closest,enemy["type"],enemy["hp"],game.attack_mode,relative])
    demo.combat_hud.set_collapsed(false)
    for i in range(8):await process_frame
    var detailed:="res://research/combat/evidence/journey_detail_540p.png"
    var detailed_result:int=root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(detailed))
    print("JOURNEY_DETAIL_CAPTURE result=%d path=%s" % [detailed_result,detailed])
    quit(0 if code==OK and detailed_result==OK and img.get_width()>=800 and img.get_height()==540 and steps>0 and closest<60.0 else 1)
