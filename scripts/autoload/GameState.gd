extends Node
## 墨點俠村 — 全域遊戲狀態（銀兩、建材、俠客、建築）

signal resources_changed
signal heroes_changed
signal buildings_changed

var silver: int = 100
var wood: int = 50
var heroes: Array = []  # Array[Dictionary]
var buildings: Dictionary = {}  # id -> { level, unlocked }

const STARTER_HEROES_PATH := "res://data/heroes/starter_six.json"
const CORE_BUILDINGS_PATH := "res://data/buildings/core.json"

func _ready() -> void:
	_load_starter_data()
	resources_changed.emit()
	heroes_changed.emit()
	buildings_changed.emit()

func _load_starter_data() -> void:
	var heroes_data: Variant = _read_json(STARTER_HEROES_PATH)
	if heroes_data is Array:
		heroes = (heroes_data as Array).duplicate(true)
	elif heroes_data is Dictionary and (heroes_data as Dictionary).has("heroes"):
		heroes = ((heroes_data as Dictionary)["heroes"] as Array).duplicate(true)

	var buildings_data: Variant = _read_json(CORE_BUILDINGS_PATH)
	if buildings_data is Array:
		for b in buildings_data as Array:
			_register_building(b as Dictionary)
	elif buildings_data is Dictionary and (buildings_data as Dictionary).has("buildings"):
		for b in (buildings_data as Dictionary)["buildings"] as Array:
			_register_building(b as Dictionary)

func _register_building(b: Dictionary) -> void:
	var bid: String = str(b.get("id", ""))
	if bid.is_empty():
		return
	buildings[bid] = {
		"id": bid,
		"name": str(b.get("name", bid)),
		"level": int(b.get("start_level", 0)),
		"unlocked": bool(b.get("unlocked", false)),
		"base_cost_silver": int(b.get("base_cost_silver", 50)),
		"base_cost_wood": int(b.get("base_cost_wood", 20)),
	}

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("GameState: missing data file %s" % path)
		return null
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text: String = f.get_as_text()
	return JSON.parse_string(text)

func add_silver(amount: int) -> void:
	silver = maxi(0, silver + amount)
	resources_changed.emit()

func add_wood(amount: int) -> void:
	wood = maxi(0, wood + amount)
	resources_changed.emit()

func try_spend(silver_cost: int, wood_cost: int = 0) -> bool:
	if silver < silver_cost or wood < wood_cost:
		return false
	silver -= silver_cost
	wood -= wood_cost
	resources_changed.emit()
	return true

func hero_count() -> int:
	return heroes.size()

func idle_hero_count() -> int:
	var n: int = 0
	for h in heroes:
		if str((h as Dictionary).get("status", "idle")) == "idle":
			n += 1
	return n

func to_save_dict() -> Dictionary:
	return {
		"silver": silver,
		"wood": wood,
		"heroes": heroes.duplicate(true),
		"buildings": buildings.duplicate(true),
	}

func load_from_dict(d: Dictionary) -> void:
	silver = int(d.get("silver", silver))
	wood = int(d.get("wood", wood))
	if d.has("heroes"):
		heroes = (d["heroes"] as Array).duplicate(true)
	if d.has("buildings"):
		buildings = (d["buildings"] as Dictionary).duplicate(true)
	resources_changed.emit()
	heroes_changed.emit()
	buildings_changed.emit()
