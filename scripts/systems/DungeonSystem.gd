extends RefCounted
class_name DungeonSystem
## 秘境入口最小 — 最多 5 俠、3 波結算（末波狼王／山賊頭目示意）

const DATA_PATH := "res://data/dungeons/core.json"
const MAX_PARTY := 5

static var _data: Dictionary = {}
static var _loaded: bool = false
static var _rng := RandomNumberGenerator.new()
static var _rng_ready: bool = false

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
	if not _rng_ready:
		_rng.randomize()
		_rng_ready = true

static func dungeon_def() -> Dictionary:
	ensure_loaded()
	return _data.duplicate(true)

static func max_party() -> int:
	ensure_loaded()
	return int(_data.get("max_party", MAX_PARTY))

static func can_enter(hero_ids: Array) -> Dictionary:
	ensure_loaded()
	if hero_ids.is_empty():
		return {"ok": false, "reason": "未揀俠客"}
	if hero_ids.size() > max_party():
		return {"ok": false, "reason": "最多 %d 俠" % max_party()}
	var bid: String = str(_data.get("require_building", "bounty"))
	var need_lv: int = int(_data.get("require_level", 1))
	if bid != "" and BuildingSystem.building_level(bid) < need_lv:
		return {"ok": false, "reason": "%s 未達 Lv.%d" % [BuildingSystem.building_name(bid), need_lv]}
	if GameState.dungeon_busy:
		return {"ok": false, "reason": "秘境進行中"}
	var seen: Dictionary = {}
	for hid_v in hero_ids:
		var hid: String = str(hid_v)
		if seen.has(hid):
			return {"ok": false, "reason": "重複揀咗同一俠"}
		seen[hid] = true
		var hero: Dictionary = HeroSystem.get_hero(hid)
		if hero.is_empty():
			return {"ok": false, "reason": "俠客不存在"}
		if not HeroSystem.can_hunt(hero):
			return {"ok": false, "reason": "%s 派唔到" % str(hero.get("name", hid))}
	return {"ok": true, "reason": ""}

static func _party_power(hero_ids: Array) -> int:
	var total: int = 0
	for hid_v in hero_ids:
		total += HeroSystem.power_of(HeroSystem.get_hero(str(hid_v)))
	return total

static func _party_success_bonus(hero_ids: Array) -> float:
	var bonus: float = 0.0
	for hid_v in hero_ids:
		bonus += AcademySystem.passive_success_bonus(HeroSystem.get_hero(str(hid_v)))
	return bonus

