extends RefCounted
class_name AcademySystem
## 師門書院 — 被動槽＋武學／經世技能樹（碎片解鎖／預覽／全村）

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
	_ensure_starter_unlocks()

static func reload() -> void:
	## 測試／熱更用
	_loaded = false
	ensure_loaded()

static func _tree() -> Dictionary:
	ensure_loaded()
	var t: Variant = _data.get("skill_tree", {})
	if typeof(t) == TYPE_DICTIONARY:
		return t as Dictionary
	return {}

static func _ensure_starter_unlocks() -> void:
	var tree: Dictionary = _tree()
	for sid in tree.get("starter_unlocks", []) as Array:
		var nid: String = str(sid)
		if nid != "" and not is_node_unlocked(nid):
			GameState.academy_unlocked_nodes.append(nid)

static func academy_ready() -> bool:
	ensure_loaded()
	_ensure_starter_unlocks()
	var bid: String = str(_data.get("require_building", "academy"))
	var need: int = int(_data.get("require_level", 1))
	return BuildingSystem.building_level(bid) >= need

static func branches() -> Array:
	ensure_loaded()
	var out: Array = []
	for b in _tree().get("branches", []) as Array:
		out.append((b as Dictionary).duplicate(true))
	return out

static func branch_name(branch_id: String) -> String:
	for b in branches():
		var bd: Dictionary = b as Dictionary
		if str(bd.get("id", "")) == branch_id:
			return str(bd.get("name", branch_id))
	return branch_id

static func passive_slots_unlocked() -> int:
	if not academy_ready():
		return 0
	ensure_loaded()
	var base: int = int(_data.get("passive_slots", 1))
	var bonus: int = int(round(village_effect_add("passive_slots_bonus", 0.0)))
	return maxi(1, base + bonus)

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

static func tree_nodes() -> Array:
	ensure_loaded()
	var out: Array = []
	for n in _tree().get("nodes", []) as Array:
		out.append((n as Dictionary).duplicate(true))
	return out

static func tree_nodes_sorted() -> Array:
	## row→col 排序，方便 UI 佈局
	var nodes: Array = tree_nodes()
	nodes.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da: Dictionary = a as Dictionary
		var db: Dictionary = b as Dictionary
		var ra: int = int(da.get("row", 0))
		var rb: int = int(db.get("row", 0))
		if ra != rb:
			return ra < rb
		return int(da.get("col", 0)) < int(db.get("col", 0))
	)
	return nodes

static func node_by_id(node_id: String) -> Dictionary:
	for n in tree_nodes():
		var nd: Dictionary = n as Dictionary
		if str(nd.get("id", "")) == node_id:
			return nd
	return {}

static func is_node_unlocked(node_id: String) -> bool:
	for x in GameState.academy_unlocked_nodes:
		if str(x) == node_id:
			return true
	return false

static func is_skill_unlocked(skill_id: String) -> bool:
	if skill_id.is_empty():
		return false
	for n in tree_nodes():
		var nd: Dictionary = n as Dictionary
		if str(nd.get("skill_id", "")) == skill_id and is_node_unlocked(str(nd.get("id", ""))):
			return true
	## 無樹資料時：全部技能可用（兼容舊）
	if tree_nodes().is_empty():
		return not skill_by_id(skill_id).is_empty()
	return false

static func unlocked_assignable_skills() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for n in tree_nodes():
		var nd: Dictionary = n as Dictionary
		var sid: String = str(nd.get("skill_id", ""))
		if sid.is_empty() or seen.has(sid):
			continue
		if is_node_unlocked(str(nd.get("id", ""))):
			var sk: Dictionary = skill_by_id(sid)
			if not sk.is_empty():
				out.append(sk)
				seen[sid] = true
	if out.is_empty() and tree_nodes().is_empty():
		return all_skills()
	return out

