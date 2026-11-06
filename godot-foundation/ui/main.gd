extends Node3D
const Session=preload("res://core/session.gd")
const Catalog=preload("res://data/catalog.gd")
const LightShader=preload("res://visuals/light.gdshader")
const MapView=preload("res://ui/map_view.gd")
var game:RefCounted
var camera:Camera3D
var environment:Environment
var markers:Dictionary={}
var shots:Dictionary={}
var effect_nodes:Array[MeshInstance3D]=[]
var held:Dictionary={"forward":false,"back":false,"left":false,"right":false}
var auto_forward:bool=false
var root:Control
var modal:PanelContainer
var modal_kind:String=""
var modal_id:String=""
var modal_tab:int=0
var auto_button:Button
var pause_button:Button
var access_button:Button
var status:Label
var resources_label:Label
var notice:Label
var guide:Label
var hp_bar:ProgressBar
var fuel_bar:ProgressBar
var mini_map:Control
var flash:ColorRect
var target_id:String=""
var previous_hp:float=45.0
var sync_time:float=0.0
var save_time:float=0.0
var enemy_labels:Array[Label]=[]
var reset_dialog:ConfirmationDialog

func _ready()->void:
    get_tree().auto_accept_quit=false
    game=Session.new()
    var loaded:String=game.load_game()
    _build_world();_build_ui();_sync_markers();_visuals(0.0)
    if loaded=="error":_settings()
    elif game.phase=="docked":_facility(game.current_facility)
    print("FOUNDATION_READY phase=%s load=%s speed=%.1f fuel=%.0f" % [game.phase,loaded,game.speed(),game.max_fuel()])

func _build_world()->void:
    environment=Environment.new();environment.background_mode=Environment.BG_SKY
    var sky_material:=ProceduralSkyMaterial.new()
    sky_material.sky_top_color=Color("07141f");sky_material.sky_horizon_color=Color("102731")
    sky_material.ground_bottom_color=Color("07141f");sky_material.ground_horizon_color=Color("102731")
    sky_material.sky_energy_multiplier=0.6
    sky_material.ground_energy_multiplier=0.6
    sky_material.sky_curve=0.5;sky_material.ground_curve=0.5
    var sky:=Sky.new();sky.sky_material=sky_material;environment.sky=sky
    environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
    environment.glow_intensity=0.16;environment.glow_hdr_threshold=0.9
    var world_environment:=WorldEnvironment.new();world_environment.environment=environment;add_child(world_environment)
    camera=Camera3D.new();camera.fov=72;camera.far=700;add_child(camera);camera.current=true

func _object_height(object:Dictionary)->float:
    var phase:float=object.get("phase",0.0)
    return sin(phase)*2.0+sin(game.campaign.world_time*0.3+phase)*0.2

func _marker(color:Color,appearance:int,size_value:float,shape:=0)->MeshInstance3D:
    var node:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(size_value,size_value);node.mesh=quad
    node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var material:=ShaderMaterial.new();material.shader=LightShader
    material.set_shader_parameter("signal_color",color);material.set_shader_parameter("appearance",appearance);material.set_shader_parameter("kind",shape)
    node.material_override=material;add_child(node);return node

func _sync_markers()->void:
    var live:Dictionary={}
    for object:Dictionary in game.active_objects(600.0):
        var key:String=object["id"];live[key]=true
        if not markers.has(key):
            var hostile:bool=object["kind"]=="enemy"
            var profile:Resource=Catalog.enemy(object["type"]) if hostile else null
            var color:Color=profile.color if hostile else (Color("67ffcb") if object["kind"]=="signal" else Color("55d5ff"))
            markers[key]=_marker(color,1 if hostile or object["kind"]=="signal" else 2,7.0 if hostile else 6.0,profile.shape if hostile else 3)
        markers[key].position=Vector3(object["pos"].x,_object_height(object),object["pos"].y)
    for facility:Dictionary in game.world.facilities.values():
        if game.position.distance_to(facility["pos"])>650.0:continue
        var key:String="f:"+facility["id"];live[key]=true
        var color:=Color("ffd18a") if game.facility_built(facility["id"]) else Color("a79ca3")
        if not markers.has(key):markers[key]=_marker(color,1,13.0,3)
        markers[key].material_override.set_shader_parameter("signal_color",color)
        markers[key].position=Vector3(facility["pos"].x,0.0,facility["pos"].y)
    for key:String in markers.keys():
        if not live.has(key):markers[key].queue_free();markers.erase(key)

