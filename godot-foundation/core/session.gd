extends RefCounted
const Campaign=preload("res://core/campaign.gd")
const World=preload("res://core/world.gd")
const Catalog=preload("res://data/catalog.gd")
const Storage=preload("res://core/storage.gd")
const SAVE_PATH:="res://.local/campaign.json"
var campaign:RefCounted
var world:RefCounted
var phase:String="docked"
var position:=Vector2.ZERO
var yaw:float=0.0
var hp:float=45.0
var fuel:float=100.0
var paused:bool=false
var current_facility:String="base"
var departure_id:String="base"
var projectiles:Array[Dictionary]=[]
var effects:Array[Dictionary]=[]
var attack_cooldown:float=0.0
var attack_mode:String=""
var shot_sequence:int=0
var pickups:int=0
var kills:int=0
var departure_credits:int=0
var report:String="弱い探索者として、未知の空間へ。"
var message:String="準備して出発できます。"
var allow_save:bool=true
var dirty:bool=false
var saved_notice:String=""

func _init()->void:new_campaign(71127)

func notify(value:String)->void:
    message=value;dirty=true
    print("SESSION ",value)

func new_campaign(seed_number:int)->void:
    campaign=Campaign.new();campaign.seed_value=seed_number
    world=World.new();world.initialize(seed_number)
    for facility:Dictionary in world.facilities.values():
        if facility["existing"] and facility["id"]!="base":
            campaign.facility_state[facility["id"]]={"built":true,"known":false,"registered":false}
    phase="docked";position=Vector2.ZERO;yaw=0.0;paused=false
    current_facility="base";departure_id="base";projectiles.clear();effects.clear()
    hp=max_hp();fuel=max_fuel();attack_cooldown=0;attack_mode="";pickups=0;kills=0
    allow_save=true;dirty=true
    report="最初は遠くへ届きません。発見した成果で少しずつ改修できます。"
    notify("起点ステーションで準備中。")

func max_hp()->float:return 45.0+15.0*int(campaign.upgrades["combat"])
func max_fuel()->float:return 100.0+25.0*int(campaign.upgrades["range"])
func fuel_cost()->float:return 0.4*pow(0.9,int(campaign.upgrades["range"]))
func speed()->float:return 6.0*(1.0+0.12*int(campaign.upgrades["drive"]))
func sense()->float:return 90.0+25.0*int(campaign.upgrades["sensor"])
func cargo_limit()->int:return 3+int(campaign.upgrades["range"])
func upgrade_cost(key:String)->int:return ceili(float(Catalog.UPGRADE_COSTS[key])*pow(1.55,int(campaign.upgrades[key])))
func weapon_reach(profile:Resource)->float:return profile.reach*(1.0+0.035*int(campaign.upgrades["combat"]))
func weapon_damage(profile:Resource)->float:return profile.damage*pow(1.4,int(campaign.upgrades["combat"]))

func facility_state(id:String)->Dictionary:
    return campaign.facility_state.get(id,{"built":false,"known":false,"registered":false})
func facility_built(id:String)->bool:return bool(facility_state(id).get("built",false))
func facility_known(id:String)->bool:return bool(facility_state(id).get("known",false))
func facility_available(id:String)->bool:
    if not world.facilities.has(id):return false
    if phase=="docked":return id==current_facility
    return position.distance_to(world.facilities[id]["pos"])<=14.0
func has_service(id:String,service:String)->bool:
    return facility_available(id) and facility_built(id) and service in world.facilities[id]["services"]

func depart(id:String)->bool:
    if phase!="docked" or not world.facilities.has(id):return false
    var state:=facility_state(id)
    if not state.get("registered",false) or not state.get("built",false):return false
    departure_id=id;current_facility=id;position=world.facilities[id]["pos"]
    campaign.sortie_sequence+=1
    world.reset_sortie(campaign.sortie_sequence);world.ensure_nearby(position)
    phase="travel";paused=false;fuel=max_fuel();hp=max_hp();attack_cooldown=0;attack_mode=""
    pickups=0;kills=0;departure_credits=campaign.credits
    projectiles.clear();effects.clear()
    for facility_id in world.facilities:campaign.stocks[facility_id]=8
    var nearest:=nearest_kind("light")
    if not nearest.is_empty():
        var delta:Vector2=nearest["pos"]-position;yaw=atan2(-delta.x,-delta.y)
    discover()
    notify("%sから出発。" % world.facilities[id]["title"])
    return true

