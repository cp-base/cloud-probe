extends Control
## Separate playable research scene; Foundation's Main.tscn is unchanged.
const World=preload("res://core/world.gd")
const Campaign=preload("res://core/campaign.gd")
const Storage=preload("res://core/storage.gd")
const Ledger=preload("res://research/exploration/exploration_ledger.gd")
const SAVE_PATH:="res://.local/exploration_lab.json"
const MAP_RECT:=Rect2(22,96,820,638)
var world:RefCounted
var campaign:RefCounted
var ledger:RefCounted
var ship_pos:=Vector2.ZERO
var yaw:float=0.0
var zoom:float=1400.0
var sensor_range:float=90.0
var demo_speed:float=155.0 # Lab camera-only travel, not Foundation ship balance.
var status:String="航行開始。WASD / 矢印で移動、地図をクリックして経由点を追加。"
var was_scanned:bool=false
var has_focus:bool=true
var screenshot_path:String=""

func _ready()->void:
    mouse_filter=Control.MOUSE_FILTER_STOP
    set_process(true)
    world=World.new();world.initialize(71127)
    campaign=Campaign.new()
    ledger=Ledger.new()
    world.reset_sortie(1)
    campaign.sortie_sequence=1
    ledger.begin_sortie(1)
    update_exploration()
    add_button("出撃を更新",150,func():new_sortie())
    add_button("周辺情報を取得",188,func():wide_scan())
    add_button("現在地を経由点へ",226,func():mark_here())
    add_button("航路を消去",264,func():ledger.clear_route();status="航路線のみ削除。地点記録は保持。";queue_redraw())
    add_button("研究データ保存",302,func():save_state())
    add_button("研究データ再読込",340,func():load_state())
    add_button("起点へ戻る",378,func():ship_pos=Vector2.ZERO;update_exploration();status="起点へ移動（実験操作）";queue_redraw())
    add_button("拡大",416,func():zoom=maxf(240.0,zoom*0.7);queue_redraw())
    add_button("縮小",454,func():zoom=minf(10500.0,zoom/0.7);queue_redraw())
    if "--evidence" in OS.get_cmdline_user_args():
        demo_fixture()
        screenshot_path="res://research/exploration/evidence/overview.png"
        call_deferred("capture_evidence")

func add_button(text_value:String,y:int,callback:Callable)->void:
    var b:=Button.new()
    b.text=text_value
    b.position=Vector2(868,y)
    b.custom_minimum_size=Vector2(282,32)
    b.pressed.connect(callback)
    add_child(b)

func new_sortie()->void:
    campaign.sortie_sequence+=1
    world.reset_sortie(campaign.sortie_sequence)
    ledger.begin_sortie(campaign.sortie_sequence)
    ship_pos=Vector2.ZERO
    was_scanned=false
    update_exploration()
    status="出撃 %d。既知の地形・経由点・航路は維持。動的対象は更新。" % campaign.sortie_sequence
    queue_redraw()

func update_exploration()->void:
    world.ensure_nearby(ship_pos)
    ledger.record_position(ship_pos,world,sensor_range)
    queue_redraw()

func wide_scan()->void:
    var count:int=ledger.scan_area(ship_pos,world,900.0)
    was_scanned=true
    status="半径900を試験スキャン。新しい施設 %d件（調査専用の無料操作）。" % count
    queue_redraw()

func mark_here()->void:
    var id:String=ledger.add_waypoint(ship_pos)
    if id!="":ledger.append_route(id)
    status="現在地を記録。" if id!="" else "地点数か境界の制限。"
    queue_redraw()

func save_state(path:String=SAVE_PATH)->bool:
    campaign.settings["exploration_lab"]=ledger.to_dict()
    var ok:bool=Storage.write(path,{"campaign":campaign.to_dict(),"world":world.to_dict(),"session":{"position":ship_pos,"yaw":yaw,"phase":"travel"}})
    status="研究データを保存。" if ok else "保存エラー。"
    queue_redraw()
    return ok

