extends Node
## headless 煙測 v0.9.6：紅六人 Pivot 256＋attack／建築 Pivot R1／戰鬥用 attack anim
## godot --headless --path . res://scenes/dev/smoke_v096.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	var red_ids := ["red_zhangwuji", "red_dongfang", "red_dugu", "red_saodi", "red_wangchongyang", "red_huangshang"]
	for rid in red_ids:
		var idle_path: String = "res://assets/art/heroes/red/%s_idle.png" % rid
		var walk_path: String = "res://assets/art/heroes/red/%s_walk.png" % rid
		var atk_path: String = "res://assets/art/heroes/red/%s_attack.png" % rid
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
			errors.append("load idle fail %s" % rid)
		elif idle_tex.get_width() != 256 or idle_tex.get_height() != 256:
			ok = false
			errors.append("%s idle want 256x256 got %dx%d" % [rid, idle_tex.get_width(), idle_tex.get_height()])
		var walk_tex: Texture2D = ArtPaths.load_tex(walk_path)
		if walk_tex == null:
			ok = false
			errors.append("load walk fail %s" % rid)
		elif walk_tex.get_width() != 1024 or walk_tex.get_height() != 256:
			ok = false
			errors.append("%s walk want 1024x256 got %dx%d" % [rid, walk_tex.get_width(), walk_tex.get_height()])
		var atk_tex: Texture2D = ArtPaths.load_tex(atk_path)
		if atk_tex == null:
			ok = false
			errors.append("load attack fail %s" % rid)
		elif atk_tex.get_width() != 1024 or atk_tex.get_height() != 256:
			ok = false
			errors.append("%s attack want 1024x256 got %dx%d" % [rid, atk_tex.get_width(), atk_tex.get_height()])

	## ArtPaths stem via RED_ART keys
	var p0: String = ArtPaths.hero_idle("pool_r_dongfang")
	if not p0.contains("red_dongfang"):
		ok = false
		errors.append("ArtPaths red idle stem fail: %s" % p0)
	var pa: String = ArtPaths.hero_attack("pool_r_dongfang")
	if not pa.contains("red_dongfang_attack"):
		ok = false
		errors.append("ArtPaths red attack stem fail: %s" % pa)
	if not ArtPaths.has_red_art("pool_r_dongfang"):
		ok = false
		errors.append("has_red_art false")

	## inject red hero for make_hero_frames（跟 Array heroes）
	var rh := {
		"id": "test_red_dongfang_v096",
		"template_id": "pool_r_dongfang",
		"name": "測東方",
		"weapon": "暗器",
		"rarity": "紅",
		"base_power": 48,
		"art_stem": "red_dongfang",
		"art_key": "",
		"placeholder": false,
		"status": "idle",
		"stamina": 100,
		"satiety": 100,
		"injury": 0,
		"level": 1,
	}
	rh = HeroSystem.normalize_hero(rh)
	GameState.heroes.append(rh)
	GameState.heroes_changed.emit()

	var fw: int = ArtPaths.hero_frame_px("test_red_dongfang_v096")
	if fw < 240:
		ok = false
		errors.append("red frame_px want ~256 got %d" % fw)
	var frames: SpriteFrames = ArtPaths.make_hero_frames("test_red_dongfang_v096")
	if frames == null or not frames.has_animation("idle") or not frames.has_animation("walk") or not frames.has_animation("attack"):
		ok = false
		errors.append("make_hero_frames missing anims")
	else:
		if frames.get_frame_count("walk") < 4:
			ok = false
			errors.append("walk frames %d < 4" % frames.get_frame_count("walk"))
		if frames.get_frame_count("attack") < 4:
			ok = false
			errors.append("attack frames %d < 4" % frames.get_frame_count("attack"))
	var ds: float = ArtPaths.display_scale_for("test_red_dongfang_v096", 88.0)
	## 88/256 ≈ 0.343
	if ds < 0.25 or ds > 0.45:
		ok = false
		errors.append("red combat display_scale weird %s" % str(ds))

	## buildings pivot
	for bid in ["manor", "inn", "forge"]:
		var bpath: String = ArtPaths.building_icon(bid)
		if not ArtPaths.exists(bpath):
			ok = false
			errors.append("missing building %s" % bpath)
			continue
		var btex: Texture2D = ArtPaths.load_tex(bpath)
		if btex == null or btex.get_width() < 160:
			ok = false
			errors.append("%s icon want >=160 got %s" % [bid, str(btex.get_width() if btex else 0)])

	## combat prefers attack
	var ac_src := FileAccess.get_file_as_string("res://scenes/combat/auto_combat.gd")
	if not ac_src.contains('has_animation("attack")'):
		ok = false
		errors.append("auto_combat not using attack anim")

	## version bump
	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not main_src.contains("v0.9.6"):
		ok = false
		errors.append("main.gd not bumped to v0.9.6")

	## inkdot backup present
	if not DirAccess.open("res://assets/art/heroes/red/_prev_inkdot"):
		ok = false
		errors.append("missing _prev_inkdot backup dir")

	if ok:
		print("SMOKE_V096_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V096_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
