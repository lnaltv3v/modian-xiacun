extends RefCounted
class_name OutpostSystem
## 前哨防衛（v0.18）— 三波＋難度階＋駐守升級／手動巡哨 stub

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
		silver_gain = maxi(0, int(round(float(silver_gain) * (1.0 + AcademySystem.village_effect_add("outpost_silver_bonus", 0.0)))))
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


## --- v0.13 外派營地／多前哨長期駐守 stub ---

static func camps() -> Array:
	ensure_loaded()
	var out: Array = []
	for c in _def.get("camps", []) as Array:
		out.append((c as Dictionary).duplicate(true))
	return out


static func camp_by_id(camp_id: String) -> Dictionary:
	for c in camps():
		var cd: Dictionary = c as Dictionary
		if str(cd.get("id", "")) == camp_id:
			return cd
	return {}


static func default_camp_id() -> String:
	ensure_loaded()
	var d: String = str(_def.get("default_camp", ""))
	if d != "" and not camp_by_id(d).is_empty():
		return d
	var arr: Array = camps()
	if arr.is_empty():
		return ""
	return str((arr[0] as Dictionary).get("id", ""))


static func is_camp_unlocked(camp_id: String) -> bool:
	if not is_unlocked():
		return false
	var c: Dictionary = camp_by_id(camp_id)
	if c.is_empty():
		return false
	var mode: String = str(c.get("unlock_mode", "outpost"))
	if mode == "clears":
		return GameState.outpost_clears >= int(c.get("unlock_clears_need", 1))
	return true


static func camp_station(camp_id: String) -> Dictionary:
	if typeof(GameState.camp_stations.get(camp_id, {})) != TYPE_DICTIONARY:
		return {}
	return (GameState.camp_stations.get(camp_id, {}) as Dictionary).duplicate(true)


static func stationed_hero_ids(camp_id: String = "") -> Array:
	var out: Array = []
	if camp_id != "":
		var st: Dictionary = camp_station(camp_id)
		for hid in st.get("hero_ids", []) as Array:
			out.append(str(hid))
		return out
	for cid in GameState.camp_stations.keys():
		var st2: Dictionary = camp_station(str(cid))
		for hid2 in st2.get("hero_ids", []) as Array:
			out.append(str(hid2))
	return out


static func is_hero_stationed(hero_id: String) -> bool:
	return stationed_hero_ids("").has(hero_id)


static func camp_of_hero(hero_id: String) -> String:
	for cid in GameState.camp_stations.keys():
		var st: Dictionary = camp_station(str(cid))
		for hid in st.get("hero_ids", []) as Array:
			if str(hid) == hero_id:
				return str(cid)
	return ""


static func can_station(camp_id: String, hero_ids: Array) -> Dictionary:
	ensure_loaded()
	if not is_unlocked():
		return {"ok": false, "reason": "前哨未解鎖，未能外派駐守"}
	var c: Dictionary = camp_by_id(camp_id)
	if c.is_empty():
		return {"ok": false, "reason": "無此地營地"}
	if not is_camp_unlocked(camp_id):
		return {"ok": false, "reason": "「%s」未解鎖（需前哨全勝 %d 次）" % [
			str(c.get("name", camp_id)), int(c.get("unlock_clears_need", 1))
		]}
	var slots: int = effective_slots(camp_id)
	if hero_ids.is_empty():
		return {"ok": false, "reason": "未揀駐守俠客"}
	if hero_ids.size() > slots:
		return {"ok": false, "reason": "「%s」最多駐 %d 人" % [str(c.get("name", camp_id)), slots]}
	var seen: Dictionary = {}
	for hid_v in hero_ids:
		var hid: String = str(hid_v)
		if seen.has(hid):
			return {"ok": false, "reason": "重複揀咗同一俠"}
		seen[hid] = true
		var h: Dictionary = HeroSystem.get_hero(hid)
		if h.is_empty():
			return {"ok": false, "reason": "俠客不存在"}
		if str(h.get("status", "idle")) != "idle":
			return {"ok": false, "reason": "%s 唔喺村（%s）" % [
				str(h.get("name", "")), str(h.get("status", ""))
			]}
		if not HeroSystem.can_hunt(h):
			return {"ok": false, "reason": "%s 狀態唔適合駐守" % str(h.get("name", ""))}
	var cur: Dictionary = camp_station(camp_id)
	var cur_n: int = (cur.get("hero_ids", []) as Array).size()
	if cur_n > 0:
		return {"ok": false, "reason": "「%s」已有駐軍，請先召回" % str(c.get("name", camp_id))}
	return {"ok": true, "reason": ""}


