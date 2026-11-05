extends RefCounted
class_name HeroSystem
## 俠客系統 — 六兵種、體力／飽食／傷勢、裝備

enum WeaponType {
	DAO,
	JIAN,
	QIANG,
	GUN,
	ANQI,
	QUAN,
}

const WEAPON_NAMES := {
	WeaponType.DAO: "刀",
	WeaponType.JIAN: "劍",
	WeaponType.QIANG: "長槍",
	WeaponType.GUN: "棍",
	WeaponType.ANQI: "暗器",
	WeaponType.QUAN: "拳腳",
}

static func normalize_hero(raw: Dictionary) -> Dictionary:
	var h: Dictionary = raw.duplicate(true)
	h["id"] = str(h.get("id", ""))
	h["name"] = str(h.get("name", h["id"]))
	h["weapon"] = str(h.get("weapon", "刀"))
	h["rarity"] = str(h.get("rarity", "綠"))
	h["level"] = int(h.get("level", 1))
	h["base_power"] = int(h.get("base_power", 10))
	h["personality"] = str(h.get("personality", ""))
	h["template_id"] = str(h.get("template_id", h.get("id", "")))
	h["art_key"] = str(h.get("art_key", ""))
	h["art_stem"] = str(h.get("art_stem", ""))
	h["status"] = str(h.get("status", "idle"))
	h["stamina"] = float(h.get("stamina", 100))
	h["max_stamina"] = float(h.get("max_stamina", 100))
	h["satiety"] = float(h.get("satiety", 100))
	h["injury"] = float(h.get("injury", 0))
	h["xp"] = float(h.get("xp", 0))
	var lv: int = int(h["level"])
	h["xp_to_next"] = int(h.get("xp_to_next", TrainingSystem.xp_to_next(lv)))
	if not h.has("equipment") or typeof(h["equipment"]) != TYPE_DICTIONARY:
		h["equipment"] = {}
	else:
		h["equipment"] = (h["equipment"] as Dictionary).duplicate(true)
	h["passive_id"] = str(h.get("passive_id", ""))
	h["passive_name"] = str(h.get("passive_name", ""))
	## art_key（綠白複用圖）→ 非 placeholder；art_stem 只係路徑預約，檔未到可仍 placeholder
	if str(h.get("art_key", "")) != "":
		h["placeholder"] = false
	else:
		h["placeholder"] = bool(h.get("placeholder", false))
	return h

static func weapon_from_string(s: String) -> int:
	match s:
		"刀", "dao", "DAO":
			return WeaponType.DAO
		"劍", "jian", "JIAN":
			return WeaponType.JIAN
		"長槍", "槍", "qiang", "QIANG":
			return WeaponType.QIANG
		"棍", "gun", "GUN":
			return WeaponType.GUN
		"暗器", "anqi", "ANQI":
			return WeaponType.ANQI
		"拳腳", "拳", "quan", "QUAN":
			return WeaponType.QUAN
		_:
			return WeaponType.DAO

static func find_hero_index(hero_id: String) -> int:
	for i in range(GameState.heroes.size()):
		if str((GameState.heroes[i] as Dictionary).get("id", "")) == hero_id:
			return i
	return -1

static func get_hero(hero_id: String) -> Dictionary:
	var idx: int = find_hero_index(hero_id)
	if idx < 0:
		return {}
	return (GameState.heroes[idx] as Dictionary).duplicate(true)

static func find_idle_heroes(limit: int = -1) -> Array:
	var result: Array = []
	for h in GameState.heroes:
		var hd: Dictionary = h as Dictionary
		if str(hd.get("status", "idle")) == "idle":
			result.append(hd)
			if limit > 0 and result.size() >= limit:
				break
	return result

static func find_ready_heroes(limit: int = -1) -> Array:
	var result: Array = []
	for h in GameState.heroes:
		var hd: Dictionary = h as Dictionary
		if can_hunt(hd):
			result.append(hd)
			if limit > 0 and result.size() >= limit:
				break
	return result

static func can_hunt(hero: Dictionary) -> bool:
	if str(hero.get("status", "idle")) != "idle":
		return false
	if float(hero.get("stamina", 0)) < float(GameState.MIN_STAMINA_TO_HUNT):
		return false
	if float(hero.get("injury", 0)) >= 80.0:
		return false
	if float(hero.get("satiety", 0)) < 5.0:
		return false
	return true

static func set_status(hero_id: String, status: String) -> void:
	var idx: int = find_hero_index(hero_id)
	if idx < 0:
		return
	var hd: Dictionary = GameState.heroes[idx] as Dictionary
	hd["status"] = status
	GameState.heroes[idx] = hd
	GameState.heroes_changed.emit()

static func mutate(hero_id: String, mutator: Callable) -> void:
	var idx: int = find_hero_index(hero_id)
	if idx < 0:
		return
	var hd: Dictionary = (GameState.heroes[idx] as Dictionary).duplicate(true)
	mutator.call(hd)
	GameState.heroes[idx] = normalize_hero(hd)
	GameState.heroes_changed.emit()

static func equip_item(hero_id: String, slot: String, item: Dictionary) -> void:
	mutate(hero_id, func(hd: Dictionary) -> void:
		var eq: Dictionary = {}
		if hd.has("equipment") and typeof(hd["equipment"]) == TYPE_DICTIONARY:
			eq = (hd["equipment"] as Dictionary).duplicate(true)
		eq[slot] = item.duplicate(true)
		hd["equipment"] = eq
	)

static func equipment_power(hero: Dictionary) -> int:
	var total: int = 0
	var eq: Variant = hero.get("equipment", {})
	if typeof(eq) != TYPE_DICTIONARY:
		return 0
	for slot in (eq as Dictionary).keys():
		var it: Variant = (eq as Dictionary)[slot]
		if typeof(it) == TYPE_DICTIONARY:
			total += int((it as Dictionary).get("power", 0))
	return total

static func power_of(hero: Dictionary) -> int:
	var level: int = int(hero.get("level", 1))
	var base: int = int(hero.get("base_power", 10))
	var forge: int = ResourceLoop.forge_bonus_power()
	var gear: int = equipment_power(hero)
	var passive: int = AcademySystem.passive_power_bonus(hero)
	var injury: float = float(hero.get("injury", 0))
	var resist: float = AcademySystem.passive_injury_resist(hero)
	var raw: float = float(base + (level - 1) * 3 + forge + gear + passive)
	var injury_factor: float = clampf(1.0 - (injury / 120.0) * (1.0 - resist * 0.5), 0.4, 1.0)
	return int(maxi(1, int(round(raw * injury_factor))))

static func apply_village_recovery(delta: float) -> void:
	## 已改由 UpkeepSystem（食住醫消耗）；保留入口兼容舊呼叫
	UpkeepSystem.tick(delta)
