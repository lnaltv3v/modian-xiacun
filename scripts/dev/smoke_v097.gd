extends Node
## headless 煙測 v0.9.7：建築 Pivot R2（七棟 160）＋村景拉開預設／art_revision
## godot --headless --path . res://scenes/dev/smoke_v097.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## seven core buildings ≥160（academy 暫 128 唔強制）
	var core := ["manor", "inn", "forge", "clinic", "training", "bounty", "warehouse"]
	for bid in core:
		var bpath: String = ArtPaths.building_icon(bid)
		if not ArtPaths.exists(bpath):
			ok = false
			errors.append("missing building %s" % bpath)
			continue
		var btex: Texture2D = ArtPaths.load_tex(bpath)
		if btex == null or btex.get_width() < 160 or btex.get_height() < 160:
			ok = false
			errors.append("%s icon want >=160 got %s" % [
				bid, str(btex.get_width() if btex else 0)
			])

	## village layers
	for layer in ["village_ground", "village_hills", "village_buildings_pad", "village_fg"]:
		var p: String = "res://assets/art/tiles/%s.png" % layer
		if not FileAccess.file_exists(p):
			ok = false
			errors.append("missing tile %s" % p)
	if not ArtPaths.exists(ArtPaths.VILLAGE_GROUND):
		ok = false
		errors.append("VILLAGE_GROUND missing")

	## layout revision + spaced defaults
	var layout_txt := FileAccess.get_file_as_string("res://data/buildings/layout.json")
	if not layout_txt.contains("pivot_r2"):
		ok = false
		errors.append("layout art_revision not pivot_r2")
	if not layout_txt.contains("\"w\": 160"):
		ok = false
		errors.append("layout icon_size not 160")

	## spaced defaults（對齊 R2 preview：manor 北／warehouse 西／forge 東／inn 西南／training 東南）
	var manor: Vector2 = GameState.get_building_pos("manor")
	var warehouse: Vector2 = GameState.get_building_pos("warehouse")
	var forge: Vector2 = GameState.get_building_pos("forge")
	var inn: Vector2 = GameState.get_building_pos("inn")
	var training: Vector2 = GameState.get_building_pos("training")
	var clinic: Vector2 = GameState.get_building_pos("clinic")
	var bounty: Vector2 = GameState.get_building_pos("bounty")
	if manor.y > 220.0:
		ok = false
		errors.append("manor should be north (y<=220) got %s" % str(manor))
	if warehouse.x > 180.0:
		ok = false
		errors.append("warehouse should be west (x<=180) got %s" % str(warehouse))
	if forge.x < 780.0:
		ok = false
		errors.append("forge should be east (x>=780) got %s" % str(forge))
	if inn.x > 220.0 or inn.y < 400.0:
		ok = false
		errors.append("inn should be SW got %s" % str(inn))
	if training.x < 740.0 or training.y < 400.0:
		ok = false
		errors.append("training should be SE got %s" % str(training))
	## clinic / bounty along south, not clustered on same point
	if clinic.distance_to(bounty) < 200.0:
		ok = false
		errors.append("clinic/bounty too close %s" % str(clinic.distance_to(bounty)))
	## center kept clear: no building near (480, 360)
	var center := Vector2(480, 360)
	for bid2 in core:
		var p2: Vector2 = GameState.get_building_pos(bid2)
		if p2.distance_to(center) < 140.0:
			ok = false
			errors.append("%s intrudes center empty (dist %.0f)" % [bid2, p2.distance_to(center)])

	## pairwise min separation among defaults
	for i in range(core.size()):
		for j in range(i + 1, core.size()):
			var a: Vector2 = GameState.get_building_pos(core[i])
			var b: Vector2 = GameState.get_building_pos(core[j])
			if a.distance_to(b) < 120.0:
				ok = false
				errors.append("%s-%s defaults too close %.0f" % [core[i], core[j], a.distance_to(b)])

	## version bump
	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not main_src.contains("v0.9.7"):
		ok = false
		errors.append("main.gd not bumped to v0.9.7")

	## village.gd uses 160 fallback / separation
	var village_src := FileAccess.get_file_as_string("res://scenes/village/village.gd")
	if not village_src.contains("Vector2(160, 160)"):
		ok = false
		errors.append("village.gd icon fallback not 160")
	if not village_src.contains("MIN_SEPARATION := 120"):
		ok = false
		errors.append("village.gd MIN_SEPARATION not 120")

	if ok:
		print("SMOKE_V097_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V097_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
