extends Node
## headless 煙測 v0.13.0：多前哨外派駐守／召回／涓滴／存檔
## godot --headless --path . res://scenes/dev/smoke_v130.tscn

const SmokeUtil = preload("res://scripts/dev/SmokeUtil.gd")

func _ready() -> void:
	call_deferred("_run")

func _upgrade_to(bid: String, need: int) -> bool:
	while BuildingSystem.building_level(bid) < need:
		if not BuildingSystem.upgrade(bid):
			return false
	return true

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	var main_src := SmokeUtil.main_src()
	if not SmokeUtil.version_at_least(main_src, 0, 13, 0):
		ok = false
		errors.append("main.gd title should be >= v0.13.0")
	if not main_src.contains("_on_camp_station_pressed") or not main_src.contains("_on_camp_recall_pressed"):
		ok = false
		errors.append("main missing camp station/recall handlers")
	if not main_src.contains("_rebuild_camp_pick_buttons"):
		ok = false
		errors.append("main missing camp pick buttons")
	if not main_src.contains("describe_pick_panel_full"):
		ok = false
		errors.append("main not using describe_pick_panel_full")

	if int(GameState.SAVE_VERSION) < 14:
		ok = false
		errors.append("SAVE_VERSION should be >= 14 got %d" % int(GameState.SAVE_VERSION))
	if int(SaveManager.SAVE_VERSION) < 14:
		ok = false
		errors.append("SaveManager SAVE_VERSION should be >= 14")

	## camps data
	var camps: Array = OutpostSystem.camps()
	if camps.size() < 2:
		ok = false
		errors.append("need >=2 camps got %d" % camps.size())
	for need in ["luanshan", "guandao"]:
		if OutpostSystem.camp_by_id(need).is_empty():
			ok = false
			errors.append("missing camp %s" % need)

	## unlock gates
	if OutpostSystem.is_unlocked():
		ok = false
		errors.append("outpost should start locked")
	if OutpostSystem.is_camp_unlocked("luanshan"):
		ok = false
		errors.append("luanshan camp should start locked with outpost")

	GameState.add_silver(8000)
	GameState.add_wood(4000)
	if not _upgrade_to("manor", 2) or not _upgrade_to("bounty", 2):
		ok = false
		errors.append("cannot upgrade manor/bounty to 2")

	if not OutpostSystem.is_unlocked():
		ok = false
		errors.append("outpost still locked after manor2 bounty2")
	if not OutpostSystem.is_camp_unlocked("luanshan"):
		ok = false
		errors.append("luanshan should unlock with outpost")
	if OutpostSystem.is_camp_unlocked("guandao"):
		ok = false
		errors.append("guandao should need a clear")

	## freshen heroes
	for i in range(GameState.heroes.size()):
		var hx: Dictionary = (GameState.heroes[i] as Dictionary).duplicate(true)
		hx["status"] = "idle"
		hx["stamina"] = 100
		hx["satiety"] = 100
		hx["injury"] = 0
		hx["level"] = 6
		GameState.heroes[i] = HeroSystem.normalize_hero(hx)

	var ready: Array = HeroSystem.find_ready_heroes(2)
	if ready.size() < 2:
		ok = false
		errors.append("need 2 ready heroes")
	else:
		var party: Array = [str(ready[0].get("id", "")), str(ready[1].get("id", ""))]
		var st0: Dictionary = OutpostSystem.station("luanshan", party)
		if not bool(st0.get("ok", false)):
			ok = false
			errors.append("station fail: %s" % str(st0.get("reason", "")))
		else:
			var h0: Dictionary = HeroSystem.get_hero(party[0])
			if str(h0.get("status", "")) != "camped":
				ok = false
				errors.append("hero status not camped got %s" % str(h0.get("status", "")))
			if HeroSystem.can_hunt(h0):
				ok = false
				errors.append("camped hero should not be dispatchable")
			var ready2: Array = HeroSystem.find_ready_heroes(1)
			if ready2.size() > 0:
				var st_busy: Dictionary = OutpostSystem.station("luanshan", [str(ready2[0].get("id", ""))])
				if bool(st_busy.get("ok", false)):
					ok = false
					errors.append("should not station onto occupied camp")
			var silver_before: int = GameState.silver
			var tick_res: Dictionary = OutpostSystem.tick_camps(55.0)
			if not bool(tick_res.get("ok", false)):
				ok = false
				errors.append("tick_camps failed")
			var gains: Dictionary = tick_res.get("gains", {}) as Dictionary
			if int(gains.get("silver", 0)) <= 0:
				tick_res = OutpostSystem.tick_camps(60.0)
				gains = tick_res.get("gains", {}) as Dictionary
			if int(gains.get("silver", 0)) <= 0 and GameState.silver <= silver_before:
				ok = false
				errors.append("expected silver trickle/skirmish gains")
			var st_snap: Dictionary = OutpostSystem.camp_station("luanshan")
			if int(st_snap.get("total_silver", 0)) <= 0 and int(st_snap.get("skirmishes", 0)) <= 0:
				ok = false
				errors.append("station totals empty after tick")
			var panel: String = OutpostSystem.describe_camps_panel()
			if panel.find("亂山前哨") < 0 or panel.find("官道哨卡") < 0:
				ok = false
				errors.append("camp panel missing names")
			var saved: Dictionary = GameState.to_save_dict()
			if not saved.has("camp_stations"):
				ok = false
				errors.append("save missing camp_stations")
			SaveManager.save_game()
			OutpostSystem.recall("luanshan")
			if OutpostSystem.stationed_count() != 0:
				ok = false
				errors.append("recall should clear stations")
			if not SaveManager.load_game():
				ok = false
				errors.append("load_game failed")
			else:
				if OutpostSystem.stationed_count() < 2:
					ok = false
					errors.append("loaded camp stations missing heroes got %d" % OutpostSystem.stationed_count())
				var h_reload: Dictionary = HeroSystem.get_hero(party[0])
				if str(h_reload.get("status", "")) != "camped":
					ok = false
					errors.append("reloaded hero not camped")
			GameState.outpost_clears = 1
			if not OutpostSystem.is_camp_unlocked("guandao"):
				ok = false
				errors.append("guandao unlock after clear fail")
			var rec: Dictionary = OutpostSystem.recall("luanshan")
			if not bool(rec.get("ok", false)):
				ok = false
				errors.append("recall after load fail: %s" % str(rec.get("reason", "")))
			else:
				var h_back: Dictionary = HeroSystem.get_hero(party[0])
				if str(h_back.get("status", "")) != "idle":
					ok = false
					errors.append("recalled hero not idle")

	## freshen one hero for HUD chip
	for i2 in range(GameState.heroes.size()):
		var hx2: Dictionary = (GameState.heroes[i2] as Dictionary).duplicate(true)
		hx2["status"] = "idle"
		hx2["stamina"] = 100
		hx2["satiety"] = 100
		hx2["injury"] = 0
		GameState.heroes[i2] = HeroSystem.normalize_hero(hx2)
	var ready3: Array = HeroSystem.find_ready_heroes(1)
	if ready3.size() > 0:
		var st_hud: Dictionary = OutpostSystem.station("luanshan", [str(ready3[0].get("id", ""))])
		if bool(st_hud.get("ok", false)):
			var line: String = ResourceLoop.describe_readiness(0)
			if line.find("駐") < 0:
				ok = false
				errors.append("readiness missing 駐 chip: %s" % line)
			OutpostSystem.recall("luanshan")

	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	if packed == null:
		ok = false
		errors.append("main.tscn load fail")
	else:
		var main: Node = packed.instantiate()
		add_child(main)
		await get_tree().process_frame
		await get_tree().process_frame
		if main.get_node_or_null("OutpostPickPanel") == null:
			ok = false
			errors.append("OutpostPickPanel missing")
		else:
			var panel_n: Node = main.get_node("OutpostPickPanel")
			if panel_n.get_node_or_null("CampPickRow") == null:
				ok = false
				errors.append("CampPickRow missing")
		if main.has_method("_on_outpost_pressed"):
			GameState.add_silver(5000)
			GameState.add_wood(2000)
			_upgrade_to("manor", 2)
			_upgrade_to("bounty", 2)
			main.call("_on_outpost_pressed")
			await get_tree().process_frame
			var op: CanvasItem = main.get_node_or_null("OutpostPickPanel") as CanvasItem
			if op == null or not op.visible:
				ok = false
				errors.append("outpost panel should open when unlocked")
		main.queue_free()
		await get_tree().process_frame

	if ok:
		print("SMOKE_V130_OK")
	else:
		print("SMOKE_V130_FAIL")
		for e in errors:
			print("  - ", e)
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if ok else 1)
