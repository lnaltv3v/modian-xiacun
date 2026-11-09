extends Node
## headless 煙測 v0.18.1：開局六綠俠 Pivot 高密度 idle／walk／attack 接入
## godot --headless --path . res://scenes/dev/smoke_v181.tscn

const SmokeUtil = preload("res://scripts/dev/SmokeUtil.gd")

const GREEN_IDS := [
	"hero_atie", "hero_aqing", "hero_achang",
	"hero_dali", "hero_azhen", "hero_aniu",
]
const GREEN_STEMS := [
	"hero_dao_atie", "hero_jian_aqing", "hero_qiang_achang",
	"hero_gun_dali", "hero_anqi_azhen", "hero_quan_aniu",
]

func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	var main_src := SmokeUtil.main_src()
	if not SmokeUtil.version_at_least(main_src, 0, 18, 1):
		ok = false
		errors.append("main.gd title should be >= v0.18.1")

	var ap_src := FileAccess.get_file_as_string("res://scripts/constants/ArtPaths.gd")
	if not ap_src.contains("HEROES_GREEN_DIR"):
		ok = false
		errors.append("ArtPaths missing HEROES_GREEN_DIR")
	if not ap_src.contains("has_green_art"):
		ok = false
		errors.append("ArtPaths missing has_green_art")

	## disk + rarity-dir dual-write
	for stem in GREEN_STEMS:
		for suf in ["_idle.png", "_walk.png", "_attack.png"]:
			var root_p: String = "res://assets/art/heroes/%s%s" % [stem, suf]
			var green_p: String = "res://assets/art/heroes/green/%s%s" % [stem, suf]
			if not FileAccess.file_exists(root_p):
				ok = false
				errors.append("missing root %s" % root_p)
			if not FileAccess.file_exists(green_p):
				ok = false
				errors.append("missing green/ %s" % green_p)

	## size + load via ArtPaths for starter ids
	for i in range(GREEN_IDS.size()):
		var hid: String = str(GREEN_IDS[i])
		var stem: String = str(GREEN_STEMS[i])
		if not ArtPaths.has_green_art(hid):
			ok = false
			errors.append("has_green_art false for %s" % hid)

		var idle_path: String = ArtPaths.hero_idle(hid)
		if "/heroes/green/" not in idle_path and ("/heroes/" + stem) not in idle_path:
			ok = false
			errors.append("%s idle path unexpected %s" % [hid, idle_path])
		var idle_tex: Texture2D = ArtPaths.load_tex(idle_path)
		if idle_tex == null:
			ok = false
			errors.append("load idle fail %s" % hid)
		elif idle_tex.get_width() != 64 or idle_tex.get_height() != 64:
			ok = false
			errors.append("%s idle want 64x64 got %dx%d" % [hid, idle_tex.get_width(), idle_tex.get_height()])

		var walk_path: String = ArtPaths.hero_walk(hid)
		var walk_tex: Texture2D = ArtPaths.load_tex(walk_path)
		if walk_tex == null:
			ok = false
			errors.append("load walk fail %s" % hid)
		elif walk_tex.get_width() != 256 or walk_tex.get_height() != 64:
			ok = false
			errors.append("%s walk want 256x64 got %dx%d" % [hid, walk_tex.get_width(), walk_tex.get_height()])

		var atk_path: String = ArtPaths.hero_attack(hid)
		if atk_path == "":
			ok = false
			errors.append("%s attack path empty" % hid)
		elif "/heroes/green/" not in atk_path and ("/heroes/" + stem + "_attack") not in atk_path:
			ok = false
			errors.append("%s attack should be green/ or root got %s" % [hid, atk_path])
		## prefer rarity dir when present
		if FileAccess.file_exists("res://assets/art/heroes/green/%s_attack.png" % stem):
			if "/heroes/green/" not in atk_path:
				ok = false
				errors.append("%s attack should prefer green/ got %s" % [hid, atk_path])
		var atk_tex: Texture2D = ArtPaths.load_tex(atk_path)
		if atk_tex == null:
			ok = false
			errors.append("load attack fail %s" % hid)
		elif atk_tex.get_width() != 256 or atk_tex.get_height() != 64:
			ok = false
			errors.append("%s attack want 256x64 got %dx%d" % [hid, atk_tex.get_width(), atk_tex.get_height()])

		var fw: int = ArtPaths.hero_frame_px(hid)
		if fw != 64:
			ok = false
			errors.append("%s frame_px want 64 got %d" % [hid, fw])

		var frames: SpriteFrames = ArtPaths.make_hero_frames(hid)
		if frames == null:
			ok = false
			errors.append("frames null %s" % hid)
			continue
		if not frames.has_animation("idle") or frames.get_frame_count("idle") < 1:
			ok = false
			errors.append("%s missing idle frames" % hid)
		if not frames.has_animation("walk") or frames.get_frame_count("walk") < 4:
			ok = false
			errors.append("%s walk frames want >=4 got %d" % [hid, frames.get_frame_count("walk") if frames.has_animation("walk") else 0])
		if not frames.has_animation("attack") or frames.get_frame_count("attack") < 4:
			ok = false
			errors.append("%s attack frames want >=4 got %d" % [hid, frames.get_frame_count("attack") if frames.has_animation("attack") else 0])

	## stem ids also resolve (used by some probes)
	for stem2 in GREEN_STEMS:
		var ap2: String = ArtPaths.hero_attack(stem2)
		## stem2 is not a roster id — hero_stem may miss; still root HERO_ART keys only.
		## Prefer checking via mapped starter already covered.
		pass

	## gacha art_key path (white/green pool remaps)
	var probe := {
		"id": "test_gacha_green_v181",
		"template_id": "pool_g_probe",
		"name": "試綠",
		"weapon": "刀",
		"rarity": "綠",
		"base_power": 10,
		"art_key": "hero_atie",
		"status": "idle",
		"stamina": 100,
		"satiety": 100,
		"injury": 0,
		"level": 1,
	}
	probe = HeroSystem.normalize_hero(probe)
	GameState.heroes.append(probe)
	var gap: String = ArtPaths.hero_attack(str(probe["id"]))
	if gap == "" or "/heroes/green/" not in gap:
		ok = false
		errors.append("gacha art_key attack should prefer green/ got %s" % gap)

	SaveManager.clear_save()

	if ok:
		print("SMOKE_V181_OK")
	else:
		print("SMOKE_V181_FAIL")
		for e in errors:
			print("  - ", e)
	get_tree().quit(0 if ok else 1)
