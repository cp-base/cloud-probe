extends RefCounted
const Catalog=preload("res://data/catalog.gd")

static func weapon_state(session:RefCounted)->Dictionary:
    var melee:Resource=Catalog.weapon(session.campaign.equipped["melee"])
    var ranged:Resource=Catalog.weapon(session.campaign.equipped["ranged"])
    return {"melee":melee.title,"melee_reach":session.weapon_reach(melee),"melee_damage":session.weapon_damage(melee),"ranged":ranged.title,"ranged_reach":session.weapon_reach(ranged),"ranged_damage":session.weapon_damage(ranged),"mode":session.attack_mode,"cooldown":session.attack_cooldown}

static func enemy_state(session:RefCounted,enemy:Dictionary)->Dictionary:
    var profile:Resource=Catalog.enemy(enemy["type"])
    var distance:float=session.position.distance_to(enemy["pos"])
    var reach:float=maxf(profile.melee_range,profile.ranged_range)
    var cooldown:float=float(enemy.get("cooldown",0.0))
    var incoming:bool=false
    for shot:Dictionary in session.projectiles:
        if bool(shot.get("hostile",false)):incoming=true;break
    var risk:int=0
    if distance<profile.detection:risk=1
    if distance<=reach:risk=2
    if distance<=reach and cooldown<=0.4:risk=3
    if incoming:risk=3
    var state:String="待機 / 遠方"
    if risk==1:state="追跡・接近"
    elif risk==2:state="敵の射程内"
    elif risk==3:state="被弾注意"
    if bool(enemy.get("windup",false)):state="重装・攻撃予兆";risk=3
    var behavior:String="巡回" if enemy.get("behavior","wait")=="patrol" else "待機"
    return {"id":enemy["id"],"title":profile.title,"type":enemy["type"],"behavior":behavior,"distance":distance,"hp":float(enemy["hp"]),"max_hp":float(enemy["max_hp"]),"danger":risk,"state":state,"reach":reach,"cooldown":cooldown,"color":profile.color}

static func nearest(session:RefCounted,maximum:float=150.0)->Array[Dictionary]:
    var values:Array[Dictionary]=[]
    for enemy:Dictionary in session.active_objects(maximum):
        if enemy.get("kind")!="enemy":continue
        values.append(enemy_state(session,enemy))
    values.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a["distance"]<b["distance"])
    return values