func _label(text_value:String,fs:=16)->Label:
    var label:=Label.new();label.text=text_value;label.add_theme_font_size_override("font_size",fs)
    label.mouse_filter=Control.MOUSE_FILTER_IGNORE;return label
func _button(text_value:String,callback:Callable,width:=130.0)->Button:
    var button:=Button.new();button.text=text_value;button.custom_minimum_size=Vector2(width,40)
    button.focus_mode=Control.FOCUS_NONE;button.pressed.connect(callback);return button
func _row(parent:Node)->HBoxContainer:
    var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);parent.add_child(row);return row
func _section(parent:Node,text_value:String)->void:parent.add_child(_label(text_value,19))

func _build_ui()->void:
    var layer:=CanvasLayer.new();layer.layer=10;add_child(layer)
    root=Control.new();layer.add_child(root);root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE
    root.theme=Theme.new();root.theme.default_font_size=16
    var font:=SystemFont.new();font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo","sans-serif"]);root.theme.default_font=font
    flash=ColorRect.new();root.add_child(flash);flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.color=Color(0.8,0.05,0.12,0);flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var top:=VBoxContainer.new();root.add_child(top);top.position=Vector2(22,15);top.add_theme_constant_override("separation",8)
    top.add_child(_label("CLOUD / PROBE   —   全体模型",24))
    status=_label("");top.add_child(status)
    var row:=_row(top)
    access_button=_button("アクセス",_access,180);row.add_child(access_button)
    row.add_child(_button("地図・記録",_map))
    row.add_child(_button("保存",_save,95))
    pause_button=_button("一時停止",_toggle_pause);row.add_child(pause_button)
    row.add_child(_button("設定",_settings,95))
    var reticle:=_label("＋",22);root.add_child(reticle);reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER);reticle.position-=Vector2(10,15);reticle.modulate=Color(0.7,0.85,0.9,0.35)
    guide=_label("",14);root.add_child(guide);guide.modulate=Color("b3e9eb")
    for i in range(5):
        var label:=_label("",14);label.modulate=Color("ffa1b6");root.add_child(label);enemy_labels.append(label)
    mini_map=Control.new();mini_map.set_script(MapView);mini_map.session=game;root.add_child(mini_map)
    mini_map.anchor_left=1;mini_map.anchor_right=1;mini_map.offset_left=-180;mini_map.offset_right=-20;mini_map.offset_top=165;mini_map.offset_bottom=325
    mini_map.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var bottom:=VBoxContainer.new();root.add_child(bottom);bottom.anchor_left=0.5;bottom.anchor_right=0.5;bottom.anchor_top=1;bottom.anchor_bottom=1
    bottom.offset_left=-440;bottom.offset_right=440;bottom.offset_top=-170;bottom.offset_bottom=-10;bottom.add_theme_constant_override("separation",5)
    var bars:=_row(bottom)
    bars.add_child(_label("燃料"));fuel_bar=ProgressBar.new();fuel_bar.custom_minimum_size=Vector2(145,22);bars.add_child(fuel_bar)
    bars.add_child(_label("耐久"));hp_bar=ProgressBar.new();hp_bar.custom_minimum_size=Vector2(145,22);bars.add_child(hp_bar)
    resources_label=_label("");bars.add_child(resources_label)
    notice=_label("",15);notice.modulate=Color("ffe1a9");bottom.add_child(notice)
    var controls:=_row(bottom);controls.alignment=BoxContainer.ALIGNMENT_CENTER
    for item in [["◀ 左旋回","left"],["▼ 後退","back"],["▲ 前進","forward"],["右旋回 ▶","right"]]:
        var button:=_button(item[0],func():pass)
        button.button_down.connect(_hold.bind(item[1],true));button.button_up.connect(_hold.bind(item[1],false));controls.add_child(button)
    auto_button=_button("自動前進",func():pass);auto_button.toggle_mode=true;auto_button.toggled.connect(func(value:bool):auto_forward=value);controls.add_child(auto_button)
    bottom.add_child(_label("W/S・↑↓：前後　A/D・←→：旋回　Space：停止/再開　E：アクセス　M：地図",14))
    bottom.add_child(_label("砲撃と近接は自動。燃料切れ・敗北では出発施設へ戻り、成果を使って再挑戦できます。",14))
    reset_dialog=ConfirmationDialog.new();root.add_child(reset_dialog)
    reset_dialog.dialog_text="新しい世界を作ります。現在の進行は初期状態になります。"
    reset_dialog.confirmed.connect(_new_campaign)

