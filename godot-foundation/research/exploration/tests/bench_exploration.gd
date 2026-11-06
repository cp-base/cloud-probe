extends SceneTree
const World=preload("res://core/world.gd")
const Storage=preload("res://core/storage.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
    var w:=World.new();w.initialize(71127);w.reset_sortie(1)
    var before:int=Time.get_ticks_usec()
    for x in range(-20,21):
        for y in range(-20,21):w.generate_chunk(Vector2i(x,y))
    var generated_usec:int=Time.get_ticks_usec()-before
    before=Time.get_ticks_usec()
    for i in range(1000):w.active(Vector2.ZERO,550.0)
    var active_usec:int=Time.get_ticks_usec()-before
    var bytes:int=JSON.stringify(Storage.pack(w.to_dict())).to_utf8_buffer().size()
    print("BENCH chunks=",w.chunks.size()," objects=",w.objects.size()," generate_ms=",generated_usec/1000.0," active_1000_ms=",active_usec/1000.0," world_json_bytes=",bytes)
    quit()