func load_state(path:String=SAVE_PATH)->bool:
    var loaded:Dictionary=Storage.read(path)
    if loaded.get("status")!="ok":
        status="再読込失敗："+str(loaded.get("status"));queue_redraw();return false
    var d:Dictionary=loaded["data"]
    if not d.get("world") is Dictionary or not d["session"].get("position") is Vector2:
        status="不完全な試験データ。";queue_redraw();return false
    var next_campaign:=Campaign.new();next_campaign.from_dict(d["campaign"])
    var next_world:=World.new();next_world.initialize(next_campaign.seed_value);next_world.from_dict(d["world"])
    var next_ledger:=Ledger.new();next_ledger.from_dict(next_campaign.settings.get("exploration_lab",{}))
    campaign=next_campaign;world=next_world;ledger=next_ledger
    ship_pos=d["session"]["position"];yaw=float(d["session"].get("yaw",0.0))
    status="再読込成功：位置・出撃・記録・動的対象を復元。"
    update_exploration()
    return true

func _process(delta:float)->void:
    var input:=Vector2.ZERO
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):input.y-=1
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):input.y+=1
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):input.x-=1
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):input.x+=1
    if input.length_squared()>0:
        var next:Vector2=ship_pos+input.normalized()*demo_speed*delta
        ship_pos=next.limit_length(World.RADIUS)
        update_exploration()

func _gui_input(event:InputEvent)->void:
    if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and MAP_RECT.has_point(event.position):
        var p:=pixel_to_world(event.position)
        var id:String=ledger.add_waypoint(p)
        if id!="":ledger.append_route(id)
        status="地図へ経由点を追加（自動移動ではありません）。" if id!="" else "境界外か記録数上限。"
        queue_redraw()
    if event is InputEventMouseButton and event.pressed and MAP_RECT.has_point(event.position):
        if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom=maxf(240.0,zoom*0.8);queue_redraw()
        if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom=minf(10500.0,zoom/0.8);queue_redraw()

func _unhandled_key_input(event:InputEvent)->void:
    if not event.pressed or event.echo:return
    match event.keycode:
        KEY_N:new_sortie()
        KEY_M:mark_here()
        KEY_E:wide_scan()
        KEY_F5:save_state()
        KEY_F9:load_state()

func world_to_pixel(p:Vector2)->Vector2:
    return MAP_RECT.get_center()+(p-ship_pos)*(MAP_RECT.size.y*0.5/zoom)
func pixel_to_world(p:Vector2)->Vector2:
    return ship_pos+(p-MAP_RECT.get_center())*(zoom/(MAP_RECT.size.y*0.5))