func _hold(key:String,value:bool)->void:
    held[key]=value
    if key=="back" and value:_stop_auto()
func _stop_auto()->void:
    auto_forward=false
    if auto_button!=null:auto_button.set_pressed_no_signal(false)
func _toggle_pause()->void:
    if modal!=null or game.phase!="travel":return
    game.paused=not game.paused;_stop_auto()
func _save()->void:
    if game.save_game():game.message="保存しました。"
    else:game.message="保存できませんでした。元の保存を保護しています。"

func _clear_modal()->void:
    if modal!=null:root.remove_child(modal);modal.queue_free();modal=null
func _close_modal()->void:
    _clear_modal();modal_kind="";game.paused=false
    game.save_game();_sync_markers()
func _open_modal(title:String)->VBoxContainer:
    _stop_auto();game.paused=true;_clear_modal()
    modal=PanelContainer.new();root.add_child(modal);modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    modal.offset_left=55;modal.offset_right=-55;modal.offset_top=45;modal.offset_bottom=-35
    var style:=StyleBoxFlat.new();style.bg_color=Color("0c1c29");style.border_color=Color("52798b");style.set_border_width_all(1);style.set_corner_radius_all(12);style.set_content_margin_all(20)
    modal.add_theme_stylebox_override("panel",style)
    var body:=VBoxContainer.new();body.add_theme_constant_override("separation",12);modal.add_child(body)
    var header:=_row(body);var heading:=_label(title,23);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(heading)
    header.add_child(_button("閉じる",_close_modal,100))
    return body

func _page(tabs:TabContainer,title:String)->VBoxContainer:
    var scroll:=ScrollContainer.new();scroll.name=title;tabs.add_child(scroll)
    var page:=VBoxContainer.new();page.size_flags_horizontal=Control.SIZE_EXPAND_FILL;page.add_theme_constant_override("separation",12);scroll.add_child(page)
    return page
func _action(callback:Callable)->void:
    callback.call();game.save_game();_sync_markers()
    if game.phase=="docked" or modal_kind=="facility":_facility(modal_id)