static func station(camp_id: String, hero_ids: Array) -> Dictionary:
	var chk: Dictionary = can_station(camp_id, hero_ids)
	if not bool(chk.get("ok", false)):
		return {"ok": false, "reason": str(chk.get("reason", ""))}
	var c: Dictionary = camp_by_id(camp_id)
	var ids: Array = []
	var names: PackedStringArray = PackedStringArray()
	for hid_v in hero_ids:
		var hid: String = str(hid_v)
		ids.append(hid)
		names.append(str(HeroSystem.get_hero(hid).get("name", hid)))
		HeroSystem.set_status(hid, "camped")
	var now: float = Time.get_unix_time_from_system()
	GameState.camp_stations[camp_id] = {
		"hero_ids": ids.duplicate(),
		"stationed_at": now,
		"tick_accum": 0.0,
		"skirmish_accum": 0.0,
		"total_silver": 0,
		"total_iron": 0,
		"total_fur": 0,
		"skirmishes": 0,
		"manual_skirmishes": 0,
		"manual_cd_until": 0.0,
		"last_summary": "剛進駐",
	}
	GameState.camp_pick_id = camp_id
	GameState.push_report("外派「%s」：%s 長期駐守" % [
		str(c.get("name", camp_id)), "、".join(names)
	])
	GameState.heroes_changed.emit()
	return {
		"ok": true,
		"reason": "",
		"camp_id": camp_id,
		"camp_name": str(c.get("name", camp_id)),
		"heroes": ids.duplicate(),
	}


static func can_recall(camp_id: String) -> Dictionary:
	var c: Dictionary = camp_by_id(camp_id)
	if c.is_empty():
		return {"ok": false, "reason": "無此地營地"}
	var st: Dictionary = camp_station(camp_id)
	if (st.get("hero_ids", []) as Array).is_empty():
		return {"ok": false, "reason": "「%s」無人駐守" % str(c.get("name", camp_id))}
	return {"ok": true, "reason": ""}


static func recall(camp_id: String) -> Dictionary:
	var chk: Dictionary = can_recall(camp_id)
	if not bool(chk.get("ok", false)):
		return {"ok": false, "reason": str(chk.get("reason", ""))}
	var c: Dictionary = camp_by_id(camp_id)
	var st: Dictionary = camp_station(camp_id)
	var ids: Array = []
	var names: PackedStringArray = PackedStringArray()
	for hid_v in st.get("hero_ids", []) as Array:
		var hid: String = str(hid_v)
		ids.append(hid)
		var h: Dictionary = HeroSystem.get_hero(hid)
		names.append(str(h.get("name", hid)))
		if str(h.get("status", "")) == "camped":
			HeroSystem.set_status(hid, "idle")
	var summary: String = "召回「%s」：%s｜累計銀%d 鐵%d 毛皮%d 小戰%d" % [
		str(c.get("name", camp_id)),
		"、".join(names),
		int(st.get("total_silver", 0)),
		int(st.get("total_iron", 0)),
		int(st.get("total_fur", 0)),
		int(st.get("skirmishes", 0)),
	]
	GameState.camp_stations.erase(camp_id)
	GameState.push_report(summary)
	GameState.heroes_changed.emit()
	return {
		"ok": true,
		"reason": "",
		"camp_id": camp_id,
		"camp_name": str(c.get("name", camp_id)),
		"heroes": ids.duplicate(),
		"summary": summary,
		"totals": {
			"silver": int(st.get("total_silver", 0)),
			"iron": int(st.get("total_iron", 0)),
			"fur": int(st.get("total_fur", 0)),
			"skirmishes": int(st.get("skirmishes", 0)),
		},
	}