func return_to_departure(reason:String)->void:
    report="%s / 回収 %d・撃破 %d / 資金の増減 %+d C / 最深 %.0f" % [reason,pickups,kills,campaign.credits-departure_credits,campaign.best_range]
    position=world.facilities[departure_id]["pos"];current_facility=departure_id
    phase="docked";paused=false;hp=max_hp();fuel=max_fuel();attack_cooldown=0;attack_mode=""
    projectiles.clear();effects.clear()
    notify(reason+"。出発施設へ帰還しました。成果・改修・施設は保持。")

func dock(id:String)->bool:
    if not has_service(id,"departure"):return false
    departure_id=id;return_to_departure("施設へ帰着")
    return true

func active_objects(radius:=550.0)->Array[Dictionary]:return world.active(position,radius)
func nearest_kind(kind:String,radius:=INF)->Dictionary:
    var result:Dictionary={};var best:float=radius
    for object:Dictionary in world.objects.values():
        if not object["alive"] or object["kind"]!=kind:continue
        var distance:=position.distance_to(object["pos"])
        if distance<best:result=object;best=distance
    return result

func discover()->void:
    for facility:Dictionary in world.facilities.values():
        if position.distance_to(facility["pos"])>sense() or facility_known(facility["id"]):continue
        var state:=facility_state(facility["id"]).duplicate()
        state["known"]=true;campaign.facility_state[facility["id"]]=state
        campaign.credits+=3
        notify("施設を初発見：%s。成果 +3 C" % facility["title"])
    for object:Dictionary in world.active(position,sense()):
        if object["kind"]=="enemy":continue
        if not campaign.discoveries.has(object["id"]):
            campaign.discoveries[object["id"]]={"kind":object["kind"],"pos":object["pos"],"sortie":world.sortie_id}
            dirty=true

func nearest_interaction()->Dictionary:
    var result:Dictionary={};var best:=14.0
    for facility:Dictionary in world.facilities.values():
        var distance:=position.distance_to(facility["pos"])
        if distance<=best:
            result={"kind":"facility","id":facility["id"],"title":facility["title"]};best=distance
    for object:Dictionary in world.active(position,14.0):
        if object["kind"]=="signal" and position.distance_to(object["pos"])<best:
            result={"kind":"signal","id":object["id"],"title":"古い信号"};best=position.distance_to(object["pos"])
    return result

func resolve_signal(id:String,choice:String)->bool:
    var object:Dictionary=world.objects.get(id,{})
    if phase!="travel" or object.is_empty() or not object["alive"] or object["kind"]!="signal" or position.distance_to(object["pos"])>14.0:return false
    if choice not in ["scan","salvage"]:return false
    object["alive"]=false
    if choice=="salvage":campaign.credits+=2;notify("古い記録を回収。成果 +2 C")
    else:
        var count:=reveal_facilities(position,900.0)
        notify("残された接続記録から、施設情報 %d件を取得。" % count)
    return true

func reveal_facilities(origin:Vector2,radius:float)->int:
    var count:=0
    for facility:Dictionary in world.facilities.values():
        if origin.distance_to(facility["pos"])>radius or facility_known(facility["id"]):continue
        var state:=facility_state(facility["id"]).duplicate();state["known"]=true
        campaign.facility_state[facility["id"]]=state;count+=1
    dirty=true
    return count

func buy_upgrade(id:String,key:String)->bool:
    if not has_service(id,"upgrade") or not Catalog.UPGRADE_NAMES.has(key):return false
    if int(campaign.upgrades[key])>=30:return false
    var cost:=upgrade_cost(key)
    if campaign.credits<cost:notify("資金不足。必要 %d C" % cost);return false
    campaign.credits-=cost;campaign.upgrades[key]=int(campaign.upgrades[key])+1
    fuel=minf(fuel,max_fuel());hp=minf(hp,max_hp())
    notify("%sをLv.%dへ改修。−%d C" % [Catalog.UPGRADE_NAMES[key],campaign.upgrades[key],cost])
    return true

