extends SceneTree
const Session=preload("res://research/combat/combat_session.gd")
const Catalog=preload("res://data/catalog.gd")
var checks:int=0
var failures:int=0
func check(ok:bool,label:String)->void:
    checks+=1
    if ok:print("PASS MODE ",label)
    else:failures+=1;push_error("FAIL MODE "+label)

func make_session()->RefCounted:
    var game:RefCounted=Session.new()
    game.new_campaign(71127)
    game.depart("base")
    game.world.objects.clear()
    game.position=Vector2.ZERO;game.yaw=0.0
    return game

func add_enemy(s:RefCounted)->Dictionary:
    var p:Resource=Catalog.enemy("fast")
    var e:Dictionary={"id":"mode-enemy","kind":"enemy","pos":Vector2(0,-27),"home":Vector2(0,-27),"alive":true,"phase":0.0,"type":"fast","tier":0,"max_hp":p.hp,"hp":p.hp,"damage":p.damage,"cooldown":999.0,"behavior":"wait","patrol_heading":0.0,"patrol_leg":0}
    s.world.objects[e["id"]]=e
    return e

func attack_is_always_automatic(mode:String)->Dictionary:
    var s:RefCounted=make_session()
    var e:Dictionary=add_enemy(s)
    s.set_auto_battle_enabled(mode=="battle")
    s.auto_explore_requested=mode!="manual"
    var forward:float=0.0 if mode=="manual" else 1.0
    s.tick(0.05,forward,0.0)
    var attacked:bool=s.attack_mode!=" " and s.attack_mode!="" and (s.projectiles.size()>0 or float(e["hp"])<float(e["max_hp"]))
    check(attacked,"automatic weapons still fire in "+mode)
    check(s.attack_mode=="砲撃" or s.attack_mode=="近接","Foundation chose ordinary weapon in "+mode)
    check(mode=="battle" or s.autopilot.mode=="explore","no enemy pursuit in "+mode)
    return {"mode":mode,"attack":s.attack_mode,"shots":s.projectiles.size(),"targeted":s.autopilot.target_id}

func run_cruise_without_pursuit()->void:
    var a:RefCounted=make_session()
    var b:RefCounted=make_session()
    var ea:Dictionary=add_enemy(a)
    var eb:Dictionary=add_enemy(b)
    ea["pos"]=Vector2(60,-70);ea["home"]=ea["pos"]
    eb["pos"]=Vector2(60,-70);eb["home"]=eb["pos"]
    a.set_auto_battle_enabled(false);a.auto_explore_requested=true
    b.set_auto_battle_enabled(true);b.auto_explore_requested=true
    for i in range(36):
        a.tick(0.05,1.0,0.0);b.tick(0.05,1.0,0.0)
    check(a.autopilot.encounter_count==0,"straight auto cruise never invokes pursuit")
    check(absf(a.yaw)<0.001,"straight auto cruise retains heading")
    check(a.position.distance_to(b.position)>0.1 or b.autopilot.encounter_count>0,"auto-battle differs from cruise by enemy acquisition")
    check(b.autopilot.encounter_count>0 and b.autopilot.mode=="battle","auto-battle captures nearby offset enemy")

func _init()->void:call_deferred("run")
func run()->void:
    var records:Array=[]
    for mode in ["manual","cruise","battle"]:
        records.append(attack_is_always_automatic(mode))
    run_cruise_without_pursuit()
    var report:Dictionary={"checks":checks,"failures":failures,"modes":records}
    var path:="res://tests/.state/combat-movement-modes-result.json"
    var file:=FileAccess.open(path,FileAccess.WRITE)
    if file!=null:file.store_string(JSON.stringify(report,"  "));file.close()
    print("MODE SUMMARY "+JSON.stringify(report))
    quit(0 if failures==0 else 1)
