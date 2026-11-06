extends RefCounted
## Experimental, additive navigation memory. Not part of Foundation save schema.
## Attach to campaign.settings["exploration_lab"] to use existing JSON packing.
const World=preload("res://core/world.gd")
const MAX_TRAIL_POINTS:=500
const MAX_WAYPOINTS:=80
const MAX_ROUTE_POINTS:=80
const MAX_SENSING:=2400.0
var visited:Dictionary={}
var surveyed:Dictionary={}
var contacts:Dictionary={}
var waypoints:Array=[]
var route:Array=[]
var trail:Array=[]
var waypoint_sequence:int=0
var sortie_id:int=0
var last_chunk:String=""

static func chunk_key(pos:Vector2)->String:
    return "%d:%d" % [floori(pos.x/World.CHUNK),floori(pos.y/World.CHUNK)]

func begin_sortie(id:int)->void:
    sortie_id=id
    last_chunk=""
    if not trail.is_empty():trail.append({"break":true})

func record_position(pos:Vector2,world:RefCounted,sense:float=90.0)->void:
    if pos.length()>World.RADIUS+0.01:return
    var key:=chunk_key(pos)
    if key!=last_chunk:
        var value:Dictionary=visited.get(key,{"first_sortie":sortie_id,"entries":0})
        value["entries"]=int(value.get("entries",0))+1
        value["last_sortie"]=sortie_id
        visited[key]=value
        last_chunk=key
    if trail.is_empty() or trail.back().has("break") or trail.back()["pos"].distance_to(pos)>=75.0:
        trail.append({"pos":pos,"sortie":sortie_id})
        if trail.size()>MAX_TRAIL_POINTS:trail=trail.slice(trail.size()-MAX_TRAIL_POINTS)
    for f:Dictionary in world.facilities.values():
        var d:float=pos.distance_to(f["pos"])
        if d>maxf(0.0,sense):continue
        var id:String=f["id"]
        var contact:Dictionary=contacts.get(id,{"id":id,"pos":f["pos"],"title":f["title"],"first_sortie":sortie_id,"visited":false,"source":"detection"})
        if d<=14.0:contact["visited"]=true
        contacts[id]=contact

func scan_area(pos:Vector2,world:RefCounted,radius:float=900.0)->int:
    radius=clampf(radius,0.0,MAX_SENSING)
    var first:Vector2i=Vector2i(floori((pos.x-radius)/World.CHUNK),floori((pos.y-radius)/World.CHUNK))
    var last:Vector2i=Vector2i(floori((pos.x+radius)/World.CHUNK),floori((pos.y+radius)/World.CHUNK))
    for x in range(first.x,last.x+1):
        for y in range(first.y,last.y+1):
            var midpoint:=Vector2((x+0.5)*World.CHUNK,(y+0.5)*World.CHUNK)
            if midpoint.length()>World.RADIUS+World.CHUNK or midpoint.distance_to(pos)>radius+World.CHUNK*0.7072:continue
            surveyed["%d:%d" % [x,y]]=true
    var new_contacts:=0
    for f:Dictionary in world.facilities.values():
        if f["pos"].distance_to(pos)>radius:continue
        if not contacts.has(f["id"]):
            contacts[f["id"]]={"id":f["id"],"pos":f["pos"],"title":f["title"],"first_sortie":sortie_id,"visited":false,"source":"scan"}
            new_contacts+=1
    return new_contacts

func add_waypoint(pos:Vector2,title:String="")->String:
    if pos.length()>World.RADIUS or waypoints.size()>=MAX_WAYPOINTS:return ""
    waypoint_sequence+=1
    var id:="wp_%d" % waypoint_sequence
    var short_title:=title.strip_edges().left(32)
    if short_title.is_empty():short_title="地点 %d" % waypoint_sequence
    waypoints.append({"id":id,"pos":pos,"title":short_title})
    return id

func append_route(id:String)->bool:
    if route.size()>=MAX_ROUTE_POINTS:return false
    var found:=false
    for wp:Dictionary in waypoints:
        if wp["id"]==id:found=true;break
    if not found:return false
    if route.is_empty() or route.back()!=id:
        route.append(id)
        return true
    return false

func clear_route()->void:route.clear()

func to_dict()->Dictionary:
    return {"version":1,"visited":visited,"surveyed":surveyed,"contacts":contacts,"waypoints":waypoints,"route":route,"trail":trail,"waypoint_sequence":waypoint_sequence,"sortie_id":sortie_id,"last_chunk":last_chunk}

func from_dict(data:Dictionary)->void:
    if int(data.get("version",0))!=1:return
    if data.get("visited") is Dictionary:
        visited=data["visited"].duplicate(true)
        for key in visited:
            if visited[key] is Dictionary:
                for item in ["entries","first_sortie","last_sortie"]:
                    if visited[key].has(item):visited[key][item]=int(visited[key][item])
    if data.get("surveyed") is Dictionary:surveyed=data["surveyed"].duplicate(true)
    if data.get("contacts") is Dictionary:contacts=data["contacts"].duplicate(true)
    if data.get("waypoints") is Array:waypoints=data["waypoints"].duplicate(true).slice(0,MAX_WAYPOINTS)
    if data.get("trail") is Array:trail=data["trail"].duplicate(true).slice(-MAX_TRAIL_POINTS)
    waypoint_sequence=maxi(0,int(data.get("waypoint_sequence",0)))
    sortie_id=maxi(0,int(data.get("sortie_id",0)))
    last_chunk=str(data.get("last_chunk",""))
    # Ignore dangling IDs introduced by older or edited saves.
    var ids:Dictionary={}
    for wp in waypoints:
        if wp is Dictionary and wp.get("id") is String and wp.get("pos") is Vector2:ids[wp["id"]]=true
    route.clear()
    if data.get("route") is Array:
        for item in data["route"]:
            if item is String and ids.has(item) and route.size()<MAX_ROUTE_POINTS:route.append(item)
