extends RefCounted
class_name OutpostSystem
## 前哨防衛（v0.11）— 三波＋難度階；UI 接自動戰鬥演出

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

static func difficulties() -> Array:
	ensure_loaded()
	var out: Array = []
	for d in _def.get("difficulties", []) as Array:
		out.append((d as Dictionary).duplicate(true))
	if out.is_empty():
		out.append({"id": "normal", "name": "普通", "power_mult": 1.0, "reward_mult": 1.0})
	return out

static func difficulty_by_id(diff_id: String) -> Dictionary:
	for d in difficulties():
		var dd: Dictionary = d as Dictionary
		if str(dd.get("id", "")) == diff_id:
			return dd
	var arr: Array = difficulties()
	return (arr[0] as Dictionary).duplicate(true) if arr.size() > 0 else {}

static func clears_of(diff_id: String) -> int:
	return int(GameState.outpost_diff_clears.get(diff_id, 0))

static func is_difficulty_unlocked(diff_id: String) -> bool:
	var d: Dictionary = difficulty_by_id(diff_id)
	if d.is_empty():
		return false
	var need_of: String = str(d.get("unlock_clears_of", ""))
	if need_of.is_empty():
		return true
	return clears_of(need_of) >= int(d.get("unlock_clears_need", 1))

static func record_clear(diff_id: String) -> void:
	GameState.outpost_diff_clears[diff_id] = clears_of(diff_id) + 1

static func describe_pick_panel() -> String:
	ensure_loaded()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("【前哨防衛 · 難度選擇】")
	var did: String = str(GameState.outpost_pick_diff)
	var diff: Dictionary = difficulty_by_id(did)
	lines.append("而家：%s　敵×%.2f　獎×%.2f" % [
		str(diff.get("name", did)), float(diff.get("power_mult", 1.0)), float(diff.get("reward_mult", 1.0))
	])
	for d in difficulties():
		var dd: Dictionary = d as Dictionary
		var idd: String = str(dd.get("id", ""))
		var lock: String = "" if is_difficulty_unlocked(idd) else "（鎖）"
		var mark: String = "●" if idd == did else "○"
		lines.append("%s %s%s　全勝%d" % [mark, str(dd.get("name", idd)), lock, clears_of(idd)])
	lines.append("剔選守點俠後撳「守前哨」出發。")
	return "\n".join(lines)

static func wave_count() -> int:
	ensure_loaded()
	var waves: Array = _def.get("waves", []) as Array
	if waves.is_empty() and _def.has("wave"):
		return 1
	return maxi(1, waves.size())

static func is_unlocked() -> bool:
	ensure_loaded()
	var need_manor: int = int(_def.get("unlock_manor_level", 2))
	var need_bounty: int = int(_def.get("unlock_bounty_level", 2))
	return BuildingSystem.building_level("manor") >= need_manor \
		and BuildingSystem.building_level("bounty") >= need_bounty

static func can_defend(hero_ids: Array, diff_id: String = "") -> Dictionary:
	ensure_loaded()
	if not is_unlocked():
		return {"ok": false, "reason": "前哨未解鎖（村長府＋懸賞榜皆要 Lv.%d／Lv.%d）" % [
			int(_def.get("unlock_manor_level", 2)), int(_def.get("unlock_bounty_level", 2))
		]}
	var did: String = diff_id if diff_id != "" else str(GameState.outpost_pick_diff)
	if did == "":
		did = str(_def.get("default_difficulty", "normal"))
	if not is_difficulty_unlocked(did):
		var dd: Dictionary = difficulty_by_id(did)
		return {"ok": false, "reason": "難度「%s」未解鎖" % str(dd.get("name", did))}
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

static func _wave_defs() -> Array:
	ensure_loaded()
	var waves: Array = _def.get("waves", []) as Array
	if not waves.is_empty():
		return waves
	## 兼容舊單波 stub
	if _def.has("wave"):
		var w: Dictionary = (_def.get("wave", {}) as Dictionary).duplicate(true)
		w["index"] = 1
		w["label"] = str(w.get("enemy_name", "山賊潮"))
		return [w]
	return []

