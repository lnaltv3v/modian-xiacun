extends RefCounted
class_name DungeonSystem
## 秘境入口 — 難度階／波次選擇＋最多 5 俠結算（末波狼王／山賊頭目示意）

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

static func difficulties() -> Array:
	ensure_loaded()
	var out: Array = []
	for d in _data.get("difficulties", []) as Array:
		out.append((d as Dictionary).duplicate(true))
	if out.is_empty():
		out.append({"id": "normal", "name": "普通", "power_mult": 1.0, "reward_mult": 1.0})
	return out

static func wave_sets() -> Array:
	ensure_loaded()
	var out: Array = []
	for w in _data.get("wave_sets", []) as Array:
		out.append((w as Dictionary).duplicate(true))
	if out.is_empty():
		out.append({"id": "full", "name": "三波全破", "max_waves": 3, "reward_mult": 1.0})
	return out

static func difficulty_by_id(diff_id: String) -> Dictionary:
	for d in difficulties():
		var dd: Dictionary = d as Dictionary
		if str(dd.get("id", "")) == diff_id:
			return dd
	var arr: Array = difficulties()
	return (arr[0] as Dictionary).duplicate(true) if arr.size() > 0 else {}

static func wave_set_by_id(ws_id: String) -> Dictionary:
	for w in wave_sets():
		var wd: Dictionary = w as Dictionary
		if str(wd.get("id", "")) == ws_id:
			return wd
	var arr: Array = wave_sets()
	return (arr[0] as Dictionary).duplicate(true) if arr.size() > 0 else {}

static func clears_of(diff_id: String) -> int:
	return int(GameState.dungeon_diff_clears.get(diff_id, 0))

static func is_difficulty_unlocked(diff_id: String) -> bool:
	var d: Dictionary = difficulty_by_id(diff_id)
	if d.is_empty():
		return false
	var need_of: String = str(d.get("unlock_clears_of", ""))
	if need_of.is_empty():
		return true
	var need_n: int = int(d.get("unlock_clears_need", 1))
	return clears_of(need_of) >= need_n

static func record_clear(diff_id: String) -> void:
	var n: int = clears_of(diff_id) + 1
	GameState.dungeon_diff_clears[diff_id] = n

static func can_enter(hero_ids: Array, diff_id: String = "", wave_set_id: String = "") -> Dictionary:
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
	var did: String = diff_id if diff_id != "" else str(GameState.dungeon_pick_diff)
	var wid: String = wave_set_id if wave_set_id != "" else str(GameState.dungeon_pick_waves)
	if difficulty_by_id(did).is_empty():
		return {"ok": false, "reason": "未知難度"}
	if not is_difficulty_unlocked(did):
		var dd: Dictionary = difficulty_by_id(did)
		return {"ok": false, "reason": "難度「%s」未解鎖（先全破「%s」）" % [
			str(dd.get("name", did)), str(difficulty_by_id(str(dd.get("unlock_clears_of", ""))).get("name", ""))
		]}
	if wave_set_by_id(wid).is_empty():
		return {"ok": false, "reason": "未知波次組"}
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