func _facility(id:String)->void:
    if not game.world.facilities.has(id):return
    if game.phase=="travel" and not game.facility_available(id):return
    modal_kind="facility";modal_id=id
    var facility:Dictionary=game.world.facilities[id]
    var body:=_open_modal(facility["title"])
    body.add_child(_label("資金 %d C　積載 %d/%d　燃料 %.0f/%.0f　耐久 %.0f/%.0f" % [game.campaign.credits,game.campaign.cargo,game.cargo_limit(),game.fuel,game.max_fuel(),game.hp,game.max_hp()],17))
    body.add_child(_label(game.message,15))
    var tabs:=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(tabs)
    var general:=_page(tabs,"準備・施設")
    if not game.facility_built(id):
        _section(general,"まだ稼働していない候補地")
        general.add_child(_label("建設費 %d C。建てた施設は次の探索にも残ります。" % facility["cost"]))
        general.add_child(_button("この施設を建設",_action.bind(game.build.bind(id)),260))
    else:
        general.add_child(_label("この施設の機能："+_service_names(facility["services"])))
        if game.has_service(id,"supply"):general.add_child(_button("補給・修理",_action.bind(game.supply.bind(id)),230))
        if game.phase=="travel" and game.has_service(id,"departure"):
            general.add_child(_button("ここで探索を区切って帰着",_action.bind(game.dock.bind(id)),330))
        if game.phase=="docked":
            _section(general,"次の出発")
            general.add_child(_label(game.report))
            var selection:=OptionButton.new();selection.custom_minimum_size=Vector2(480,42)
            var index:=0
            for available:Dictionary in game.world.facilities.values():
                if not game.facility_state(available["id"]).get("registered",false):continue
                selection.add_item(available["title"]+" / 深度 %.0f" % available["pos"].length())
                selection.set_item_metadata(index,available["id"])
                if available["id"]==game.current_facility:selection.select(index)
                index+=1
            general.add_child(selection)
            general.add_child(_button("選んだ施設から出発",func():_depart(selection.get_item_metadata(selection.selected)),330))
        else:general.add_child(_button("補給地点を離れて航行を続ける",_close_modal,330))
    if game.has_service(id,"upgrade"):
        var page:=_page(tabs,"改修")
        page.add_child(_label("最初は弱い状態です。必要な能力へ少しずつ投資できます。"))
        for key:String in Catalog.UPGRADE_NAMES:
            var level:int=game.campaign.upgrades[key];var cost:int=game.upgrade_cost(key)
            var row:=_row(page);row.add_child(_label("%s Lv.%d　%s" % [Catalog.UPGRADE_NAMES[key],level,_upgrade_description(key)]))
            var button:=_button("改修 %d C" % cost,_action.bind(game.buy_upgrade.bind(id,key)),145);button.disabled=game.campaign.credits<cost;row.add_child(button)
    if game.has_service(id,"weapons"):
        var page:=_page(tabs,"装備")
        page.add_child(_label("遠距離と近接を1つずつ装備。距離に応じて自動で切り替わります。"))
        for weapon:Resource in Catalog.WEAPONS:
            var equipped:bool=game.campaign.equipped[weapon.slot]==weapon.id
            var owned:bool=weapon.id in game.campaign.owned_weapons
            var row:=_row(page)
            row.add_child(_label("%s　射程 %.0f / 威力 %.0f / %.1f秒" % [weapon.title,game.weapon_reach(weapon),game.weapon_damage(weapon),weapon.interval]))
            var button:=_button("装備中" if equipped else ("装備する" if owned else "購入・装備 %d C" % weapon.price),_action.bind(game.use_weapon.bind(id,weapon.id)),180)
            button.disabled=equipped or (not owned and game.campaign.credits<weapon.price);row.add_child(button)
    if game.has_service(id,"trade"):
        var page:=_page(tabs,"交易")
        _section(page,"交易データ 1種類")
        page.add_child(_label("買って運び、別の施設で売却できます。場所によって価格が違います。"))
        page.add_child(_label("購入 %d C / 売却 %d C / 在庫 %d / 積載 %d/%d" % [facility["buy"],facility["sell"],game.campaign.stocks.get(id,8),game.campaign.cargo,game.cargo_limit()]))
        var row:=_row(page)
        row.add_child(_button("1個購入",_action.bind(game.buy_goods.bind(id)),190))
        var sell:=_button("1個売却",_action.bind(game.sell_goods.bind(id)),190);sell.disabled=game.campaign.cargo<=0;row.add_child(sell)
    if game.has_service(id,"dispatch"):
        var page:=_page(tabs,"調査派遣")
        _section(page,"調査担当 1枠")
        page.add_child(_label("未発見の施設1か所を調査します。費用3 C、航行中90秒。停止中と終了中は進みません。"))
        var job:Dictionary=game.campaign.job
        var text:="依頼なし"
        if job.get("status")=="running":text="調査中：残り %.0f秒" % maxf(0.0,float(job["finish"])-game.campaign.world_time)
        elif job.get("status")=="ready":text="報告が届いています。"
        elif job.get("status")=="claimed":text="前回の報告は受領済みです。"
        page.add_child(_label(text,18))
        var row:=_row(page)
        var request:=_button("調査を依頼 3 C",_action.bind(game.request_survey.bind(id)),240)
        request.disabled=game.campaign.credits<3 or job.get("status","") in ["running","ready"];row.add_child(request)
        var claim:=_button("報告を受け取る",_action.bind(game.claim_survey.bind(id)),240);claim.disabled=job.get("status","")!="ready";row.add_child(claim)
    tabs.current_tab=mini(modal_tab,tabs.get_tab_count()-1)
    tabs.tab_changed.connect(func(value:int):modal_tab=value)

