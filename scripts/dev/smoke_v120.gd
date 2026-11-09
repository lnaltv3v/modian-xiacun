extends Node
## headless 煙測 v0.12.0：新手秘境／前哨引導步＋HUD 資訊密度
## godot --headless --path . res://scenes/dev/smoke_v120.tscn

const SmokeUtil = preload("res://scripts/dev/SmokeUtil.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- tutorial: 1..4 still work; 4→5 not 0 ---
	GameState.tutorial_step = 4
	if GameState.tutorial_step != 4:
		ok = false
		errors.append("cannot set tutorial 4")

	## simulate main completion helper logic
	var main_src := SmokeUtil.main_src()
	if not SmokeUtil.version_at_least(main_src, 0, 12, 0):
		ok = false
		errors.append("main.gd title should be >= v0.12.0")
	if not main_src.contains("_setup_dense_hud"):
		ok = false
		errors.append("main missing _setup_dense_hud")
	if not main_src.contains("_refresh_dense_chips"):
		ok = false
		errors.append("main missing _refresh_dense_chips")
	if not main_src.contains("_finish_tutorial"):
		ok = false
		errors.append("main missing _finish_tutorial")
	if not main_src.contains("_advance_tutorial"):
		ok = false
		errors.append("main missing _advance_tutorial")
	if not main_src.contains("tutorial_step = 5"):
		ok = false
		errors.append("step4 should advance to 5")
	if not main_src.contains("引導⑤") and not main_src.contains("⑤ 秘境"):
		ok = false
		errors.append("missing tutorial step 5 copy")
	if not main_src.contains("⑥ 前哨") and not main_src.contains("引導⑥"):
		ok = false
		errors.append("missing tutorial step 6 copy")
	## old saves: step 0 stays done (no auto re-entry)
	GameState.tutorial_step = 0
	var save0: Dictionary = GameState.to_save_dict()
	GameState.tutorial_step = 99
	GameState.load_from_dict(save0)
	if GameState.tutorial_step != 0:
		ok = false
		errors.append("tutorial_step 0 not persisted got %d" % GameState.tutorial_step)

	GameState.tutorial_step = 5
	var save5: Dictionary = GameState.to_save_dict()
	GameState.tutorial_step = 1
	GameState.load_from_dict(save5)
	if GameState.tutorial_step != 5:
		ok = false
		errors.append("tutorial_step 5 not persisted got %d" % GameState.tutorial_step)

	GameState.tutorial_step = 6
	var save6: Dictionary = GameState.to_save_dict()
	GameState.tutorial_step = 2
	GameState.load_from_dict(save6)
	if GameState.tutorial_step != 6:
		ok = false
		errors.append("tutorial_step 6 not persisted got %d" % GameState.tutorial_step)

	## --- ResourceLoop dense readiness ---
	var ready_line: String = ResourceLoop.describe_readiness(0)
	if ready_line.find("食") < 0 or ready_line.find("秘境") < 0 or ready_line.find("前哨") < 0:
		ok = false
		errors.append("describe_readiness missing chips: %s" % ready_line)
	## starter bounty 已係 Lv1 → 秘境門檻預設開
	if not ResourceLoop.dungeon_gate_ok():
		ok = false
		errors.append("dungeon_gate should be true at starter (bounty Lv1)")

	GameState.add_silver(5000)
	GameState.add_wood(3000)

	var ready2: String = ResourceLoop.describe_readiness(2)
	if ready2.find("已選2") < 0 and ready2.find("已選 2") < 0:
		## format is 已選%d without space
		if ready2.find("已選2") < 0:
			ok = false
			errors.append("readiness missing selected mark: %s" % ready2)

	## --- HUD art paths still resolve ---
	for path in [ArtPaths.HUD_PANEL, ArtPaths.BTN_DISPATCH, ArtPaths.BTN_BUILD, ArtPaths.ICON_HERB, ArtPaths.ICON_SILVER]:
		if ArtPaths.load_tex(path) == null:
			ok = false
			errors.append("missing UI tex %s" % path)

	## --- main scene loads + dense hud nodes ---
	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	if packed == null:
		ok = false
		errors.append("main.tscn load fail")
	else:
		var main: Node = packed.instantiate()
		add_child(main)
		await get_tree().process_frame
		await get_tree().process_frame
		if main.get_node_or_null("DenseHudBg") == null:
			ok = false
			errors.append("DenseHudBg not created")
		if main.get_node_or_null("ChipFoodLab") == null:
			ok = false
			errors.append("ChipFoodLab missing")
		if main.get_node_or_null("ChipDungeonLab") == null:
			ok = false
			errors.append("ChipDungeonLab missing")
		if main.get_node_or_null("ChipOutpostLab") == null:
			ok = false
			errors.append("ChipOutpostLab missing")
		## drive tutorial 5→6 via dungeon button
		GameState.tutorial_step = 5
		if main.has_method("_on_dungeon_pressed"):
			main.call("_on_dungeon_pressed")
			await get_tree().process_frame
			if GameState.tutorial_step != 6:
				ok = false
				errors.append("dungeon open should advance 5→6 got %d" % GameState.tutorial_step)
		## step 6 via locked outpost tip
		GameState.tutorial_step = 6
		if main.has_method("_on_outpost_pressed"):
			main.call("_on_outpost_pressed")
			await get_tree().process_frame
			if GameState.tutorial_step != 0:
				ok = false
				errors.append("outpost tip should finish tutorial got %d" % GameState.tutorial_step)
		## skip still works
		GameState.tutorial_step = 3
		if main.has_method("_on_skip_tutorial"):
			main.call("_on_skip_tutorial")
			if GameState.tutorial_step != 0:
				ok = false
				errors.append("skip should set 0")
		main.queue_free()
		await get_tree().process_frame

	if int(GameState.SAVE_VERSION) < 13:
		ok = false
		errors.append("SAVE_VERSION should be >= 13")

	## regression: dungeon / academy still present
	if not main_src.contains("_setup_dungeon_panel") or not main_src.contains("_setup_academy_panel"):
		ok = false
		errors.append("v0.11 panels missing")

	if ok:
		print("SMOKE_V120_OK")
	else:
		print("SMOKE_V120_FAIL")
		for e in errors:
			print("  - ", e)
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if ok else 1)
