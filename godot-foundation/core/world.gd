extends RefCounted
const Catalog=preload("res://data/catalog.gd")
const CHUNK:=480.0
const RADIUS:=10000.0
const GAP:=150.0
var seed_value:int=71127
var sortie_id:int=0
var facilities:Dictionary={}
var objects:Dictionary={}
var chunks:Dictionary={}

func initialize(value:int)->void:
    seed_value=value
    facilities.clear()
    facilities["base"]={"id":"base","title":"起点ステーション","pos":Vector2.ZERO,"services":["supply","upgrade","weapons","trade","dispatch","departure"],"cost":0,"existing":true,"buy":3,"sell":2}
    var rng:=RandomNumberGenerator.new();rng.seed=seed_value+133
    var distances:=[210.0,460.0,900.0,1500.0,2350.0,3400.0,4800.0,6300.0,7900.0,9500.0]
    for i in range(distances.size()):
        var angle:float=rng.randf_range(-0.22,0.22) if i==0 else rng.randf_range(-PI,PI)
        var p:Vector2=Vector2(sin(angle),-cos(angle))*float(distances[i])
        var id:="facility_%d" % i
        var service:Array=["supply","departure"]
        var title:="中継施設候補"
        if i%3==0:service=["supply","trade"];title="交易施設"
        elif i%3==2:service=["supply","upgrade","weapons","dispatch"];title="整備施設候補"
        facilities[id]={"id":id,"title":title,"pos":p,"services":service,"cost":8+int(distances[i]/700.0)*3,"existing":i==0,"buy":6+(i%3),"sell":5+(i%3)}

func reset_sortie(value:int)->void:
    sortie_id=value;objects.clear();chunks.clear()
    var rng:=RandomNumberGenerator.new();rng.seed=seed_value*31+sortie_id*101
    var angle:=rng.randf_range(-0.3,0.3)
    var point:=Vector2(sin(angle),-cos(angle))*rng.randf_range(85.0,115.0)
    var id:="%d:start" % sortie_id
    objects[id]=make_object(id,"light",point,rng)

func ensure_nearby(position:Vector2)->void:
    var center:=Vector2i(floori(position.x/CHUNK),floori(position.y/CHUNK))
    for x in range(center.x-1,center.x+2):
        for y in range(center.y-1,center.y+2):generate_chunk(Vector2i(x,y))

func generate_chunk(key:Vector2i)->void:
    var chunk_id:="%d:%d" % [key.x,key.y]
    if chunks.has(chunk_id):return
    chunks[chunk_id]=true
    var rng:=RandomNumberGenerator.new()
    rng.seed=abs(seed_value*1000003+sortie_id*83492791+key.x*73856093+key.y*19349663)
    for attempt in range(100):
        var p:=Vector2(key.x*CHUNK+rng.randf_range(GAP*0.5,CHUNK-GAP*0.5),key.y*CHUNK+rng.randf_range(GAP*0.5,CHUNK-GAP*0.5))
        if p.length()>RADIUS or p.length()<150.0:continue
        var valid:=true
        for facility:Dictionary in facilities.values():
            if p.distance_to(facility["pos"])<55.0:valid=false;break
        if not valid:continue
        # A single random point per sector; category selection is independent of count.
        var roll:=rng.randf()
        var kind:="enemy" if roll<0.28 else ("signal" if roll<0.36 else "light")
        var id:="%d:%s" % [sortie_id,chunk_id]
        objects[id]=make_object(id,kind,p,rng)
        break

func make_object(id:String,kind:String,point:Vector2,rng:RandomNumberGenerator)->Dictionary:
    var result:={"id":id,"kind":kind,"pos":point,"home":point,"alive":true,"phase":rng.randf_range(0,TAU)}
    if kind=="enemy":
        var profile:Resource=Catalog.ENEMIES[rng.randi_range(0,3)]
        var tier:=floori(point.length()/800.0)
        var strength:=pow(1.7,tier)
        result.merge({"type":profile.id,"tier":tier,"max_hp":profile.hp*strength,"hp":profile.hp*strength,"damage":profile.damage*strength,"cooldown":rng.randf_range(0.1,0.8)})
    elif kind=="light":
        result["reward"]=rng.randi_range(1,2)
        result["fuel"]=rng.randf_range(14.0,24.0) if rng.randf()<0.65 else 0.0
    return result

func active(position:Vector2,radius:=550.0)->Array[Dictionary]:
    var result:Array[Dictionary]=[]
    for object:Dictionary in objects.values():
        if object["alive"] and position.distance_to(object["pos"])<=radius:result.append(object)
    return result

func to_dict()->Dictionary:
    return {"sortie_id":sortie_id,"objects":objects,"chunks":chunks}

func from_dict(data:Dictionary)->void:
    sortie_id=int(data.get("sortie_id",0))
    objects=data.get("objects",{});chunks=data.get("chunks",{})

