extends Node
## headless 煙測 v0.9.9：academy 160＋pivot_r4＋食住醫／秘境前哨文案；橙紫 attack 沿用 v0.9.8
## godot --headless --path . res://scenes/dev/smoke_v099.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	var core := ["manor", "inn", "forge", "clinic", "training", "bounty", "warehouse", "academy"]
	for bid in core:
		var bpath: String = ArtPaths.building_icon(bid)
		if not ArtPaths.exists(bpath):
			ok = false
			errors.append("missing building %s" % bpath)
			continue
		var btex: Texture2D = ArtPaths.load_tex(bpath)
		if btex == null or btex.get_width() < 160 or btex.get_height() < 160:
			ok = false
			errors.append("%s icon want >=160 got %s" % [bid, str(btex.get_width() if btex else 0)])

	var layout_txt := FileAccess.get_file_as_string("res://data/buildings/layout.json")
	if not layout_txt.contains("pivot_r4"):
		ok = false
		errors.append("layout art_revision not pivot_r4")
	if not layout_txt.contains("\"id\": \"academy\""):
		ok = false
		errors.append("layout missing academy")

	var academy: Vector2 = GameState.get_building_pos("academy")
	if academy.x < 200.0 or academy.x > 360.0 or academy.y < 280.0 or academy.y > 380.0:
		ok = false
		errors.append("academy default not mid-west plateau got %s" % str(academy))
	for bid2 in core:
		if bid2 == "academy":
			continue
		var p2: Vector2 = GameState.get_building_pos(bid2)
		if academy.distance_to(p2) < 120.0:
			ok = false
			errors.append("academy too close to %s (%.0f)" % [bid2, academy.distance_to(p2)])

	## orange / purple attack still wired (v0.9.8)
	if not ArtPaths.has_orange_art("pool_o_yangguo"):
		ok = false
		errors.append("orange art missing")
	else:
		var frames: SpriteFrames = ArtPaths.make_hero_frames("pool_o_yangguo")
		if frames == null or not frames.has_animation("attack"):
			ok = false
			errors.append("orange attack anim missing")
	if not ArtPaths.has_purple_art("pool_p_weixiaobao"):
		ok = false
		errors.append("purple art missing")
	else:
		var pframes: SpriteFrames = ArtPaths.make_hero_frames("pool_p_weixiaobao")
		if pframes == null or not pframes.has_animation("attack"):
			ok = false
			errors.append("purple attack anim missing")

	var st: String = UpkeepSystem.describe_status()
	if st.find("食客棧") < 0:
		ok = false
		errors.append("describe_status missing 食客棧")
	if BuildingSystem.building_level("inn") < 1 and st.find("未建客棧") < 0:
		ok = false
		errors.append("describe_status should tip missing inn")

	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not main_src.contains("v0.9.9"):
		ok = false
		errors.append("main.gd not bumped to v0.9.9")
	if not main_src.contains("秘境·"):
		ok = false
		errors.append("dungeon btn wave label missing")
	if not main_src.contains("前哨·"):
		ok = false
		errors.append("outpost btn wave label missing")
	if not main_src.contains("describe_status"):
		ok = false
		errors.append("HUD not using describe_status")

	if ok:
		print("SMOKE_V099_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V099_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
