extends SceneTree
const Session=preload("res://research/combat/combat_session.gd")
const Readout=preload("res://research/combat/combat_readout.gd")
const Catalog=preload("res://data/catalog.gd")
var checks:int=0
var failed:int=0
func check(value:bool,label:String)->void:
    checks+=1
    if value:print("PASS COMBAT ",label)
    else:failed+=1;push_error("FAIL COMBAT "+label)
func enemy_at(s:RefCounted,type:String,point:Vector2,cooldown:float=0.0)->Dictionary:
    var profile:Resource=Catalog.enemy(type)
    var enemy:Dictionary={"id":"test-%s" % type,"kind":"enemy","pos":point,"home":point,"alive":true,"phase":0.0,"type":type,"tier":0,"max_hp":profile.hp,"hp":profile.hp,"damage":profile.damage,"cooldown":cooldown,"behavior":"wait","patrol_heading":0.0,"patrol_leg":0}
    s.world.objects[enemy["id"]]=enemy
    return enemy
func _init()->void:call_deferred("run")
func run()->void:
    var s:RefCounted=Session.new();s.depart("base");s.world.objects.clear()
    var equip:Dictionary=Readout.weapon_state(s)
    check(equip["ranged"]=="標準砲" and equip["melee"]=="標準近接" and equip["ranged_reach"]>equip["melee_reach"],"existing weapons read from equipped resources")
    for type in ["melee","artillery","fast","heavy"]:
        var enemy:Dictionary=enemy_at(s,type,Vector2(0,-35),2.0)
        var result:Dictionary=Readout.enemy_state(s,enemy)
        check(result["type"]==type and result["hp"]==Catalog.enemy(type).hp and result["distance"]==35.0,"resource-driven readout "+type)
        s.world.objects.clear()
    var ranged_enemy:Dictionary=enemy_at(s,"artillery",Vector2(0,-40),2.0)
    check(Readout.enemy_state(s,ranged_enemy)["danger"]==2,"artillery warns in enemy range")
    ranged_enemy["cooldown"]=0.1
    check(Readout.enemy_state(s,ranged_enemy)["danger"]==3,"attack ready elevates danger")
    var before:float=ranged_enemy["hp"]
    s._attack(0.01)
    check(s.attack_mode=="砲撃" and s.projectiles.size()==1 and ranged_enemy["hp"]==before,"base auto fire is unchanged")
    var samples:Array[Dictionary]=Readout.nearest(s)
    check(samples.size()==1 and samples[0]["type"]=="artillery","nearby readout uses real session")
    s.world.objects.clear();s.projectiles.clear()
    var fast:Dictionary=enemy_at(s,"fast",Vector2(0,-35),3.0)
    s.experimental_patterns=true
    s._enemies(0.1)
    check(absf(float(fast["pos"].x))>0.01,"experimental fast sidestep changes lateral position")
    s.world.objects.clear()
    var heavy:Dictionary=enemy_at(s,"heavy",Vector2(0,-20),0.0)
    s._enemies(0.05)
    check(bool(heavy.get("windup",false)) and s.hp==s.max_hp() and heavy["cooldown"]>1.0,"heavy attack telegraph starts before hit")
    check(Readout.enemy_state(s,heavy)["state"]=="重装・攻撃予兆","telegraph visible to HUD")
    s._enemies(1.15)
    check(not heavy.get("windup",true) and s.projectiles.size()>0,"heavy ranged shot follows warning")
    s.world.objects.clear();s.projectiles.clear()
    s.experimental_patterns=false
    var original:Dictionary=enemy_at(s,"fast",Vector2(0,-35),3.0)
    s._enemies(0.1)
    check(absf(float(original["pos"].x))<0.001,"experimental pattern off preserves original straight chase")
    var camp_path:="res://tests/.state/combat-research.json"
    var saved:bool=s.save_game(camp_path)
    var reloaded:RefCounted=Session.new();var restored:String=reloaded.load_game(camp_path)
    check(saved and restored=="ok" and reloaded.world.objects.has(original["id"]),"existing session save/load stays connected")
    var result_path:="res://tests/.state/combat-research-result.json"
    var file:=FileAccess.open(result_path,FileAccess.WRITE)
    if file!=null:file.store_string(JSON.stringify({"checks":checks,"failures":failed}));file.close()
    print("COMBAT RESULT checks=%d failures=%d" % [checks,failed])
    quit(0 if failed==0 else 1)
