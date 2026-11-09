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
const SAVE_VERSION := 12

const MIN_STAMINA_TO_HUNT := 20

var silver: int = 120
var wood: int = 60
var fur: int = 0
var iron: int = 0
var diamonds: int = 5  ## 鑽石（付費／秘境 stub）
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
## 新手引導：0=完成／跳過；1=興建客棧；2=派遣；3=等回村；4=抽卡／興建
var tutorial_step: int = 1
## 英雄帖碎片（重覆轉換）
var fragments: int = 0
## 懸賞目標 id："" / wolf / bandit
var bounty_target: String = ""
## 兵器鋪自動買裝
var auto_shop: bool = false
## 秘境演出中（鎖重複入場）
var dungeon_busy: bool = false
## 抽卡軟保底計數（未出紅／橙連續抽數）
var pity_red: int = 0
var pity_orange: int = 0
var gacha_pulls_total: int = 0
## 招募日節奏（UTC+8 曆日字串 YYYY-MM-DD）
var gacha_day_key: String = ""
var gacha_silver_today: int = 0
var gacha_free_used_today: bool = false
## 當前野外圖
var selected_zone: String = "luan_shan_po"
## 前哨成功次數（stub 統計）
var outpost_clears: int = 0
## 秘境／前哨難度全破次數：diff_id -> int
var dungeon_diff_clears: Dictionary = {}
var outpost_diff_clears: Dictionary = {}
## 秘境／前哨入場選擇（UI）
var dungeon_pick_diff: String = "normal"
var dungeon_pick_waves: String = "full"
var outpost_pick_diff: String = "normal"
## 書院技能樹已解鎖節點 id
var academy_unlocked_nodes: Array = []
## 比武台日限／連勝
var arena_day_key: String = ""
var arena_spars_today: int = 0
var arena_wins_total: int = 0
var arena_win_streak: int = 0
var arena_last_winner: String = ""
var _hunt_seq: int = 0
var _gacha_seq: int = 0
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
	fragments = 0
	bounty_target = ""
	auto_shop = false
	dungeon_busy = false
	pity_red = 0
	pity_orange = 0
	gacha_pulls_total = 0
	gacha_day_key = ""
	gacha_silver_today = 0
	gacha_free_used_today = false
	selected_zone = "luan_shan_po"
	outpost_clears = 0
	dungeon_diff_clears = {}
	outpost_diff_clears = {}
	dungeon_pick_diff = "normal"
	dungeon_pick_waves = "full"
	outpost_pick_diff = "normal"
	academy_unlocked_nodes = []
	arena_day_key = ""
	arena_spars_today = 0
	arena_wins_total = 0
	arena_win_streak = 0
	arena_last_winner = ""
	_hunt_seq = 0
	_gacha_seq = 0
	silver = 120
	wood = 60
	fur = 0
	iron = 2
	diamonds = 5

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

func add_fragments(amount: int) -> void:
	fragments = maxi(0, fragments + amount)
	resources_changed.emit()

func try_spend_fragments(cost: int) -> bool:
	if cost <= 0:
		return true
	if fragments < cost:
		return false
	fragments -= cost
	resources_changed.emit()
	return true

func add_diamonds(amount: int) -> void:
	diamonds = maxi(0, diamonds + amount)
	resources_changed.emit()

func try_spend_diamonds(cost: int) -> bool:
	if diamonds < cost:
		return false
	diamonds -= cost
	resources_changed.emit()
	return true

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
		"diamonds": diamonds,
		"heroes": heroes.duplicate(true),
		"buildings": buildings.duplicate(true),
		"active_hunts": active_hunts.duplicate(true),
		"auto_dispatch": auto_dispatch,
		"reports": reports.duplicate(true),
		"inventory": inventory.duplicate(true),
		"building_placements": building_placements.duplicate(true),
		"tutorial_step": tutorial_step,
		"fragments": fragments,
		"bounty_target": bounty_target,
		"auto_shop": auto_shop,
		"pity_red": pity_red,
		"pity_orange": pity_orange,
		"gacha_pulls_total": gacha_pulls_total,
		"gacha_day_key": gacha_day_key,
		"gacha_silver_today": gacha_silver_today,
		"gacha_free_used_today": gacha_free_used_today,
		"selected_zone": selected_zone,
		"outpost_clears": outpost_clears,
		"dungeon_diff_clears": dungeon_diff_clears.duplicate(true),
		"outpost_diff_clears": outpost_diff_clears.duplicate(true),
		"dungeon_pick_diff": dungeon_pick_diff,
		"dungeon_pick_waves": dungeon_pick_waves,
		"outpost_pick_diff": outpost_pick_diff,
		"academy_unlocked_nodes": academy_unlocked_nodes.duplicate(true),
		"arena_day_key": arena_day_key,
		"arena_spars_today": arena_spars_today,
		"arena_wins_total": arena_wins_total,
		"arena_win_streak": arena_win_streak,
		"arena_last_winner": arena_last_winner,
		"hunt_seq": _hunt_seq,
		"gacha_seq": _gacha_seq,
	}

func load_from_dict(d: Dictionary) -> void:
	silver = int(d.get("silver", silver))
	wood = int(d.get("wood", wood))
	fur = int(d.get("fur", fur))
	iron = int(d.get("iron", iron))
	diamonds = int(d.get("diamonds", diamonds))
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
	fragments = int(d.get("fragments", 0))
	bounty_target = str(d.get("bounty_target", ""))
	auto_shop = bool(d.get("auto_shop", false))
	pity_red = int(d.get("pity_red", 0))
	pity_orange = int(d.get("pity_orange", 0))
	gacha_pulls_total = int(d.get("gacha_pulls_total", 0))
	gacha_day_key = str(d.get("gacha_day_key", ""))
	gacha_silver_today = int(d.get("gacha_silver_today", 0))
	gacha_free_used_today = bool(d.get("gacha_free_used_today", false))
	selected_zone = str(d.get("selected_zone", "luan_shan_po"))
	outpost_clears = int(d.get("outpost_clears", 0))
	dungeon_diff_clears = (d.get("dungeon_diff_clears", {}) as Dictionary).duplicate(true) if typeof(d.get("dungeon_diff_clears", {})) == TYPE_DICTIONARY else {}
	outpost_diff_clears = (d.get("outpost_diff_clears", {}) as Dictionary).duplicate(true) if typeof(d.get("outpost_diff_clears", {})) == TYPE_DICTIONARY else {}
	dungeon_pick_diff = str(d.get("dungeon_pick_diff", "normal"))
	dungeon_pick_waves = str(d.get("dungeon_pick_waves", "full"))
	outpost_pick_diff = str(d.get("outpost_pick_diff", "normal"))
	academy_unlocked_nodes = (d.get("academy_unlocked_nodes", []) as Array).duplicate(true) if typeof(d.get("academy_unlocked_nodes", [])) == TYPE_ARRAY else []
	arena_day_key = str(d.get("arena_day_key", ""))
	arena_spars_today = int(d.get("arena_spars_today", 0))
	arena_wins_total = int(d.get("arena_wins_total", 0))
	arena_win_streak = int(d.get("arena_win_streak", 0))
	arena_last_winner = str(d.get("arena_last_winner", ""))
	dungeon_busy = false
	_hunt_seq = int(d.get("hunt_seq", _hunt_seq))
	_gacha_seq = int(d.get("gacha_seq", _gacha_seq))
	_emit_all()
