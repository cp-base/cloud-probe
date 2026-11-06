extends SceneTree
const Session=preload("res://core/session.gd")
const World=preload("res://core/world.gd")
const Catalog=preload("res://data/catalog.gd")
const Storage=preload("res://core/storage.gd")
const PATH="res://tests/.state/roundtrip.json"
var checks:int=0
var failures:int=0

func check(condition:bool,title:String)->void:
    checks+=1
    if condition:print("PASS ",title)
    else:failures+=1;push_error("FAIL "+title)

func enemy_for(s:RefCounted,p:Vector2,type:String="melee",tier:int=0)->Dictionary:
    var profile:Resource=Catalog.enemy(type)
    var strength:float=pow(1.7,tier)
    var e:Dictionary={"id":"test-enemy","kind":"enemy","pos":p,"home":p,"alive":true,"phase":0.0,"type":type,"tier":tier,"hp":profile.hp*strength,"max_hp":profile.hp*strength,"damage":profile.damage*strength,"cooldown":0.0}
    s.world.objects[e["id"]]=e
    return e

func _init()->void:
    call_deferred("run")

func run()->void:
    # Generated population, stable IDs and visitation independence, not UI fixtures.
    var a:RefCounted=World.new();a.initialize(71127);a.reset_sortie(1)
    var b:RefCounted=World.new();b.initialize(71127);b.reset_sortie(1)
    var keys:Array[Vector2i]=[]
    for x in range(-6,7):
        for y in range(-6,7):keys.append(Vector2i(x,y))
    for key in keys:a.generate_chunk(key)
    keys.reverse()
    for key in keys:b.generate_chunk(key)
    var stable:bool=a.objects.size()==b.objects.size()
    var kinds:Dictionary={};var behaviors:Dictionary={};var points:Array[Vector2]=[];var minimum:float=INF
    for id:String in a.objects:
        var o:Dictionary=a.objects[id]
        stable=stable and b.objects.has(id) and o==b.objects[id]
        if o["kind"]=="enemy":kinds[o["type"]]=true;behaviors[o["behavior"]]=true
        if not id.ends_with(":start") and not id.ends_with(":start-enemy"):points.append(o["pos"])
    for i in range(points.size()):
        for j in range(i):minimum=minf(minimum,points[i].distance_to(points[j]))
    check(stable,"seed/sortie/chunk: visit order independent")
    check(a.objects.size()<=171 and minimum>=150.0,"sparse generation: <=1 per 480 sector; gap >=150 (origin encounters excluded)")
    check(kinds.size()==4,"all four enemy types coexist in same world")
    check(behaviors.size()==2,"wait and patrol coexist independently of combat type")
    var near_enemy:Dictionary=a.objects["1:start-enemy"]
    var before_nearby:int=a.objects.size();a.ensure_nearby(Vector2.ZERO)
    check(near_enemy["kind"]=="enemy" and near_enemy["behavior"]=="wait" and near_enemy["pos"].length()<200.0 and a.objects.size()==before_nearby,"one extra enemy near origin; nearby generation cannot duplicate it")
    var s:RefCounted=Session.new()
    check(s.max_fuel()/s.fuel_cost()<300 and s.speed()==6,"initial reach far below 10000 and slow speed")
    s.depart("base")
    # Actually navigate from origin to the generated first light using normal ticks.
    var light:Dictionary=s.nearest_kind("light")
    var first_id:String=light["id"]
    for i in range(1000):
        s.tick(0.05,1,0)
        if not s.world.objects[first_id]["alive"]:break
    check(s.pickups==1 and s.phase=="travel" and s.position.length()>70,"ordinary navigation auto-collects without a modal")
    var collected:int=s.campaign.credits
    for i in range(10):s.tick(0.05,0,0)
    check(s.campaign.credits==collected and s.pickups==1,"collected light cannot pay twice")
    # Complete first outing: continue to its end, no forced victory or invulnerability.
    for i in range(2000):
        s.tick(0.05,1,0)
        if s.phase=="docked":break
    check(s.phase=="docked" and s.campaign.credits>=4 and s.campaign.best_range<10000,"initial exploration fails/returns with usable permanent earnings")
    var original_reach:float=s.max_fuel()/s.fuel_cost()
    check(s.buy_upgrade("base","range") and s.max_fuel()/s.fuel_cost()>original_reach,"earned currency purchases a real increase in travel range")
    check(not s.buy_upgrade("facility_2","range"),"remote facility cannot apply upgrades")
    s.depart("base")
    check(is_equal_approx(s.fuel,s.max_fuel()),"next departure uses upgraded full capacity")
    var patrol_test:RefCounted=Session.new();patrol_test.depart("base");patrol_test.world.objects.clear()
    var patroller:Dictionary=enemy_for(patrol_test,Vector2(200,0))
    var starting_point:Vector2=patroller["pos"]
    patrol_test._enemies(1.0)
    check(patroller["pos"]==starting_point,"waiting and legacy enemies stay still outside detection")
    patroller["behavior"]="patrol";patroller["patrol_heading"]=PI/2;patroller["patrol_leg"]=0
    var turned:bool=false;var max_offset:float=0.0
    for i in range(1600):
        patrol_test._enemies(0.05)
        max_offset=maxf(max_offset,patroller["pos"].distance_to(patroller["home"]))
        if patroller["patrol_leg"]==1:turned=true
    check(turned and max_offset<=30.01 and patroller["pos"]!=starting_point,"patroller moves without detecting player and turns within radius 30")
    var paused_point:Vector2=patroller["pos"];patrol_test.paused=true;patrol_test.tick(5,0,0)
    check(patroller["pos"]==paused_point,"pause stops patrol as well as pursuit")
    # Explicit fixtures below exercise hard-to-reach states, not claims of normal completion.
    s.world.objects.clear()
    var e:Dictionary=enemy_for(s,s.position+Vector2(0,-25))
    s._attack(0.01)
    check(s.attack_mode=="砲撃" and s.projectiles.size()==1,"ranged weapon fires automatically")
    var prior_hp:float=e["hp"]
    e["pos"]=s.position+Vector2(0,-4)
    s._attack(0.01)
    check(s.attack_mode=="近接" and e["hp"]==prior_hp,"distance switch retains cooldown, cannot grant a free attack")
    s._attack(3)
    check(e["hp"]<prior_hp,"melee weapon attacks automatically after cooldown")
    s.damage_enemy(e,10000);var awarded:int=s.campaign.credits
    s.damage_enemy(e,10000)
    check(s.campaign.credits==awarded and s.kills==1,"dead enemy cannot pay twice")
    var signal_object:Dictionary={"id":"test-signal","kind":"signal","pos":s.position,"home":s.position,"alive":true,"phase":0.0}
    s.world.objects[signal_object["id"]]=signal_object
    var before_signal:int=s.campaign.credits
    check(s.resolve_signal(signal_object["id"],"salvage") and not s.resolve_signal(signal_object["id"],"salvage") and s.campaign.credits==before_signal+2,"optional signal choice resolves and pays only once")
    var rng:=RandomNumberGenerator.new();rng.seed=9
    var deep:Dictionary=s.world.make_object("deep","enemy",Vector2(0,-2400),rng)
    var deep_hp:float=deep["hp"];s.campaign.upgrades["combat"]=5
    s.world.objects[deep["id"]]=deep;s.position=Vector2(0,-50);s._enemies(0.05)
    check(deep["tier"]==3 and deep["hp"]==deep_hp and deep_hp>Catalog.enemy(deep["type"]).hp,"depth strength is fixed at spawn, not scaled to player or pursuit")
    # Same nearby opponent: unmodified ship loses, improved ship wins.
    var outcomes:Array=[]
    for level in [0,5]:
        var duel:RefCounted=Session.new();duel.campaign.upgrades["combat"]=level;duel.depart("base");duel.world.objects.clear()
        var foe:Dictionary=enemy_for(duel,Vector2(0,-4),"heavy",0)
        for i in range(2400):
            duel.tick(0.05,0,0)
            if not foe["alive"] or duel.phase=="docked":break
        outcomes.append(not foe["alive"])
    check(outcomes==[false,true],"same heavy enemy defeats initial ship but is beatable after growth (fixture)")
    s=Session.new();s.campaign.credits=100;s.depart("base")
    var site:String="facility_1";s.position=s.world.facilities[site]["pos"];s.discover()
    var credits_before:int=s.campaign.credits
    var built:bool=s.build(site);var after_build:int=s.campaign.credits
    check(built and s.facility_state(site)["registered"] and not s.build(site) and s.campaign.credits==after_build and after_build<credits_before,"discover/build: pay once and register departure-capable facility")
    check(s.dock(site) and s.depart(site) and s.position==s.world.facilities[site]["pos"],"built relay can be selected as the next start")
    s.save_game(PATH)
    var built_reload:RefCounted=Session.new();built_reload.load_game(PATH)
    check(built_reload.facility_built(site) and built_reload.facility_state(site)["registered"] and built_reload.departure_id==site,"construction and selected departure survive save/reload")
    s.return_to_departure("test failure")
    check(s.facility_built(site) and s.campaign.upgrades["range"]==0,"failure retains constructed facilities")
    s.add_marker("a");s.remove_marker(s.campaign.marker_sequence)
    check(s.campaign.markers.is_empty() and s.facility_built(site),"deleting a memo does not delete its facility")
    s=Session.new();s.campaign.credits=20
    check(s.buy_goods("base") and s.campaign.cargo==1,"trade buys cargo with payment")
    s.sell_goods("base")
    check(s.campaign.credits==19,"same-place buy/sell does not create profit")
    for i in range(3):s.buy_goods("base")
    var full_cash:int=s.campaign.credits
    check(s.campaign.cargo==3 and not s.buy_goods("base") and s.campaign.credits==full_cash,"full cargo rejects purchase without taking money")
    for i in range(3):s.sell_goods("base")
    s.buy_goods("base");s.depart("base");s.position=s.world.facilities["facility_0"]["pos"];s.discover()
    var cash:int=s.campaign.credits
    check(s.sell_goods("facility_0") and s.campaign.cargo==0 and s.campaign.credits==cash+5,"cargo can be carried and sold at another facility")
    s.return_to_departure("test");s.campaign.credits=20
    var requested:bool=s.request_survey("base")
    check(requested and not s.request_survey("base"),"survey: single slot prevents duplicate order")
    s.depart("base");s.world.objects.clear();s.paused=true;s.tick(100,0,0)
    check(s.campaign.world_time==0 and s.campaign.job["status"]=="running","pause does not advance simulation or survey")
    s.paused=false
    for i in range(1801):s.tick(0.05,0,0)
    check(s.campaign.job["status"]=="ready","survey completes after 90 seconds of simulation")
    s.return_to_departure("test")
    check(s.claim_survey("base") and not s.claim_survey("base"),"survey result can be claimed only once")
    # Mid-flight save, including damaged enemy, used light and in-flight attack.
    s.add_marker("save-test");s.buy_goods("base");s.depart("base");s.world.objects.clear()
    e=enemy_for(s,s.position+Vector2(0,-20));e["hp"]=17
    e["behavior"]="patrol";e["patrol_heading"]=0.7;e["patrol_leg"]=1
    s.world.objects["used-light"]={"id":"used-light","kind":"light","pos":s.position,"home":s.position,"alive":false,"phase":0.0,"reward":9,"fuel":9.0}
    s.attack_cooldown=1.23;s.fire(s.position,e["id"],7,40,false);s.fuel=56;s.position=Vector2(1,-2)
    var stored:bool=s.save_game(PATH)
    var loaded:RefCounted=Session.new();var restored:String=loaded.load_game(PATH)
    check(stored and restored=="ok" and loaded.paused and loaded.phase=="travel" and loaded.position==s.position and loaded.fuel==56 and loaded.attack_cooldown==1.23 and loaded.projectiles.size()==1 and loaded.world.objects[e["id"]]["hp"]==17,"mid-flight save restores position, fuel, cooldown, projectile and enemy HP; resumes paused")
    check(loaded.campaign.markers.size()==1 and loaded.campaign.cargo==s.campaign.cargo and loaded.campaign.job==s.campaign.job,"save restores cargo, memo and claimed survey")
    var restored_enemy:Dictionary=loaded.world.objects[e["id"]]
    check(restored_enemy["behavior"]=="patrol" and restored_enemy["patrol_heading"]==0.7 and restored_enemy["patrol_leg"]==1,"save restores individual behavior and patrol direction")
    var loaded_cash:int=loaded.campaign.credits
    loaded.paused=false;loaded.tick(0.01,0,0)
    check(not loaded.world.objects["used-light"]["alive"] and loaded.campaign.credits==loaded_cash,"reloading cannot regenerate or recollect a used light in the same sortie")
    var target_health:float=loaded.world.objects[e["id"]]["hp"]
    loaded.paused=false;loaded._projectiles(1.0)
    check(loaded.world.objects[e["id"]]["hp"]==target_health-7 and loaded.projectiles.is_empty(),"saved projectile resolves once after reload")
    var invalid_path:String="res://tests/.state/unsupported.json"
    var invalid:=FileAccess.open(invalid_path,FileAccess.WRITE);invalid.store_string('{"schema":999}');invalid.close()
    var before_hash:String=FileAccess.get_sha256(invalid_path)
    var bad:RefCounted=Session.new()
    check(bad.load_game(invalid_path)=="error" and not bad.save_game(invalid_path) and FileAccess.get_sha256(invalid_path)==before_hash,"unsupported save is rejected without overwriting original")
    loaded.position=Vector2(0,-9999.8);loaded.yaw=0;loaded.fuel=50;loaded.tick(0.05,1,0)
    check(loaded.campaign.reached_edge and loaded.position.length()<=10000.01,"world boundary clamps and records arrival (injected boundary fixture)")
    print("RESULT checks=%d failures=%d" % [checks,failures])
    quit(0 if failures==0 else 1)