static func can_unlock_node(node_id: String) -> Dictionary:
	if not academy_ready():
		return {"ok": false, "reason": "師門書院未啟用"}
	var nd: Dictionary = node_by_id(node_id)
	if nd.is_empty():
		return {"ok": false, "reason": "未知節點"}
	if is_node_unlocked(node_id):
		return {"ok": false, "reason": "已解鎖"}
	for req in nd.get("requires", []) as Array:
		if not is_node_unlocked(str(req)):
			var rn: Dictionary = node_by_id(str(req))
			return {"ok": false, "reason": "需先解鎖「%s」" % str(rn.get("name", req))}
	var cost: int = int(nd.get("cost", 0))
	var cur: String = str(_tree().get("currency", "fragments"))
	if cur == "fragments" and GameState.fragments < cost:
		return {"ok": false, "reason": "碎片不足（要%d／有%d）" % [cost, GameState.fragments]}
	if cur == "silver" and GameState.silver < cost:
		return {"ok": false, "reason": "銀兩不足"}
	return {"ok": true, "reason": "", "cost": cost, "currency": cur}

static func unlock_node(node_id: String) -> Dictionary:
	var check: Dictionary = can_unlock_node(node_id)
	if not bool(check.get("ok", false)):
		return {"ok": false, "reason": str(check.get("reason", ""))}
	var nd: Dictionary = node_by_id(node_id)
	var cost: int = int(nd.get("cost", 0))
	var cur: String = str(check.get("currency", "fragments"))
	if cost > 0:
		if cur == "fragments":
			if not GameState.try_spend_fragments(cost):
				return {"ok": false, "reason": "碎片不足"}
		elif cur == "silver":
			if not GameState.try_spend(cost):
				return {"ok": false, "reason": "銀兩不足"}
	GameState.academy_unlocked_nodes.append(node_id)
	GameState.push_report("書院樹：解鎖「%s」" % str(nd.get("name", node_id)))
	return {"ok": true, "reason": "", "node": nd.duplicate(true)}

static func preview_node(node_id: String) -> String:
	var nd: Dictionary = node_by_id(node_id)
	if nd.is_empty():
		return "（無此節點）"
	var lines: PackedStringArray = PackedStringArray()
	var br: String = branch_name(str(nd.get("branch", "")))
	var br_tag: String = ("〔%s〕" % br) if br != "" else ""
	lines.append("【%s】%s%s" % [
		str(nd.get("name", node_id)),
		br_tag,
		("已解鎖" if is_node_unlocked(node_id) else "未解鎖"),
	])
	var desc: String = str(nd.get("desc", ""))
	if desc != "":
		lines.append(desc)
	var sid: String = str(nd.get("skill_id", ""))
	if sid != "":
		var sk: Dictionary = skill_by_id(sid)
		if not sk.is_empty():
			lines.append("被動：%s — %s" % [str(sk.get("name", sid)), str(sk.get("desc", ""))])
			lines.append(_format_skill_stats(sk))
	var village: Variant = nd.get("village", {})
	if typeof(village) == TYPE_DICTIONARY and not (village as Dictionary).is_empty():
		lines.append("全村：" + _format_village_effects(village as Dictionary))
	var reqs: Array = nd.get("requires", []) as Array
	if reqs.size() > 0:
		var rnames: PackedStringArray = PackedStringArray()
		for r in reqs:
			var rn2: Dictionary = node_by_id(str(r))
			var mark: String = "✓" if is_node_unlocked(str(r)) else "·"
			rnames.append("%s%s" % [mark, str(rn2.get("name", r))])
		lines.append("前置：%s" % "、".join(rnames))
	var cost: int = int(nd.get("cost", 0))
	var afford: String = ""
	if not is_node_unlocked(node_id):
		var cur: String = str(_tree().get("currency", "fragments"))
		var have: int = GameState.fragments if cur == "fragments" else GameState.silver
		afford = "　（有%d／%s）" % [have, ("夠" if have >= cost else "不足")]
	lines.append("消耗：%d %s%s" % [cost, str(_tree().get("currency_name", "碎片")), afford])
	var chk: Dictionary = can_unlock_node(node_id)
	if not is_node_unlocked(node_id) and not bool(chk.get("ok", false)):
		lines.append("狀態：%s" % str(chk.get("reason", "")))
	elif not is_node_unlocked(node_id):
		lines.append("狀態：可解鎖")
	return "\n".join(lines)

