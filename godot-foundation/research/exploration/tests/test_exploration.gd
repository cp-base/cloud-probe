extends SceneTree
const World=preload("res://core/world.gd")
const Campaign=preload("res://core/campaign.gd")
const Storage=preload("res://core/storage.gd")
const Ledger=preload("res://research/exploration/exploration_ledger.gd")
const SAVE:="res://.local/research-exploration-test.json"
var tests:int=0
var failed:int=0
func check(ok:bool,description:String)->void:
    tests+=1
    if not ok:failed+=1
    print(("PASS" if ok else "FAIL")+" #"+str(tests)+" "+description)

func equivalent(a:Variant,b:Variant)->bool:
    if a is Dictionary and b is Dictionary:
        if a.size()!=b.size():return false
        for k in a:
            if not b.has(k) or not equivalent(a[k],b[k]):return false
        return true
    if a is Array and b is Array:
        if a.size()!=b.size():return false
        for i in a.size():
            if not equivalent(a[i],b[i]):return false
        return true
    if (a is int or a is float) and (b is int or b is float):
        return absf(float(a)-float(b))<=0.0001
    if a is Vector2 and b is Vector2:
        return a.distance_to(b)<=0.0001
    return a==b

func snapshot(w:RefCounted)->Dictionary:
    return Storage.pack(w.to_dict())

func _initialize()->void:
    call_deferred("run")

func run()->void:
    var a:=World.new();a.initialize(71127);a.reset_sortie(4)
    var b:=World.new();b.initialize(71127);b.reset_sortie(4)
    var keys:=[Vector2i(-2,1),Vector2i(1,-2),Vector2i(0,-1),Vector2i(-1,-1)]
    for p in keys:a.generate_chunk(p)
    keys.reverse()
    for p in keys:b.generate_chunk(p)
    check(snapshot(a)["objects"]==snapshot(b)["objects"],"seed / sortie / chunk generation is independent of visit order")
    check(a.objects.size()==b.objects.size() and a.objects.has("4:start-enemy"),"same object IDs including v0.3 start encounter")
    var previous:=snapshot(a)
    a.generate_chunk(Vector2i(-2,1))
    check(snapshot(a)==previous,"repeat visit cannot regenerate or duplicate chunk objects")
    var ledger:=Ledger.new();ledger.begin_sortie(4)
    var path:=[Vector2(0,0),Vector2(100,-100),Vector2(350,-350),Vector2(550,-450),Vector2(300,-350),Vector2(0,0)]
    for p in path:
        a.ensure_nearby(p);ledger.record_position(p,a,90.0)
    check(ledger.visited.size()>=3,"actual path marks multiple explored chunks")
    var entries:int=ledger.visited["0:0"]["entries"]
    ledger.record_position(Vector2(0,0),a)
    check(ledger.visited["0:0"]["entries"]==entries,"stationary repeated updates do not count as a new revisit")
    check(entries>=2,"re-entering a visited section counts as a revisit")
    var id1:String=ledger.add_waypoint(Vector2(-50,-40),"a")
    var id2:String=ledger.add_waypoint(Vector2(500,-300),"b")
    check(ledger.append_route(id1) and ledger.append_route(id2) and ledger.route.size()==2,"waypoints support ordered route legs")
    check(not ledger.append_route("invalid") and not ledger.append_route(id2),"invalid and immediate repeated route points are rejected")
    check(ledger.add_waypoint(Vector2(10001,0))=="","world boundary rejects out-of-bounds waypoint")
    var contacts_before:int=ledger.contacts.size()
    var new_contacts:int=ledger.scan_area(Vector2.ZERO,a,900.0)
    check(new_contacts>=0 and ledger.contacts.size()>=contacts_before and ledger.surveyed.size()>0,"scan reveals facility intel and surveyed chunks")
    var c:=Campaign.new();c.sortie_sequence=4;c.settings["exploration_lab"]=ledger.to_dict()
    var position:=Vector2(300,-350)
    check(Storage.write(SAVE,{"campaign":c.to_dict(),"world":a.to_dict(),"session":{"phase":"travel","position":position}}),"Foundation Storage writes independent navigation data")
    var read:Dictionary=Storage.read(SAVE)
    check(read["status"]=="ok","Foundation Storage reads navigation save without schema changes")
    var loaded_c:=Campaign.new();loaded_c.from_dict(read["data"]["campaign"])
    var loaded_w:=World.new();loaded_w.initialize(loaded_c.seed_value);loaded_w.from_dict(read["data"]["world"])
    var loaded_ledger:=Ledger.new();loaded_ledger.from_dict(loaded_c.settings["exploration_lab"])
    check(read["data"]["session"]["position"]==position and loaded_w.sortie_id==4,"position and sortie id survive restart")
    check(equivalent(snapshot(loaded_w),snapshot(a)),"world object positions, HP and generated-section set survive restart")
    check(equivalent(loaded_ledger.visited,ledger.visited) and equivalent(loaded_ledger.surveyed,ledger.surveyed),"visited and surveyed cells survive restart")
    check(loaded_ledger.route==ledger.route and loaded_ledger.waypoints==ledger.waypoints,"waypoints and route survive restart")
    var before_count:=loaded_w.objects.size()
    loaded_w.ensure_nearby(position)
    check(loaded_w.objects.size()==before_count,"revisit after restart does not duplicate generated entities")
    var old_facilities:Dictionary=loaded_w.facilities.duplicate(true)
    loaded_w.reset_sortie(5);loaded_ledger.begin_sortie(5)
    check(loaded_w.facilities==old_facilities,"fixed facilities retain their coordinates on the next sortie")
    check(equivalent(loaded_ledger.route,ledger.route) and equivalent(loaded_ledger.visited,ledger.visited),"navigation memory retained between sorties")
    check(not loaded_w.objects.has("4:start-enemy") and loaded_w.objects.has("5:start-enemy"),"dynamic objects are explicitly regenerated per sortie")
    var empty:=Ledger.new();empty.from_dict({})
    check(empty.visited.is_empty() and empty.route.is_empty(),"old save with no navigation section produces empty ledger")
    var edited:Dictionary=ledger.to_dict().duplicate(true)
    edited["route"].append("missing")
    var scrubbed:=Ledger.new();scrubbed.from_dict(edited)
    check(scrubbed.route.size()==ledger.route.size(),"dangling route target is filtered on load")
    check(Ledger.chunk_key(Vector2(-0.5,-480.01))=="-1:-2","negative chunk coordinates use floor, not truncation")
    var packed:Variant=Storage.pack({"v":Vector2(-0.1,349.9)})
    check(Storage.unpack(packed)["v"]==Vector2(-0.1,349.9),"serialized negative and fractional positions roundtrip")
    print("RESULT ",tests-failed,"/",tests," tests passed, failures=",failed)
    quit(0 if failed==0 else 1)