func _depart(id:String)->void:
    if not game.depart(id):return
    target_id="";_close_modal();game.save_game();_sync_markers();_visuals(0.0)
func _service_names(services:Array)->String:
    var names:={"supply":"補給","upgrade":"改修","weapons":"装備","trade":"交易","dispatch":"派遣","departure":"出発登録"}
    var list:=PackedStringArray()
    for service in services:list.append(names.get(service,service))
    return "・".join(list)
func _upgrade_description(key:String)->String:
    match key:
        "range":return "容量・効率を向上"
        "drive":return "航行速度を向上"
        "combat":return "武器性能・耐久を向上"
        _:return "探知範囲を拡大"

func _access()->void:
    if game.phase=="docked":_facility(game.current_facility);return
    var interaction:Dictionary=game.nearest_interaction()
    if interaction.is_empty():return
    if interaction["kind"]=="facility":modal_tab=0;_facility(interaction["id"])
    else:
        modal_kind="signal";modal_id=interaction["id"]
        var body:=_open_modal("古い信号へアクセス")
        body.add_child(_label("断片的な記録が残っています。",20))
        body.add_child(_button("接続記録から施設の位置を調べる",_signal.bind(modal_id,"scan"),480))
        body.add_child(_button("記録を探索成果として回収する +2 C",_signal.bind(modal_id,"salvage"),480))
func _signal(id:String,choice:String)->void:
    game.resolve_signal(id,choice);_close_modal()

func _map()->void:
    modal_kind="map"
    var body:=_open_modal("地図・記録")
    var row:=_row(body);row.size_flags_vertical=Control.SIZE_EXPAND_FILL
    var view:=Control.new();view.set_script(MapView);view.session=game;view.overview=true;view.custom_minimum_size=Vector2(390,320);view.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(view)
    var scroll:=ScrollContainer.new();scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(scroll)
    var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",8);scroll.add_child(list)
    list.add_child(_label("発見した施設",19))
    for facility:Dictionary in game.world.facilities.values():
        if not game.facility_known(facility["id"]):continue
        var title:String=facility["title"]+(" / 稼働" if game.facility_built(facility["id"]) else " / 候補地")
        list.add_child(_button(title+"　距離 %.0f" % game.position.distance_to(facility["pos"]),_target.bind(facility["id"]),430))
    list.add_child(_label("地点メモ",19))
    var entry:=LineEdit.new();entry.placeholder_text="現在地の名前（省略可）";entry.custom_minimum_size=Vector2(400,36);list.add_child(entry)
    list.add_child(_button("現在地を記録",func():game.add_marker(entry.text);game.save_game();_map(),240))
    for item:Dictionary in game.campaign.markers:
        var marker_row:=_row(list);marker_row.add_child(_label(item["title"]+"　距離 %.0f" % game.position.distance_to(item["pos"])))
        marker_row.add_child(_button("削除",_remove_marker.bind(int(item["id"])),75))
    body.add_child(_label("最深 %.0f / 10000　施設の記録と地点メモは帰還後も残ります。" % game.campaign.best_range,15))