static func _pick_enemies(wave: Dictionary, count: int) -> Array:
	var mix: Array = wave.get("mix", []) as Array
	if mix.is_empty():
		var kind: String = str(wave.get("enemy_kind", "bandit"))
		var nm: String = str(wave.get("enemy_name", kind))
		var out0: Array = []
		for _i in range(maxi(1, count)):
			out0.append({"kind": kind, "name": nm})
		return out0
	var total_w: int = 0
	for m in mix:
		total_w += int((m as Dictionary).get("weight", 1))
	var out: Array = []
	for _j in range(maxi(1, count)):
		var roll: int = _rng.randi_range(1, maxi(1, total_w))
		var acc: int = 0
		var chosen: Dictionary = mix[0] as Dictionary
		for m2 in mix:
			acc += int((m2 as Dictionary).get("weight", 1))
			if roll <= acc:
				chosen = m2 as Dictionary
				break
		var ck: String = str(chosen.get("kind", "bandit"))
		var is_elite: bool = ck in ["bandit_chief", "wolf_king", "python"]
		var sc: float = 1.0
		if bool(wave.get("boss", false)) and out.is_empty():
			sc = 1.35 if is_elite else 1.25
		elif is_elite:
			sc = 1.2
		out.append({
			"kind": ck,
			"name": str(chosen.get("name", chosen.get("kind", "敵"))),
			"elite": is_elite,
			"scale": sc,
		})
	return out

