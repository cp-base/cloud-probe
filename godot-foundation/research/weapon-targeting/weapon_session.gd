extends "res://core/session.gd"
# Isolated extension of the REAL Foundation Session; main code and existing weapon Resources stay untouched.
const Targeting=preload("res://research/weapon-targeting/targeting.gd")
var prototype_mode:String="single" # single | area | multi
var splash_radius:float=14.0
var multi_count:int=3

func _attack(dt:float)->void:
    if prototype_mode not in ["area","multi"]:
        super._attack(dt)
        return
    var target:Dictionary=nearest_kind("enemy",150.0)
    if not target.is_empty():
        var melee:Resource=Catalog.weapon(campaign.equipped["melee"])
        # Keep the original melee-first selection and the shared cooldown.
        if position.distance_to(target["pos"])<=weapon_reach(melee):
            super._attack(dt)
            return
    attack_cooldown=maxf(0.0,attack_cooldown-dt)
    attack_mode=""
    if target.is_empty():return
    var ranged:Resource=Catalog.weapon(campaign.equipped["ranged"])
    var reach:float=weapon_reach(ranged)
    if position.distance_to(target["pos"])>reach:return
    attack_mode="範囲砲" if prototype_mode=="area" else "複数照準"
    if attack_cooldown>0.0:return
    attack_cooldown=ranged.interval
    if prototype_mode=="multi":
        var picks:Array[Dictionary]=Targeting.multi(world.active(position,150.0),target,position,reach,multi_count)
        for enemy:Dictionary in picks:
            fire(position,str(enemy["id"]),weapon_damage(ranged),reach,false)
    else:
        fire(position,str(target["id"]),weapon_damage(ranged),reach,false)
        var shot:Dictionary=projectiles.back()
        shot["splash_radius"]=maxf(0.0,splash_radius)

func _projectiles(dt:float)->void:
    # Let the unmodified Foundation logic handle all ordinary and multi-target shots.
    # Only splash-tagged experimental projectiles need extra impact collision checks.
    var normal:Array[Dictionary]=[]
    var enhanced:Array[Dictionary]=[]
    for shot:Dictionary in projectiles:
        if not bool(shot.get("hostile",false)) and shot.has("splash_radius"):
            enhanced.append(shot)
        else:
            normal.append(shot)
    projectiles.assign(normal)
    super._projectiles(dt)
    var remaining:Array[Dictionary]=projectiles.duplicate()
    for shot:Dictionary in enhanced:
        shot["life"]=float(shot["life"])+dt
        if float(shot["life"])>8.0:continue
        var primary:Dictionary=world.objects.get(str(shot["target"]),{})
        if primary.is_empty() or not bool(primary.get("alive",false)):continue
        var center:Vector2=primary["pos"]
        if center.distance_to(shot["origin"])>float(shot["reach"]):continue
        var travel:float=60.0*dt
        var p:Vector2=shot["pos"]
        if p.distance_to(center)<=travel+0.7:
            var radius:float=float(shot["splash_radius"])
            for enemy:Dictionary in Targeting.splash(world.active(center,radius),center,radius):
                damage_enemy(enemy,float(shot["damage"]))
        else:
            shot["pos"]=p.move_toward(center,travel)
            remaining.append(shot)
    projectiles.assign(remaining)
