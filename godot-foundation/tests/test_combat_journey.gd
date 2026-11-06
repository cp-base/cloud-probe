extends SceneTree
const Session=preload("res://research/combat/combat_session.gd")
const Readout=preload("res://research/combat/combat_readout.gd")
var checks:int=0
var failed:int=0

func check(ok:bool,title:String)->void:
    checks+=1
    if ok:print("PASS JOURNEY ",title)
    else:failed+=1;push_error("FAIL JOURNEY "+title)

func simulate(patterns:bool,seed_value:int)->Dictionary:
    var game:RefCounted=Session.new()
    game.new_campaign(seed_value)
    game.experimental_patterns=patterns
    check(game.depart("base"),"departure works patterns=%s" % patterns)
    var original_ids:Array=game.world.objects.keys()
    var enemy_id:String="%d:start-enemy" % game.world.sortie_id
    check(game.world.objects.has(enemy_id),"natural starter encounter exists patterns=%s" % patterns)
    if not game.world.objects.has(enemy_id):return {}
    var enemy:Dictionary=game.world.objects[enemy_id]
    var initial_hp:float=game.hp
    var beginning:Vector2=game.position
    var closest:float=INF
    var seen:bool=false
    var attacking:bool=false
    var exchanged:bool=false
    var incoming:bool=false
    var steps:int=0
    var first_attack_time:float=-1.0
    for i in range(1600):
        if game.phase!="travel" or not bool(enemy.get("alive",false)):break
        var delta:Vector2=enemy["pos"]-game.position
        var distance:float=delta.length()
        var target_yaw:float=atan2(-delta.x,-delta.y)
        var steering:float=clampf(wrapf(target_yaw-game.yaw,-PI,PI)*3.0,-1.0,1.0)
        game.tick(0.05,1.0 if distance>24.0 else 0.0,steering)
        steps=i+1
        closest=minf(closest,game.position.distance_to(enemy["pos"]))
        seen=seen or Readout.nearest(game).size()>0
        if game.attack_mode!="":
            attacking=true
            if first_attack_time<0.0:first_attack_time=steps*0.05
        for shot:Dictionary in game.projectiles:
            if bool(shot["hostile"]):incoming=true
        exchanged=exchanged or game.hp<initial_hp or not bool(enemy.get("alive",false)) or float(enemy["hp"])<float(enemy["max_hp"])
    check(game.position.distance_to(beginning)>50.0 or game.phase=="docked","player moved from station patterns=%s" % patterns)
    check(closest<50.0,"navigation reached natural encounter patterns=%s" % patterns)
    check(seen,"nearby enemy entered actual Session readout patterns=%s" % patterns)
    check(attacking,"base automatic weapon attack activated patterns=%s" % patterns)
    check(exchanged,"combat changed HP or dealt damage patterns=%s" % patterns)
    check(original_ids.has(enemy_id) and not game.world.objects.has("combat-demo-heavy"),"no injected fixture enemies patterns=%s" % patterns)
    var path:String="res://tests/.state/journey-%s-%s.json" % [enemy["type"],"patterns" if patterns else "baseline"]
    var saved:bool=game.save_game(path)
    var restored:RefCounted=Session.new()
    var status:String=restored.load_game(path) if saved else "error"
    check(saved and status=="ok","natural journey state saved and reloaded patterns=%s" % patterns)
    if status=="ok":
        check(restored.campaign.credits==game.campaign.credits and restored.world.objects.has(enemy_id),"credits and natural encounter persist patterns=%s" % patterns)
    return {"patterns":patterns,"seed":seed_value,"steps":steps,"closest":snappedf(closest,0.01),"first_attack_s":first_attack_time,"damage_or_hit":exchanged,"incoming":incoming,"kills":game.kills,"final_phase":game.phase,"remaining_hp":game.hp,"enemy_type":enemy["type"],"enemy_hp":enemy["hp"]}

func _init()->void:call_deferred("run")
func run()->void:
    var seed_by_type:Dictionary={}
    for seed_value in range(71127,71327):
        var probe:RefCounted=Session.new()
        probe.new_campaign(seed_value)
        if not probe.depart("base"):continue
        var start_id:String="%d:start-enemy" % probe.world.sortie_id
        var natural:Dictionary=probe.world.objects.get(start_id,{})
        if not natural.is_empty() and not seed_by_type.has(natural["type"]):
            seed_by_type[natural["type"]]=seed_value
        if seed_by_type.size()==4:break
    check(seed_by_type.size()==4,"real world generation supplied all 4 enemy types")
    var results:Array=[]
    for enemy_type in ["melee","artillery","fast","heavy"]:
        if not seed_by_type.has(enemy_type):continue
        for patterns in [false,true]:
            results.append(simulate(patterns,int(seed_by_type[enemy_type])))
    var report:Dictionary={"checks":checks,"failures":failed,"seeds":seed_by_type,"journeys":results}
    var path:="res://tests/.state/combat-journey-result.json"
    var file:=FileAccess.open(path,FileAccess.WRITE)
    if file!=null:file.store_string(JSON.stringify(report,"  "));file.close()
    print("JOURNEY SUMMARY "+JSON.stringify(report))
    quit(0 if failed==0 else 1)
