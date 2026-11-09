extends Node
## headless 煙測 v0.15.0：書院武學／經世技能樹擴充＋效果接線
## godot --headless --path . res://scenes/dev/smoke_v150.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()
	AcademySystem.reload()

	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not ("v0.15.0" in main_src):
		ok = false
		errors.append("main.gd not bumped to v0.15.0")
	if not main_src.contains("_academy_play_unlock_flash"):
		ok = false
		errors.append("main missing unlock flash")
	if not main_src.contains("tree_nodes_sorted"):
		ok = false
		errors.append("main should layout via tree_nodes_sorted")

	## SAVE 維持 14（節點 id 陣列 schema 未變）
	if int(GameState.SAVE_VERSION) < 14:
		ok = false
		errors.append("SAVE_VERSION should stay >= 14 got %d" % int(GameState.SAVE_VERSION))
	if int(SaveManager.SAVE_VERSION) < 14:
		ok = false
		errors.append("SaveManager SAVE_VERSION should be >= 14")

	## tree shape：至少兩專精＋明顯多過 stub 7 節
	var branches: Array = AcademySystem.branches()
	if branches.size() < 2:
		ok = false
		errors.append("need >=2 branches got %d" % branches.size())
	else:
		var ids_br: PackedStringArray = PackedStringArray()
		for b in branches:
			ids_br.append(str((b as Dictionary).get("id", "")))
		if not ("wuxue" in ids_br) or not ("jingshi" in ids_br):
			ok = false
			errors.append("branches should include wuxue/jingshi")
	var nodes: Array = AcademySystem.tree_nodes()
	if nodes.size() < 14:
		ok = false
		errors.append("tree nodes should expand (>=14) got %d" % nodes.size())

	## 舊 stub 節點仍在（存檔兼容）
	for keep in ["n_tiegu", "n_jifeng", "n_chenzhuo", "n_xueqi", "n_tiegu_plus", "n_village_ledger", "n_village_store"]:
		if AcademySystem.node_by_id(keep).is_empty():
			ok = false
			errors.append("missing legacy node %s" % keep)

	## 新節點
	for need in ["n_pogao", "n_xieli", "n_gangmeng", "n_tiebi", "n_wuxue_xin", "n_kuangmai", "n_micang", "n_yingzhang", "n_qianshao", "n_jingshi_yao"]:
		if AcademySystem.node_by_id(need).is_empty():
			ok = false
			errors.append("missing new node %s" % need)

	## prepare academy
	GameState.add_silver(9000)
	GameState.add_wood(4000)
	GameState.add_fragments(400)
	for bid in ["inn", "clinic", "bounty", "manor", "academy", "training"]:
		var need_lv: int = 2 if bid in ["bounty", "manor"] else 1
		while BuildingSystem.building_level(bid) < need_lv:
			if not BuildingSystem.upgrade(bid):
				ok = false
				errors.append("cannot upgrade %s" % bid)
				break

	if not AcademySystem.academy_ready():
		ok = false
		errors.append("academy not ready")
	if not AcademySystem.is_node_unlocked("n_tiegu"):
		ok = false
		errors.append("starter n_tiegu not unlocked")
	if AcademySystem.is_skill_unlocked("pogao"):
		ok = false
		errors.append("pogao should start locked")

	## unlock 武學支線至卸力／剛猛／心訣
	for step in ["n_jifeng", "n_chenzhuo", "n_pogao", "n_xueqi", "n_xieli", "n_gangmeng"]:
		var ur: Dictionary = AcademySystem.unlock_node(step)
		if not bool(ur.get("ok", false)):
			ok = false
			errors.append("unlock %s fail: %s" % [step, str(ur.get("reason", ""))])
	if not AcademySystem.is_skill_unlocked("xieli"):
		ok = false
		errors.append("xieli should unlock")
	if not AcademySystem.is_skill_unlocked("gangmeng"):
		ok = false
		errors.append("gangmeng should unlock")

	var slots_before: int = AcademySystem.passive_slots_unlocked()
	var uw: Dictionary = AcademySystem.unlock_node("n_wuxue_xin")
	if not bool(uw.get("ok", false)):
		ok = false
		errors.append("unlock wuxue_xin fail: %s" % str(uw.get("reason", "")))
	else:
		if AcademySystem.passive_slots_unlocked() < slots_before + 1:
			ok = false
			errors.append("wuxue_xin should grant passive slot")
		var crit_v: float = AcademySystem.village_effect_add("party_crit_bonus", 0.0)
		var parry_v: float = AcademySystem.village_effect_add("party_parry_bonus", 0.0)
		if crit_v < 0.05 or parry_v < 0.05:
			ok = false
			errors.append("wuxue_xin village crit/parry missing")

	## 經世支線
	for step2 in ["n_village_ledger", "n_village_store", "n_kuangmai", "n_micang", "n_yingzhang", "n_qianshao", "n_jingshi_yao"]:
		var ur2: Dictionary = AcademySystem.unlock_node(step2)
		if not bool(ur2.get("ok", false)):
			ok = false
			errors.append("unlock %s fail: %s" % [step2, str(ur2.get("reason", ""))])

	var um: float = AcademySystem.village_effect_mult("upkeep_silver_mult", 1.0)
	## ledger 0.92 * jingshi_yao 0.95
	if um > 0.88:
		ok = false
		errors.append("upkeep mult should stack ledger+yao got %s" % str(um))
	var dl: float = AcademySystem.village_effect_add("dungeon_loot_bonus", 0.0)
	if dl < 0.16:
		ok = false
		errors.append("dungeon_loot_bonus should stack micang+yao got %s" % str(dl))
	var cs: float = AcademySystem.village_effect_add("camp_silver_bonus", 0.0)
	if cs < 0.14:
		ok = false
		errors.append("camp_silver_bonus missing")
	var os: float = AcademySystem.village_effect_add("outpost_silver_bonus", 0.0)
	if os < 0.11:
		ok = false
		errors.append("outpost_silver_bonus missing")

	## assign 破招 → party crit rises
	var heroes: Array = []
	for i in range(GameState.heroes.size()):
		var hx: Dictionary = (GameState.heroes[i] as Dictionary).duplicate(true)
		hx["status"] = "idle"
		hx["stamina"] = 100
		hx["satiety"] = 100
		hx["injury"] = 0
		hx["level"] = 8
		GameState.heroes[i] = HeroSystem.normalize_hero(hx)
		heroes.append(str(hx.get("id", "")))
		if heroes.size() >= 3:
			break
	if heroes.is_empty():
		ok = false
		errors.append("need heroes")
	else:
		var hid: String = str(heroes[0])
		var base_crit: float = AcademySystem.party_crit_chance([hid])
		var asg: Dictionary = AcademySystem.assign_passive(hid, "pogao")
		if not bool(asg.get("ok", false)):
			ok = false
			errors.append("assign pogao fail: %s" % str(asg.get("reason", "")))
		else:
			var after_crit: float = AcademySystem.party_crit_chance([hid])
			if after_crit <= base_crit + 0.05:
				ok = false
				errors.append("pogao should raise party crit %s -> %s" % [str(base_crit), str(after_crit)])
		var pwr: int = HeroSystem.power_of(HeroSystem.get_hero(hid))
		if pwr < 1:
			ok = false
			errors.append("power_of invalid")

	## preview / panel text
	var preview: String = AcademySystem.preview_node("n_micang")
	if preview.find("秘境") < 0 and preview.find("碎片") < 0:
		ok = false
		errors.append("micang preview missing loot text")
	var panel: String = AcademySystem.describe_panel(str(heroes[0]) if heroes.size() > 0 else "")
	if panel.find("武學") < 0 or panel.find("經世") < 0:
		ok = false
		errors.append("panel missing branch names")

	## auto_combat uses academy rates
	var ac_src := FileAccess.get_file_as_string("res://scenes/combat/auto_combat.gd")
	if not ac_src.contains("party_crit_chance") or not ac_src.contains("party_parry_chance"):
		ok = false
		errors.append("auto_combat not wired to academy crit/parry")

	## dungeon / outpost / dispatch wiring markers
	var dun_src := FileAccess.get_file_as_string("res://scripts/systems/DungeonSystem.gd")
	if not dun_src.contains("dungeon_loot_bonus"):
		ok = false
		errors.append("DungeonSystem missing dungeon_loot_bonus")
	var out_src := FileAccess.get_file_as_string("res://scripts/systems/OutpostSystem.gd")
	if not out_src.contains("camp_silver_bonus") or not out_src.contains("outpost_silver_bonus"):
		ok = false
		errors.append("OutpostSystem missing camp/outpost academy hooks")
	var dis_src := FileAccess.get_file_as_string("res://scripts/systems/DispatchSystem.gd")
	if not dis_src.contains("hunt_fur_bonus"):
		ok = false
		errors.append("DispatchSystem missing hunt_fur_bonus")

	## save round-trip keeps unlocked nodes
	var save_d: Dictionary = GameState.to_save_dict()
	if not save_d.has("academy_unlocked_nodes"):
		ok = false
		errors.append("save missing academy_unlocked_nodes")
	else:
		var unlocked_n: int = (save_d.get("academy_unlocked_nodes", []) as Array).size()
		if unlocked_n < 10:
			ok = false
			errors.append("expected many unlocked nodes in save got %d" % unlocked_n)
		GameState.load_from_dict(save_d)
		AcademySystem.reload()
		if not AcademySystem.is_node_unlocked("n_jingshi_yao"):
			ok = false
			errors.append("save restore lost n_jingshi_yao")
		if not AcademySystem.is_node_unlocked("n_wuxue_xin"):
			ok = false
			errors.append("save restore lost n_wuxue_xin")

	if ok:
		print("SMOKE_V150_OK")
	else:
		print("SMOKE_V150_FAIL")
		for e in errors:
			print("  - ", e)
	await get_tree().process_frame
	get_tree().quit(0 if ok else 1)
