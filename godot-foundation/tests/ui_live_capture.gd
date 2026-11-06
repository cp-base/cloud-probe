extends SceneTree
# Capture the full Foundation scene, unlike HUD sample previews.
const MAIN=preload("res://Main.tscn")
const OUTPUT="res://research/ui-v2/evidence"
var images:int=0
var failed:int=0
func _init()->void:call_deferred("run")
func capture(path:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:Image=root.get_texture().get_image()
    var err:Error=img.save_png(path)
    images+=1
    if err!=OK or img.get_width()<=0:failed+=1
    print("UI_V2_LIVE_CAPTURE ",path," size=",img.get_size()," error=",err)
func run()->void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
    var main:Node3D=MAIN.instantiate()
    root.add_child(main)
    main.set_physics_process(false)
    main.game.allow_save=false
    await capture("%s/live-preparation.png" % OUTPUT)
    var can_depart:bool=main.game.phase=="docked"
    if can_depart:main._depart("base")
    await process_frame
    if main.game.phase=="travel":
        main._visuals(0.0)
        await capture("%s/live-travel.png" % OUTPUT)
    else:
        failed+=1
        print("LIVE_DEPART_FAILED phase=",main.game.phase)
    print("UI_V2_LIVE_RESULT images=%d failures=%d" % [images,failed])
    main.queue_free()
    await process_frame
    quit(0 if images==2 and failed==0 else 1)