static func sanitize_stations() -> void:
	## 讀檔後對齊 camped 狀態同駐守表
	var valid_ids: Dictionary = {}
	for cid_v in GameState.camp_stations.keys():
		var cid: String = str(cid_v)
		var c: Dictionary = camp_by_id(cid)
		var st: Dictionary = camp_station(cid)
		var cleaned: Array = []
		for hid_v in st.get("hero_ids", []) as Array:
			var hid: String = str(hid_v)
			var h: Dictionary = HeroSystem.get_hero(hid)
			if h.is_empty():
				continue
			cleaned.append(hid)
			valid_ids[hid] = cid
			if str(h.get("status", "idle")) != "camped":
				HeroSystem.set_status(hid, "camped")
		if cleaned.is_empty() or c.is_empty():
			GameState.camp_stations.erase(cid)
		else:
			st["hero_ids"] = cleaned
			if not st.has("tick_accum"):
				st["tick_accum"] = 0.0
			if not st.has("skirmish_accum"):
				st["skirmish_accum"] = 0.0
			if not st.has("total_silver"):
				st["total_silver"] = 0
			if not st.has("total_iron"):
				st["total_iron"] = 0
			if not st.has("total_fur"):
				st["total_fur"] = 0
			if not st.has("skirmishes"):
				st["skirmishes"] = 0
			if not st.has("last_summary"):
				st["last_summary"] = ""
			if not st.has("bag_silver"):
				st["bag_silver"] = 0.0
			if not st.has("bag_upkeep"):
				st["bag_upkeep"] = 0.0
			if not st.has("comfort"):
				st["comfort"] = true
			if not st.has("manual_cd_until"):
				st["manual_cd_until"] = 0.0
			GameState.camp_stations[cid] = st
	for h in GameState.heroes:
		var hd: Dictionary = h as Dictionary
		var hid2: String = str(hd.get("id", ""))
		if str(hd.get("status", "")) == "camped" and not valid_ids.has(hid2):
			HeroSystem.set_status(hid2, "idle")


static func _party_power(hero_ids: Array) -> int:
	var total: int = 0
	for hid_v in hero_ids:
		total += HeroSystem.power_of(HeroSystem.get_hero(str(hid_v)))
	return total


