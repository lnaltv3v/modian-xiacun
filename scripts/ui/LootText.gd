extends RefCounted
class_name LootText
## 戰後掉落／結算文案（野外、秘境、自動戰鬥共用）

const RES_FLAVOR := {
	"silver": ["碎銀", "官銀", "盤纏", "戰利銀兩"],
	"fur": ["毛皮", "獸皮", "皮貨", "獵獲之皮"],
	"wood": ["山木", "薪柴", "木材", "枯枝"],
	"iron": ["廢鐵", "鐵釘", "刀錆鐵片", "礦渣鐵"],
}

const ENEMY_LOOT_HINT := {
	"wolf": "狼毫／獸牙散落",
	"boar": "野豬獠牙與厚皮",
	"bandit": "山賊腰包與鏽刃",
	"snake": "毒囊與蛻皮",
	"python": "巨蟒鱗片與膽",
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
	if silver <= 0 and fur <= 0 and wood <= 0 and iron <= 0:
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