func draw_map_text(pos:Vector2,value:String,color:Color=Color("c3e0e6"),font_size:int=14)->void:
    draw_string(ThemeDB.fallback_font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw()->void:
    draw_rect(Rect2(Vector2.ZERO,size),Color("07151f"))
    draw_map_text(Vector2(24,39),"CLOUD / PROBE   —   EXPLORATION RESEARCH LAB",Color("baf1ee"),24)
    draw_map_text(Vector2(24,68),"480区画 / 常設施設と毎回の動的対象 / 経路は記録のみ（自動移動なし）",Color("91aebd"),15)
    draw_rect(MAP_RECT,Color("09202c"),true)
    var unit:float=MAP_RECT.size.y*0.5/zoom
    # Surveyed sections are inferred intel; visited sections have independent evidence.
    var minc:Vector2i=Vector2i(floori((ship_pos.x-zoom*1.5)/World.CHUNK),floori((ship_pos.y-zoom*1.2)/World.CHUNK))
    var maxc:Vector2i=Vector2i(floori((ship_pos.x+zoom*1.5)/World.CHUNK),floori((ship_pos.y+zoom*1.2)/World.CHUNK))
    for x in range(minc.x,maxc.x+1):
        for y in range(minc.y,maxc.y+1):
            var id:="%d:%d" % [x,y]
            var top_left:=world_to_pixel(Vector2(x*World.CHUNK,y*World.CHUNK))
            var cell:=Rect2(top_left,Vector2.ONE*World.CHUNK*unit)
            var clipped:=cell.intersection(MAP_RECT)
            if clipped.has_area():
                if ledger.visited.has(id):draw_rect(clipped,Color("214e58"),true)
                elif ledger.surveyed.has(id):draw_rect(clipped,Color("133744"),true)
                draw_rect(clipped,Color("31515e",0.45),false,1.0)
    draw_circle(world_to_pixel(Vector2.ZERO),3,Color("bcb5fc"))
    # Trail contains deliberate breaks across sorties; never connect returns to base.
    var last_point:=Vector2.ZERO
    var has_prev:=false
    for item in ledger.trail:
        if item.has("break"):has_prev=false;continue
        if not item.has("pos"):continue
        var px:Vector2=world_to_pixel(item["pos"])
        if has_prev and MAP_RECT.has_point(px) and MAP_RECT.has_point(last_point):draw_line(last_point,px,Color("49aaad",0.7),1.6)
        last_point=px;has_prev=true
    var waypoint_map:Dictionary={}
    for wp:Dictionary in ledger.waypoints:waypoint_map[wp["id"]]=wp
    for i in range(1,ledger.route.size()):
        var a:Vector2=world_to_pixel(waypoint_map[ledger.route[i-1]]["pos"])
        var b:Vector2=world_to_pixel(waypoint_map[ledger.route[i]]["pos"])
        if MAP_RECT.has_point(a) or MAP_RECT.has_point(b):draw_line(a,b,Color("f6c677"),2.5)
    for wp:Dictionary in ledger.waypoints:
        var p:=world_to_pixel(wp["pos"])
        if MAP_RECT.has_point(p):
            draw_circle(p,5.5,Color("ffd27d"),false,1.7)
            draw_map_text(p+Vector2(8,-7),wp["title"],Color("ffdcb2"),11)
    # Stable facilities use full integer IDs. Unseen facilities deliberately hidden.
    for f:Dictionary in world.facilities.values():
        if not ledger.contacts.has(f["id"]):continue
        var p:=world_to_pixel(f["pos"])
        if MAP_RECT.has_point(p):
            var contact:Dictionary=ledger.contacts[f["id"]]
            draw_rect(Rect2(p-Vector2.ONE*5,Vector2.ONE*10),Color("efc777") if contact["visited"] else Color("866d47"))
            draw_map_text(p+Vector2(9,4),f["title"],Color("ddc694"),11)
    for obj:Dictionary in world.active(ship_pos,sensor_range):
        var p:=world_to_pixel(obj["pos"])
        if not MAP_RECT.has_point(p):continue
        var color:=Color("ff668d") if obj["kind"]=="enemy" else (Color("b8a2ff") if obj["kind"]=="signal" else Color("62dbf5"))
        draw_circle(p,3.4,color)
    draw_circle(world_to_pixel(ship_pos),maxf(4.0,sensor_range*unit),Color("8ba8a9",0.42),false,1.0)
    if was_scanned:draw_circle(world_to_pixel(ship_pos),900.0*unit,Color("42677f",0.40),false,1.0)
    var center:=world_to_pixel(ship_pos)
    draw_colored_polygon(PackedVector2Array([center+Vector2(0,-9),center+Vector2(-6,5),center+Vector2(6,5)]),Color("dffbf7"))
    draw_rect(MAP_RECT,Color("527887"),false,1.0)
    draw_map_text(Vector2(872,111),"WORLD LEDGER",Color("baf1ee"),20)
    draw_map_text(Vector2(872,513),"出撃  %d" % campaign.sortie_sequence,Color("c1e6eb"),16)
    draw_map_text(Vector2(872,539),"座標  %.0f, %.0f" % [ship_pos.x,ship_pos.y],Color("c1e6eb"),15)
    draw_map_text(Vector2(872,566),"探索区画  %d" % ledger.visited.size(),Color("8ed7d5"),15)
    draw_map_text(Vector2(872,592),"推定区画  %d" % ledger.surveyed.size(),Color("82b3d7"),15)
    draw_map_text(Vector2(872,618),"既知施設  %d" % ledger.contacts.size(),Color("efc777"),15)
    draw_map_text(Vector2(872,644),"地点 / 航路節  %d / %d" % [ledger.waypoints.size(),ledger.route.size()],Color("efc777"),15)
    draw_map_text(Vector2(24,751),"%s   |   ズーム ±%.0f" % [status,zoom],Color("a8c7d2"),13)

func demo_fixture()->void:
    # Deterministic visual scenario; not a playthrough and not saved.
    var positions:=[Vector2(0,0),Vector2(40,-95),Vector2(72,-180),Vector2(210,-300),Vector2(330,-380),Vector2(390,-510)]
    for p in positions:
        ship_pos=p;update_exploration()
        ledger.append_route(ledger.add_waypoint(p))
    ledger.scan_area(ship_pos,world,900.0)
    was_scanned=true
    status="スクリーンショット用の座標注入（通常攻略ではない）"
    queue_redraw()

func capture_evidence()->void:
    await RenderingServer.frame_post_draw
    var img:Image=get_viewport().get_texture().get_image()
    var absolute:=ProjectSettings.globalize_path(screenshot_path)
    DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
    var err:=img.save_png(absolute)
    print("EVIDENCE_SAVE ",err," ",absolute)
    get_tree().quit(0 if err==OK else 1)
