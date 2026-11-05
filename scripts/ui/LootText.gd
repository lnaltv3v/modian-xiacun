extends RefCounted
class_name LootText
## 戰後掉落／結算文案（野外、秘境、自動戰鬥共用）

const RES_FLAVOR := {
	"silver": ["碎銀", "官銀", "盤纏", "戰利銀兩"],
	"fur": ["毛皮", "獸皮", "皮貨", "獵獲之皮"],
	"wood": ["山木", "薪柴", "木材", "枯枝"],
	"iron": ["廢鐵", "鐵釘", "刀錆鐵片", "礦渣鐵"],
	"diamonds": ["墨晶", "紫鑽", "鑽石", "秘境晶石"],
	"fragments": ["英雄帖碎片", "殘帖", "碎帖", "帖角"],
}

const ENEMY_LOOT_HINT := {
	"wolf": "狼毫／獸牙散落",
	"boar": "野豬獠牙與厚皮",
	"bandit": "山賊腰包與鏽刃",
	"snake": "毒囊與蛻皮",
	"python": "巨蟒鱗片與膽",
	"wolf_king": "狼王鬃與牙",
	"bandit_chief": "頭目腰牌與贓銀",
}

static func format_summary(s: Dictionary) -> String:
	if s.has("text") and str(s.get("text", "")) != "":
		return str(s.get("text", ""))
	var lines: PackedStringArray = PackedStringArray()
	var flavor: String = str(s.get("flavor", ""))
	if flavor != "":
		lines.append(flavor)
	var loot_block: String = format_loot_block(s)
	if loot_block != "":
		lines.append(loot_block)
	var bounty: Dictionary = s.get("bounty_bonus", {}) as Dictionary
	if int(bounty.get("hits", 0)) > 0:
		lines.append("懸賞「%s」命中 ×%d（＋銀%d／皮%d／鐵%d）" % [
			str(bounty.get("target_name", "目標")),
			int(bounty.get("hits", 0)),
			int(bounty.get("silver", 0)),
			int(bounty.get("fur", 0)),
			int(bounty.get("iron", 0)),
		])
	var injured: Array = s.get("injured", []) as Array
	if injured.size() > 0:
		lines.append("受傷回村：%s（醫館可療）" % "、".join(PackedStringArray(injured)))
	elif bool(s.get("success", true)):
		lines.append("全員無大礙，腳步仍穩。")
	return "\n".join(lines)


static func format_loot_block(s: Dictionary) -> String:
	var silver: int = int(s.get("silver", 0))
	var fur: int = int(s.get("fur", 0))
	var wood: int = int(s.get("wood", 0))
	var iron: int = int(s.get("iron", 0))
	var diamonds: int = int(s.get("diamonds", 0))
	var fragments: int = int(s.get("fragments", 0))
	if silver <= 0 and fur <= 0 and wood <= 0 and iron <= 0 and diamonds <= 0 and fragments <= 0:
		return "戰利品：兩手空空……只帶回一身塵土。"
	var parts: PackedStringArray = PackedStringArray()
	if silver > 0:
		parts.append("%s ×%d" % [_pick_name("silver", s), silver])
	if fur > 0:
		parts.append("%s ×%d" % [_pick_name("fur", s), fur])
	if wood > 0:
		parts.append("%s ×%d" % [_pick_name("wood", s), wood])
	if iron > 0:
		parts.append("%s ×%d" % [_pick_name("iron", s), iron])
	if diamonds > 0:
		parts.append("%s ×%d" % [_pick_name("diamonds", s), diamonds])
	if fragments > 0:
		parts.append("%s ×%d" % [_pick_name("fragments", s), fragments])
	var head: String = "戰利品：" + "　".join(parts)
	var hint: String = _enemy_hint(s)
	if hint != "":
		head += "\n拾獲筆記：" + hint
	return head


static func _pick_name(key: String, s: Dictionary) -> String:
	var arr: Array = RES_FLAVOR.get(key, [key]) as Array
	if arr.is_empty():
		return key
	## 用資源量做穩定選字，避免每次刷新跳動
	var n: int = int(s.get(key, 0))
	return str(arr[n % arr.size()])


static func _enemy_hint(s: Dictionary) -> String:
	var enemies: Array = s.get("enemies", []) as Array
	if enemies.is_empty():
		return ""
	var bits: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}
	for ev in enemies:
		var kind: String = str((ev as Dictionary).get("kind", ""))
		if kind == "" or seen.has(kind):
			continue
		seen[kind] = true
		if ENEMY_LOOT_HINT.has(kind):
			bits.append(str(ENEMY_LOOT_HINT[kind]))
		else:
			var nm: String = str((ev as Dictionary).get("name", kind))
			bits.append("%s殘餘" % nm)
	return "；".join(bits)