static func tick_camps(delta: float) -> Dictionary:
	## 被動涓滴＋週期小戰摘要；駐守飽食／體力只走此路徑（唔疊村莊饑餓）
	## 糧餉繳足 → 舒適減耗；欠餉 → 略加重耗；疲憊自動召回
	if delta <= 0.0 or GameState.camp_stations.is_empty():
		return {"ok": true, "gains": {}, "events": []}
	ensure_loaded()
	var events: Array = []
	var gained_silver: int = 0
	var gained_iron: int = 0
	var gained_fur: int = 0
	var spent_upkeep: int = 0
	var changed: bool = false
	var cids: Array = GameState.camp_stations.keys()
	for cid_v in cids:
		var cid: String = str(cid_v)
		var c: Dictionary = camp_by_id(cid)
		if c.is_empty():
			continue
		var st: Dictionary = camp_station(cid)
		var ids: Array = []
		for hid_v in st.get("hero_ids", []) as Array:
			ids.append(str(hid_v))
		if ids.is_empty():
			continue
		var n: float = float(ids.size())
		var power: int = _party_power(ids)
		var power_m: float = 1.0 + float(power) * float(c.get("power_bonus_per", 0.08)) * 0.01
		var tick_acc: float = float(st.get("tick_accum", 0.0)) + delta
		var sk_acc: float = float(st.get("skirmish_accum", 0.0)) + delta
		## 先結糧餉 → 決定舒適減耗（單一飽食路徑）
		var camp_up_m: float = AcademySystem.village_effect_mult("camp_upkeep_mult", 1.0)
		var camp_sil_b: float = AcademySystem.village_effect_add("camp_silver_bonus", 0.0)
		var up_m: float = camp_trickle_mult(cid)
		var upkeep_rate: float = float(c.get("upkeep_silver_per_min", 1.5)) * n / 60.0 * camp_up_m
		var silver_rate: float = float(c.get("trickle_silver_per_min", 10.0)) * power_m / 60.0 * (1.0 + camp_sil_b) * up_m
		var fur_rate: float = float(c.get("trickle_fur_per_min", 0.0)) * power_m / 60.0 * up_m
		var iron_rate: float = float(c.get("trickle_iron_per_min", 0.0)) * power_m / 60.0 * up_m
		var bag_s: float = float(st.get("bag_silver", 0.0)) + silver_rate * delta
		var bag_f: float = float(st.get("bag_fur", 0.0)) + fur_rate * delta
		var bag_i: float = float(st.get("bag_iron", 0.0)) + iron_rate * delta
		var bag_u: float = float(st.get("bag_upkeep", 0.0)) + upkeep_rate * delta
		var pay_u: int = int(floor(bag_u))
		var comfort: bool = true
		if pay_u > 0:
			bag_u -= float(pay_u)
			var paid: int = mini(GameState.silver, pay_u)
			if paid > 0:
				GameState.try_spend(paid, 0)
				spent_upkeep += paid
			if paid >= pay_u:
				comfort = true
			else:
				comfort = false
				st["last_summary"] = "糧餉不足，駐軍更疲"
				changed = true
		elif upkeep_rate > 0.0:
			## 未到整銀結算：銀庫空＝無乾糧舒適；有銀維持上一段舒適
			if GameState.silver <= 0:
				comfort = false
			else:
				comfort = bool(st.get("comfort", true))
		var comfort_m: float = float(c.get("comfort_drain_mult", 0.55)) if comfort else float(c.get("unpaid_drain_mult", 1.15))
		if comfort:
			comfort_m *= camp_comfort_drain_scale(cid)
		var stam_d: float = float(c.get("stamina_drain_per_min", 3.0)) / 60.0 * delta * comfort_m
		var sat_d: float = float(c.get("satiety_drain_per_min", 1.8)) / 60.0 * delta * comfort_m
		## 舒適時微補營帳乾糧（唔疊村莊客棧）
		var sat_comfort: float = 0.0
		if comfort:
			sat_comfort = float(c.get("comfort_satiety_per_min", 0.35)) / 60.0 * delta
		for hid in ids:
			HeroSystem.mutate(str(hid), func(hd: Dictionary) -> void:
				hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - stam_d)
				var sat_now: float = float(hd.get("satiety", 100)) - sat_d + sat_comfort
				hd["satiety"] = clampf(sat_now, 0.0, 100.0)
				hd["status"] = "camped"
			)
		st["comfort"] = comfort
		var add_s: int = int(floor(bag_s))
		var add_f: int = int(floor(bag_f))
		var add_i: int = int(floor(bag_i))
		if add_s > 0:
			bag_s -= float(add_s)
			GameState.add_silver(add_s)
			st["total_silver"] = int(st.get("total_silver", 0)) + add_s
			gained_silver += add_s
			changed = true
		if add_f > 0:
			bag_f -= float(add_f)
			GameState.add_fur(add_f)
			st["total_fur"] = int(st.get("total_fur", 0)) + add_f
			gained_fur += add_f
			changed = true
		if add_i > 0:
			bag_i -= float(add_i)
			GameState.add_iron(add_i)
			st["total_iron"] = int(st.get("total_iron", 0)) + add_i
			gained_iron += add_i
			changed = true
		## periodic auto-skirmish summary
		var sk_iv: float = maxf(20.0, float(c.get("skirmish_interval_sec", 48.0)))
		while sk_acc >= sk_iv:
			sk_acc -= sk_iv
			var sk_s: int = int(round(float(c.get("skirmish_silver_base", 10)) * power_m))
			var sk_f: int = 1 if _rng.randf() <= float(c.get("skirmish_fur_chance", 0.3)) else 0
			if sk_s > 0:
				GameState.add_silver(sk_s)
				st["total_silver"] = int(st.get("total_silver", 0)) + sk_s
				gained_silver += sk_s
			if sk_f > 0:
				GameState.add_fur(sk_f)
				st["total_fur"] = int(st.get("total_fur", 0)) + sk_f
				gained_fur += sk_f
			st["skirmishes"] = int(st.get("skirmishes", 0)) + 1
			## small stamina hit for skirmish
			for hid2 in ids:
				HeroSystem.mutate(str(hid2), func(hd: Dictionary) -> void:
					hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - 3.0)
					hd["status"] = "camped"
				)
			var ev: String = "「%s」小戰捷報＋銀%d%s" % [
				str(c.get("name", cid)), sk_s, (" 毛皮%d" % sk_f) if sk_f > 0 else ""
			]
			st["last_summary"] = ev
			GameState.push_report(ev)
			events.append({"camp_id": cid, "text": ev, "silver": sk_s, "fur": sk_f})
			changed = true
		st["tick_accum"] = tick_acc
		st["skirmish_accum"] = sk_acc
		st["bag_silver"] = bag_s
		st["bag_fur"] = bag_f
		st["bag_iron"] = bag_i
		st["bag_upkeep"] = bag_u
		st["hero_ids"] = ids.duplicate()
		GameState.camp_stations[cid] = st
		## auto-recall if all heroes too exhausted
		var all_down: bool = true
		for hid3 in ids:
			var hh: Dictionary = HeroSystem.get_hero(str(hid3))
			if float(hh.get("stamina", 0)) >= 8.0 and float(hh.get("satiety", 0)) >= 5.0:
				all_down = false
				break
		if all_down:
			var rec: Dictionary = recall(cid)
			events.append({"camp_id": cid, "text": "疲憊自動召回", "recall": rec})
			changed = true
	if changed:
		GameState.heroes_changed.emit()
	return {
		"ok": true,
		"gains": {"silver": gained_silver, "iron": gained_iron, "fur": gained_fur, "upkeep": spent_upkeep},
		"events": events,
	}


