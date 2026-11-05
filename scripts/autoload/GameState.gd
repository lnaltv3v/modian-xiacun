extends Node
## 墨點俠村 — 全域遊戲狀態（資源、俠客、建築、出征、回報、庫存、放置）

signal resources_changed
signal heroes_changed
signal buildings_changed
signal hunts_changed
signal reports_changed
signal inventory_changed
signal placements_changed

const STARTER_HEROES_PATH := "res://data/heroes/starter_six.json"
const CORE_BUILDINGS_PATH := "res://data/buildings/core.json"
const ZONES_PATH := "res://data/zones/core.json"
const LAYOUT_PATH := "res://data/buildings/layout.json"
const SAVE_VERSION := 5

const MIN_STAMINA_TO_HUNT := 20

var silver: int = 120
var wood: int = 60
var fur: int = 0
var iron: int = 0
var heroes: Array = []
var buildings: Dictionary = {}
## 進行中出征
var active_hunts: Array = []
var auto_dispatch: bool = false
var reports: Array = []
var zones: Dictionary = {}
## 背包：[{id,name,kind,...}]
var inventory: Array = []
## 玩家放置：building_id -> {x, y}（設計座標 960×540）；空則用 layout 預設
var building_placements: Dictionary = {}
## 新手引導：0=完成／跳過；1=興建客棧；2=派遣；3=等回村
var tutorial_step: int = 1
var _hunt_seq: int = 0
var _default_layout_buildings: Array = []

func _ready() -> void:
	_load_starter_data()
	_emit_all()

func _load_starter_data() -> void:
	heroes.clear()
	buildings.clear()
	zones.clear()
	active_hunts.clear()
	reports.clear()
	inventory.clear()
	building_placements.clear()
	auto_dispatch = false
	tutorial_step = 1
	_hunt_seq = 0
	silver = 120
	wood = 60
	fur = 0
	iron = 2

	var heroes_data: Variant = _read_json(STARTER_HEROES_PATH)
	if heroes_data is Array:
		for h in heroes_data as Array:
			heroes.append(HeroSystem.normalize_hero(h as Dictionary))
	elif heroes_data is Dictionary and (heroes_data as Dictionary).has("heroes"):
		for h in (heroes_data as Dictionary)["heroes"] as Array:
			heroes.append(HeroSystem.normalize_hero(h as Dictionary))

	var buildings_data: Variant = _read_json(CORE_BUILDINGS_PATH)
	if buildings_data is Array:
		for b in buildings_data as Array:
			_register_building(b as Dictionary)
	elif buildings_data is Dictionary and (buildings_data as Dictionary).has("buildings"):
		for b in (buildings_data as Dictionary)["buildings"] as Array:
			_register_building(b as Dictionary)

	var zones_data: Variant = _read_json(ZONES_PATH)
	if zones_data is Array:
		for z in zones_data as Array:
			var zd: Dictionary = z as Dictionary
			zones[str(zd.get("id", ""))] = zd.duplicate(true)
	elif zones_data is Dictionary and (zones_data as Dictionary).has("zones"):
		for z in (zones_data as Dictionary)["zones"] as Array:
			var zd2: Dictionary = z as Dictionary
			zones[str(zd2.get("id", ""))] = zd2.duplicate(true)

	_load_default_layout()

func _load_default_layout() -> void:
	_default_layout_buildings.clear()
	var layout: Variant = _read_json(LAYOUT_PATH)
	if layout is Dictionary:
		var arr: Array = (layout as Dictionary).get("buildings", []) as Array
		for b in arr:
			_default_layout_buildings.append((b as Dictionary).duplicate(true))

func get_default_placement(building_id: String) -> Dictionary:
	for b in _default_layout_buildings:
		var bd: Dictionary = b as Dictionary
		if str(bd.get("id", "")) == building_id:
			return {"x": float(bd.get("cx", 480)), "y": float(bd.get("cy", 270))}
	return {"x": 480.0, "y": 270.0}

func get_building_pos(building_id: String) -> Vector2:
	if building_placements.has(building_id):
		var p: Dictionary = building_placements[building_id] as Dictionary
		return Vector2(float(p.get("x", 480)), float(p.get("y", 270)))
	var d: Dictionary = get_default_placement(building_id)
	return Vector2(float(d.x), float(d.y))

func set_building_pos(building_id: String, pos: Vector2) -> void:
	building_placements[building_id] = {"x": pos.x, "y": pos.y}
	placements_changed.emit()

func clear_building_pos(building_id: String) -> void:
	if building_placements.has(building_id):
		building_placements.erase(building_id)
		placements_changed.emit()

func _register_building(b: Dictionary) -> void:
	var bid: String = str(b.get("id", ""))
	if bid.is_empty():
		return
	buildings[bid] = {
		"id": bid,
		"name": str(b.get("name", bid)),
		"level": int(b.get("start_level", 0)),
		"unlocked": bool(b.get("unlocked", false)),
		"max_level": int(b.get("max_level", 8)),
		"base_cost_silver": int(b.get("base_cost_silver", 50)),
		"base_cost_wood": int(b.get("base_cost_wood", 20)),
		"desc": str(b.get("desc", "")),
	}

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("GameState: missing data file %s" % path)
		return null
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())