func _remove_marker(id:int)->void:game.remove_marker(id);game.save_game();_map()
func _target(id:String)->void:target_id=id;_close_modal()

func _settings()->void:
    modal_kind="settings"
    var body:=_open_modal("模型の設定")
    body.add_child(_label("表現や数値は仮の設定です。ゲームの全体の流れを確認する模型です。",17))
    var glow:=CheckButton.new();glow.text="弱い追加発光";glow.button_pressed=game.campaign.settings.get("glow",false)
    glow.toggled.connect(func(value:bool):game.campaign.settings["glow"]=value;game.dirty=true);body.add_child(glow)
    body.add_child(_label("保存："+game.saved_notice))
    if not game.allow_save:body.add_child(_label(game.message,17))
    body.add_child(_button("新しい世界を作る（進行を初期化）",func():reset_dialog.popup_centered(Vector2i(570,170)),500))
func _new_campaign()->void:
    game.new_campaign(game.campaign.seed_value+1);game.save_game();modal_tab=0;target_id="";_facility("base");_sync_markers()

func _physics_process(dt:float)->void:
    if game==null:return
    var back:bool=held["back"] or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
    var forward:bool=held["forward"] or auto_forward or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
    var left:bool=held["left"] or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
    var right:bool=held["right"] or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
    if back:_stop_auto()
    var previous_phase:String=game.phase
    game.tick(minf(dt,0.05),float(forward)-float(back),float(left)-float(right))
    if previous_phase=="travel" and game.phase=="docked":_stop_auto();modal_tab=0;_facility(game.current_facility)
    sync_time-=dt;save_time+=dt
    if sync_time<=0:_sync_markers();sync_time=0.15
    if save_time>=5.0:
        if game.dirty:game.save_game()
        save_time=0.0
    _visuals(dt)

func _visuals(dt:float)->void:
    camera.position=Vector3(game.position.x,0.0,game.position.y);camera.rotation=Vector3(0,game.yaw,0)
    environment.glow_enabled=bool(game.campaign.settings.get("glow",false))
    for key:String in markers:
        var node:MeshInstance3D=markers[key]
        if not key.begins_with("f:"):
            var object:Dictionary=game.world.objects.get(key,{})
            node.visible=not object.is_empty() and object["alive"]
            if node.visible:node.position=Vector3(object["pos"].x,_object_height(object),object["pos"].y)
        if node.position.distance_squared_to(camera.position)>0.01:node.look_at(camera.position,Vector3.UP,true)
    var live:Dictionary={}
    for shot:Dictionary in game.projectiles:
        var key:String=str(shot["id"]);live[key]=true
        if not shots.has(key):shots[key]=_marker(Color("ff7b78") if shot["hostile"] else Color("a1e9ff"),2,1.7)
        var shot_height:=0.0
        if not shot["hostile"]:
            var target:Dictionary=game.world.objects.get(shot["target"],{})
            if not target.is_empty():
                var full_distance:float=maxf(0.01,shot["origin"].distance_to(target["pos"]))
                shot_height=_object_height(target)*clampf(1.0-shot["pos"].distance_to(target["pos"])/full_distance,0.0,1.0)
        var node:MeshInstance3D=shots[key];node.position=Vector3(shot["pos"].x,shot_height,shot["pos"].y)
        if node.position.distance_squared_to(camera.position)>0.01:node.look_at(camera.position,Vector3.UP,true)
    for key:String in shots.keys():
        if not live.has(key):shots[key].queue_free();shots.erase(key)
    while effect_nodes.size()<game.effects.size():effect_nodes.append(_marker(Color.WHITE,0,1.0,3))
    for i in range(effect_nodes.size()):
        var node:=effect_nodes[i];node.visible=i<game.effects.size()
        if not node.visible:continue
        var effect:Dictionary=game.effects[i];var age:float=effect["age"]
        node.position=Vector3(effect["pos"].x,0.0,effect["pos"].y);node.scale=Vector3.ONE*(1.0+age*12)
        node.material_override.set_shader_parameter("gain",maxf(0,1-age/0.65))
        node.material_override.set_shader_parameter("signal_color",Color("85e8ff") if effect["kind"]=="collect" else Color("ffb68a"))
        if node.position.distance_squared_to(camera.position)>0.01:node.look_at(camera.position,Vector3.UP,true)
    hp_bar.max_value=game.max_hp();hp_bar.value=game.hp;fuel_bar.max_value=game.max_fuel();fuel_bar.value=game.fuel
    resources_label.text="回収 %d　撃破 %d　%s" % [game.pickups,game.kills,game.attack_mode]
    status.text="%s　資金 %d C　最深 %.0f / 10000　速度 %.1f" % ["準備中" if game.phase=="docked" else ("一時停止中" if game.paused else "航行中"),game.campaign.credits,game.campaign.best_range,game.speed()]
    notice.text=game.message
    pause_button.text="再開" if game.paused and modal==null else "一時停止"
    if game.hp<previous_hp:flash.color.a=0.16
    else:flash.color.a=maxf(0,flash.color.a-dt*0.7)
    previous_hp=game.hp
    var interaction:Dictionary=game.nearest_interaction() if game.phase=="travel" else {"title":"準備画面"}
    access_button.disabled=interaction.is_empty()
    access_button.text=interaction.get("title","アクセス")
    mini_map.queue_redraw();_labels()