static func run_defense(hero_ids: Array, diff_id: String = "") -> Dictionary:
	## 同步結算最多三波；UI 再逐波自動戰鬥
	var did: String = diff_id if diff_id != "" else str(GameState.outpost_pick_diff)
	if did == "":
		did = str(_def.get("default_difficulty", "normal"))
	var chk: Dictionary = can_defend(hero_ids, did)
	if not bool(chk.get("ok", false)):
		return {"ok": false, "reason": str(chk.get("reason", "")), "success": false, "waves": [], "rewards": {}}

	ensure_loaded()
	var diff: Dictionary = difficulty_by_id(did)
	var power_mult: float = float(diff.get("power_mult", 1.0))
	var reward_mult: float = float(diff.get("reward_mult", 1.0))
	var diff_name: String = str(diff.get("name", did))
	var ids: Array = []
	for hid_v in hero_ids:
		ids.append(str(hid_v))

	var total_power: int = 0
	for hid in ids:
		total_power += HeroSystem.power_of(HeroSystem.get_hero(str(hid)))

	var manor_lv: int = BuildingSystem.building_level("manor")
	var rewards_def: Dictionary = _def.get("rewards", {}) as Dictionary
	var waves_out: Array = []
	var cleared_all: bool = true
	var waves_cleared: int = 0

	for wv in _wave_defs():
		var wd: Dictionary = wv as Dictionary
		var count: int = int(wd.get("count_base", 5)) + manor_lv * int(wd.get("count_per_manor", 2))
		var power_per: int = int(wd.get("power_per", 8))
		var need: int = int(round(float(count * power_per) * power_mult))
		var success_chance: float = clampf(0.32 + float(total_power) / float(maxi(1, need)) * 0.55, 0.12, 0.95)
		var success: bool = _rng.randf() <= success_chance
		var enemies: Array = _pick_enemies(wd, mini(count, 4))
		waves_out.append({
			"index": int(wd.get("index", waves_out.size() + 1)),
			"label": str(wd.get("label", "波次")),
			"boss": bool(wd.get("boss", false)),
			"enemy_name": str(wd.get("enemy_name", "")),
			"enemy_count": count,
			"enemies": enemies,
			"party_power": total_power,
			"enemy_power": need,
			"success": success,
			"success_chance": success_chance,
		})
		if success:
			waves_cleared += 1
		else:
			cleared_all = false
			break

	var silver_gain: int = 0
	var iron_gain: int = 0
	var fur_gain: int = 0
	var inj_amt: float = float(_def.get("fail_injury", 12))

	if waves_cleared > 0:
		silver_gain = int(round(float(rewards_def.get("silver_base", 35)) + float(total_power) * float(rewards_def.get("power_bonus_per", 0.45))))
		silver_gain += waves_cleared * int(rewards_def.get("wave_clear_bonus_silver", 15))
		iron_gain = int(rewards_def.get("iron_base", 1)) * waves_cleared
		fur_gain = int(rewards_def.get("fur_base", 1)) * waves_cleared
		if cleared_all:
			silver_gain += int(rewards_def.get("full_clear_bonus_silver", 40))
			iron_gain += int(rewards_def.get("full_clear_bonus_iron", 2))
		silver_gain = maxi(0, int(round(float(silver_gain) * reward_mult)))
		iron_gain = maxi(0, int(round(float(iron_gain) * reward_mult)))
		fur_gain = maxi(0, int(round(float(fur_gain) * reward_mult)))
		GameState.add_silver(silver_gain)
		if iron_gain > 0:
			GameState.add_iron(iron_gain)
		if fur_gain > 0:
			GameState.add_fur(fur_gain)
		for hid_x in ids:
			HeroSystem.mutate(str(hid_x), func(hd: Dictionary) -> void:
				hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - (16.0 + float(waves_cleared) * 4.0))
				hd["satiety"] = maxf(0.0, float(hd.get("satiety", 100)) - (10.0 + float(waves_cleared) * 3.0))
				if not cleared_all:
					hd["injury"] = clampf(float(hd.get("injury", 0)) + inj_amt * 0.5, 0.0, 100.0)
				var add_xp: float = 8.0 + float(waves_cleared) * 5.0 + float(BuildingSystem.building_level("training")) * 2.0
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
	else:
		silver_gain = int(round(float(rewards_def.get("silver_base", 35)) * 0.15))
		GameState.add_silver(silver_gain)
		for hid_f in ids:
			HeroSystem.mutate(str(hid_f), func(hd: Dictionary) -> void:
				hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - 28.0)
				hd["injury"] = clampf(float(hd.get("injury", 0)) + inj_amt, 0.0, 100.0)
			)

	var flavor: String
	if cleared_all:
		flavor = "前哨「%s」三波盡破！山賊／獸潮退散。" % diff_name
	elif waves_cleared > 0:
		flavor = "前哨「%s」守住 %d／3 波後不敵撤返。" % [diff_name, waves_cleared]
	else:
		flavor = "前哨「%s」首波即潰，守軍負傷。" % diff_name

	GameState.push_report("前哨「%s·%s」%s 波%d／%d ＋銀%d 鐵%d 毛皮%d" % [
		str(_def.get("name", "前哨")),
		diff_name,
		("全勝" if cleared_all else ("部分" if waves_cleared > 0 else "失利")),
		waves_cleared,
		wave_count(),
		silver_gain,
		iron_gain,
		fur_gain,
	])
	if cleared_all:
		GameState.outpost_clears += 1
		record_clear(did)
	GameState.heroes_changed.emit()

	return {
		"ok": true,
		"reason": "",
		"success": cleared_all,
		"cleared": cleared_all,
		"waves_cleared": waves_cleared,
		"waves": waves_out,
		"heroes": ids.duplicate(),
		"flavor": flavor,
		"difficulty_id": did,
		"difficulty_name": diff_name,
		"rewards": {
			"silver": silver_gain,
			"iron": iron_gain,
			"fur": fur_gain,
			"wood": 0,
			"flavor": flavor,
			"injured": [],
			"difficulty_id": did,
			"difficulty_name": diff_name,
		},
	}

## 兼容舊 API
static func run_wave(hero_ids: Array) -> Dictionary:
	var res: Dictionary = run_defense(hero_ids)
	if not bool(res.get("ok", false)):
		return res
	var waves: Array = res.get("waves", []) as Array
	var last: Dictionary = waves[waves.size() - 1] as Dictionary if waves.size() > 0 else {}
	return {
		"ok": true,
		"reason": "",
		"success": bool(res.get("cleared", false)),
		"enemy_name": str(last.get("enemy_name", "山賊潮")),
		"enemy_count": int(last.get("enemy_count", 0)),
		"success_chance": float(last.get("success_chance", 0)),
		"rewards": (res.get("rewards", {}) as Dictionary).duplicate(true),
		"waves": waves,
		"waves_cleared": int(res.get("waves_cleared", 0)),
		"cleared": bool(res.get("cleared", false)),
		"heroes": res.get("heroes", []),
		"flavor": str(res.get("flavor", "")),
	}