func use_weapon(id:String,weapon_id:String)->bool:
    if not has_service(id,"weapons"):return false
    var profile:=Catalog.weapon(weapon_id)
    if profile.id!=weapon_id:return false
    if weapon_id not in campaign.owned_weapons:
        if campaign.credits<profile.price:notify("資金不足。必要 %d C" % profile.price);return false
        campaign.credits-=profile.price;campaign.owned_weapons.append(weapon_id)
    campaign.equipped[profile.slot]=weapon_id
    notify("%sを装備。" % profile.title)
    return true

func supply(id:String)->bool:
    if not has_service(id,"supply"):return false
    fuel=max_fuel();hp=max_hp();notify("補給・修理が完了。")
    return true

func build(id:String)->bool:
    if not world.facilities.has(id) or not facility_available(id) or not facility_known(id) or facility_built(id):return false
    var cost:int=world.facilities[id]["cost"]
    if campaign.credits<cost:notify("建設資金不足。必要 %d C" % cost);return false
    campaign.credits-=cost
    var state:=facility_state(id).duplicate();state["built"]=true
    state["registered"]="departure" in world.facilities[id]["services"]
    campaign.facility_state[id]=state
    notify("施設を建設しました。−%d C" % cost)
    return true

func buy_goods(id:String)->bool:
    if not has_service(id,"trade"):return false
    var price:int=world.facilities[id]["buy"]
    var stock:int=campaign.stocks.get(id,8)
    if campaign.cargo>=cargo_limit():notify("積載上限です。");return false
    if campaign.credits<price or stock<=0:notify("資金または在庫が足りません。");return false
    campaign.credits-=price;campaign.cargo+=1;campaign.stocks[id]=stock-1
    notify("交易データを購入。−%d C" % price)
    return true

func sell_goods(id:String)->bool:
    if not has_service(id,"trade") or campaign.cargo<=0:return false
    var price:int=world.facilities[id]["sell"]
    campaign.cargo-=1;campaign.credits+=price
    campaign.stocks[id]=int(campaign.stocks.get(id,8))+1
    notify("交易データを売却。+%d C" % price)
    return true

func request_survey(id:String)->bool:
    if not has_service(id,"dispatch"):return false
    if not campaign.job.is_empty() and campaign.job.get("status") in ["running","ready"]:return false
    var origin:Vector2=world.facilities[id]["pos"]
    var target:String="";var best:=INF
    for facility:Dictionary in world.facilities.values():
        if facility_known(facility["id"]):continue
        var distance:=origin.distance_to(facility["pos"])
        if distance<best:best=distance;target=facility["id"]
    if target=="":notify("新しい調査対象は見つかりません。");return false
    if campaign.credits<3:notify("調査費用は3 Cです。");return false
    campaign.credits-=3
    campaign.job={"status":"running","target":target,"finish":campaign.world_time+90.0,"origin":id}
    notify("調査担当へ依頼。航行中の90秒で結果が届きます。−3 C")
    return true

func claim_survey(id:String)->bool:
    if not has_service(id,"dispatch") or campaign.job.get("status","")!="ready":return false
    var target:String=campaign.job["target"]
    var state:=facility_state(target).duplicate();state["known"]=true
    campaign.facility_state[target]=state;campaign.job["status"]="claimed"
    notify("調査報告を受領：%sの位置を記録。" % world.facilities[target]["title"])
    return true

func add_marker(title:String)->void:
    campaign.marker_sequence+=1
    campaign.markers.append({"id":campaign.marker_sequence,"title":title.strip_edges().left(40) if not title.strip_edges().is_empty() else "地点","pos":position})
    notify("現在地を記録しました。")
func remove_marker(id:int)->bool:
    for i in range(campaign.markers.size()):
        if int(campaign.markers[i]["id"])==id:
            campaign.markers.remove_at(i);notify("地点メモを削除しました。");return true
    return false

