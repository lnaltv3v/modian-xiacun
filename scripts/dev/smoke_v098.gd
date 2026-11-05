extends Node
## headless 煙測 v0.9.8：橙／紫 Pivot 高密度 idle＋walk＋attack
## godot --headless --path . res://scenes/dev/smoke_v098.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	var orange_stems := [
		"orange_yangguo", "orange_guojing", "orange_linghuzhong", "orange_qiaofeng",
		"orange_zhangsanfeng", "orange_fengqingyang", "orange_huangyaoshi", "orange_ouyangfeng",
		"orange_hongqigong", "orange_yideng", "orange_zhoubotong", "orange_miejueshitai",
	]
	for stem in orange_stems:
		var idle_path: String = "res://assets/art/heroes/orange/%s_idle.png" % stem
		var walk_path: String = "res://assets/art/heroes/orange/%s_walk.png" % stem
		var atk_path: String = "res://assets/art/heroes/orange/%s_attack.png" % stem
		if not FileAccess.file_exists(idle_path):
			ok = false
			errors.append("missing idle %s" % idle_path)
		if not FileAccess.file_exists(walk_path):
			ok = false
			errors.append("missing walk %s" % walk_path)
		if not FileAccess.file_exists(atk_path):
			ok = false
			errors.append("missing attack %s" % atk_path)
		var idle_tex: Texture2D = ArtPaths.load_tex(idle_path)
		if idle_tex == null:
			ok = false
			errors.append("load idle fail %s" % stem)
		elif idle_tex.get_width() != 128 or idle_tex.get_height() != 128:
			ok = false
			errors.append("%s idle want 128x128 got %dx%d" % [stem, idle_tex.get_width(), idle_tex.get_height()])
		var walk_tex: Texture2D = ArtPaths.load_tex(walk_path)
		if walk_tex == null:
			ok = false
			errors.append("load walk fail %s" % stem)
		elif walk_tex.get_width() != 512 or walk_tex.get_height() != 128:
			ok = false
			errors.append("%s walk want 512x128 got %dx%d" % [stem, walk_tex.get_width(), walk_tex.get_height()])
		var atk_tex: Texture2D = ArtPaths.load_tex(atk_path)
		if atk_tex == null:
			ok = false
			errors.append("load attack fail %s" % stem)
		elif atk_tex.get_width() != 512 or atk_tex.get_height() != 128:
			ok = false
			errors.append("%s attack want 512x128 got %dx%d" % [stem, atk_tex.get_width(), atk_tex.get_height()])

	var purple_stems := [
		"purple_weixiaobao", "purple_hufei", "purple_miaorenfeng", "purple_yuanchengzhi",
		"purple_diyun", "purple_shipotian", "purple_xuzhu", "purple_limochou",
		"purple_xiaolongnu", "purple_zhaomin", "purple_zhouzhiruo", "purple_yuebuqun",
	]
	for stem in purple_stems:
		var idle_path: String = "res://assets/art/heroes/purple/%s_idle.png" % stem
		var walk_path: String = "res://assets/art/heroes/purple/%s_walk.png" % stem
		var atk_path: String = "res://assets/art/heroes/purple/%s_attack.png" % stem
		if not FileAccess.file_exists(idle_path):
			ok = false
			errors.append("missing idle %s" % idle_path)
		if not FileAccess.file_exists(walk_path):
			ok = false
			errors.append("missing walk %s" % walk_path)
		if not FileAccess.file_exists(atk_path):
			ok = false
			errors.append("missing attack %s" % atk_path)
		var idle_tex: Texture2D = ArtPaths.load_tex(idle_path)
		if idle_tex == null:
			ok = false
			errors.append("load idle fail %s" % stem)
		elif idle_tex.get_width() != 96 or idle_tex.get_height() != 96:
			ok = false
			errors.append("%s idle want 96x96 got %dx%d" % [stem, idle_tex.get_width(), idle_tex.get_height()])
		var walk_tex: Texture2D = ArtPaths.load_tex(walk_path)
		if walk_tex == null:
			ok = false
			errors.append("load walk fail %s" % stem)
		elif walk_tex.get_width() != 384 or walk_tex.get_height() != 96:
			ok = false
			errors.append("%s walk want 384x96 got %dx%d" % [stem, walk_tex.get_width(), walk_tex.get_height()])
		var atk_tex: Texture2D = ArtPaths.load_tex(atk_path)
		if atk_tex == null:
			ok = false
			errors.append("load attack fail %s" % stem)
		elif atk_tex.get_width() != 384 or atk_tex.get_height() != 96:
			ok = false
			errors.append("%s attack want 384x96 got %dx%d" % [stem, atk_tex.get_width(), atk_tex.get_height()])

	## ArtPaths stems
	var po: String = ArtPaths.hero_idle("pool_o_yangguo")
	## pool ids need hero in roster — inject
	var oh := {
		"id": "test_orange_yg_v098",
		"template_id": "pool_o_yangguo",
		"name": "楊菓",
		"weapon": "拳腳",
		"rarity": "橙",
		"base_power": 36,
		"art_stem": "orange_yangguo",
		"art_key": "",
		"placeholder": false,
		"status": "idle",
		"stamina": 100,
		"satiety": 100,
		"injury": 0,
		"level": 1,
	}
	oh = HeroSystem.normalize_hero(oh)
	GameState.heroes.append(oh)
	var ph := {
		"id": "test_purple_wxb_v098",
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

	var idle_o: String = ArtPaths.hero_idle("test_orange_yg_v098")
	if not idle_o.contains("/orange/orange_yangguo_idle"):
		ok = false
		errors.append("ArtPaths orange idle fail: %s" % idle_o)
	var atk_o: String = ArtPaths.hero_attack("test_orange_yg_v098")
	if not atk_o.contains("orange_yangguo_attack"):
		ok = false
		errors.append("ArtPaths orange attack fail: %s" % atk_o)
	if not ArtPaths.has_orange_art("test_orange_yg_v098"):
		ok = false
		errors.append("has_orange_art false")

	var idle_p: String = ArtPaths.hero_idle("test_purple_wxb_v098")
	if not idle_p.contains("/purple/purple_weixiaobao_idle"):
		ok = false
		errors.append("ArtPaths purple idle fail: %s" % idle_p)
	var atk_p: String = ArtPaths.hero_attack("test_purple_wxb_v098")
	if not atk_p.contains("purple_weixiaobao_attack"):
		ok = false
		errors.append("ArtPaths purple attack fail: %s" % atk_p)
	if not ArtPaths.has_purple_art("test_purple_wxb_v098"):
		ok = false
		errors.append("has_purple_art false")

	var fw_o: int = ArtPaths.hero_frame_px("test_orange_yg_v098")
	if fw_o < 120 or fw_o > 140:
		ok = false
		errors.append("orange frame_px want ~128 got %d" % fw_o)
	var frames_o: SpriteFrames = ArtPaths.make_hero_frames("test_orange_yg_v098")
	if frames_o == null or not frames_o.has_animation("idle") or not frames_o.has_animation("walk") or not frames_o.has_animation("attack"):
		ok = false
		errors.append("orange make_hero_frames missing anims")
	else:
		if frames_o.get_frame_count("walk") < 4:
			ok = false
			errors.append("orange walk frames %d < 4" % frames_o.get_frame_count("walk"))
		if frames_o.get_frame_count("attack") < 4:
			ok = false
			errors.append("orange attack frames %d < 4" % frames_o.get_frame_count("attack"))

	var fw_p: int = ArtPaths.hero_frame_px("test_purple_wxb_v098")
	if fw_p < 90 or fw_p > 110:
		ok = false
		errors.append("purple frame_px want ~96 got %d" % fw_p)
	var frames_p: SpriteFrames = ArtPaths.make_hero_frames("test_purple_wxb_v098")
	if frames_p == null or not frames_p.has_animation("idle") or not frames_p.has_animation("walk") or not frames_p.has_animation("attack"):
		ok = false
		errors.append("purple make_hero_frames missing anims")
	else:
		if frames_p.get_frame_count("walk") < 4:
			ok = false
			errors.append("purple walk frames %d < 4" % frames_p.get_frame_count("walk"))
		if frames_p.get_frame_count("attack") < 4:
			ok = false
			errors.append("purple attack frames %d < 4" % frames_p.get_frame_count("attack"))

	## combat prefers attack
	var ac_src := FileAccess.get_file_as_string("res://scenes/combat/auto_combat.gd")
	if not ac_src.contains('has_animation("attack")'):
		ok = false
		errors.append("auto_combat not using attack anim")

	## inkdot backups
	if not DirAccess.open("res://assets/art/heroes/orange/_prev_inkdot"):
		ok = false
		errors.append("missing orange _prev_inkdot")
	if not DirAccess.open("res://assets/art/heroes/purple/_prev_inkdot"):
		ok = false
		errors.append("missing purple _prev_inkdot")

	## version bump
	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not main_src.contains("v0.9.8"):
		ok = false
		errors.append("main.gd not bumped to v0.9.8")

	## silence unused
	if po != "":
		pass

	if ok:
		print("SMOKE_V098_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V098_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