static func run_dungeon(hero_ids: Array) -> Dictionary:
	## 同步結算三波；UI 再逐步演出
	var check: Dictionary = can_enter(hero_ids)
	if not bool(check.get("ok", false)):
		return {"ok": false, "reason": str(check.get("reason", "")), "waves": [], "rewards": {}}

	ensure_loaded()
	var ids: Array = []
	for hid_v in hero_ids:
		ids.append(str(hid_v))

	for hid in ids:
		HeroSystem.set_status(str(hid), "dungeon")

	var party_power: int = _party_power(ids)
	var success_bonus: float = _party_success_bonus(ids)
	var waves_out: Array = []
	var cleared_all: bool = true
	var wave_defs: Array = _data.get("waves", []) as Array

	for wv in wave_defs:
		var wd: Dictionary = wv as Dictionary
		var enemy_power: int = int(wd.get("enemy_power", 20))
		var ratio: float = float(party_power) / float(maxi(1, enemy_power))
		var chance: float = clampf(0.35 + ratio * 0.35 + success_bonus, 0.15, 0.95)
		var success: bool = _rng.randf() <= chance
		if not success:
			cleared_all = false
		var enemies: Array = []
		for ev in wd.get("enemies", []) as Array:
			enemies.append((ev as Dictionary).duplicate(true))
		waves_out.append({
			"index": int(wd.get("index", waves_out.size() + 1)),
			"label": str(wd.get("label", "波次")),
			"boss": bool(wd.get("boss", false)),
			"enemies": enemies,
			"enemy_power": enemy_power,
			"party_power": party_power,
			"success": success,
			"success_chance": chance,
		})
		if not success:
			## 失敗仍可繼續示意後續波，但清關失敗；最小版：中斷後面波
			break

	var stamina_cost: float = float(_data.get("stamina_cost", 28))
	var satiety_cost: float = float(_data.get("satiety_cost", 18))
	var injury_chance: float = float(_data.get("injury_chance", 0.22))
	var injury_amount: float = float(_data.get("injury_amount", 10))
	## 被動傷勢抗性
	var injured_names: PackedStringArray = PackedStringArray()
	for hid2 in ids:
		var hero2: Dictionary = HeroSystem.get_hero(str(hid2))
		var resist: float = AcademySystem.passive_injury_resist(hero2)
		var stam_disc: float = AcademySystem.passive_stamina_discount(hero2)
		var got_hurt: bool = _rng.randf() < injury_chance * (1.0 - resist * 0.5)
		if not cleared_all:
			got_hurt = got_hurt or _rng.randf() < 0.4
		HeroSystem.mutate(str(hid2), func(hd: Dictionary) -> void:
			hd["status"] = "idle"
			hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - stamina_cost * (1.0 - stam_disc))
			hd["satiety"] = maxf(0.0, float(hd.get("satiety", 100)) - satiety_cost)
			if got_hurt:
				hd["injury"] = clampf(float(hd.get("injury", 0)) + injury_amount * (1.0 - resist), 0.0, 100.0)
		)
		if got_hurt:
			injured_names.append(str(hero2.get("name", hid2)))

	var silver_gain: int = int(_data.get("base_silver", 40))
	var fur_gain: int = int(_data.get("base_fur", 4))
	var wood_gain: int = int(_data.get("base_wood", 2))
	var iron_gain: int = int(_data.get("base_iron", 1))
	var waves_cleared: int = 0
	for wvo in waves_out:
		if bool((wvo as Dictionary).get("success", false)):
			waves_cleared += 1
	silver_gain = int(round(float(silver_gain) * (0.4 + 0.2 * float(waves_cleared))))
	fur_gain = int(round(float(fur_gain) * (0.5 + 0.2 * float(waves_cleared))))
	## 血氣被動銀獎
	var silver_mult: float = 1.0
	for hid3 in ids:
		silver_mult += AcademySystem.passive_silver_bonus(HeroSystem.get_hero(str(hid3)))
	silver_gain = int(round(float(silver_gain) * silver_mult))

	if cleared_all:
		silver_gain += int(_data.get("clear_bonus_silver", 30))
		iron_gain += int(_data.get("clear_bonus_iron", 2))
		for hid_x in ids:
			HeroSystem.mutate(str(hid_x), func(hd: Dictionary) -> void:
				var add_xp: float = 18.0 + float(BuildingSystem.building_level("training")) * 4.0
				var lv: int = int(hd.get("level", 1))
				var xp: float = float(hd.get("xp", 0)) + add_xp
				var need: float = float(TrainingSystem.xp_to_next(lv))
				while xp >= need and lv < 30:
					xp -= need
					lv += 1
					need = float(TrainingSystem.xp_to_next(lv))
				hd["level"] = lv
				hd["xp"] = xp
				hd["xp_to_next"] = int(need)
			)
	else:
		silver_gain = maxi(0, int(round(float(silver_gain) * 0.35)))
		fur_gain = maxi(0, int(round(float(fur_gain) * 0.3)))
		wood_gain = maxi(0, int(round(float(wood_gain) * 0.3)))
		iron_gain = maxi(0, int(round(float(iron_gain) * 0.2)))

	GameState.add_silver(silver_gain)
	GameState.add_fur(fur_gain)
	if wood_gain > 0:
		GameState.add_wood(wood_gain)
	if iron_gain > 0:
		GameState.add_iron(iron_gain)

	var flavor: String
	if cleared_all:
		flavor = "秘境三波盡破！狼王示意已退。"
	else:
		flavor = "秘境第 %d 波失手，狼狽撤出。" % maxi(1, waves_cleared + 1)

	var rewards: Dictionary = {
		"silver": silver_gain,
		"fur": fur_gain,
		"wood": wood_gain,
		"iron": iron_gain,
		"heroes": ids.duplicate(),
		"zone_name": str(_data.get("name", "秘境")),
		"injured": injured_names,
		"cleared": cleared_all,
		"waves_cleared": waves_cleared,
		"flavor": flavor,
	}
	GameState.push_report("秘境「%s」%s 波%d／%d ＋銀%d 毛皮%d 鐵%d" % [
		str(_data.get("name", "秘境")),
		("通關" if cleared_all else "中挫"),
		waves_cleared,
		wave_defs.size(),
		silver_gain,
		fur_gain,
		iron_gain,
	])
	return {
		"ok": true,
		"reason": "",
		"waves": waves_out,
		"rewards": rewards,
		"dungeon_name": str(_data.get("name", "秘境")),
		"cleared": cleared_all,
	}
