extends Node
## headless 煙測 v0.10.0：結果卡波次／掉落／解鎖＋村莊維護面板
## godot --headless --path . res://scenes/dev/smoke_v010.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	var snap: Dictionary = UpkeepSystem.panel_snapshot()
	if not snap.has("food_alert") or not snap.has("status_line"):
		ok = false
		errors.append("panel_snapshot missing keys")
	var panel: String = UpkeepSystem.describe_panel()
	if panel.find("村莊維護") < 0 or panel.find("食") < 0:
		ok = false
		errors.append("describe_panel missing 村莊維護／食")

	GameState.add_silver(5000)
	GameState.add_wood(3000)
	for bid in ["inn", "clinic", "bounty", "manor"]:
		while BuildingSystem.building_level(bid) < (2 if bid in ["bounty", "manor"] else 1):
			if not BuildingSystem.upgrade(bid):
				ok = false
				errors.append("cannot upgrade %s" % bid)
				break

	var heroes: Array = []
	for i in range(GameState.heroes.size()):
		var hx: Dictionary = (GameState.heroes[i] as Dictionary).duplicate(true)
		hx["status"] = "idle"
		hx["stamina"] = 100
		hx["satiety"] = 100
		hx["injury"] = 0
		GameState.heroes[i] = HeroSystem.normalize_hero(hx)
		heroes.append(str(hx.get("id", "")))
		if heroes.size() >= 3:
			break

	if heroes.is_empty():
		ok = false
		errors.append("no heroes")
	else:
		var dres: Dictionary = DungeonSystem.run_dungeon(heroes)
		if not bool(dres.get("ok", false)):
			ok = false
			errors.append("dungeon run failed: %s" % str(dres.get("reason", "")))
		else:
			var pack: Dictionary = (dres.get("rewards", {}) as Dictionary).duplicate(true)
			pack["run_mode"] = "dungeon"
			pack["waves"] = dres.get("waves", [])
			pack["cleared"] = bool(dres.get("cleared", false))
			pack["total_waves"] = 3
			pack["zone_name"] = str(dres.get("dungeon_name", "秘境"))
			var txt: String = LootText.format_run_result(pack)
			if txt.find("波次") < 0:
				ok = false
				errors.append("dungeon run_result missing 波次")
			if txt.find("戰利品") < 0 and txt.find("兩手空空") < 0:
				ok = false
				errors.append("dungeon run_result missing loot")
			if txt.find("——") < 0:
				ok = false
				errors.append("dungeon run_result missing section dividers/hints")

		heroes.clear()
		for i2 in range(GameState.heroes.size()):
			var hx2: Dictionary = (GameState.heroes[i2] as Dictionary).duplicate(true)
			hx2["status"] = "idle"
			hx2["stamina"] = 100
			hx2["satiety"] = 100
			hx2["injury"] = 0
			GameState.heroes[i2] = HeroSystem.normalize_hero(hx2)
			heroes.append(str(hx2.get("id", "")))
			if heroes.size() >= 3:
				break
		var ores: Dictionary = OutpostSystem.run_defense(heroes)
		if not bool(ores.get("ok", false)):
			ok = false
			errors.append("outpost run failed: %s" % str(ores.get("reason", "")))
		else:
			var opack: Dictionary = (ores.get("rewards", {}) as Dictionary).duplicate(true)
			opack["run_mode"] = "outpost"
			opack["waves"] = ores.get("waves", [])
			opack["waves_cleared"] = int(ores.get("waves_cleared", 0))
			opack["cleared"] = bool(ores.get("cleared", false))
			opack["total_waves"] = OutpostSystem.wave_count()
			opack["zone_name"] = "前哨防衛"
			var otxt: String = LootText.format_run_result(opack)
			if otxt.find("波次") < 0:
				ok = false
				errors.append("outpost run_result missing 波次")

	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not ("v0.10." in main_src or "v0.11." in main_src):
		ok = false
		errors.append("main.gd not bumped to v0.10+/v0.11+")
	if not main_src.contains("_setup_upkeep_panel"):
		ok = false
		errors.append("main missing upkeep panel setup")
	var ac := FileAccess.get_file_as_string("res://scenes/combat/auto_combat.gd")
	if not ac.contains("format_run_result"):
		ok = false
		errors.append("auto_combat missing format_run_result")

	if ok:
		print("SMOKE_V010_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V010_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