static func describe_camps_panel() -> String:
	ensure_loaded()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("【外派駐守 · 多前哨】")
	var pick: String = str(GameState.camp_pick_id)
	if pick == "" or camp_by_id(pick).is_empty():
		pick = default_camp_id()
	for c in camps():
		var cd: Dictionary = c as Dictionary
		var cid: String = str(cd.get("id", ""))
		var lock: bool = not is_camp_unlocked(cid)
		var st: Dictionary = camp_station(cid)
		var ids: Array = st.get("hero_ids", []) as Array
		var mark: String = "●" if cid == pick else "○"
		var lock_txt: String = "（鎖）" if lock else ""
		var lv: int = camp_level(cid)
		var slots_n: int = effective_slots(cid)
		var sil_m: float = float(cd.get("trickle_silver_per_min", 0.0)) * camp_trickle_mult(cid)
		if ids.is_empty():
			lines.append("%s %s%s　空　Lv%d　槽%d　銀≈%.0f/分" % [
				mark, str(cd.get("name", cid)), lock_txt, lv, slots_n, sil_m
			])
		else:
			var names: PackedStringArray = PackedStringArray()
			for hid_v in ids:
				names.append(str(HeroSystem.get_hero(str(hid_v)).get("name", hid_v)))
			lines.append("%s %s　Lv%d　駐：%s（%d／%d）" % [
				mark, str(cd.get("name", cid)), lv, "、".join(names), ids.size(), slots_n
			])
			var comfort_txt: String = "舒適" if bool(st.get("comfort", true)) else "欠餉"
			lines.append("　累計銀%d 鐵%d 毛皮%d 小戰%d 巡%d｜%s｜%s" % [
				int(st.get("total_silver", 0)), int(st.get("total_iron", 0)),
				int(st.get("total_fur", 0)), int(st.get("skirmishes", 0)),
				int(st.get("manual_skirmishes", 0)),
				comfort_txt,
				str(st.get("last_summary", ""))
			])
		var nxt: Dictionary = next_upgrade_def(cid)
		if nxt.is_empty():
			lines.append("　升級：已滿 Lv.%d" % lv)
		else:
			lines.append("　下級「%s」：銀%d 木%d 鐵%d（＋槽%d　涓×%.2f　舒×%.2f）" % [
				str(nxt.get("name", "升級")),
				int(nxt.get("silver", 0)), int(nxt.get("wood", 0)), int(nxt.get("iron", 0)),
				int(nxt.get("add_slots", 0)), float(nxt.get("trickle_mult", 1.0)),
				float(nxt.get("comfort_drain_scale", 1.0)),
			])
	lines.append("規則：駐守飽食／體力只走營地耗（唔疊村莊饑餓）；糧餉繳足＝舒適減耗＋微補乾糧，欠餉加重。")
	lines.append("「升級營」耗銀木鐵加深營地；「巡哨」一鍵小戰（重用自動戰鬥）。駐守中唔可派遣／秘境／一波防衛。")
	return "\n".join(lines)


static func describe_pick_panel_full() -> String:
	## 難度選擇＋駐守摘要（前哨面板）
	return describe_pick_panel() + "\n\n" + describe_camps_panel()


static func stationed_count() -> int:
	return stationed_hero_ids("").size()




## --- v0.18 營地升級／手動巡哨 ---