func burst(point:Vector2,kind:String)->void:effects.append({"pos":point,"kind":kind,"age":0.0})
func damage_enemy(enemy:Dictionary,amount:float)->void:
    if not enemy["alive"]:return
    enemy["hp"]=maxf(0.0,float(enemy["hp"])-amount);burst(enemy["pos"],"hit");dirty=true
    if enemy["hp"]<=0:
        enemy["alive"]=false;kills+=1
        campaign.credits+=1+int(enemy["tier"])
        burst(enemy["pos"],"kill")
        notify("%sを停止。成果 +%d C" % [Catalog.enemy(enemy["type"]).title,1+int(enemy["tier"])])

func fire(origin:Vector2,target:String,damage:float,reach:float,hostile:bool)->void:
    shot_sequence+=1
    projectiles.append({"id":shot_sequence,"pos":origin,"origin":origin,"target":target,"damage":damage,"reach":reach+25.0,"hostile":hostile,"life":0.0})

func _enemies(dt:float)->void:
    for enemy:Dictionary in world.active(position,430.0):
        if enemy["kind"]!="enemy":continue
        var profile:=Catalog.enemy(enemy["type"])
        enemy["cooldown"]=maxf(0.0,float(enemy["cooldown"])-dt)
        var p:Vector2=enemy["pos"];var home:Vector2=enemy["home"]
        var distance:=p.distance_to(position)
        if distance<profile.detection and p.distance_to(home)<160.0:
            if profile.keep_distance>0 and distance<profile.keep_distance:
                var away:Vector2=(p-position).normalized();p+=away*profile.speed*dt
            elif distance>maxf(profile.melee_range*0.8,profile.ranged_range*0.75):p=p.move_toward(position,profile.speed*dt)
        elif p.distance_to(home)>3.0:p=p.move_toward(home,profile.speed*dt)
        enemy["pos"]=p;distance=p.distance_to(position)
        if enemy["cooldown"]>0:continue
        if distance<=profile.melee_range:
            hp=maxf(0.0,hp-float(enemy["damage"]));burst(position,"damage")
            enemy["cooldown"]=profile.interval;notify("%sの近接攻撃！ 耐久 −%.0f" % [profile.title,enemy["damage"]])
        elif profile.ranged_range>0 and distance<=profile.ranged_range:
            fire(p,"player",enemy["damage"],profile.ranged_range,true);enemy["cooldown"]=profile.interval

func _attack(dt:float)->void:
    attack_cooldown=maxf(0.0,attack_cooldown-dt)
    var target:=nearest_kind("enemy",150.0)
    attack_mode=""
    if target.is_empty():return
    var distance:=position.distance_to(target["pos"])
    var melee:=Catalog.weapon(campaign.equipped["melee"])
    var ranged:=Catalog.weapon(campaign.equipped["ranged"])
    var selected:Resource
    if distance<=weapon_reach(melee):selected=melee;attack_mode="近接"
    elif distance<=weapon_reach(ranged):selected=ranged;attack_mode="砲撃"
    else:return
    if attack_cooldown>0:return
    attack_cooldown=selected.interval
    if selected.slot=="melee":damage_enemy(target,weapon_damage(selected));burst(target["pos"],"melee")
    else:fire(position,target["id"],weapon_damage(selected),weapon_reach(selected),false)

func _projectiles(dt:float)->void:
    var remaining:Array[Dictionary]=[]
    for shot in projectiles:
        shot["life"]+=dt
        if shot["life"]>8.0:continue
        var destination:Vector2=position
        var enemy:Dictionary={}
        if not shot["hostile"]:
            enemy=world.objects.get(shot["target"],{})
            if enemy.is_empty() or not enemy["alive"]:continue
            destination=enemy["pos"]
        if destination.distance_to(shot["origin"])>float(shot["reach"]):continue
        var p:Vector2=shot["pos"]
        var travel:float=(24.0 if shot["hostile"] else 60.0)*dt
        if p.distance_to(destination)<=travel+0.7:
            if shot["hostile"]:
                hp=maxf(0.0,hp-float(shot["damage"]));burst(position,"damage")
                notify("砲撃を受けた。耐久 −%.0f" % shot["damage"])
            else:damage_enemy(enemy,float(shot["damage"]))
        else:
            shot["pos"]=p.move_toward(destination,travel);remaining.append(shot)
    projectiles=remaining

