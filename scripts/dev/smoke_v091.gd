extends Node
## headless 煙測 v0.9.1：數值粗平衡／紫階 96 圖／稀有邊／資源列
## godot --headless --path . res://scenes/dev/smoke_v091.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- Zones balance ---
	var z1: Dictionary = GameState.get_zone("luan_shan_po")
	if int(z1.get("duration_sec", 0)) < 12:
		ok = false
		errors.append("luan_shan_po duration too short %s" % str(z1.get("duration_sec")))
	var z2: Dictionary = GameState.get_zone("du_zhao")
	if int(z2.get("duration_sec", 0)) < 16:
		ok = false
		errors.append("du_zhao duration too short %s" % str(z2.get("duration_sec")))

	## --- Building curve Lv0 < Lv3 < Lv7 ---
	var c0: Dictionary = BuildingSystem.get_upgrade_cost("inn")
	## bump inn to lv3 then compare
	GameState.add_silver(50000)
	GameState.add_wood(20000)
	while BuildingSystem.building_level("inn") < 3:
		if not BuildingSystem.upgrade("inn"):
			ok = false
			errors.append("cannot upgrade inn to 3")
			break
	var c3: Dictionary = BuildingSystem.get_upgrade_cost("inn")
	while BuildingSystem.building_level("inn") < 7:
		if not BuildingSystem.upgrade("inn"):
			ok = false
			errors.append("cannot upgrade inn to 7")
			break
	var c7: Dictionary = BuildingSystem.get_upgrade_cost("inn")
	if int(c0.silver) >= int(c3.silver) or int(c3.silver) >= int(c7.silver):
		ok = false
		errors.append("building curve not rising %d/%d/%d" % [int(c0.silver), int(c3.silver), int(c7.silver)])

	## --- Purple art files + ArtPaths ---
	var purple_stems := [
		"purple_weixiaobao", "purple_hufei", "purple_miaorenfeng", "purple_yuanchengzhi",
		"purple_diyun", "purple_shipotian", "purple_xuzhu", "purple_limochou",
		"purple_xiaolongnu", "purple_zhaomin", "purple_zhouzhiruo", "purple_yuebuqun",
	]
	for stem in purple_stems:
		var idle_path: String = "res://assets/art/heroes/purple/%s_idle.png" % stem
		var walk_path: String = "res://assets/art/heroes/purple/%s_walk.png" % stem
		if not ResourceLoader.exists(idle_path):
			ok = false
			errors.append("missing idle %s" % idle_path)
		if not ResourceLoader.exists(walk_path):
			ok = false
			errors.append("missing walk %s" % walk_path)

	var ph := {
		"id": "test_purple_wxb",
		"template_id": "pool_p_weixiaobao",
		"name": "韋小保",
		"weapon": "暗器",
		"rarity": "紫",
		"base_power": 24,
		"art_stem": "purple_weixiaobao",
		"art_key": "",
		"placeholder": false,
		"status": "idle",
		"stamina": 100,
		"satiety": 100,
		"injury": 0,
		"level": 1,
	}
	ph = HeroSystem.normalize_hero(ph)
	GameState.heroes.append(ph)
	GameState.heroes_changed.emit()

	var idle: String = ArtPaths.hero_idle("test_purple_wxb")
	if not idle.contains("/purple/purple_weixiaobao_idle"):
		ok = false
		errors.append("ArtPaths.hero_idle not purple: %s" % idle)
	if not ArtPaths.has_purple_art("test_purple_wxb"):
		ok = false
		errors.append("has_purple_art false")
	var frames: SpriteFrames = ArtPaths.make_hero_frames("test_purple_wxb")
	if frames == null or not frames.has_animation("idle") or not frames.has_animation("walk"):
		ok = false
		errors.append("make_hero_frames failed purple")
	else:
		if frames.get_frame_count("walk") < 4:
			ok = false
			errors.append("purple walk frames %d < 4" % frames.get_frame_count("walk"))
	var fw: int = ArtPaths.hero_frame_px("test_purple_wxb")
	if fw < 90 or fw > 110:
		ok = false
		errors.append("purple frame_px expected ~96 got %d" % fw)
	var ds_list: float = ArtPaths.display_scale_for("test_purple_wxb", 72.0)
	## 72/96 = 0.75
	if ds_list < 0.7 or ds_list > 0.8:
		ok = false
		errors.append("purple list display_scale weird %s" % str(ds_list))
	var ds_combat: float = ArtPaths.display_scale_for("test_purple_wxb", 88.0)
	## 88/96 ≈ 0.916
	if ds_combat < 0.85 or ds_combat > 0.98:
		ok = false
		errors.append("purple combat display_scale weird %s" % str(ds_combat))

	## Pool: 12 purple, art_stem, not placeholder
	var pcount := 0
	for h in GachaSystem.heroes_of_rarity("紫"):
		pcount += 1
		var hh: Dictionary = h as Dictionary
		if str(hh.get("art_stem", "")) == "":
			ok = false
			errors.append("purple pool missing art_stem %s" % str(hh.get("name", "")))
		if bool(hh.get("placeholder", true)):
			ok = false
			errors.append("purple pool still placeholder %s" % str(hh.get("name", "")))
	if pcount != 12:
		ok = false
		errors.append("purple pool count %d != 12" % pcount)

	## Rarity colors exist
	for r in ["白", "綠", "藍", "紫", "橙", "紅"]:
		var c: Color = HeroPortrait.rarity_color(r)
		if c.a < 0.5:
			ok = false
			errors.append("rarity color bad %s" % r)

	if ok:
		print("SMOKE_V091_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V091_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
