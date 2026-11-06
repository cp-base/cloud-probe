extends RefCounted
const ENEMIES=[preload("res://data/melee.tres"),preload("res://data/artillery.tres"),preload("res://data/fast.tres"),preload("res://data/heavy.tres")]
const WEAPONS=[preload("res://data/cannon.tres"),preload("res://data/long_cannon.tres"),preload("res://data/blade.tres"),preload("res://data/heavy_blade.tres")]
const UPGRADE_NAMES={"range":"航続", "drive":"推進", "combat":"戦闘", "sensor":"探知"}
const UPGRADE_COSTS={"range":4,"drive":5,"combat":5,"sensor":4}
static func weapon(id:String)->Resource:
    for item in WEAPONS:
        if item.id==id:return item
    return WEAPONS[0]
static func enemy(id:String)->Resource:
    for item in ENEMIES:
        if item.id==id:return item
    return ENEMIES[0]

