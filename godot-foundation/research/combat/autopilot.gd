extends RefCounted
# Experimental autopilot. No combat damage/dodge rules; existing Session owns combat.
# Only intercepts forward/turn when the user has enabled auto-forward exploration.
const Catalog=preload("res://data/catalog.gd")
const ENGAGE_RADIUS:float=78.0
const DISENGAGE_RADIUS:float=180.0
var mode:String="explore" # explore | battle | resume
var target_id:String=""
var resume_yaw:float=0.0
var encounter_count:int=0
var completed_count:int=0
var cancelled_count:int=0
var total_combat_time:float=0.0

func reset()->void:
    mode="explore";target_id="";resume_yaw=0.0

func cancel()->void:
    if mode!="explore":cancelled_count+=1
    reset()

func _nearest_enemy(session:RefCounted)->Dictionary:
    var nearest:Dictionary={}
    var distance:float=ENGAGE_RADIUS
    for enemy:Dictionary in session.world.active(session.position,ENGAGE_RADIUS):
        if enemy.get("kind")!="enemy":continue
        var d:float=session.position.distance_to(enemy["pos"])
        if d<distance:
            distance=d;nearest=enemy
    return nearest

func _steer(session:RefCounted,point:Vector2)->float:
    var delta:Vector2=point-session.position
    var wanted:float=atan2(-delta.x,-delta.y)
    return clampf(wrapf(wanted-session.yaw,-PI,PI)*3.0,-1.0,1.0)

func control(session:RefCounted,dt:float,forward:float,turn:float)->Dictionary:
    if mode=="battle":
        var target:Dictionary=session.world.objects.get(target_id,{})
        if target.is_empty() or not bool(target.get("alive",false)):
            completed_count+=1;target_id="";mode="resume"
        elif session.position.distance_to(target["pos"])>DISENGAGE_RADIUS:
            cancelled_count+=1;target_id="";mode="resume"
    if mode=="explore" or mode=="resume":
        var candidate:Dictionary=_nearest_enemy(session)
        if not candidate.is_empty():
            if mode=="explore":resume_yaw=session.yaw
            target_id=candidate["id"];mode="battle";encounter_count+=1
    if mode=="battle":
        var enemy:Dictionary=session.world.objects.get(target_id,{})
        if enemy.is_empty():return {"forward":0.0,"turn":0.0}
        total_combat_time+=dt
        var ranged:Resource=Catalog.weapon(session.campaign.equipped["ranged"])
        var preferred:float=maxf(12.0,minf(session.weapon_reach(ranged)*0.8,36.0))
        var distance:float=session.position.distance_to(enemy["pos"])
        var steer:float=_steer(session,enemy["pos"])
        var bearing:float=wrapf(atan2(-(enemy["pos"]-session.position).x,-(enemy["pos"]-session.position).y)-session.yaw,-PI,PI)
        var advance:float=1.0 if distance>preferred+2.0 and absf(bearing)<0.5 else 0.0
        return {"forward":advance,"turn":steer}
    if mode=="resume":
        var angle:float=wrapf(resume_yaw-session.yaw,-PI,PI)
        if absf(angle)<0.06:
            mode="explore"
            return {"forward":forward,"turn":turn}
        return {"forward":0.0,"turn":clampf(angle*3.0,-1.0,1.0)}
    return {"forward":forward,"turn":turn}
