extends Node
const _Arena = preload("res://scripts/systems/ArenaSystem.gd")
const _Craft = preload("res://scripts/systems/CraftSystem.gd")
## headless 煙測 v0.9：橙階 128 圖／ArtPaths／抽卡 stem／貨棧自動販／比武台 stub
## godot --headless --path . res://scenes/dev/smoke_v09.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- Orange art files ---
	var orange_stems := [
		"orange_yangguo", "orange_guojing", "orange_linghuzhong", "orange_qiaofeng",
		"orange_zhangsanfeng", "orange_fengqingyang", "orange_huangyaoshi", "orange_ouyangfeng",
		"orange_hongqigong", "orange_yideng", "orange_zhoubotong", "orange_miejueshitai",
	]
	for stem in orange_stems:
		var idle_path: String = "res://assets/art/heroes/orange/%s_idle.png" % stem
		var walk_path: String = "res://assets/art/heroes/orange/%s_walk.png" % stem
		if not ResourceLoader.exists(idle_path):
			ok = false
			errors.append("missing idle %s" % idle_path)
		if not ResourceLoader.exists(walk_path):
			ok = false
			errors.append("missing walk %s" % walk_path)

	## Inject orange hero
	var oh := {
		"id": "test_orange_yg",
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
	GameState.heroes_changed.emit()

	var idle: String = ArtPaths.hero_idle("test_orange_yg")
	if not idle.contains("/orange/orange_yangguo_idle"):
		ok = false
		errors.append("ArtPaths.hero_idle not orange: %s" % idle)
	if not ArtPaths.has_orange_art("test_orange_yg"):
		ok = false
		errors.append("has_orange_art false")
	var frames: SpriteFrames = ArtPaths.make_hero_frames("test_orange_yg")
	if frames == null or not frames.has_animation("idle") or not frames.has_animation("walk"):
		ok = false
		errors.append("make_hero_frames failed orange")
	else:
		if frames.get_frame_count("walk") < 4:
			ok = false
			errors.append("orange walk frames %d < 4" % frames.get_frame_count("walk"))
	var fw: int = ArtPaths.hero_frame_px("test_orange_yg")
	if fw < 100 or fw > 140:
		ok = false
		errors.append("orange frame_px expected ~128 got %d" % fw)
	var ds: float = ArtPaths.display_scale_for("test_orange_yg", 72.0)
	## 72/128 ≈ 0.5625
	if ds < 0.45 or ds > 0.7:
		ok = false
		errors.append("orange display_scale weird %s" % str(ds))

	## Red still works
	var rh := {
		"id": "test_red_zwj2",
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
	rh = HeroSystem.normalize_hero(rh)
	GameState.heroes.append(rh)
	var idle_r: String = ArtPaths.hero_idle("test_red_zwj2")
	if not idle_r.contains("/red/red_zhangwuji_idle"):
		ok = false
		errors.append("red path broken: %s" % idle_r)
	var ds_r: float = ArtPaths.display_scale_for("test_red_zwj2", 72.0)
	if ds_r > 0.5 or ds_r < 0.2:
		ok = false
		errors.append("red display_scale weird %s" % str(ds_r))

	## Gacha pool orange art_stem + not placeholder
	for h in GachaSystem.heroes_of_rarity("橙"):
		var hh: Dictionary = h as Dictionary
		if str(hh.get("art_stem", "")) == "":
			ok = false
			errors.append("orange pool missing art_stem %s" % str(hh.get("name", "")))
		if bool(hh.get("placeholder", true)):
			ok = false
			errors.append("orange pool still placeholder %s" % str(hh.get("name", "")))

	## Warehouse autosell
	GameState.add_fur(20)
	GameState.add_silver(500)
	GameState.add_wood(200)
	while BuildingSystem.building_level("warehouse") < 1:
		if not BuildingSystem.upgrade("warehouse"):
			## may need manor first / costs
			BuildingSystem.upgrade("manor")
			if not BuildingSystem.upgrade("warehouse"):
				ok = false
				errors.append("cannot build warehouse")
				break
	var sell: Dictionary = _Craft.auto_sell_fur(2)
	if not bool(sell.get("ok", false)):
		ok = false
		errors.append("auto_sell_fur fail: %s" % str(sell.get("reason", "")))
	elif int(sell.get("sold_batches", 0)) < 1:
		ok = false
		errors.append("auto_sell sold 0")

	## Arena stub
	if not _Arena.arena_ready():
		while BuildingSystem.building_level("training") < 1:
			if not BuildingSystem.upgrade("training"):
				BuildingSystem.upgrade("manor")
				BuildingSystem.upgrade("inn")
				if not BuildingSystem.upgrade("training"):
					ok = false
					errors.append("cannot build training")
					break
	## pick two starter heroes
	var ids: Array = []
	for hv in GameState.heroes:
		var hd: Dictionary = hv as Dictionary
		var id0: String = str(hd.get("id", ""))
		if id0.begins_with("test_"):
			continue
		if HeroSystem.can_hunt(hd):
			ids.append(id0)
		if ids.size() >= 2:
			break
	if ids.size() >= 2:
		var spar: Dictionary = _Arena.spar(str(ids[0]), str(ids[1]))
		if not bool(spar.get("ok", false)):
			ok = false
			errors.append("arena spar fail: %s" % str(spar.get("reason", "")))
	else:
		ok = false
		errors.append("not enough heroes for spar")

	if ok:
		print("SMOKE_V09_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V09_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
