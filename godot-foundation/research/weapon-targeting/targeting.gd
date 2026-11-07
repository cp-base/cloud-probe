extends RefCounted
# Prototype-only target selection; no tactical optimization or new enemy AI.

static func eligible(enemy:Dictionary, origin:Vector2, reach:float)->bool:
    return bool(enemy.get("alive",false)) and enemy.get("kind","")=="enemy" and origin.distance_to(enemy["pos"])<=reach

static func multi(candidates:Array[Dictionary], primary:Dictionary, origin:Vector2, reach:float, max_targets:int)->Array[Dictionary]:
    var result:Array[Dictionary]=[]
    if not eligible(primary,origin,reach):return result
    result.append(primary)
    var others:Array[Dictionary]=[]
    for enemy:Dictionary in candidates:
        if enemy.get("id","")==primary.get("id",""):continue
        if eligible(enemy,origin,reach):others.append(enemy)
    others.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
        var da:float=origin.distance_squared_to(a["pos"])
        var db:float=origin.distance_squared_to(b["pos"])
        if not is_equal_approx(da,db):return da<db
        return str(a["id"])<str(b["id"])
    )
    for enemy:Dictionary in others:
        if result.size()>=maxi(1,max_targets):break
        result.append(enemy)
    return result

static func splash(candidates:Array[Dictionary], center:Vector2, radius:float)->Array[Dictionary]:
    var result:Array[Dictionary]=[]
    for enemy:Dictionary in candidates:
        if bool(enemy.get("alive",false)) and enemy.get("kind","")=="enemy" and center.distance_to(enemy["pos"])<=maxf(0.0,radius):
            result.append(enemy)
    result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return str(a["id"])<str(b["id"]))
    return result
