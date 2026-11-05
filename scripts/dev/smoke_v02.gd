extends Node
## headless 煙測 v0.2：製作鏈、戰鬥敵人、64 art、放置、存讀
## godot --headless --path . res://scenes/dev/smoke_v02.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	if GameState.hero_count() != 6:
		ok = false
		errors.append("expected 6 heroes, got %d" % GameState.hero_count())

	## Art 64 preferred
	for hid in ["hero_atie", "hero_aqing", "hero_aniu"]:
		var path: String = ArtPaths.hero_idle(hid)
		if not ArtPaths.exists(path):
			ok = false
			errors.append("missing hero idle %s" % hid)
			continue
		if path.find("_prev_48") != -1:
			ok = false
			errors.append("still on 48 fallback for %s: %s" % [hid, path])
		var frames: SpriteFrames = ArtPaths.make_hero_frames(hid)
		if frames.get_frame_count("walk") < 4:
			ok = false
			errors.append("walk frames want >=4 got %d for %s" % [frames.get_frame_count("walk"), hid])
		var fp: int = ArtPaths.hero_frame_px(hid)
		if fp < 64:
			ok = false
			errors.append("frame_px want 64 got %d %s" % [fp, hid])

	for kind in ["wolf", "boar", "bandit"]:
		if not ArtPaths.exists(ArtPaths.monster_idle(kind)):
			ok = false
			errors.append("missing monster %s" % kind)

	if not ArtPaths.exists(ArtPaths.building_icon("warehouse")):
		ok = false
		errors.append("missing warehouse icon")

	## Iron + placements
	if GameState.iron < 1:
		ok = false
		errors.append("starter iron expected >=1")

	GameState.set_building_pos("inn", Vector2(300, 300))
	var pos: Vector2 = GameState.get_building_pos("inn")
	if absf(pos.x - 300) > 0.1:
		ok = false
		errors.append("placement not sticky")

	GameState.add_silver(500)
	GameState.add_wood(500)
	GameState.add_fur(20)
	GameState.add_iron(10)
	if not BuildingSystem.upgrade("forge"):
		ok = false
		errors.append("forge upgrade failed")
	if not BuildingSystem.upgrade("clinic"):
		ok = false
		errors.append("clinic upgrade failed")
	if not BuildingSystem.upgrade("warehouse"):
		ok = false
		errors.append("warehouse upgrade failed")

	## Craft leather armor onto hero
	var craft1: Dictionary = CraftSystem.craft("leather_armor", "hero_atie")
	if not bool(craft1.get("ok", false)):
		ok = false
		errors.append("craft leather failed: %s" % str(craft1.get("reason", "")))
	else:
		var h: Dictionary = HeroSystem.get_hero("hero_atie")
		var gear: int = HeroSystem.equipment_power(h)
		if gear < 3:
			ok = false
			errors.append("equip power want >=3 got %d" % gear)

	var craft2: Dictionary = CraftSystem.craft("wound_salve", "hero_atie")
	if not bool(craft2.get("ok", false)):
		ok = false
		errors.append("craft salve failed: %s" % str(craft2.get("reason", "")))

	var craft3: Dictionary = CraftSystem.craft("hide_bundle", "")
	if not bool(craft3.get("ok", false)):
		ok = false
		errors.append("craft hide_bundle failed: %s" % str(craft3.get("reason", "")))

	## Hunt with enemies
	var dispatch := DispatchSystem.new()
	add_child(dispatch)
	var res: Dictionary = dispatch.dispatch_ready(2, "luan_shan_po")
	if not bool(res.get("ok", false)):
		ok = false
		errors.append("dispatch failed: %s" % str(res.get("reason", "")))
	else:
		var hunt: Dictionary = GameState.active_hunts[0] as Dictionary
		hunt["return_at"] = Time.get_unix_time_from_system() - 1.0
		GameState.active_hunts[0] = hunt
		var finished: Array = []
		dispatch.hunt_finished.connect(func(rw: Dictionary) -> void: finished.append(rw))
		dispatch.resolve_due_hunts()
		if finished.is_empty():
			ok = false
			errors.append("hunt_finished not emitted")
		else:
			var rw: Dictionary = finished[0] as Dictionary
			var enemies: Array = rw.get("enemies", []) as Array
			if enemies.is_empty():
				ok = false
				errors.append("no enemies in rewards")
			if int(rw.get("silver", 0)) < 1:
				ok = false
				errors.append("no silver reward")

	## Save / load placements + iron + inventory
	SaveManager.clear_save()
	var iron_before: int = GameState.iron
	var place_before: Vector2 = GameState.get_building_pos("inn")
	if not SaveManager.save_game():
		ok = false
		errors.append("save failed")
	GameState.add_iron(99)
	GameState.set_building_pos("inn", Vector2(1, 1))
	if not SaveManager.load_game():
		ok = false
		errors.append("load failed")
	if GameState.iron != iron_before:
		ok = false
		errors.append("iron mismatch %d vs %d" % [GameState.iron, iron_before])
	var place_after: Vector2 = GameState.get_building_pos("inn")
	if absf(place_after.x - place_before.x) > 0.1:
		ok = false
		errors.append("placement load mismatch")

	if ok:
		print("SMOKE_V02_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V02_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
