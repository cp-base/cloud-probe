extends RefCounted
const SCHEMA:=1
const GENERATION:=1
static func pack(value:Variant)->Variant:
    if value is Vector2:return {"_v2":[value.x,value.y]}
    if value is Vector2i:return {"_v2i":[value.x,value.y]}
    if value is Dictionary:
        var result:Dictionary={}
        for key in value:result[str(key)]=pack(value[key])
        return result
    if value is Array:
        var result:Array=[]
        for item in value:result.append(pack(item))
        return result
    return value
static func unpack(value:Variant)->Variant:
    if value is Dictionary:
        if value.has("_v2"):return Vector2(float(value["_v2"][0]),float(value["_v2"][1]))
        if value.has("_v2i"):return Vector2i(int(value["_v2i"][0]),int(value["_v2i"][1]))
        var result:Dictionary={}
        for key in value:result[key]=unpack(value[key])
        return result
    if value is Array:
        var result:Array=[]
        for item in value:result.append(unpack(item))
        return result
    return value
static func read(path:String)->Dictionary:
    if not FileAccess.file_exists(path):return {"status":"missing"}
    var file:=FileAccess.open(path,FileAccess.READ)
    if file==null:return {"status":"error","reason":"保存ファイルを開けません。"}
    var data:Variant=JSON.parse_string(file.get_as_text())
    if not data is Dictionary or int(data.get("schema",0))!=SCHEMA or int(data.get("generation",0))!=GENERATION or not data.get("campaign") is Dictionary or not data.get("session") is Dictionary:
        return {"status":"error","reason":"保存データの版または形式が違います。上書きせず保護しました。"}
    return {"status":"ok","data":unpack(data)}
static func write(path:String,data:Dictionary)->bool:
    var absolute:=ProjectSettings.globalize_path(path)
    if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())!=OK:return false
    var payload:=data.duplicate(true);payload["schema"]=SCHEMA;payload["generation"]=GENERATION
    var encoded:=JSON.stringify(pack(payload))
    var temporary:=absolute+".tmp"
    var file:=FileAccess.open(temporary,FileAccess.WRITE)
    if file==null:return false
    file.store_string(encoded);file.flush();file.close()
    var verify:=read(temporary)
    if verify.get("status")!="ok":return false
    var backup:=absolute+".bak"
    if FileAccess.file_exists(absolute):
        if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup)!=OK:return false
        if DirAccess.rename_absolute(absolute,backup)!=OK:return false
    if DirAccess.rename_absolute(temporary,absolute)!=OK:
        if FileAccess.file_exists(backup):DirAccess.rename_absolute(backup,absolute)
        return false
    return true
