extends Node
## headless 煙測 v0.10.1：紫 walk／attack AI 條＋精英怪高密度優先
## godot --headless --path . res://scenes/dev/smoke_v011.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	var purple_stems := [
		"purple_weixiaobao", "purple_hufei", "purple_miaorenfeng", "purple_yuanchengzhi",
		"purple_diyun", "purple_shipotian", "purple_xuzhu", "purple_limochou",
		"purple_xiaolongnu", "purple_zhaomin", "purple_zhouzhiruo", "purple_yuebuqun",
	]
	for stem in purple_stems:
		var walk_path: String = "res://assets/art/heroes/purple/%s_walk.png" % stem
		var atk_path: String = "res://assets/art/heroes/purple/%s_attack.png" % stem
		var walk_tex: Texture2D = ArtPaths.load_tex(walk_path)
		var atk_tex: Texture2D = ArtPaths.load_tex(atk_path)
		if walk_tex == null or walk_tex.get_width() != 384 or walk_tex.get_height() != 96:
			ok = false
			errors.append("%s walk want 384x96" % stem)
		if atk_tex == null or atk_tex.get_width() != 384 or atk_tex.get_height() != 96:
			ok = false
			errors.append("%s attack want 384x96" % stem)

	## inject purple hero → make_hero_frames has attack
	var ph := {
		"id": "test_purple_wb_v011",
		"template_id": "pool_p_weixiaobao",
		"art_stem": "purple_weixiaobao",
		"name": "測韋",
		"rarity": "purple",
		"status": "idle",
		"level": 1,
		"base_power": 12,
		"stamina": 100,
		"max_stamina": 100,
		"satiety": 100,
		"injury": 0,
	}
	GameState.heroes.append(HeroSystem.normalize_hero(ph))
	var frames: SpriteFrames = ArtPaths.make_hero_frames("test_purple_wb_v011")
	if frames == null or not frames.has_animation("attack") or frames.get_frame_count("attack") < 4:
		ok = false
		errors.append("purple make_hero_frames missing 4-frame attack")
	if not frames.has_animation("walk") or frames.get_frame_count("walk") < 4:
		ok = false
		errors.append("purple make_hero_frames missing 4-frame walk")

	var elite := {
		"snake": {"idle": Vector2i(64, 64), "attack": Vector2i(256, 64), "stem": "monster_snake"},
		"python": {"idle": Vector2i(96, 96), "attack": Vector2i(384, 96), "stem": "monster_python"},
		"wolf_king": {"idle": Vector2i(96, 96), "attack": Vector2i(384, 96), "stem": "monster_wolf_king"},
		"bandit_chief": {"idle": Vector2i(96, 96), "attack": Vector2i(384, 96), "stem": "monster_bandit_chief"},
	}
	for kind in elite.keys():
		var spec: Dictionary = elite[kind]
		var stem: String = str(spec["stem"])
		if ArtPaths.monster_stem(kind) != stem:
			ok = false
			errors.append("%s stem want %s got %s" % [kind, stem, ArtPaths.monster_stem(kind)])
		var idle_path: String = ArtPaths.monster_idle(kind)
		var atk_path: String = ArtPaths.monster_attack(kind)
		if not idle_path.contains(stem):
			ok = false
			errors.append("%s idle path not elite: %s" % [kind, idle_path])
		if not atk_path.contains(stem):
			ok = false
			errors.append("%s attack path not elite: %s" % [kind, atk_path])
		var idle_tex: Texture2D = ArtPaths.load_tex(idle_path)
		var atk_tex: Texture2D = ArtPaths.load_tex(atk_path)
		var iw: Vector2i = spec["idle"]
		var aw: Vector2i = spec["attack"]
		if idle_tex == null or idle_tex.get_width() != iw.x or idle_tex.get_height() != iw.y:
			ok = false
			errors.append("%s idle size" % kind)
		if atk_tex == null or atk_tex.get_width() != aw.x or atk_tex.get_height() != aw.y:
			ok = false
			errors.append("%s attack size" % kind)
		## old low-res still on disk but unused for these kinds
		if kind == "wolf_king" and idle_path.contains("monster_wolf_idle"):
			ok = false
			errors.append("wolf_king fell back to old wolf 64")
		if kind == "bandit_chief" and idle_path.contains("monster_bandit_idle"):
			ok = false
			errors.append("bandit_chief fell back to old bandit 64")

	## dungeon boss kinds + outpost boss mix
	var ddef: Dictionary = DungeonSystem.dungeon_def()
	var boss_kinds: PackedStringArray = PackedStringArray()
	for wv in ddef.get("waves", []) as Array:
		if bool((wv as Dictionary).get("boss", false)):
			for ev in (wv as Dictionary).get("enemies", []) as Array:
				boss_kinds.append(str((ev as Dictionary).get("kind", "")))
	if not ("wolf_king" in boss_kinds and "bandit_chief" in boss_kinds):
		ok = false
		errors.append("dungeon boss kinds missing elite")

	var odef: Dictionary = OutpostSystem.def()
	var oboss: PackedStringArray = PackedStringArray()
	for wv2 in odef.get("waves", []) as Array:
		var wd: Dictionary = wv2 as Dictionary
		if bool(wd.get("boss", false)):
			for m in wd.get("mix", []) as Array:
				oboss.append(str((m as Dictionary).get("kind", "")))
	if not ("bandit_chief" in oboss and "wolf_king" in oboss):
		ok = false
		errors.append("outpost boss mix missing elite got %s" % ",".join(oboss))

	## old 64 still present (unused for elite kinds)
	if not FileAccess.file_exists("res://assets/art/monsters/monster_wolf_idle.png"):
		ok = false
		errors.append("old wolf 64 should remain on disk")
	if not FileAccess.file_exists("res://assets/art/monsters/monster_bandit_idle.png"):
		ok = false
		errors.append("old bandit 64 should remain on disk")

	if ok:
		print("SMOKE_V011_OK")
	else:
		print("SMOKE_V011_FAIL")
		for e in errors:
			print("  ERR: ", e)
	await get_tree().process_frame
	get_tree().quit(0 if ok else 1)