static func camp_upgrade_levels() -> Array:
	ensure_loaded()
	var cu: Dictionary = _def.get("camp_upgrades", {}) as Dictionary
	var out: Array = []
	for u in cu.get("levels", []) as Array:
		out.append((u as Dictionary).duplicate(true))
	return out


static func camp_max_level() -> int:
	ensure_loaded()
	var cu: Dictionary = _def.get("camp_upgrades", {}) as Dictionary
	var mx: int = int(cu.get("max_level", 0))
	if mx <= 0:
		mx = camp_upgrade_levels().size()
	return maxi(0, mx)


static func camp_level(camp_id: String) -> int:
	return clampi(int(GameState.camp_levels.get(camp_id, 0)), 0, camp_max_level())


static func next_upgrade_def(camp_id: String) -> Dictionary:
	var want: int = camp_level(camp_id) + 1
	for u in camp_upgrade_levels():
		var ud: Dictionary = u as Dictionary
		if int(ud.get("level", 0)) == want:
			return ud.duplicate(true)
	return {}


static func effective_slots(camp_id: String) -> int:
	var c: Dictionary = camp_by_id(camp_id)
	var slots: int = int(c.get("slots", 2))
	var lv: int = camp_level(camp_id)
	for u in camp_upgrade_levels():
		var ud: Dictionary = u as Dictionary
		if int(ud.get("level", 0)) <= lv:
			slots += int(ud.get("add_slots", 0))
	return maxi(1, slots)


static func camp_trickle_mult(camp_id: String) -> float:
	var m: float = 1.0
	var lv: int = camp_level(camp_id)
	for u in camp_upgrade_levels():
		var ud: Dictionary = u as Dictionary
		if int(ud.get("level", 0)) <= lv:
			m *= float(ud.get("trickle_mult", 1.0))
	return maxf(0.1, m)


static func camp_comfort_drain_scale(camp_id: String) -> float:
	## <1 = 舒適時更少耗
	var m: float = 1.0
	var lv: int = camp_level(camp_id)
	for u in camp_upgrade_levels():
		var ud: Dictionary = u as Dictionary
		if int(ud.get("level", 0)) <= lv:
			m *= float(ud.get("comfort_drain_scale", 1.0))
	return clampf(m, 0.35, 1.5)


static func can_upgrade_camp(camp_id: String) -> Dictionary:
	ensure_loaded()
	if not is_unlocked():
		return {"ok": false, "reason": "前哨未解鎖"}
	var c: Dictionary = camp_by_id(camp_id)
	if c.is_empty():
		return {"ok": false, "reason": "無此地營地"}
	if not is_camp_unlocked(camp_id):
		return {"ok": false, "reason": "「%s」未解鎖" % str(c.get("name", camp_id))}
	var nxt: Dictionary = next_upgrade_def(camp_id)
	if nxt.is_empty():
		return {"ok": false, "reason": "「%s」已滿級 Lv.%d" % [str(c.get("name", camp_id)), camp_level(camp_id)]}
	var need_s: int = int(nxt.get("silver", 0))
	var need_w: int = int(nxt.get("wood", 0))
	var need_i: int = int(nxt.get("iron", 0))
	if GameState.silver < need_s or GameState.wood < need_w or GameState.iron < need_i:
		return {
			"ok": false,
			"reason": "升級「%s」欠資源（要銀%d 木%d 鐵%d）" % [
				str(nxt.get("name", "升級")), need_s, need_w, need_i
			],
			"cost": {"silver": need_s, "wood": need_w, "iron": need_i},
		}
	return {
		"ok": true,
		"reason": "",
		"cost": {"silver": need_s, "wood": need_w, "iron": need_i},
		"upgrade": nxt.duplicate(true),
	}


