extends "res://core/session.gd"
const FastPattern=preload("res://research/combat/data/fast_pattern.tres")
const HeavyPattern=preload("res://research/combat/data/heavy_pattern.tres")
var experimental_patterns:bool=false
var _inside_base_tick:bool=false

func set_patterns_enabled(value:bool)->void:
    experimental_patterns=value
    if not value:_clear_windups()

func _clear_windups()->void:
    if world==null:return
    for enemy:Dictionary in world.objects.values():
        if enemy.get("kind")=="enemy":enemy.erase("windup")

func load_game(path:String=SAVE_PATH)->String:
    var result:String=super.load_game(path)
    if result=="ok":
        experimental_patterns=false
        _clear_windups()
    return result

func tick(dt:float,forward:float,turn:float)->void:
    # Foundation's inherited tick resolves its own _enemies implementation.
    # Apply experimental behavior explicitly before the original tick so real travel uses it.
    var active:bool=phase=="travel" and not paused
    _inside_base_tick=active
    if active and experimental_patterns:_apply_patterns(dt)
    super.tick(dt,forward,turn)
    _inside_base_tick=false

func _enemies(dt:float)->void:
    # Keep a callable isolated encounter step for research/unit tests.
    if experimental_patterns and not _inside_base_tick:_apply_patterns(dt)
    super._enemies(dt)

func _apply_patterns(dt:float)->void:
    for enemy:Dictionary in world.active(position,430.0):
        if enemy.get("kind")!="enemy":continue
        var profile:Resource=Catalog.enemy(enemy["type"])
        var separation:Vector2=enemy["pos"]-position
        var distance:float=separation.length()
        if enemy["type"]==FastPattern.id and distance<profile.detection and distance>profile.melee_range+3.0 and enemy["pos"].distance_to(enemy["home"])<140.0:
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