static func _format_skill_stats(sk: Dictionary) -> String:
	var bits: PackedStringArray = PackedStringArray()
	if int(sk.get("power_bonus", 0)) != 0:
		bits.append("戰力＋%d" % int(sk.get("power_bonus", 0)))
	if int(sk.get("atk_bonus", 0)) != 0:
		bits.append("攻意＋%d" % int(sk.get("atk_bonus", 0)))
	if int(sk.get("def_bonus", 0)) != 0:
		bits.append("守勢＋%d" % int(sk.get("def_bonus", 0)))
	if float(sk.get("injury_resist", 0)) > 0.0:
		bits.append("傷抗%.0f%%" % (float(sk.get("injury_resist", 0)) * 100.0))
	if float(sk.get("stamina_discount", 0)) > 0.0:
		bits.append("體力減耗%.0f%%" % (float(sk.get("stamina_discount", 0)) * 100.0))
	if float(sk.get("success_bonus", 0)) > 0.0:
		bits.append("成功率＋%.0f%%" % (float(sk.get("success_bonus", 0)) * 100.0))
	if float(sk.get("silver_bonus", 0)) > 0.0:
		bits.append("銀獎＋%.0f%%" % (float(sk.get("silver_bonus", 0)) * 100.0))
	if float(sk.get("crit_chance", 0)) > 0.0:
		bits.append("暴擊＋%.0f%%" % (float(sk.get("crit_chance", 0)) * 100.0))
	if float(sk.get("parry_chance", 0)) > 0.0:
		bits.append("招架＋%.0f%%" % (float(sk.get("parry_chance", 0)) * 100.0))
	return "效果：" + ("、".join(bits) if bits.size() > 0 else "—")

static func _format_village_effects(v: Dictionary) -> String:
	var bits: PackedStringArray = PackedStringArray()
	if v.has("upkeep_silver_mult"):
		var m: float = float(v.get("upkeep_silver_mult", 1.0))
		bits.append("日耗銀×%.2f（約%+.0f%%）" % [m, (m - 1.0) * 100.0])
	if v.has("hunt_silver_bonus"):
		bits.append("出征銀＋%.0f%%" % (float(v.get("hunt_silver_bonus", 0)) * 100.0))
	if v.has("hunt_fur_bonus"):
		bits.append("出征毛皮＋%.0f%%" % (float(v.get("hunt_fur_bonus", 0)) * 100.0))
	if v.has("hunt_iron_bonus"):
		bits.append("出征鐵＋%.0f%%" % (float(v.get("hunt_iron_bonus", 0)) * 100.0))
	if v.has("dungeon_loot_bonus"):
		bits.append("秘境銀＋%.0f%%" % (float(v.get("dungeon_loot_bonus", 0)) * 100.0))
	if v.has("dungeon_frag_bonus"):
		bits.append("秘境碎片＋%.0f%%" % (float(v.get("dungeon_frag_bonus", 0)) * 100.0))
	if v.has("camp_silver_bonus"):
		bits.append("駐守銀＋%.0f%%" % (float(v.get("camp_silver_bonus", 0)) * 100.0))
	if v.has("camp_upkeep_mult"):
		var cm: float = float(v.get("camp_upkeep_mult", 1.0))
		bits.append("營帳耗×%.2f" % cm)
	if v.has("outpost_silver_bonus"):
		bits.append("前哨銀＋%.0f%%" % (float(v.get("outpost_silver_bonus", 0)) * 100.0))
	if v.has("party_crit_bonus"):
		bits.append("全村暴擊＋%.0f%%" % (float(v.get("party_crit_bonus", 0)) * 100.0))
	if v.has("party_parry_bonus"):
		bits.append("全村招架＋%.0f%%" % (float(v.get("party_parry_bonus", 0)) * 100.0))
	if v.has("passive_slots_bonus"):
		bits.append("被動槽＋%d" % int(round(float(v.get("passive_slots_bonus", 0)))))
	return "、".join(bits) if bits.size() > 0 else "—"

