extends Node
## headless 煙測 v0.3-playable：放置碰撞／取消、引導步進、64 art、main 可載
## godot --headless --path . res://scenes/dev/smoke_v03.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	## 清舊存檔，避免污染放置／引導測試
	SaveManager.clear_save()
	GameState._load_starter_data()

	## Art still 64
	var fp: int = ArtPaths.hero_frame_px("hero_atie")
	if fp < 64:
		ok = false
		errors.append("hero frame want >=64 got %d" % fp)
	if not ArtPaths.exists(ArtPaths.VILLAGE_GROUND):
		ok = false
		errors.append("missing village_ground")
	if not ArtPaths.exists(ArtPaths.building_icon("inn")):
		ok = false
		errors.append("missing inn icon")
	var inn_tex: Texture2D = ArtPaths.load_tex(ArtPaths.building_icon("inn"))
	if inn_tex and inn_tex.get_width() < 128:
		ok = false
		errors.append("inn icon want >=128 got %d" % inn_tex.get_width())

	## Main scene loads
	var main_ps: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	if main_ps == null:
		ok = false
		errors.append("main.tscn failed to load")
	else:
		var main: Node = main_ps.instantiate()
		add_child(main)
		await get_tree().process_frame
		await get_tree().process_frame
		if main.get_node_or_null("%TutorialBanner") == null:
			ok = false
			errors.append("TutorialBanner missing")
		if main.get_node_or_null("%VillageHost") == null:
			ok = false
			errors.append("VillageHost missing")
		## Village place API
		var village: Node = null
		var host: Node = main.get_node_or_null("%VillageHost")
		if host and host.get_child_count() > 0:
			village = host.get_child(0)
		if village == null or not village.has_method("begin_place"):
			ok = false
			errors.append("village begin_place missing")
		else:
			## Placement collision
			GameState.set_building_pos("manor", Vector2(400, 280))
			## Ensure manor counts as unlocked (start_level 1)
			var chk_bad: Dictionary = village.can_place_at(Vector2(400, 280), "inn")
			if bool(chk_bad.get("ok", true)):
				ok = false
				errors.append("expected overlap reject near manor")
			## 遠離 manor(400,280) 同預設解鎖建築
			var chk_ok: Dictionary = village.can_place_at(Vector2(600, 250), "inn")
			if not bool(chk_ok.get("ok", false)):
				ok = false
				errors.append("expected free spot ok: %s" % str(chk_ok.get("reason", "")))
			## Cancel path
			village.begin_place("inn")
			if not bool(village.is_placing()):
				ok = false
				errors.append("begin_place did not arm")
			village.cancel_place()
			if bool(village.is_placing()):
				ok = false
				errors.append("cancel_place failed")
			## Out of buildable
			var chk_oob: Dictionary = village.can_place_at(Vector2(20, 20), "inn")
			if bool(chk_oob.get("ok", true)):
				ok = false
				errors.append("expected OOB reject")
		main.queue_free()
		await get_tree().process_frame

	## Tutorial step machine (no UI)
	GameState.tutorial_step = 1
	GameState.add_silver(200)
	GameState.add_wood(200)
	if not BuildingSystem.upgrade("inn"):
		ok = false
		errors.append("inn upgrade failed")
	## main would advance; simulate
	if GameState.tutorial_step == 1:
		GameState.tutorial_step = 2
	if GameState.tutorial_step != 2:
		ok = false
		errors.append("tutorial step want 2")

	SaveManager.clear_save()
	GameState.tutorial_step = 3
	if not SaveManager.save_game():
		ok = false
		errors.append("save failed")
	GameState.tutorial_step = 9
	if not SaveManager.load_game():
		ok = false
		errors.append("load failed")
	if GameState.tutorial_step != 3:
		ok = false
		errors.append("tutorial_step not persisted got %d" % GameState.tutorial_step)

	if ok:
		print("SMOKE_V03_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V03_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