func tick(dt:float,forward:float,turn:float)->void:
    if phase!="travel" or paused:return
    campaign.world_time+=dt
    yaw=wrapf(yaw+turn*0.75*dt,-PI,PI)
    var requested:=absf(forward)*speed()*dt
    var distance:=minf(requested,fuel/maxf(0.0001,fuel_cost()))
    position+=Vector2(-sin(yaw),-cos(yaw))*signf(forward)*distance
    fuel=maxf(0.0,fuel-distance*fuel_cost())
    if position.length()>World.RADIUS:position=position.normalized()*World.RADIUS
    if position.length()>campaign.best_range:
        campaign.best_range=position.length()
        var step:=floori(campaign.best_range/100.0)
        if step>campaign.paid_step:
            campaign.credits+=step-campaign.paid_step;campaign.paid_step=step
            notify("到達記録更新：%.0f。探索成果を獲得。" % campaign.best_range)
    if position.length()>=9999.9 and not campaign.reached_edge:
        campaign.reached_edge=true;notify("10000の果てへ到達。到達記録を保存しました。")
    world.ensure_nearby(position);discover()
    for object:Dictionary in world.active(position,6.0):
        if object["kind"]=="light":
            object["alive"]=false;pickups+=1
            campaign.credits+=int(object["reward"])
            fuel=minf(max_fuel(),fuel+float(object["fuel"]))
            burst(object["pos"],"collect")
            notify("光を回収。+%d C / 燃料 +%.0f" % [object["reward"],object["fuel"]])
    _enemies(dt)
    if hp>0:_attack(dt)
    _projectiles(dt)
    for effect in effects:effect["age"]+=dt
    effects=effects.filter(func(value:Dictionary)->bool:return float(value["age"])<0.65)
    if campaign.job.get("status","")=="running" and campaign.world_time>=float(campaign.job["finish"]):
        campaign.job["status"]="ready";notify("調査担当から報告が届きました。派遣施設で受領できます。")
    if hp<=0:return_to_departure("耐久切れ")
    elif fuel<=0:return_to_departure("燃料切れ")
    dirty=true

func save_game(path:=SAVE_PATH)->bool:
    if not allow_save:return false
    var session:Dictionary={}
    for key in ["phase","position","yaw","hp","fuel","current_facility","departure_id","projectiles","attack_cooldown","attack_mode","shot_sequence","pickups","kills","departure_credits","report"]:session[key]=get(key)
    var success:bool=Storage.write(path,{"campaign":campaign.to_dict(),"world":world.to_dict(),"session":session})
    if success:dirty=false;saved_notice="保存済み"
    else:saved_notice="保存に失敗しました。"
    return success

func load_game(path:=SAVE_PATH)->String:
    var result:=Storage.read(path)
    if result["status"]=="missing":return "missing"
    if result["status"]!="ok":allow_save=false;message=result["reason"];return "error"
    var data:Dictionary=result["data"]
    var state:Dictionary=data["session"]
    if not data.get("world") is Dictionary or not state.get("position") is Vector2 or state.get("phase") not in ["docked","travel"]:
        allow_save=false;message="保存データの内容を読み取れません。元の保存は保護しました。";return "error"
    campaign=Campaign.new();campaign.from_dict(data["campaign"])
    world=World.new();world.initialize(campaign.seed_value);world.from_dict(data["world"])
    for key in ["phase","position","yaw","hp","fuel","current_facility","departure_id","projectiles","attack_cooldown","attack_mode","shot_sequence","pickups","kills","departure_credits","report"]:
        if state.has(key):
            if key=="projectiles":projectiles.assign(state[key])
            else:set(key,state[key])
    if not world.facilities.has(current_facility) or not world.facilities.has(departure_id):
        allow_save=false;message="施設情報が一致しません。元の保存は保護しました。";return "error"
    allow_save=true;paused=phase=="travel";effects.clear();dirty=false
    message="保存データを復元。";saved_notice="保存を復元"
    return "ok"