static func village_effect_mult(key: String, default_val: float = 1.0) -> float:
	## 乘性效果：多節點相乘
	ensure_loaded()
	var m: float = 1.0
	var found: bool = false
	for n in tree_nodes():
		var nd: Dictionary = n as Dictionary
		if not is_node_unlocked(str(nd.get("id", ""))):
			continue
		var village: Variant = nd.get("village", {})
		if typeof(village) != TYPE_DICTIONARY:
			continue
		var vd: Dictionary = village as Dictionary
		if vd.has(key):
			m *= float(vd.get(key, 1.0))
			found = true
	return m if found else default_val

static func village_effect_add(key: String, default_val: float = 0.0) -> float:
	## 加性效果：多節點相加
	ensure_loaded()
	var s: float = 0.0
	var found: bool = false
	for n in tree_nodes():
		var nd: Dictionary = n as Dictionary
		if not is_node_unlocked(str(nd.get("id", ""))):
			continue
		var village: Variant = nd.get("village", {})
		if typeof(village) != TYPE_DICTIONARY:
			continue
		var vd: Dictionary = village as Dictionary
		if vd.has(key):
			s += float(vd.get(key, 0.0))
			found = true
	return s if found else default_val

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
	if not is_skill_unlocked(skill_id):
		return {"ok": false, "reason": "技能樹未解鎖此被動"}
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

static func rotate_passive(hero_id: String) -> Dictionary:
	## 喺已解鎖被動之間輪換（兼容舊一鍵行為）
	var skills: Array = unlocked_assignable_skills()
	if skills.is_empty():
		return {"ok": false, "reason": "未解鎖任何可授被動"}
	var cur: String = str(HeroSystem.get_hero(hero_id).get("passive_id", ""))
	var idx: int = 0
	for i in range(skills.size()):
		if str((skills[i] as Dictionary).get("id", "")) == cur:
			idx = (i + 1) % skills.size()
			break
	var sk: Dictionary = skills[idx] as Dictionary
	return assign_passive(hero_id, str(sk.get("id", "")))

static func describe_panel(hero_id: String = "") -> String:
	ensure_loaded()
	_ensure_starter_unlocks()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("【師門書院 · 武學／經世】")
	lines.append("碎片：%d　被動槽：%d　（解鎖後授徒／全村生效）" % [
		GameState.fragments, passive_slots_unlocked()
	])
	if hero_id != "":
		var h: Dictionary = HeroSystem.get_hero(hero_id)
		var pas: String = str(h.get("passive_name", ""))
		lines.append("選中俠：%s　而家被動：%s" % [
			str(h.get("name", hero_id)),
			(pas if pas != "" else "無"),
		])
	else:
		lines.append("提示：剔選一名俠客後可「授／輪換」已解鎖被動。")
	var unlocked_n: int = 0
	for n0 in tree_nodes():
		if is_node_unlocked(str((n0 as Dictionary).get("id", ""))):
			unlocked_n += 1
	lines.append("進度：%d／%d 節點" % [unlocked_n, tree_nodes().size()])
	for br in branches():
		var bd: Dictionary = br as Dictionary
		var bid: String = str(bd.get("id", ""))
		var bcount: int = 0
		var bunlock: int = 0
		for n1 in tree_nodes():
			var nd1: Dictionary = n1 as Dictionary
			if str(nd1.get("branch", "")) != bid:
				continue
			bcount += 1
			if is_node_unlocked(str(nd1.get("id", ""))):
				bunlock += 1
		lines.append("· %s %d／%d — %s" % [
			str(bd.get("name", bid)), bunlock, bcount, str(bd.get("desc", ""))
		])
	var um: float = village_effect_mult("upkeep_silver_mult", 1.0)
	var hb: float = village_effect_add("hunt_silver_bonus", 0.0)
	var dl: float = village_effect_add("dungeon_loot_bonus", 0.0)
	var cs: float = village_effect_add("camp_silver_bonus", 0.0)
	var os: float = village_effect_add("outpost_silver_bonus", 0.0)
	var pc: float = village_effect_add("party_crit_bonus", 0.0)
	var pp: float = village_effect_add("party_parry_bonus", 0.0)
	if um < 0.999 or hb > 0.001 or dl > 0.001 or cs > 0.001 or os > 0.001 or pc > 0.001 or pp > 0.001:
		lines.append("—— 生效中 ——")
		if um < 0.999:
			lines.append("日耗銀×%.2f" % um)
		if hb > 0.001:
			lines.append("出征銀＋%.0f%%" % (hb * 100.0))
		if dl > 0.001:
			lines.append("秘境銀＋%.0f%%" % (dl * 100.0))
		if cs > 0.001:
			lines.append("駐守銀＋%.0f%%" % (cs * 100.0))
		if os > 0.001:
			lines.append("前哨銀＋%.0f%%" % (os * 100.0))
		if pc > 0.001:
			lines.append("全村暴擊＋%.0f%%" % (pc * 100.0))
		if pp > 0.001:
			lines.append("全村招架＋%.0f%%" % (pp * 100.0))
	return "\n".join(lines)

