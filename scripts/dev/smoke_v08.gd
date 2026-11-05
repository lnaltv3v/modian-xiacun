extends Node
const _OutpostScript = preload("res://scripts/systems/OutpostSystem.gd")
## headless 煙測 v0.8：紅階圖／自動戰鬥場景／前哨三波
## godot --headless --path . res://scenes/dev/smoke_v08.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- Red art stems ---
	var expected := {
		"pool_r_zhangwuji": "red_zhangwuji",
		"pool_r_dongfang": "red_dongfang",
		"pool_r_dugu": "red_dugu",
		"pool_r_saodi": "red_saodi",
		"pool_r_wangchongyang": "red_wangchongyang",
		"pool_r_huangshang": "red_huangshang",
	}
	for tid in expected.keys():
		var stem: String = str(expected[tid])
		var idle_path: String = "res://assets/art/heroes/red/%s_idle.png" % stem
		var walk_path: String = "res://assets/art/heroes/red/%s_walk.png" % stem
		if not ResourceLoader.exists(idle_path):
			ok = false
			errors.append("missing idle %s" % idle_path)
		if not ResourceLoader.exists(walk_path):
			ok = false
			errors.append("missing walk %s" % walk_path)

	## Inject a red hero and resolve via ArtPaths
	var red_hero := {
		"id": "test_red_zwj",
		"template_id": "pool_r_zhangwuji",
		"name": "張無記",
		"weapon": "拳腳",
		"rarity": "紅",
		"base_power": 48,
		"art_stem": "red_zhangwuji",
		"art_key": "",
		"placeholder": false,
		"status": "idle",
		"stamina": 100,
		"satiety": 100,
		"injury": 0,
		"level": 1,
	}
	red_hero = HeroSystem.normalize_hero(red_hero)
	GameState.heroes.append(red_hero)
	GameState.heroes_changed.emit()
	var idle: String = ArtPaths.hero_idle("test_red_zwj")
	if not idle.contains("/red/red_zhangwuji_idle"):
		ok = false
		errors.append("ArtPaths.hero_idle not red: %s" % idle)
	if not ArtPaths.has_red_art("test_red_zwj"):
		ok = false
		errors.append("has_red_art false")
	var frames: SpriteFrames = ArtPaths.make_hero_frames("test_red_zwj")
	if frames == null or not frames.has_animation("idle") or not frames.has_animation("walk"):
		ok = false
		errors.append("make_hero_frames failed for red")
	else:
		var walk_count: int = frames.get_frame_count("walk")
		if walk_count < 4:
			ok = false
			errors.append("red walk frames %d < 4" % walk_count)
	var fw: int = ArtPaths.hero_frame_px("test_red_zwj")
	if fw < 200:
		ok = false
		errors.append("red frame_px expected ~256 got %d" % fw)
	var ds: float = ArtPaths.display_scale_for("test_red_zwj", 72.0)
	if ds > 0.5 or ds < 0.2:
		ok = false
		errors.append("display_scale weird %s" % str(ds))

	## Gacha pool red entries have art_stem
	for h in GachaSystem.heroes_of_rarity("紅"):
		var hh: Dictionary = h as Dictionary
		if str(hh.get("art_stem", "")) == "":
			ok = false
			errors.append("red pool missing art_stem %s" % str(hh.get("name", "")))
		if bool(hh.get("placeholder", true)):
			ok = false
			errors.append("red pool still placeholder %s" % str(hh.get("name", "")))

	## AutoCombat scene
	var ac_res: Resource = load("res://scenes/combat/auto_combat.tscn")
	if ac_res == null:
		ok = false
		errors.append("auto_combat.tscn missing")
	else:
		var ac: Node = (ac_res as PackedScene).instantiate()
		if ac == null or not ac.has_method("play"):
			ok = false
			errors.append("auto_combat has no play()")
		else:
			ac.free()

	## Outpost 3 waves
	GameState.add_silver(2000)
	GameState.add_wood(1000)
	while BuildingSystem.building_level("bounty") < 2:
		if not BuildingSystem.upgrade("bounty"):
			ok = false
			errors.append("bounty up fail")
			break
	while BuildingSystem.building_level("manor") < 2:
		if not BuildingSystem.upgrade("manor"):
			ok = false
			errors.append("manor up fail")
			break
	if _OutpostScript.wave_count() < 3:
		ok = false
		errors.append("outpost wave_count %d < 3" % _OutpostScript.wave_count())
	var party: Array = []
	for i in range(mini(3, GameState.heroes.size())):
		var hx: Dictionary = (GameState.heroes[i] as Dictionary).duplicate(true)
		hx["status"] = "idle"
		hx["stamina"] = 100
		hx["satiety"] = 100
		hx["injury"] = 0
		GameState.heroes[i] = HeroSystem.normalize_hero(hx)
		party.append(str(hx.get("id", "")))
	var defres: Dictionary = _OutpostScript.run_defense(party)
	if not bool(defres.get("ok", false)):
		ok = false
		errors.append("run_defense fail: %s" % str(defres.get("reason", "")))
	else:
		var waves: Array = defres.get("waves", []) as Array
		if waves.is_empty():
			ok = false
			errors.append("outpost no waves")
		else:
			var w0: Dictionary = waves[0] as Dictionary
			if not w0.has("enemies") or (w0.get("enemies", []) as Array).is_empty():
				ok = false
				errors.append("wave0 no enemies for auto combat")

	## Hunt still emits enemies for auto combat
	for i2 in range(GameState.heroes.size()):
		var hy: Dictionary = (GameState.heroes[i2] as Dictionary).duplicate(true)
		if str(hy.get("id", "")) == "test_red_zwj":
			continue
		hy["status"] = "idle"
		hy["stamina"] = 100
		hy["satiety"] = 100
		hy["injury"] = 0
		GameState.heroes[i2] = HeroSystem.normalize_hero(hy)
	var hid0: String = ""
	for hv in GameState.heroes:
		var hd: Dictionary = hv as Dictionary
		if str(hd.get("id", "")) != "test_red_zwj" and HeroSystem.can_hunt(hd):
			hid0 = str(hd.get("id", ""))
			break
	var dispatch := DispatchSystem.new()
	add_child(dispatch)
	var got_finish := {"v": false, "enemies": 0}
	dispatch.hunt_finished.connect(func(rw: Dictionary) -> void:
		got_finish["v"] = true
		got_finish["enemies"] = (rw.get("enemies", []) as Array).size()
	)
	if hid0 != "":
		var hr: Dictionary = dispatch.start_hunt([hid0], "luan_shan_po")
		if bool(hr.get("ok", false)):
			var hunt: Dictionary = (GameState.active_hunts[0] as Dictionary).duplicate(true)
			hunt["return_at"] = 0
			GameState.active_hunts[0] = hunt
			dispatch.resolve_due_hunts()
			if not bool(got_finish["v"]):
				ok = false
				errors.append("hunt_finished not fired")
			elif int(got_finish["enemies"]) < 1:
				ok = false
				errors.append("hunt no enemies")

	if ok:
		print("SMOKE_V08_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V08_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
