extends Control
var session:RefCounted
var overview:bool=false
func _draw()->void:
    if session==null:return
    var center:=size*0.5
    var radius:=minf(size.x,size.y)*0.44
    var origin:Vector2=Vector2.ZERO if overview else session.position
    var span:float=maxf(400.0,session.campaign.best_range*1.2) if overview else maxf(160.0,session.sense()*1.5)
    if overview:
        for facility:Dictionary in session.world.facilities.values():
            if session.facility_known(facility["id"]):span=maxf(span,facility["pos"].length()*1.15)
    draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.055,0.08,0.94))
    draw_circle(center,radius,Color("365665"),false,1.0,true)
    draw_line(center-Vector2(radius,0),center+Vector2(radius,0),Color("213e4d"),1.0)
    draw_line(center-Vector2(0,radius),center+Vector2(0,radius),Color("213e4d"),1.0)
    for facility:Dictionary in session.world.facilities.values():
        if not session.facility_known(facility["id"]):continue
        var offset:Vector2=(facility["pos"]-origin)/span*radius
        if offset.length()>radius:continue
        var color:=Color("ffcf73") if session.facility_built(facility["id"]) else Color("b49c69")
        draw_rect(Rect2(center+offset-Vector2.ONE*3,Vector2.ONE*6),color)
    if not overview:
        for object:Dictionary in session.active_objects(session.sense()):
            var offset:Vector2=(object["pos"]-origin)/span*radius
            draw_circle(center+offset,2.5,Color("ff6581") if object["kind"]=="enemy" else Color("65d5ff"))
    for marker:Dictionary in session.campaign.markers:
        var offset:Vector2=(marker["pos"]-origin)/span*radius
        if offset.length()<radius:draw_circle(center+offset,3.5,Color("dbd5ff"),false,1.2,true)
    var player:Vector2=center+(session.position-origin)/span*radius
    draw_set_transform(player,-session.yaw)
    draw_colored_polygon(PackedVector2Array([Vector2(0,-7),Vector2(-4,5),Vector2(4,5)]),Color("b4f2ef"))
    draw_set_transform(Vector2.ZERO)
    draw_string(ThemeDB.fallback_font,Vector2(7,15),"MAP / %.0f" % span,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("b5cfdc"))

