extends SceneTree
const Session=preload("res://research/weapon-targeting/weapon_session.gd")
const Catalog=preload("res://data/catalog.gd")
var checks:int=0
var failures:int=0

func check(condition:bool,label:String)->void:
    checks+=1
    if condition:print("PASS ",label)
    else:
        failures+=1
        push_error("FAIL "+label)

func spawn(s:RefCounted,id:String,point:Vector2)->Dictionary:
    var profile:Resource=Catalog.enemy("melee")
    var e:Dictionary={
        "id":id,"kind":"enemy","pos":point,"home":point,"alive":true,
        "phase":0.0,"type":"melee","tier":0,"hp":100.0,"max_hp":100.0,
        "damage":profile.damage,"cooldown":10.0,"behavior":"wait"
    }
    s.world.objects[id]=e
    return e

func fixture()->RefCounted:
    var s:RefCounted=Session.new()
    s.depart("base")
    s.world.objects.clear()
    s.position=Vector2.ZERO
    return s

func resolve(s:RefCounted)->void:
    s._projectiles(1.0)

func health(s:RefCounted,id:String)->float:
    return float(s.world.objects[id]["hp"])

func _init()->void:
    call_deferred("run")

func run()->void:
    # Exactly the same clustered enemies for baseline, splash, and multi targeting.
    for mode in ["single","area","multi"]:
        var s:RefCounted=fixture()
        s.prototype_mode=mode
        spawn(s,"A",Vector2(0,-25))
        spawn(s,"B",Vector2(8,-31))
        spawn(s,"C",Vector2(-10,-27))
        spawn(s,"D",Vector2(30,5))
        s._attack(0.01)
        var shot_count:int=s.projectiles.size()
        check(shot_count==(3 if mode=="multi" else 1),mode+": correct projectile count, one attack event")
        check(is_equal_approx(s.attack_cooldown,2.0),mode+": one shared 2s cooldown")
        s._attack(0.01)
        check(s.projectiles.size()==shot_count,mode+": repeat attack blocked by cooldown")
        resolve(s)
        var hit_count:int=0
        for id in ["A","B","C","D"]:
            if health(s,id)<100.0:hit_count+=1
        check(hit_count==(1 if mode=="single" else 3),mode+": clustered encounter hit count")
        check(s.projectiles.is_empty(),mode+": projectiles resolved")
    # Range spread: splash hits only primary, multi fires at additional separated enemies.
    for mode in ["area","multi"]:
        var s:RefCounted=fixture()
        s.prototype_mode=mode
        spawn(s,"A",Vector2(0,-25))
        spawn(s,"B",Vector2(23,-15))
        spawn(s,"C",Vector2(-23,-15))
        spawn(s,"D",Vector2(0,-39))
        s._attack(0.01)
        resolve(s)
        var expected:int=1 if mode=="area" else 3
        var hits:int=0
        for id in ["A","B","C","D"]:
            if health(s,id)<100.0:hits+=1
        check(hits==expected,mode+": spread-out encounter count")
    # Keep melee-first behavior; new modes must not change close-combat priority.
    var melee:RefCounted=fixture()
    melee.prototype_mode="multi"
    spawn(melee,"A",Vector2(0,-4))
    melee._attack(0.01)
    check(melee.attack_mode=="近接" and is_equal_approx(health(melee,"A"),86.0),"melee within reach retains Foundation priority")
    check(melee.projectiles.is_empty(),"melee sends no experimental ranged shots")
    # Respect ranged reach and no attack if target is too far.
    var distant:RefCounted=fixture()
    distant.prototype_mode="area"
    spawn(distant,"A",Vector2(0,-60))
    distant._attack(0.01)
    check(distant.projectiles.is_empty() and is_equal_approx(health(distant,"A"),100.0),"out of range: no damage or projectile")
    # Edge: dead enemies never selected by multishot.
    var dead:RefCounted=fixture()
    dead.prototype_mode="multi"
    spawn(dead,"A",Vector2(0,-25))
    var b:Dictionary=spawn(dead,"B",Vector2(14,-20))
    b["alive"]=false
    spawn(dead,"C",Vector2(-15,-20))
    dead._attack(0.01)
    check(dead.projectiles.size()==2,"multi skips already defeated enemies")
    resolve(dead)
    check(is_equal_approx(health(dead,"B"),100.0),"defeated enemy not damaged again")
    print("RESULT weapon-targeting checks=%d failures=%d" % [checks,failures])
    quit(0 if failures==0 else 1)