func _emit_all() -> void:
	resources_changed.emit()
	heroes_changed.emit()
	buildings_changed.emit()
	hunts_changed.emit()
	reports_changed.emit()
	inventory_changed.emit()
	placements_changed.emit()

func add_silver(amount: int) -> void:
	silver = maxi(0, silver + amount)
	resources_changed.emit()

func add_wood(amount: int) -> void:
	wood = maxi(0, wood + amount)
	resources_changed.emit()

func add_fur(amount: int) -> void:
	fur = maxi(0, fur + amount)
	resources_changed.emit()

func add_iron(amount: int) -> void:
	iron = maxi(0, iron + amount)
	resources_changed.emit()

func try_spend(silver_cost: int, wood_cost: int = 0, fur_cost: int = 0, iron_cost: int = 0) -> bool:
	if silver < silver_cost or wood < wood_cost or fur < fur_cost or iron < iron_cost:
		return false
	silver -= silver_cost
	wood -= wood_cost
	fur -= fur_cost
	iron -= iron_cost
	resources_changed.emit()
	return true

func add_inventory_item(item: Dictionary) -> void:
	inventory.append(item.duplicate(true))
	inventory_changed.emit()

func remove_inventory_at(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	inventory.remove_at(index)
	inventory_changed.emit()

func hero_count() -> int:
	return heroes.size()

func idle_hero_count() -> int:
	var n: int = 0
	for h in heroes:
		if str((h as Dictionary).get("status", "idle")) == "idle":
			n += 1
	return n

func hunting_hero_count() -> int:
	var n: int = 0
	for h in heroes:
		if str((h as Dictionary).get("status", "idle")) == "hunting":
			n += 1
	return n

func hero_capacity() -> int:
	var manor_lv: int = BuildingSystem.building_level("manor")
	var inn_lv: int = BuildingSystem.building_level("inn")
	return 4 + manor_lv * 2 + inn_lv * 2

func recovery_stamina_per_sec() -> float:
	return 1.5 + float(BuildingSystem.building_level("clinic")) * 1.2

func recovery_satiety_per_sec() -> float:
	return 0.8 + float(BuildingSystem.building_level("inn")) * 0.9

func recovery_injury_per_sec() -> float:
	return 0.4 + float(BuildingSystem.building_level("clinic")) * 0.8

func push_report(msg: String) -> void:
	var stamp: String = Time.get_time_string_from_system()
	reports.push_front("[%s] %s" % [stamp, msg])
	while reports.size() > 12:
		reports.pop_back()
	reports_changed.emit()

func next_hunt_id() -> String:
	_hunt_seq += 1
	return "hunt_%d" % _hunt_seq

func get_zone(zone_id: String) -> Dictionary:
	if zones.has(zone_id):
		return (zones[zone_id] as Dictionary).duplicate(true)
	return {}

func to_save_dict() -> Dictionary:
	return {
		"silver": silver,
		"wood": wood,
		"fur": fur,
		"iron": iron,
		"heroes": heroes.duplicate(true),
		"buildings": buildings.duplicate(true),
		"active_hunts": active_hunts.duplicate(true),
		"auto_dispatch": auto_dispatch,
		"reports": reports.duplicate(true),
		"inventory": inventory.duplicate(true),
		"building_placements": building_placements.duplicate(true),
		"tutorial_step": tutorial_step,
		"hunt_seq": _hunt_seq,
	}

func load_from_dict(d: Dictionary) -> void:
	silver = int(d.get("silver", silver))
	wood = int(d.get("wood", wood))
	fur = int(d.get("fur", fur))
	iron = int(d.get("iron", iron))
	if d.has("heroes"):
		heroes.clear()
		for h in d["heroes"] as Array:
			heroes.append(HeroSystem.normalize_hero(h as Dictionary))
	if d.has("buildings"):
		var saved: Dictionary = (d["buildings"] as Dictionary).duplicate(true)
		for bid in buildings.keys():
			if saved.has(bid):
				var cur: Dictionary = buildings[bid] as Dictionary
				var s: Dictionary = saved[bid] as Dictionary
				cur["level"] = int(s.get("level", cur.get("level", 0)))
				cur["unlocked"] = bool(s.get("unlocked", cur.get("unlocked", false)))
				buildings[bid] = cur
		for bid2 in saved.keys():
			if not buildings.has(bid2):
				buildings[bid2] = (saved[bid2] as Dictionary).duplicate(true)
	if d.has("active_hunts"):
		active_hunts = (d["active_hunts"] as Array).duplicate(true)
	auto_dispatch = bool(d.get("auto_dispatch", false))
	if d.has("reports"):
		reports = (d["reports"] as Array).duplicate(true)
	if d.has("inventory"):
		inventory = (d["inventory"] as Array).duplicate(true)
	if d.has("building_placements"):
		building_placements = (d["building_placements"] as Dictionary).duplicate(true)
	tutorial_step = int(d.get("tutorial_step", 0))
	_hunt_seq = int(d.get("hunt_seq", _hunt_seq))
	_emit_all()
