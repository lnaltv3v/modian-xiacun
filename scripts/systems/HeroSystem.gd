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
	h["status"] = str(h.get("status", "idle"))
	h["stamina"] = float(h.get("stamina", 100))
	h["max_stamina"] = float(h.get("max_stamina", 100))
	h["satiety"] = float(h.get("satiety", 100))
	h["injury"] = float(h.get("injury", 0))
	if not h.has("equipment") or typeof(h["equipment"]) != TYPE_DICTIONARY:
		h["equipment"] = {}
	else:
		h["equipment"] = (h["equipment"] as Dictionary).duplicate(true)
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
	var injury: float = float(hero.get("injury", 0))
	var raw: float = float(base + (level - 1) * 3 + forge + gear)
	var factor: float = clampf(1.0 - injury / 120.0, 0.4, 1.0)
	return int(maxi(1, int(round(raw * factor))))

static func apply_village_recovery(delta: float) -> void:
	if delta <= 0.0:
		return
	var stam: float = GameState.recovery_stamina_per_sec() * delta
	var sat: float = GameState.recovery_satiety_per_sec() * delta
	var inj: float = GameState.recovery_injury_per_sec() * delta
	var changed: bool = false
	for i in range(GameState.heroes.size()):
		var hd: Dictionary = GameState.heroes[i] as Dictionary
		if str(hd.get("status", "idle")) != "idle":
			continue
		var before_s: float = float(hd.get("stamina", 100))
		var before_a: float = float(hd.get("satiety", 100))
		var before_i: float = float(hd.get("injury", 0))
		var max_s: float = float(hd.get("max_stamina", 100))
		hd["stamina"] = clampf(before_s + stam, 0.0, max_s)
		hd["satiety"] = clampf(before_a + sat, 0.0, 100.0)
		hd["injury"] = clampf(before_i - inj, 0.0, 100.0)
		GameState.heroes[i] = hd
		if absf(float(hd["stamina"]) - before_s) > 0.01 \
				or absf(float(hd["satiety"]) - before_a) > 0.01 \
				or absf(float(hd["injury"]) - before_i) > 0.01:
			changed = true
	if changed:
		GameState.heroes_changed.emit()
