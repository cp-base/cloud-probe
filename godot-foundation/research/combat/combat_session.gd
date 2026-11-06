extends "res://core/session.gd"
const FastPattern=preload("res://research/combat/data/fast_pattern.tres")
const HeavyPattern=preload("res://research/combat/data/heavy_pattern.tres")
var experimental_patterns:bool=false

func _enemies(dt:float)->void:
    if experimental_patterns:
        for enemy:Dictionary in world.active(position,430.0):
            if enemy.get("kind")!="enemy":continue
            var profile:Resource=Catalog.enemy(enemy["type"])
            var separation:Vector2=enemy["pos"]-position
            var distance:float=separation.length()
            if enemy["type"]==FastPattern.id and distance<profile.detection and distance>profile.melee_range+3.0 and enemy["pos"].distance_to(enemy["home"])<140.0:
                # Sideways movement; changes position, not enemy stats or world generator.
                var side:Vector2=Vector2(-separation.y,separation.x).normalized()
                var direction:float=1.0 if sin(campaign.world_time*1.6+float(enemy.get("phase",0.0)))>=0 else -1.0
                enemy["pos"]+=side*direction*FastPattern.sidestep_speed*dt
            if enemy["type"]==HeavyPattern.id:
                var in_range:bool=distance<=maxf(profile.melee_range,profile.ranged_range)
                if not bool(enemy.get("windup",false)) and in_range and float(enemy["cooldown"])<=0.0:
                    enemy["windup"]=true
                    enemy["cooldown"]=HeavyPattern.telegraph_seconds+dt
                elif bool(enemy.get("windup",false)) and float(enemy["cooldown"])<=dt:
                    enemy["windup"]=false
    super._enemies(dt)