static func run_dungeon(hero_ids: Array, diff_id: String = "", wave_set_id: String = "") -> Dictionary:
	## 同步結算選定波次；UI 再逐步演出
	var did: String = diff_id if diff_id != "" else str(GameState.dungeon_pick_diff)
	var wid: String = wave_set_id if wave_set_id != "" else str(GameState.dungeon_pick_waves)
	if did == "":
		did = str(_data.get("default_difficulty", "normal"))
	if wid == "":
		wid = str(_data.get("default_wave_set", "full"))
	var check: Dictionary = can_enter(hero_ids, did, wid)
	if not bool(check.get("ok", false)):
		return {"ok": false, "reason": str(check.get("reason", "")), "waves": [], "rewards": {}}

	ensure_loaded()
	var diff: Dictionary = difficulty_by_id(did)
	var wset: Dictionary = wave_set_by_id(wid)
	var power_mult: float = float(diff.get("power_mult", 1.0))
	var reward_mult: float = float(diff.get("reward_mult", 1.0)) * float(wset.get("reward_mult", 1.0))
	var stamina_mult: float = float(diff.get("stamina_mult", 1.0))
	var injury_mult: float = float(diff.get("injury_mult", 1.0))
	var max_waves: int = int(wset.get("max_waves", 3))

	var ids: Array = []
	for hid_v in hero_ids:
		ids.append(str(hid_v))

	for hid in ids:
		HeroSystem.set_status(str(hid), "dungeon")

	var party_power: int = _party_power(ids)
	var success_bonus: float = _party_success_bonus(ids)
	var waves_out: Array = []
	var cleared_all: bool = true
	var wave_defs_all: Array = _data.get("waves", []) as Array
	var wave_defs: Array = []
	for i in range(mini(max_waves, wave_defs_all.size())):
		wave_defs.append(wave_defs_all[i])

	for wv in wave_defs:
		var wd: Dictionary = wv as Dictionary
		var enemy_power: int = int(round(float(wd.get("enemy_power", 20)) * power_mult))
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

	var stamina_cost: float = float(_data.get("stamina_cost", 28)) * stamina_mult * (0.55 + 0.15 * float(waves_out.size()))
	var satiety_cost: float = float(_data.get("satiety_cost", 18)) * (0.55 + 0.15 * float(waves_out.size()))
	var injury_chance: float = float(_data.get("injury_chance", 0.22)) * injury_mult
	var injury_amount: float = float(_data.get("injury_amount", 10)) * injury_mult
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

	var table: Dictionary = {}
	var rt: Variant = _data.get("reward_table", {})
	if typeof(rt) == TYPE_DICTIONARY:
		table = (rt as Dictionary).duplicate(true)
	var base: Dictionary = table.get("base", {}) as Dictionary
	var silver_gain: int = int(base.get("silver", _data.get("base_silver", 40)))
	var fur_gain: int = int(base.get("fur", _data.get("base_fur", 4)))
	var wood_gain: int = int(base.get("wood", _data.get("base_wood", 2)))
	var iron_gain: int = int(base.get("iron", _data.get("base_iron", 1)))
	var waves_cleared: int = 0
	var boss_ok: bool = false
	for wvo in waves_out:
		var wd_out: Dictionary = wvo as Dictionary
		if bool(wd_out.get("success", false)):
			waves_cleared += 1
			if bool(wd_out.get("boss", false)):
				boss_ok = true
	var floor_s: float = float((table.get("wave_floor", {}) as Dictionary).get("silver", 0.4))
	var floor_f: float = float((table.get("wave_floor", {}) as Dictionary).get("fur", 0.5))
	var mult_s: float = float((table.get("per_wave_mult", {}) as Dictionary).get("silver", 0.2))
	var mult_f: float = float((table.get("per_wave_mult", {}) as Dictionary).get("fur", 0.2))
	silver_gain = int(round(float(silver_gain) * (floor_s + mult_s * float(waves_cleared))))
	fur_gain = int(round(float(fur_gain) * (floor_f + mult_f * float(waves_cleared))))
	## 血氣被動銀獎
	var silver_mult: float = 1.0
	for hid3 in ids:
		silver_mult += AcademySystem.passive_silver_bonus(HeroSystem.get_hero(str(hid3)))
	silver_gain = int(round(float(silver_gain) * silver_mult))

	var diamond_gain: int = 0
	var frag_gain: int = 0
	var rare_items: Array = []
	## 全破＝打完選定波次組全部成功；通關大獎只喺 full 波組
	var is_full_set: bool = max_waves >= wave_defs_all.size() and wave_defs_all.size() > 0

	if cleared_all:
		if is_full_set:
			var clear_b: Dictionary = table.get("clear_bonus", {}) as Dictionary
			silver_gain += int(clear_b.get("silver", _data.get("clear_bonus_silver", 30)))
			iron_gain += int(clear_b.get("iron", _data.get("clear_bonus_iron", 2)))
			frag_gain += _roll_range(clear_b.get("fragments", [0, 0]))
			diamond_gain += _roll_chance_amount(clear_b)
		else:
			## 短波組：少量碎片安慰獎
			frag_gain += maxi(0, int(round(4.0 * float(waves_cleared) * reward_mult)))
		for hid_x in ids:
			HeroSystem.mutate(str(hid_x), func(hd: Dictionary) -> void:
				var add_xp: float = (12.0 + float(waves_cleared) * 4.0) + float(BuildingSystem.building_level("training")) * 3.0
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
		var fail_m: Dictionary = table.get("fail_mult", {}) as Dictionary
		silver_gain = maxi(0, int(round(float(silver_gain) * float(fail_m.get("silver", 0.35)))))
		fur_gain = maxi(0, int(round(float(fur_gain) * float(fail_m.get("fur", 0.3)))))
		wood_gain = maxi(0, int(round(float(wood_gain) * float(fail_m.get("wood", 0.3)))))
		iron_gain = maxi(0, int(round(float(iron_gain) * float(fail_m.get("iron", 0.2)))))

	if boss_ok:
		var boss_b: Dictionary = table.get("boss_bonus", {}) as Dictionary
		silver_gain += int(boss_b.get("silver", 0))
		frag_gain += _roll_range(boss_b.get("fragments", [0, 0]))
		diamond_gain += _roll_chance_amount(boss_b)

	## 難度／波組倍率
	silver_gain = maxi(0, int(round(float(silver_gain) * reward_mult)))
	fur_gain = maxi(0, int(round(float(fur_gain) * reward_mult)))
	wood_gain = maxi(0, int(round(float(wood_gain) * reward_mult)))
	iron_gain = maxi(0, int(round(float(iron_gain) * reward_mult)))
	frag_gain = maxi(0, int(round(float(frag_gain) * reward_mult)))
	## 鑽石至少按倍率機率感：整數四捨五入
	diamond_gain = maxi(0, int(round(float(diamond_gain) * maxf(1.0, reward_mult * 0.85))))
	## 書院經世：秘藏錄等全村秘境獎
	var dungeon_loot: float = 1.0 + AcademySystem.village_effect_add("dungeon_loot_bonus", 0.0)
	var dungeon_frag: float = 1.0 + AcademySystem.village_effect_add("dungeon_frag_bonus", 0.0)
	silver_gain = maxi(0, int(round(float(silver_gain) * dungeon_loot)))
	fur_gain = maxi(0, int(round(float(fur_gain) * dungeon_loot)))
	wood_gain = maxi(0, int(round(float(wood_gain) * dungeon_loot)))
	iron_gain = maxi(0, int(round(float(iron_gain) * dungeon_loot)))
	frag_gain = maxi(0, int(round(float(frag_gain) * dungeon_frag)))

	## rare drops → inventory（短波組降低機會）
	var rare_chance_scale: float = 1.0 if is_full_set else 0.35
	for rv in table.get("rare_drops", []) as Array:
		var rd: Dictionary = rv as Dictionary
		if bool(rd.get("require_clear", false)) and not cleared_all:
			continue
		if bool(rd.get("require_boss", false)) and not boss_ok:
			continue
		if _rng.randf() <= float(rd.get("chance", 0)) * rare_chance_scale * minf(1.35, reward_mult):
			var item: Dictionary = {
				"id": "%s_%d" % [str(rd.get("id", "rare")), Time.get_ticks_msec()],
				"name": str(rd.get("name", "秘境遺物")),
				"kind": str(rd.get("kind", "material")),
				"source": "dungeon",
			}
			GameState.add_inventory_item(item)
			rare_items.append(item.duplicate(true))

	GameState.add_silver(silver_gain)
	GameState.add_fur(fur_gain)
	if wood_gain > 0:
		GameState.add_wood(wood_gain)
	if iron_gain > 0:
		GameState.add_iron(iron_gain)
	if frag_gain > 0:
		GameState.add_fragments(frag_gain)
	if diamond_gain > 0:
		GameState.add_diamonds(diamond_gain)

	if cleared_all and is_full_set:
		record_clear(did)

	var diff_name: String = str(diff.get("name", did))
	var wset_name: String = str(wset.get("name", wid))
	var flavor: String
	if cleared_all:
		if is_full_set:
			flavor = "秘境「%s／%s」三波盡破！狼王示意已退。" % [diff_name, wset_name]
		else:
			flavor = "秘境「%s／%s」選定波次全勝。" % [diff_name, wset_name]
	else:
		flavor = "秘境「%s／%s」第 %d 波失手，狼狽撤出。" % [diff_name, wset_name, maxi(1, waves_cleared + 1)]
	if diamond_gain > 0 or frag_gain > 0:
		flavor += "（鑽＋%d／碎片＋%d）" % [diamond_gain, frag_gain]
	if rare_items.size() > 0:
		var rn: PackedStringArray = PackedStringArray()
		for it in rare_items:
			rn.append(str((it as Dictionary).get("name", "?")))
		flavor += " 拾獲：%s" % "、".join(rn)

	var rewards: Dictionary = {
		"silver": silver_gain,
		"fur": fur_gain,
		"wood": wood_gain,
		"iron": iron_gain,
		"diamonds": diamond_gain,
		"fragments": frag_gain,
		"rare_items": rare_items,
		"heroes": ids.duplicate(),
		"zone_name": str(_data.get("name", "秘境")),
		"injured": injured_names,
		"cleared": cleared_all,
		"waves_cleared": waves_cleared,
		"boss_ok": boss_ok,
		"flavor": flavor,
		"enemies": _collect_enemies(waves_out),
		"success": cleared_all,
		"difficulty_id": did,
		"difficulty_name": diff_name,
		"wave_set_id": wid,
		"wave_set_name": wset_name,
		"total_waves": wave_defs.size(),
	}
	GameState.push_report("秘境「%s·%s·%s」%s 波%d／%d ＋銀%d 皮%d 鐵%d 鑽%d 碎%d" % [
		str(_data.get("name", "秘境")),
		diff_name,
		wset_name,
		("通關" if cleared_all else "中挫"),
		waves_cleared,
		wave_defs.size(),
		silver_gain,
		fur_gain,
		iron_gain,
		diamond_gain,
		frag_gain,
	])
	return {
		"ok": true,
		"reason": "",
		"waves": waves_out,
		"rewards": rewards,
		"dungeon_name": str(_data.get("name", "秘境")),
		"cleared": cleared_all,
		"difficulty_id": did,
		"difficulty_name": diff_name,
		"wave_set_id": wid,
		"wave_set_name": wset_name,
		"total_waves": wave_defs.size(),
	}

static func describe_pick_panel() -> String:
	ensure_loaded()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("【亂山秘境 · 入場選擇】")
	lines.append("難度影響敵力／獎／耗體；波次組決定打幾波。")
	var did: String = str(GameState.dungeon_pick_diff)
	var wid: String = str(GameState.dungeon_pick_waves)
	var diff: Dictionary = difficulty_by_id(did)
	var wset: Dictionary = wave_set_by_id(wid)
	lines.append("而家：%s　／　%s" % [str(diff.get("name", did)), str(wset.get("name", wid))])
	lines.append("敵力×%.2f　獎×%.2f" % [
		float(diff.get("power_mult", 1.0)),
		float(diff.get("reward_mult", 1.0)) * float(wset.get("reward_mult", 1.0)),
	])
	for d in difficulties():
		var dd: Dictionary = d as Dictionary
		var idd: String = str(dd.get("id", ""))
		var lock: String = "" if is_difficulty_unlocked(idd) else "（鎖）"
		var mark: String = "●" if idd == did else "○"
		lines.append("%s 難度 %s%s　全破%d" % [mark, str(dd.get("name", idd)), lock, clears_of(idd)])
	for w in wave_sets():
		var ww: Dictionary = w as Dictionary
		var iid: String = str(ww.get("id", ""))
		var mark2: String = "●" if iid == wid else "○"
		lines.append("%s 波組 %s（%d波）" % [mark2, str(ww.get("name", iid)), int(ww.get("max_waves", 1))])
	lines.append("剔選俠客後撳「入秘境」出發。")
	return "\n".join(lines)

static func _roll_range(spec: Variant) -> int:
	if typeof(spec) == TYPE_ARRAY:
		var arr: Array = spec as Array
		if arr.is_empty():
			return 0
		if arr.size() == 1:
			return int(arr[0])
		var a: int = int(arr[0])
		var b: int = int(arr[1])
		if a > b:
			var t: int = a
			a = b
			b = t
		return _rng.randi_range(a, b)
	return int(spec)

static func _roll_chance_amount(bonus: Dictionary) -> int:
	var chance: float = float(bonus.get("diamond_chance", 0))
	if chance <= 0.0:
		return 0
	if _rng.randf() > chance:
		return 0
	return _roll_range(bonus.get("diamond_amount", [1, 1]))

static func _collect_enemies(waves_out: Array) -> Array:
	var out: Array = []
	for wvo in waves_out:
		for ev in (wvo as Dictionary).get("enemies", []) as Array:
			out.append((ev as Dictionary).duplicate(true))
	return out
