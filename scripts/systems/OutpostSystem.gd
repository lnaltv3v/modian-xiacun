extends RefCounted
class_name OutpostSystem
## 前哨防衛 stub（v0.7）— 解鎖後一波山賊潮結算；後期再擴

const DATA_PATH := "res://data/outpost/core.json"

static var _def: Dictionary = {}
static var _loaded: bool = false
static var _rng := RandomNumberGenerator.new()
static var _rng_ready: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_def = {}
	if FileAccess.file_exists(DATA_PATH):
		var f := FileAccess.open(DATA_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			_def = (parsed as Dictionary).duplicate(true)
	_loaded = true
	if not _rng_ready:
		_rng.randomize()
		_rng_ready = true

static func def() -> Dictionary:
	ensure_loaded()
	return _def.duplicate(true)

static func is_unlocked() -> bool:
	ensure_loaded()
	var need_manor: int = int(_def.get("unlock_manor_level", 2))
	var need_bounty: int = int(_def.get("unlock_bounty_level", 2))
	return BuildingSystem.building_level("manor") >= need_manor \
		and BuildingSystem.building_level("bounty") >= need_bounty

static func can_defend(hero_ids: Array) -> Dictionary:
	ensure_loaded()
	if not is_unlocked():
		return {"ok": false, "reason": "前哨未解鎖（村長府＋懸賞榜皆要 Lv.%d／Lv.%d）" % [
			int(_def.get("unlock_manor_level", 2)), int(_def.get("unlock_bounty_level", 2))
		]}
	if hero_ids.is_empty():
		return {"ok": false, "reason": "未揀守點俠客"}
	for hid_v in hero_ids:
		var h: Dictionary = HeroSystem.get_hero(str(hid_v))
		if h.is_empty():
			return {"ok": false, "reason": "俠客不存在"}
		if str(h.get("status", "idle")) != "idle":
			return {"ok": false, "reason": "%s 唔喺村" % str(h.get("name", ""))}
		if not HeroSystem.can_hunt(h):
			return {"ok": false, "reason": "%s 狀態唔適合守點" % str(h.get("name", ""))}
	return {"ok": true, "reason": ""}

static func run_wave(hero_ids: Array) -> Dictionary:
	## 一波山賊潮結算 stub
	var chk: Dictionary = can_defend(hero_ids)
	if not bool(chk.get("ok", false)):
		return {"ok": false, "reason": str(chk.get("reason", "")), "success": false, "rewards": {}}

	ensure_loaded()
	var wave: Dictionary = _def.get("wave", {}) as Dictionary
	var rewards_def: Dictionary = _def.get("rewards", {}) as Dictionary
	var manor_lv: int = BuildingSystem.building_level("manor")
	var count: int = int(wave.get("count_base", 5)) + manor_lv * int(wave.get("count_per_manor", 2))
	var enemy_name: String = str(wave.get("enemy_name", "山賊潮"))

	var total_power: int = 0
	for hid_v in hero_ids:
		total_power += HeroSystem.power_of(HeroSystem.get_hero(str(hid_v)))

	## 簡：戰力 vs 敵數×8
	var need: int = count * 8
	var success_chance: float = clampf(0.35 + float(total_power) / float(maxi(1, need)) * 0.55, 0.15, 0.95)
	var success: bool = _rng.randf() <= success_chance

	var silver_gain: int = 0
	var iron_gain: int = 0
	var fur_gain: int = 0
	if success:
		silver_gain = int(round(float(rewards_def.get("silver_base", 40)) + float(total_power) * float(rewards_def.get("power_bonus_per", 0.5))))
		iron_gain = int(rewards_def.get("iron_base", 2))
		fur_gain = int(rewards_def.get("fur_base", 1))
		GameState.add_silver(silver_gain)
		if iron_gain > 0:
			GameState.add_iron(iron_gain)
		if fur_gain > 0:
			GameState.add_fur(fur_gain)
		for hid_x in hero_ids:
			HeroSystem.mutate(str(hid_x), func(hd: Dictionary) -> void:
				hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - 20.0)
				hd["satiety"] = maxf(0.0, float(hd.get("satiety", 100)) - 12.0)
				var add_xp: float = 12.0 + float(BuildingSystem.building_level("training")) * 3.0
				var lv: int = int(hd.get("level", 1))
				var xp: float = float(hd.get("xp", 0)) + add_xp
				var need_xp: float = float(TrainingSystem.xp_to_next(lv))
				while xp >= need_xp and lv < 30:
					xp -= need_xp
					lv += 1
					need_xp = float(TrainingSystem.xp_to_next(lv))
				hd["level"] = lv
				hd["xp"] = xp
				hd["xp_to_next"] = int(need_xp)
			)
		GameState.push_report("前哨得勝：擊退「%s」×%d（成功率 %.0f%%）＋銀%d 鐵%d" % [
			enemy_name, count, success_chance * 100.0, silver_gain, iron_gain
		])
	else:
		var inj: float = float(_def.get("fail_injury", 15))
		for hid_f in hero_ids:
			HeroSystem.mutate(str(hid_f), func(hd: Dictionary) -> void:
				hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - 30.0)
				hd["injury"] = clampf(float(hd.get("injury", 0)) + inj, 0.0, 100.0)
			)
		silver_gain = int(round(float(rewards_def.get("silver_base", 40)) * 0.2))
		GameState.add_silver(silver_gain)
		GameState.push_report("前哨失利：不敵「%s」×%d（成功率僅 %.0f%%）；守軍受傷，殘銀＋%d" % [
			enemy_name, count, success_chance * 100.0, silver_gain
		])

	GameState.outpost_clears += 1 if success else 0
	GameState.heroes_changed.emit()
	return {
		"ok": true,
		"reason": "",
		"success": success,
		"enemy_name": enemy_name,
		"enemy_count": count,
		"success_chance": success_chance,
		"rewards": {"silver": silver_gain, "iron": iron_gain, "fur": fur_gain},
	}