static func upgrade_camp(camp_id: String) -> Dictionary:
	var chk: Dictionary = can_upgrade_camp(camp_id)
	if not bool(chk.get("ok", false)):
		return {"ok": false, "reason": str(chk.get("reason", ""))}
	var nxt: Dictionary = chk.get("upgrade", {}) as Dictionary
	var need_s: int = int(nxt.get("silver", 0))
	var need_w: int = int(nxt.get("wood", 0))
	var need_i: int = int(nxt.get("iron", 0))
	if not GameState.try_spend(need_s, need_w, 0, need_i):
		return {"ok": false, "reason": "扣費失敗"}
	var new_lv: int = camp_level(camp_id) + 1
	GameState.camp_levels[camp_id] = new_lv
	var c: Dictionary = camp_by_id(camp_id)
	var msg: String = "營地「%s」升至 Lv.%d「%s」｜槽%d　涓×%.2f" % [
		str(c.get("name", camp_id)),
		new_lv,
		str(nxt.get("name", "升級")),
		effective_slots(camp_id),
		camp_trickle_mult(camp_id),
	]
	GameState.push_report(msg)
	GameState.resources_changed.emit()
	return {
		"ok": true,
		"reason": "",
		"camp_id": camp_id,
		"level": new_lv,
		"upgrade": nxt.duplicate(true),
		"slots": effective_slots(camp_id),
		"summary": msg,
	}


static func _manual_skirmish_def() -> Dictionary:
	ensure_loaded()
	var m: Dictionary = _def.get("manual_skirmish", {}) as Dictionary
	return m.duplicate(true)


static func can_manual_skirmish(camp_id: String) -> Dictionary:
	ensure_loaded()
	var c: Dictionary = camp_by_id(camp_id)
	if c.is_empty():
		return {"ok": false, "reason": "無此地營地"}
	var st: Dictionary = camp_station(camp_id)
	var ids: Array = []
	for hid_v in st.get("hero_ids", []) as Array:
		ids.append(str(hid_v))
	if ids.is_empty():
		return {"ok": false, "reason": "「%s」無人駐守，未能巡哨" % str(c.get("name", camp_id))}
	var now: float = Time.get_unix_time_from_system()
	var cd_until: float = float(st.get("manual_cd_until", 0.0))
	if now < cd_until:
		return {"ok": false, "reason": "巡哨冷卻中（約 %.0f 秒）" % maxf(1.0, cd_until - now)}
	for hid in ids:
		var h: Dictionary = HeroSystem.get_hero(str(hid))
		if h.is_empty():
			return {"ok": false, "reason": "駐軍資料異常"}
		if float(h.get("stamina", 0)) < 12.0:
			return {"ok": false, "reason": "%s 太疲，未能巡哨" % str(h.get("name", hid))}
		if float(h.get("satiety", 0)) < 8.0:
			return {"ok": false, "reason": "%s 太餓，未能巡哨" % str(h.get("name", hid))}
		if float(h.get("injury", 0)) >= 60.0:
			return {"ok": false, "reason": "%s 傷重，未能巡哨" % str(h.get("name", hid))}
	return {"ok": true, "reason": "", "heroes": ids.duplicate()}


