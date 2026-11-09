extends Node
## headless 煙測 v0.17.0：煙測版本 pin 放寬、舊存檔升級；綠階 attack 接入見 v0.18.1
## godot --headless --path . res://scenes/dev/smoke_v170.tscn

const SmokeUtil = preload("res://scripts/dev/SmokeUtil.gd")

func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()
	AcademySystem.force_reload()

	var main_src := SmokeUtil.main_src()
	if not SmokeUtil.version_at_least(main_src, 0, 17, 0):
		ok = false
		errors.append("main.gd title should be >= v0.17.0")
	if not ("工程" in main_src or "兼容" in main_src or "smoke" in main_src.to_lower() or "v0.17.0" in main_src):
		## soft marker — title bump is the hard check
		pass

	## SmokeUtil must accept newer-than-min pins
	if not SmokeUtil.version_at_least("墨點俠村 · v0.17.0", 0, 13, 0):
		ok = false
		errors.append("SmokeUtil should accept v0.17 >= v0.13")
	if SmokeUtil.version_at_least("墨點俠村 · v0.12.0", 0, 13, 0):
		ok = false
		errors.append("SmokeUtil should reject v0.12 < v0.13")

	if int(GameState.SAVE_VERSION) < 14:
		ok = false
		errors.append("SAVE_VERSION should stay >= 14 got %d" % int(GameState.SAVE_VERSION))

	## --- old-save upgrade path (missing academy / camp / tutorial keys) ---
	var old_state: Dictionary = {
		"silver": 123,
		"wood": 45,
		"fur": 6,
		"iron": 7,
		"heroes": GameState.heroes.duplicate(true),
		"buildings": GameState.buildings.duplicate(true),
		## deliberately omit: academy_unlocked_nodes, camp_stations, tutorial_step
	}
	var migrated: Dictionary = SaveManager.migrate_state(old_state, 10)
	if not migrated.has("camp_stations") or typeof(migrated["camp_stations"]) != TYPE_DICTIONARY:
		ok = false
		errors.append("migrate should default camp_stations")
	if not migrated.has("academy_unlocked_nodes") or typeof(migrated["academy_unlocked_nodes"]) != TYPE_ARRAY:
		ok = false
		errors.append("migrate should default academy_unlocked_nodes")
	if int(migrated.get("tutorial_step", -1)) != 0:
		ok = false
		errors.append("migrate missing tutorial_step should become 0 got %s" % str(migrated.get("tutorial_step")))

	GameState.load_from_dict(migrated)
	AcademySystem.force_reload()
	if GameState.tutorial_step != 0:
		ok = false
		errors.append("loaded tutorial_step want 0 got %d" % GameState.tutorial_step)
	if typeof(GameState.camp_stations) != TYPE_DICTIONARY:
		ok = false
		errors.append("camp_stations not dict after load")
	if not AcademySystem.is_node_unlocked("n_tiegu"):
		ok = false
		errors.append("academy starter n_tiegu should unlock after reload")

	## round-trip via SaveManager file path
	SaveManager.clear_save()
	## write a raw old JSON (version 10, sparse state)
	var raw: Dictionary = {
		"version": 10,
		"saved_at": "old",
		"state": {
			"silver": 50,
			"wood": 20,
			"heroes": GameState.heroes.duplicate(true),
			"buildings": GameState.buildings.duplicate(true),
		},
	}
	var f: FileAccess = FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	if f == null:
		ok = false
		errors.append("cannot write probe save")
	else:
		f.store_string(JSON.stringify(raw, "\t"))
		f = null
		if not SaveManager.load_game():
			ok = false
			errors.append("load_game failed on sparse old save")
		else:
			if GameState.tutorial_step != 0:
				ok = false
				errors.append("file-load tutorial_step want 0 got %d" % GameState.tutorial_step)
			if typeof(GameState.camp_stations) != TYPE_DICTIONARY:
				ok = false
				errors.append("file-load camp_stations missing")
			if typeof(GameState.academy_unlocked_nodes) != TYPE_ARRAY:
				ok = false
				errors.append("file-load academy_unlocked_nodes missing")
			if not AcademySystem.is_node_unlocked("n_tiegu"):
				ok = false
				errors.append("file-load should ensure academy starter")

	## --- green attack：v0.18.1 起正式接入 green/；此煙測唔再禁止（見 smoke_v181）---
	var green_ids: PackedStringArray = PackedStringArray([
		"hero_quan_aniu", "hero_dao_atie", "hero_jian_aqing",
		"hero_qiang_achang", "hero_gun_dali", "hero_anqi_azhen",
	])
	for gid in green_ids:
		var ap: String = ArtPaths.hero_attack(gid)
		if ap != "" and ("/heroes/red/" not in ap) and ("/heroes/orange/" not in ap) and ("/heroes/purple/" not in ap) and ("/heroes/green/" not in ap) and ("/heroes/hero_" not in ap):
			ok = false
			errors.append("unexpected green attack path %s" % ap)

	## rarity attack still resolves under red/orange/purple when art present
	var red_probe := ""
	for hid in ["pool_r_dongfang", "red_dongfang"]:
		var rp: String = ArtPaths.hero_attack(hid)
		if rp != "":
			red_probe = rp
			break
	if red_probe != "" and ("/heroes/red/" not in red_probe):
		ok = false
		errors.append("red attack should stay under red/ got %s" % red_probe)

	## load_tex should not require bare file without import
	var sm_src := FileAccess.get_file_as_string("res://scripts/autoload/SaveManager.gd")
	if not sm_src.contains("migrate_state"):
		ok = false
		errors.append("SaveManager missing migrate_state")
	var ap_src := FileAccess.get_file_as_string("res://scripts/constants/ArtPaths.gd")
	if not ap_src.contains("_first_existing_imported"):
		ok = false
		errors.append("ArtPaths missing _first_existing_imported")
	if not ap_src.contains("ResourceLoader.exists(path)"):
		ok = false
		errors.append("ArtPaths load_tex should gate on ResourceLoader.exists")

	SaveManager.clear_save()

	if ok:
		print("SMOKE_V170_OK")
	else:
		print("SMOKE_V170_FAIL")
		for e in errors:
			print("  - ", e)
	get_tree().quit(0 if ok else 1)