static func format_run_result(s: Dictionary) -> String:
	## 秘境／前哨終盤：波次清單＋掉落＋解鎖提示（EHT 式清晰）
	var mode: String = str(s.get("run_mode", s.get("battle_mode", "")))
	var waves: Array = s.get("waves", []) as Array
	if waves.is_empty() and mode == "":
		return format_summary(s)
	var lines: PackedStringArray = PackedStringArray()
	var title: String = str(s.get("zone_name", s.get("run_title", "")))
	if title == "":
		title = "秘境" if mode == "dungeon" else ("前哨" if mode == "outpost" else "交戰")
	var cleared: bool = bool(s.get("cleared", s.get("success", false)))
	var wc: int = int(s.get("waves_cleared", 0))
	var wt: int = int(s.get("total_waves", 0))
	if wt <= 0:
		wt = waves.size() if waves.size() > 0 else maxi(wc, 1)
	var head: String = "【%s】%s　波次 %d／%d" % [
		title,
		("全破" if cleared else ("部分守住" if wc > 0 else "失利")),
		wc,
		wt,
	]
	lines.append(head)
	if waves.size() > 0:
		lines.append("—— 波次 ——")
		for wv in waves:
			var wd: Dictionary = wv as Dictionary
			var ok: bool = bool(wd.get("success", false))
			var mark: String = "✓" if ok else "✗"
			var boss: String = "★" if bool(wd.get("boss", false)) else "·"
			var lab: String = str(wd.get("label", "波次%d" % int(wd.get("index", 0))))
			var chance: float = float(wd.get("success_chance", 0))
			var detail: String = "%s %s %s" % [mark, boss, lab]
			if int(wd.get("party_power", 0)) > 0:
				detail += "　（黨%d vs 敵%d · %.0f%%）" % [
					int(wd.get("party_power", 0)),
					int(wd.get("enemy_power", 0)),
					chance * 100.0,
				]
			lines.append(detail)
	var flavor: String = str(s.get("flavor", ""))
	if flavor != "":
		lines.append(flavor)
	var loot: String = format_loot_block(s)
	if loot != "":
		lines.append(loot)
	var rare: Array = s.get("rare_items", []) as Array
	if rare.size() > 0:
		var rn: PackedStringArray = PackedStringArray()
		for it in rare:
			rn.append(str((it as Dictionary).get("name", "?")))
		lines.append("稀有拾獲：" + "、".join(rn))
	var injured: Array = s.get("injured", []) as Array
	if injured.size() > 0:
		lines.append("受傷回村：%s（開維護／醫館可療）" % "、".join(PackedStringArray(injured)))
	elif cleared:
		lines.append("全員無大礙。")
	var hints: String = format_unlock_hints(mode, s)
	if hints != "":
		lines.append("—— 解鎖／下一步 ——")
		lines.append(hints)
	return "\n".join(lines)


static func format_unlock_hints(mode: String, s: Dictionary) -> String:
	var tips: PackedStringArray = PackedStringArray()
	var cleared: bool = bool(s.get("cleared", s.get("success", false)))
	var wc: int = int(s.get("waves_cleared", 0))
	if mode == "dungeon":
		if not OutpostSystem.is_unlocked():
			var odef: Dictionary = OutpostSystem.def()
			tips.append("前哨未開：村長府 Lv.%d（而家%d）＋懸賞榜 Lv.%d（而家%d）" % [
				int(odef.get("unlock_manor_level", 2)),
				BuildingSystem.building_level("manor"),
				int(odef.get("unlock_bounty_level", 2)),
				BuildingSystem.building_level("bounty"),
			])
		if cleared:
			tips.append("秘境全破：戰利可入鐵匠／貨棧；練功場消化 XP")
		elif wc > 0:
			tips.append("未全破：食住醫補狀態、升級練功／懸賞再戰")
		else:
			tips.append("首波即挫：先養俠／興建客棧醫館再入秘境")
	elif mode == "outpost":
		if cleared:
			tips.append("前哨全勝：可繼續升級村長府擴大駐紮")
		elif wc > 0:
			tips.append("守住部分波次：加強黨力或升級懸賞榜再守")
		else:
			tips.append("首波潰：選高戰力在村俠、補飽食傷勢")
		if BuildingSystem.building_level("clinic") < 1:
			tips.append("未建醫館：負傷難癒，建議優先興建")
	## 通用
	if GameState.silver < 8 and BuildingSystem.building_level("inn") >= 1:
		tips.append("銀緊：食循環可能停，先出征／賣貨補銀")
	if GameState.wood < 4 and (BuildingSystem.building_level("inn") >= 1 or BuildingSystem.building_level("manor") >= 1):
		tips.append("木緊：住宿恢復可能停，伐木／野外補木")
	return "\n".join(tips)

