extends RefCounted
var seed_value:int=71127
var credits:int=0
var upgrades:Dictionary={"range":0,"drive":0,"combat":0,"sensor":0}
var owned_weapons:Array=["cannon","blade"]
var equipped:Dictionary={"ranged":"cannon","melee":"blade"}
var facility_state:Dictionary={"base":{"built":true,"known":true,"registered":true}}
var discoveries:Dictionary={}
var markers:Array=[]
var marker_sequence:int=0
var cargo:int=0
var stocks:Dictionary={}
var job:Dictionary={}
var world_time:float=0.0
var best_range:float=0.0
var paid_step:int=0
var reached_edge:bool=false
var sortie_sequence:int=0
var settings:Dictionary={"glow":false}

func to_dict()->Dictionary:
    var result:Dictionary={}
    for key in ["seed_value","credits","upgrades","owned_weapons","equipped","facility_state","discoveries","markers","marker_sequence","cargo","stocks","job","world_time","best_range","paid_step","reached_edge","sortie_sequence","settings"]:
        result[key]=get(key)
    return result

func from_dict(data:Dictionary)->void:
    for key in to_dict().keys():
        if data.has(key):set(key,data[key])
    credits=maxi(0,int(credits))
    for key in upgrades:upgrades[key]=clampi(int(upgrades[key]),0,30)
    if not facility_state.has("base"):facility_state["base"]={"built":true,"known":true,"registered":true}

