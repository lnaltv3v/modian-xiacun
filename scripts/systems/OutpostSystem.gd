extends RefCounted
class_name OutpostSystem
## 前哨防衛（v0.13）— 三波＋難度階＋多前哨外派駐守 stub

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
	var slots: int = int(c.get("slots", 2))
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
	## 被動涓滴＋週期小戰摘要；耗體／飽／少量銀維持
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
		## stamina / satiety drain while posted
		var stam_d: float = float(c.get("stamina_drain_per_min", 4.0)) / 60.0 * delta
		var sat_d: float = float(c.get("satiety_drain_per_min", 2.5)) / 60.0 * delta
		for hid in ids:
			HeroSystem.mutate(str(hid), func(hd: Dictionary) -> void:
				hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - stam_d)
				hd["satiety"] = maxf(0.0, float(hd.get("satiety", 100)) - sat_d)
				hd["status"] = "camped"
			)
		## upkeep silver each full second bucket via tick_accum minutes
		var upkeep_rate: float = float(c.get("upkeep_silver_per_min", 1.5)) * n / 60.0
		var silver_rate: float = float(c.get("trickle_silver_per_min", 10.0)) * power_m / 60.0
		var fur_rate: float = float(c.get("trickle_fur_per_min", 0.0)) * power_m / 60.0
		var iron_rate: float = float(c.get("trickle_iron_per_min", 0.0)) * power_m / 60.0
		## accumulate fractional gains in station bag
		var bag_s: float = float(st.get("bag_silver", 0.0)) + silver_rate * delta
		var bag_f: float = float(st.get("bag_fur", 0.0)) + fur_rate * delta
		var bag_i: float = float(st.get("bag_iron", 0.0)) + iron_rate * delta
		var bag_u: float = float(st.get("bag_upkeep", 0.0)) + upkeep_rate * delta
		var pay_u: int = int(floor(bag_u))
		if pay_u > 0:
			bag_u -= float(pay_u)
			var paid: int = mini(GameState.silver, pay_u)
			if paid > 0:
				GameState.try_spend(paid, 0)
				spent_upkeep += paid
			## if cannot pay full upkeep, extra stamina drain already applied; mark summary
			if paid < pay_u:
				st["last_summary"] = "糧餉不足，駐軍更疲"
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
		if ids.is_empty():
			lines.append("%s %s%s　空　槽%d　銀≈%.0f/分" % [
				mark, str(cd.get("name", cid)), lock_txt, int(cd.get("slots", 2)),
				float(cd.get("trickle_silver_per_min", 0.0))
			])
		else:
			var names: PackedStringArray = PackedStringArray()
			for hid_v in ids:
				names.append(str(HeroSystem.get_hero(str(hid_v)).get("name", hid_v)))
			lines.append("%s %s　駐：%s" % [mark, str(cd.get("name", cid)), "、".join(names)])
			lines.append("　累計銀%d 鐵%d 毛皮%d 小戰%d｜%s" % [
				int(st.get("total_silver", 0)), int(st.get("total_iron", 0)),
				int(st.get("total_fur", 0)), int(st.get("skirmishes", 0)),
				str(st.get("last_summary", ""))
			])
	lines.append("剔選在村俠 → 揀營地 →「駐守」；「召回」返村。駐守中唔可派遣／秘境／一波防衛。")
	return "\n".join(lines)


static func describe_pick_panel_full() -> String:
	## 難度選擇＋駐守摘要（前哨面板）
	return describe_pick_panel() + "\n\n" + describe_camps_panel()


static func stationed_count() -> int:
	return stationed_hero_ids("").size()


static func hud_camp_chip() -> String:
	var n: int = stationed_count()
	if not is_unlocked():
		return ""
	if n <= 0:
		return "駐·"
	return "駐%d" % n
