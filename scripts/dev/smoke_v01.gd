extends Node
## headless 煙測 v0.1：升級、派遣、離線結算、存讀
## 用法：godot --headless --path . res://scenes/dev/smoke_v01.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	if GameState.hero_count() != 6:
		ok = false
		errors.append("expected 6 heroes, got %d" % GameState.hero_count())

	if not GameState.zones.has("luan_shan_po"):
		ok = false
		errors.append("missing zone luan_shan_po")

	if not FileAccess.file_exists("res://data/buildings/layout.json"):
		ok = false
		errors.append("missing layout.json")

	for hid in ["hero_atie", "hero_aqing", "hero_achang", "hero_dali", "hero_azhen", "hero_aniu"]:
		if not ArtPaths.exists(ArtPaths.hero_idle(hid)):
			ok = false
			errors.append("missing idle art %s" % hid)
		if not ArtPaths.exists(ArtPaths.hero_walk(hid)):
			ok = false
			errors.append("missing walk art %s" % hid)
		var frames: SpriteFrames = ArtPaths.make_hero_frames(hid)
		if frames.get_frame_count("walk") < 1:
			ok = false
			errors.append("walk frames empty %s" % hid)

	for bid in ["manor", "inn", "forge", "clinic", "training", "bounty"]:
		if not ArtPaths.exists(ArtPaths.building_icon(bid)):
			ok = false
			errors.append("missing building icon %s" % bid)

	GameState.add_silver(500)
	GameState.add_wood(500)
	if not BuildingSystem.upgrade("inn"):
		ok = false
		errors.append("inn upgrade failed")
	elif BuildingSystem.building_level("inn") < 1:
		ok = false
		errors.append("inn level still 0")

	var dispatch := DispatchSystem.new()
	add_child(dispatch)
	var res: Dictionary = dispatch.dispatch_ready(2, "luan_shan_po")
	if not bool(res.get("ok", false)):
		ok = false
		errors.append("dispatch failed: %s" % str(res.get("reason", "")))
	else:
		if GameState.hunting_hero_count() != 2:
			ok = false
			errors.append("hunting count want 2 got %d" % GameState.hunting_hero_count())
		if GameState.active_hunts.size() > 0:
			var hunt: Dictionary = GameState.active_hunts[0] as Dictionary
			hunt["return_at"] = Time.get_unix_time_from_system() - 1.0
			GameState.active_hunts[0] = hunt
			dispatch.resolve_due_hunts()
			if GameState.hunting_hero_count() != 0:
				ok = false
				errors.append("after resolve still hunting=%d" % GameState.hunting_hero_count())
			if GameState.fur < 1:
				ok = false
				errors.append("expected some fur after hunt")

	SaveManager.clear_save()
	if not SaveManager.save_game():
		ok = false
		errors.append("save failed")
	var fur_saved: int = GameState.fur
	GameState.add_fur(99)
	if not SaveManager.load_game():
		ok = false
		errors.append("load failed")
	if GameState.fur != fur_saved:
		ok = false
		errors.append("load fur mismatch %d vs %d" % [GameState.fur, fur_saved])

	if ok:
		print("SMOKE_V01_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V01_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
