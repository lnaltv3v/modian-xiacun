extends Node
## headless 煙測 v0.9.4：飄字腳本／抽卡閃光／存檔備份／紅階 facefix 檔
## godot --headless --path . res://scenes/dev/smoke_v094.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- red facefix files present & different from optional bak ---
	var red_ids := ["red_zhangwuji", "red_dongfang", "red_dugu", "red_saodi", "red_wangchongyang", "red_huangshang"]
	for rid in red_ids:
		var idle_path: String = "res://assets/art/heroes/red/%s_idle.png" % rid
		if not ResourceLoader.exists(idle_path) and not FileAccess.file_exists(idle_path):
			ok = false
			errors.append("missing red idle %s" % idle_path)
		var walk_path: String = "res://assets/art/heroes/red/%s_walk.png" % rid
		if not FileAccess.file_exists(walk_path):
			ok = false
			errors.append("missing red walk %s" % walk_path)
	if not FileAccess.file_exists("res://assets/art/_preview/red_faces_compare.png"):
		ok = false
		errors.append("missing red_faces_compare preview")

	## ArtPaths resolves red
	var p0: String = ArtPaths.hero_idle("pool_r_dongfang")
	if not p0.contains("red_dongfang"):
		ok = false
		errors.append("ArtPaths red stem fail: %s" % p0)

	## --- DamageFloater script loads ---
	var df = load("res://scripts/ui/DamageFloater.gd")
	if df == null:
		ok = false
		errors.append("DamageFloater missing")
	else:
		var floater = df.new()
		if floater == null or not floater.has_method("setup"):
			ok = false
			errors.append("DamageFloater.setup missing")
		else:
			floater.free()

	## --- GachaFlash ---
	var gf = load("res://scripts/ui/GachaFlash.gd")
	if gf == null:
		ok = false
		errors.append("GachaFlash missing")
	else:
		var flash = gf.new()
		if flash == null or not flash.has_method("play") or not flash.has_method("play_batch"):
			ok = false
			errors.append("GachaFlash API missing")
		else:
			flash.free()

	## --- auto_combat has floater hooks ---
	var ac_src := FileAccess.get_file_as_string("res://scenes/combat/auto_combat.gd")
	if not ac_src.contains("_spawn_hit_floaters") or not ac_src.contains("DamageFloater"):
		ok = false
		errors.append("auto_combat missing floater hooks")

	## --- save backup rotation ---
	GameState.silver = 111
	GameState.diamonds = 7
	if not SaveManager.save_game():
		ok = false
		errors.append("first save failed")
	## second save should create backup of first
	GameState.silver = 222
	GameState.diamonds = 9
	if not SaveManager.save_game():
		ok = false
		errors.append("second save failed")
	if not SaveManager.has_backup():
		ok = false
		errors.append("backup not created")
	## load current = 222
	GameState.silver = 0
	if not SaveManager.load_game():
		ok = false
		errors.append("load current failed")
	if GameState.silver != 222:
		ok = false
		errors.append("current save silver want 222 got %d" % GameState.silver)
	## restore backup should bring back 111
	if not SaveManager.restore_backup():
		ok = false
		errors.append("restore_backup failed")
	if GameState.silver != 111:
		ok = false
		errors.append("backup restore silver want 111 got %d" % GameState.silver)
	if SaveManager.SAVE_VERSION < 10:
		ok = false
		errors.append("SAVE_VERSION < 10")

	## main bump
	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not main_src.contains("v0.9.4"):
		ok = false
		errors.append("main.gd not bumped to v0.9.4")
	if not main_src.contains("_flash_gacha_result"):
		ok = false
		errors.append("main missing gacha flash hook")

	## gacha still works + rarity field for flash
	SaveManager.clear_save()
	GameState._load_starter_data()
	GameState.silver = 9999
	GachaSystem.ensure_day()
	var pull: Dictionary = GachaSystem.pull_once()
	if not bool(pull.get("ok", false)):
		ok = false
		errors.append("pull failed: %s" % str(pull.get("reason", "")))
	elif str(pull.get("rarity", "")) == "":
		ok = false
		errors.append("pull missing rarity")

	if ok:
		print("SMOKE_V094_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V094_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
