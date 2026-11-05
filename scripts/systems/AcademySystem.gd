extends RefCounted
class_name AcademySystem
## 師門書院最小 — 解鎖 1 個被動技能槽

const DATA_PATH := "res://data/academy/passives.json"

static var _data: Dictionary = {}
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_data = {}
	if FileAccess.file_exists(DATA_PATH):
		var f := FileAccess.open(DATA_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			_data = (parsed as Dictionary).duplicate(true)
	_loaded = true

static func academy_ready() -> bool:
	ensure_loaded()
	var bid: String = str(_data.get("require_building", "academy"))
	var need: int = int(_data.get("require_level", 1))
	return BuildingSystem.building_level(bid) >= need

static func passive_slots_unlocked() -> int:
	if not academy_ready():
		return 0
	ensure_loaded()
	return int(_data.get("passive_slots", 1))

static func all_skills() -> Array:
	ensure_loaded()
	var out: Array = []
	for s in _data.get("skills", []) as Array:
		out.append((s as Dictionary).duplicate(true))
	return out

static func skill_by_id(skill_id: String) -> Dictionary:
	for s in all_skills():
		var sd: Dictionary = s as Dictionary
		if str(sd.get("id", "")) == skill_id:
			return sd
	return {}

static func can_assign(hero_id: String, skill_id: String) -> Dictionary:
	if not academy_ready():
		return {"ok": false, "reason": "師門書院未啟用"}
	if passive_slots_unlocked() < 1:
		return {"ok": false, "reason": "未解鎖被動槽"}
	var hero: Dictionary = HeroSystem.get_hero(hero_id)
	if hero.is_empty():
		return {"ok": false, "reason": "俠客不存在"}
	if skill_by_id(skill_id).is_empty():
		return {"ok": false, "reason": "未知技能"}
	return {"ok": true, "reason": ""}

static func assign_passive(hero_id: String, skill_id: String) -> Dictionary:
	var check: Dictionary = can_assign(hero_id, skill_id)
	if not bool(check.get("ok", false)):
		return {"ok": false, "reason": str(check.get("reason", ""))}
	var sk: Dictionary = skill_by_id(skill_id)
	HeroSystem.mutate(hero_id, func(hd: Dictionary) -> void:
		hd["passive_id"] = str(sk.get("id", ""))
		hd["passive_name"] = str(sk.get("name", ""))
	)
	GameState.push_report("書院：%s 習得「%s」" % [
		str(HeroSystem.get_hero(hero_id).get("name", hero_id)),
		str(sk.get("name", skill_id)),
	])
	return {"ok": true, "reason": "", "skill": sk.duplicate(true)}

static func clear_passive(hero_id: String) -> void:
	HeroSystem.mutate(hero_id, func(hd: Dictionary) -> void:
		hd["passive_id"] = ""
		hd["passive_name"] = ""
	)

static func _passive_dict(hero: Dictionary) -> Dictionary:
	var pid: String = str(hero.get("passive_id", ""))
	if pid.is_empty():
		return {}
	return skill_by_id(pid)

static func passive_power_bonus(hero: Dictionary) -> int:
	return int(_passive_dict(hero).get("power_bonus", 0))

static func passive_injury_resist(hero: Dictionary) -> float:
	return float(_passive_dict(hero).get("injury_resist", 0.0))

static func passive_stamina_discount(hero: Dictionary) -> float:
	return float(_passive_dict(hero).get("stamina_discount", 0.0))

static func passive_success_bonus(hero: Dictionary) -> float:
	return float(_passive_dict(hero).get("success_bonus", 0.0))

static func passive_silver_bonus(hero: Dictionary) -> float:
	return float(_passive_dict(hero).get("silver_bonus", 0.0))
