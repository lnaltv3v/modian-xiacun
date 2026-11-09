extends RefCounted
class_name ResourceLoop
## 資源循環：建築 → 服務俠客 → 變強 → 帶回資源 → 村莊升級

static func describe_loop() -> String:
	return "建築服務俠客 → 俠客變強 → 派遣帶回資源 → 升級村莊"

static func inn_bonus_silver_per_tick() -> int:
	return BuildingSystem.building_level("inn") * 1

static func forge_bonus_power() -> int:
	return BuildingSystem.building_level("forge") * 2

static func training_bonus_xp() -> int:
	return BuildingSystem.building_level("training") * 5

static func bounty_reward_mult() -> float:
	return 1.0 + float(BuildingSystem.building_level("bounty")) * 0.07

static func dungeon_gate_ok() -> bool:
	## 秘境建築門檻（預設懸賞榜 Lv1，同 DungeonSystem.can_enter）
	DungeonSystem.ensure_loaded()
	return BuildingSystem.building_level("bounty") >= 1

static func describe_readiness(selected_n: int = 0) -> String:
	## HUD 高密度：食住醫／派遣／秘境／前哨一眼掃（EHT 式資訊密度）
	var snap: Dictionary = UpkeepSystem.panel_snapshot()
	var food: String = "食⚠" if bool(snap.get("food_alert", false)) else ("食✓" if int(snap.get("inn_lv", 0)) >= 1 else "食·")
	var lodge: String = "住⚠" if bool(snap.get("lodge_alert", false)) else ("住✓" if int(snap.get("inn_lv", 0)) >= 1 or int(snap.get("manor_lv", 0)) >= 1 else "住·")
	var med: String = "醫⚠" if bool(snap.get("med_alert", false)) else ("醫✓" if int(snap.get("clinic_lv", 0)) >= 1 else "醫·")
	var ready_n: int = HeroSystem.find_ready_heroes(-1).size()
	var hunt_n: int = GameState.hunting_hero_count()
	var idle_n: int = GameState.idle_hero_count()
	var diff: Dictionary = DungeonSystem.difficulty_by_id(str(GameState.dungeon_pick_diff))
	var wset: Dictionary = DungeonSystem.wave_set_by_id(str(GameState.dungeon_pick_waves))
	var d_txt: String = "秘境·%s·%d波" % [str(diff.get("name", "普通")), int(wset.get("max_waves", 3))]
	if GameState.dungeon_busy:
		d_txt += "▶"
	elif not dungeon_gate_ok():
		d_txt += "（要懸賞）"
	elif ready_n > 0:
		d_txt += "✓"
	else:
		d_txt += "（等俠）"
	var o_txt: String
	if not OutpostSystem.is_unlocked():
		o_txt = "前哨鎖"
	else:
		var od: Dictionary = OutpostSystem.difficulty_by_id(str(GameState.outpost_pick_diff))
		o_txt = "前哨·%s" % str(od.get("name", "普通"))
		var camp_n: int = OutpostSystem.stationed_count()
		if camp_n > 0:
			o_txt += "·駐%d" % camp_n
		elif ready_n > 0:
			o_txt += "✓"
	var sel: String = ("　已選%d" % selected_n) if selected_n > 0 else ""
	var academy: String = "　書院✓" if AcademySystem.academy_ready() else ""
	return "%s%s%s　｜　就緒%d 在村%d 出征%d%s　｜　%s　｜　%s%s" % [
		food, lodge, med, ready_n, idle_n, hunt_n, sel, d_txt, o_txt, academy,
	]