static func run_manual_skirmish(camp_id: String) -> Dictionary:
	## 一鍵巡哨：即時結算＋回傳單波供 auto_combat 演出
	var chk: Dictionary = can_manual_skirmish(camp_id)
	if not bool(chk.get("ok", false)):
		return {"ok": false, "reason": str(chk.get("reason", "")), "success": false, "waves": [], "rewards": {}}
	ensure_loaded()
	var c: Dictionary = camp_by_id(camp_id)
	var st: Dictionary = camp_station(camp_id)
	var ids: Array = []
	for hid_v in st.get("hero_ids", []) as Array:
		ids.append(str(hid_v))
	var mdef: Dictionary = _manual_skirmish_def()
	var total_power: int = _party_power(ids)
	var count: int = int(mdef.get("count_base", 3))
	var power_per: int = int(mdef.get("power_per", 7))
	## 升級略降敵壓／略加獎
	var up_m: float = camp_trickle_mult(camp_id)
	var need: int = int(round(float(count * power_per) / maxf(1.0, 0.85 + (up_m - 1.0) * 0.5)))
	var success_chance: float = clampf(0.34 + float(total_power) / float(maxi(1, need)) * 0.55, 0.15, 0.96)
	var success: bool = _rng.randf() <= success_chance
	var wave_stub: Dictionary = {
		"mix": mdef.get("mix", []) as Array,
		"boss": false,
		"enemy_name": str(mdef.get("label", "巡哨")),
	}
	var enemies: Array = _pick_enemies(wave_stub, mini(count, 4))
	var silver_gain: int = 0
	var fur_gain: int = 0
	var iron_gain: int = 0
	var stam_cost: float = float(mdef.get("stamina_cost", 7))
	var sat_cost: float = float(mdef.get("satiety_cost", 3.5))
	var inj: float = float(mdef.get("fail_injury", 6))
	if success:
		silver_gain = int(round(float(mdef.get("silver_base", 16)) + float(total_power) * float(mdef.get("power_bonus_per", 0.35))))
		silver_gain = maxi(1, int(round(float(silver_gain) * up_m)))
		if _rng.randf() <= float(mdef.get("fur_chance", 0.4)):
			fur_gain = 1
		if _rng.randf() <= float(mdef.get("iron_chance", 0.15)):
			iron_gain = 1
		GameState.add_silver(silver_gain)
		if fur_gain > 0:
			GameState.add_fur(fur_gain)
		if iron_gain > 0:
			GameState.add_iron(iron_gain)
		st["total_silver"] = int(st.get("total_silver", 0)) + silver_gain
		st["total_fur"] = int(st.get("total_fur", 0)) + fur_gain
		st["total_iron"] = int(st.get("total_iron", 0)) + iron_gain
		for hid in ids:
			HeroSystem.mutate(str(hid), func(hd: Dictionary) -> void:
				hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - stam_cost)
				hd["satiety"] = maxf(0.0, float(hd.get("satiety", 100)) - sat_cost)
				hd["status"] = "camped"
				var add_xp: float = 4.0 + float(BuildingSystem.building_level("training")) * 0.5
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
		silver_gain = maxi(0, int(round(float(mdef.get("silver_base", 16)) * 0.2)))
		if silver_gain > 0:
			GameState.add_silver(silver_gain)
			st["total_silver"] = int(st.get("total_silver", 0)) + silver_gain
		for hid2 in ids:
			HeroSystem.mutate(str(hid2), func(hd: Dictionary) -> void:
				hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - stam_cost * 1.35)
				hd["satiety"] = maxf(0.0, float(hd.get("satiety", 100)) - sat_cost)
				hd["injury"] = clampf(float(hd.get("injury", 0)) + inj, 0.0, 100.0)
				hd["status"] = "camped"
			)
	st["skirmishes"] = int(st.get("skirmishes", 0)) + 1
	st["manual_skirmishes"] = int(st.get("manual_skirmishes", 0)) + 1
	var cd: float = maxf(8.0, float(mdef.get("cooldown_sec", 28)))
	st["manual_cd_until"] = Time.get_unix_time_from_system() + cd
	var flavor: String
	if success:
		flavor = "「%s」巡哨得手，掃走斥候。" % str(c.get("name", camp_id))
	else:
		flavor = "「%s」巡哨受挫，駐軍帶傷撤回營帳。" % str(c.get("name", camp_id))
	st["last_summary"] = flavor
	st["hero_ids"] = ids.duplicate()
	GameState.camp_stations[camp_id] = st
	GameState.push_report("巡哨「%s」%s ＋銀%d%s%s" % [
		str(c.get("name", camp_id)),
		("捷" if success else "挫"),
		silver_gain,
		(" 毛皮%d" % fur_gain) if fur_gain > 0 else "",
		(" 鐵%d" % iron_gain) if iron_gain > 0 else "",
	])
	GameState.heroes_changed.emit()
	var wave_out: Dictionary = {
		"index": 1,
		"label": str(mdef.get("label", "手動巡哨")),
		"boss": false,
		"enemy_name": str(mdef.get("label", "巡哨")),
		"enemy_count": count,
		"enemies": enemies,
		"party_power": total_power,
		"enemy_power": need,
		"success": success,
		"success_chance": success_chance,
	}
	return {
		"ok": true,
		"reason": "",
		"success": success,
		"cleared": success,
		"waves_cleared": 1 if success else 0,
		"waves": [wave_out],
		"heroes": ids.duplicate(),
		"flavor": flavor,
		"camp_id": camp_id,
		"camp_name": str(c.get("name", camp_id)),
		"rewards": {
			"silver": silver_gain,
			"iron": iron_gain,
			"fur": fur_gain,
			"wood": 0,
			"flavor": flavor,
			"injured": [],
			"run_mode": "camp_skirmish",
			"battle_mode": "outpost",
			"zone_name": "巡哨 · %s" % str(c.get("name", camp_id)),
			"success": success,
			"cleared": success,
		},
	}


static func hud_camp_chip() -> String:
	var n: int = stationed_count()
	if not is_unlocked():
		return ""
	if n <= 0:
		return "駐·"
	return "駐%d" % n