func _labels()->void:
    var target:Dictionary=game.world.facilities.get(target_id,{})
    var light:Dictionary=game.nearest_kind("light",400.0)
    var point:=Vector2.ZERO
    var text_value:String=""
    if not target.is_empty():point=target["pos"];text_value=target["title"]+" %.0f" % game.position.distance_to(point)
    elif not light.is_empty():point=light["pos"];text_value="光まで %.0f" % game.position.distance_to(point)
    var p:=Vector3(point.x,_object_height(light) if target.is_empty() and not light.is_empty() else 0.0,point.y)
    guide.visible=text_value!="" and not camera.is_position_behind(p) and camera.position.distance_to(p)>1.0
    if guide.visible:guide.position=camera.unproject_position(p)+Vector2(-50,32);guide.text=text_value
    var enemies:Array[Dictionary]=[]
    for object:Dictionary in game.active_objects(150.0):
        if object["kind"]=="enemy":enemies.append(object)
    enemies.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return game.position.distance_squared_to(a["pos"])<game.position.distance_squared_to(b["pos"]))
    var shown:=0
    for enemy in enemies:
        var world_point:=Vector3(enemy["pos"].x,_object_height(enemy),enemy["pos"].y)
        if camera.is_position_behind(world_point):continue
        var screen:=camera.unproject_position(world_point)
        if screen.x<0 or screen.x>get_viewport().get_visible_rect().size.x or shown>=enemy_labels.size():continue
        var label:=enemy_labels[shown];label.visible=true;label.position=screen+Vector2(-65,28)
        label.text="%s・%s 深度%d　%.0f" % [Catalog.enemy(enemy["type"]).title,"巡回" if enemy.get("behavior","wait")=="patrol" else "待機",int(enemy["tier"])+1,enemy["hp"]];shown+=1
    for i in range(shown,enemy_labels.size()):enemy_labels[i].visible=false

func _unhandled_input(event:InputEvent)->void:
    if game==null:return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode==KEY_ESCAPE and modal!=null:_close_modal()
        elif modal==null:
            match event.keycode:
                KEY_SPACE:_toggle_pause()
                KEY_E:_access()
                KEY_M:_map()
    if event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_RIGHT and modal==null and not game.paused:game.yaw-=event.relative.x*0.003

func _notification(what:int)->void:
    if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
        for key in held:held[key]=false
        _stop_auto()
        if game!=null:game.paused=true
    if what==NOTIFICATION_WM_CLOSE_REQUEST:
        if game!=null:game.save_game()
        get_tree().quit()
