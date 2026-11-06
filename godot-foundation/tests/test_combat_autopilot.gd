extends SceneTree
const Session=preload("res://research/combat/combat_session.gd")
const Catalog=preload("res://data/catalog.gd")
var checks:int=0
var failures:int=0
func check(ok:bool,label:String)->void:
    checks+=1
    if ok:print("PASS AUTO ",label)
    else:failures+=1;push_error("FAIL AUTO "+label)

func cruise(seed:int,enabled:bool)->Dictionary:
    var s:RefCounted=Session.new();s.new_campaign(seed)
    check(s.depart("base"),"depart seed=%d enabled=%s" % [seed,enabled])
    s.set_auto_battle_enabled(enabled)
    s.auto_explore_requested=true
    var id:String="%d:start-enemy" % s.world.sortie_id
    var enemy:Dictionary=s.world.objects.get(id,{})
    check(not enemy.is_empty(),"naturally generated encounter exists seed=%d" % seed)
    if enemy.is_empty():return {}
    var start_heading:float=s.yaw
    var nearest:float=INF
    var battle_frames:int=0
    var resumed:bool=false
    var route_after:float=0.0
    var enemy_killed:bool=false
    var movement_after:Vector2=Vector2.ZERO
    var mode_history:Dictionary={"explore":0,"battle":0,"resume":0}
    for step in range(2100):
        if s.phase!="travel":break
        s.tick(0.05,1.0,0.0)
        nearest=minf(nearest,s.position.distance_to(enemy["pos"]))
        mode_history[s.autopilot.mode]=int(mode_history.get(s.autopilot.mode,0))+1
        if s.autopilot.mode=="battle":battle_frames+=1
        if not bool(enemy.get("alive",false)) and not enemy_killed:
            enemy_killed=true;movement_after=s.position
        if enemy_killed and s.autopilot.mode=="explore" and s.autopilot.completed_count>0:
            resumed=true;route_after=s.position.distance_to(movement_after)
            if route_after>10.0:break
    var result:Dictionary={"seed":seed,"type":enemy["type"],"enabled":enabled,"nearest":snappedf(nearest,0.01),"killed":enemy_killed,"enemy_hp":enemy["hp"],"player_hp":s.hp,"kills":s.kills,"phase":s.phase,"encounters":s.autopilot.encounter_count,"completions":s.autopilot.completed_count,"battle_frames":battle_frames,"resumed":resumed,"route_after":snappedf(route_after,0.01),"head_diff":snappedf(absf(wrapf(start_heading-s.yaw,-PI,PI)),0.001),"mode_history":mode_history}
    print("AUTO CRUISE "+JSON.stringify(result))
    if enabled:
        check(s.autopilot.encounter_count>0,"auto navigation enters combat mode seed=%d" % seed)
        check(battle_frames>0,"auto navigation spends frames in battle seed=%d" % seed)
    else:
        check(s.autopilot.encounter_count==0,"baseline auto-forward never switches mode seed=%d" % seed)
    if enabled and enemy_killed and s.phase=="travel":
        check(s.autopilot.completed_count>0 and resumed,"auto combat completes and restores exploration seed=%d" % seed)
        check(route_after>10.0,"auto exploration continues moving after victory seed=%d" % seed)
    return result

func _init()->void:call_deferred("run")
func run()->void:
    var samples:Array=[]
    for seed in [71127,71129,71130,71131]:
        samples.append(cruise(seed,false))
        samples.append(cruise(seed,true))
    var synthetic:RefCounted=Session.new();synthetic.depart("base");synthetic.world.objects.clear()
    var near_profile:Resource=Catalog.enemy("fast")
    var enemy:Dictionary={"id":"synthetic-fast","kind":"enemy","pos":Vector2(0,-45),"home":Vector2(0,-45),"alive":true,"phase":0.0,"type":"fast","tier":0,"max_hp":near_profile.hp,"hp":near_profile.hp,"damage":near_profile.damage,"cooldown":1.0,"behavior":"wait","patrol_heading":0.0,"patrol_leg":0}
    synthetic.world.objects[enemy["id"]]=enemy
    synthetic.set_auto_battle_enabled(true)
    synthetic.auto_explore_requested=true
    synthetic.tick(0.05,1,0)
    check(synthetic.autopilot.mode=="battle" and synthetic.autopilot.target_id=="synthetic-fast","acquire known close target")
    synthetic.auto_explore_requested=false
    synthetic.tick(0.05,0,0)
    check(synthetic.autopilot.mode=="explore" and synthetic.autopilot.cancelled_count==1,"manual override cancels auto battle")
    synthetic.auto_explore_requested=true
    synthetic.tick(0.05,1,0)
    synthetic.set_auto_battle_enabled(false)
    check(synthetic.autopilot.mode=="explore" and not synthetic.auto_battle_enabled,"disabling toggle clears battle")
    synthetic.set_auto_battle_enabled(true)
    synthetic.auto_explore_requested=true
    synthetic.tick(0.05,1,0)
    enemy["alive"]=false
    synthetic.tick(0.05,1,0)
    check(synthetic.autopilot.completed_count>0 and synthetic.autopilot.mode!="battle","defeating target ends battle phase")
    var data:Dictionary={"checks":checks,"failures":failures,"samples":samples}
    var path:="res://tests/.state/combat-auto-result.json"
    var f:=FileAccess.open(path,FileAccess.WRITE)
    if f!=null:f.store_string(JSON.stringify(data,"  "));f.close()
    print("AUTO SUMMARY "+JSON.stringify(data))
    quit(0 if failures==0 else 1)
