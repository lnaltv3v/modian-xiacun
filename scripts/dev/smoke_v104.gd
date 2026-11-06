extends Node
## headless 煙測 v0.10.4：師門書院 Pivot R3 academy drop-in
## godot --headless --path . res://scenes/dev/smoke_v104.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	var path: String = ArtPaths.building_icon("academy")
	if path != ArtPaths.BUILDINGS_DIR + "academy.png":
		ok = false
		errors.append("ArtPaths.building_icon academy path")
	if not ArtPaths.exists(path):
		ok = false
		errors.append("missing %s" % path)
	else:
		var tex: Texture2D = ArtPaths.load_tex(path)
		if tex == null or tex.get_width() != 160 or tex.get_height() != 160:
			ok = false
			errors.append("academy want 160x160")

	## R3 交付約 17KB；唔應仲係 R5 密打磨大檔
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		ok = false
		errors.append("cannot open academy png")
	else:
		var sz: int = f.get_length()
		f.close()
		if sz < 12000 or sz > 22000:
			ok = false
			errors.append("academy png size not R3-like got %d" % sz)

	var layout_txt := FileAccess.get_file_as_string("res://data/buildings/layout.json")
	if not layout_txt.contains("academy"):
		ok = false
		errors.append("layout missing academy")
	if not layout_txt.contains("pivot_r5_academy_r3"):
		ok = false
		errors.append("layout art_revision not pivot_r5_academy_r3")

	var academy: Vector2 = GameState.get_building_pos("academy")
	if academy.x < 200.0 or academy.x > 360.0 or academy.y < 280.0 or academy.y > 380.0:
		ok = false
		errors.append("academy default not mid-west plateau got %s" % str(academy))

	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not ("v0.10.4" in main_src):
		ok = false
		errors.append("main.gd not bumped to v0.10.4")

	if ok:
		print("SMOKE_V104_OK")
	else:
		print("SMOKE_V104_FAIL")
		for e in errors:
			print("  - ", e)
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if ok else 1)