static func _passive_dict(hero: Dictionary) -> Dictionary:
	var pid: String = str(hero.get("passive_id", ""))
	if pid.is_empty():
		return {}
	return skill_by_id(pid)

static func passive_power_bonus(hero: Dictionary) -> int:
	var sk: Dictionary = _passive_dict(hero)
	return int(sk.get("power_bonus", 0)) + int(sk.get("atk_bonus", 0))

static func passive_def_bonus(hero: Dictionary) -> int:
	return int(_passive_dict(hero).get("def_bonus", 0))

static func passive_injury_resist(hero: Dictionary) -> float:
	return float(_passive_dict(hero).get("injury_resist", 0.0))

static func passive_stamina_discount(hero: Dictionary) -> float:
	return float(_passive_dict(hero).get("stamina_discount", 0.0))

static func passive_success_bonus(hero: Dictionary) -> float:
	return float(_passive_dict(hero).get("success_bonus", 0.0))

static func passive_silver_bonus(hero: Dictionary) -> float:
	return float(_passive_dict(hero).get("silver_bonus", 0.0))

static func passive_crit_chance(hero: Dictionary) -> float:
	return float(_passive_dict(hero).get("crit_chance", 0.0))

static func passive_parry_chance(hero: Dictionary) -> float:
	return float(_passive_dict(hero).get("parry_chance", 0.0))

static func party_crit_chance(hero_ids: Array = []) -> float:
	## 基礎 12% + 全村 + 隊伍被動平均
	var base: float = 0.12
	base += village_effect_add("party_crit_bonus", 0.0)
	var ids: Array = hero_ids
	if ids.is_empty():
		return clampf(base, 0.0, 0.55)
	var sum: float = 0.0
	var n: int = 0
	for hid_v in ids:
		var h: Dictionary = HeroSystem.get_hero(str(hid_v))
		if h.is_empty():
			continue
		sum += passive_crit_chance(h)
		n += 1
	if n > 0:
		base += sum / float(n)
	return clampf(base, 0.0, 0.55)

static func party_parry_chance(hero_ids: Array = []) -> float:
	## 基礎 20% + 全村 + 隊伍被動平均
	var base: float = 0.20
	base += village_effect_add("party_parry_bonus", 0.0)
	var ids: Array = hero_ids
	if ids.is_empty():
		return clampf(base, 0.0, 0.60)
	var sum: float = 0.0
	var n: int = 0
	for hid_v in ids:
		var h: Dictionary = HeroSystem.get_hero(str(hid_v))
		if h.is_empty():
			continue
		sum += passive_parry_chance(h)
		n += 1
	if n > 0:
		base += sum / float(n)
	return clampf(base, 0.0, 0.60)

static func unlocked_node_count() -> int:
	var n: int = 0
	for x in GameState.academy_unlocked_nodes:
		if not str(x).is_empty():
			n += 1
	return n
