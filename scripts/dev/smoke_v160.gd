extends Node
## headless 煙測 v0.16.0：營地單一飽食路徑＋舒適減耗；Web export 文件／腳本
## godot --headless --path . res://scenes/dev/smoke_v160.tscn

const SmokeUtil = preload("res://scripts/dev/SmokeUtil.gd")

func _ready() -> void:
	call_deferred("_run")


func _upgrade_to(bid: String, need: int) -> bool:
	while BuildingSystem.building_level(bid) < need:
		if not BuildingSystem.upgrade(bid):
			return false
	return true


func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()
	OutpostSystem.ensure_loaded()

	var main_src := SmokeUtil.main_src()
	if not SmokeUtil.version_at_least(main_src, 0, 16, 0):
		ok = false
		errors.append("main.gd title should be >= v0.16.0")
	if not main_src.contains("舒適減耗"):
		ok = false
		errors.append("main camp hint should mention 舒適減耗")

	var up_src := FileAccess.get_file_as_string("res://scripts/systems/UpkeepSystem.gd")
	if not up_src.contains('status != "camped"'):
		ok = false
		errors.append("UpkeepSystem should skip hunger drain for camped")

	var out_src := FileAccess.get_file_as_string("res://scripts/systems/OutpostSystem.gd")
	if not out_src.contains("comfort_drain_mult") or not out_src.contains("comfort_satiety_per_min"):
		ok = false
		errors.append("OutpostSystem missing comfort drain path")
	if not out_src.contains("唔疊村莊饑餓"):
		ok = false
		errors.append("camp panel should clarify single satiety path")

	## export docs / script present
	if not FileAccess.file_exists("res://docs/EXPORT.md"):
		ok = false
		errors.append("docs/EXPORT.md missing")
	else:
		var exp_doc := FileAccess.get_file_as_string("res://docs/EXPORT.md")
		if not exp_doc.contains("export_web") and not exp_doc.contains("http.server"):
			ok = false
			errors.append("EXPORT.md should document web serve")
	if not FileAccess.file_exists("res://tools/export_web.sh"):
		ok = false
		errors.append("tools/export_web.sh missing")

	if int(GameState.SAVE_VERSION) < 14:
		ok = false
		errors.append("SAVE_VERSION should stay >= 14 got %d" % int(GameState.SAVE_VERSION))

	## unlock outpost + station
	GameState.add_silver(5000)
	GameState.add_wood(5000)
	GameState.add_iron(200)
	if not _upgrade_to("manor", 2) or not _upgrade_to("bounty", 2):
		ok = false
		errors.append("could not unlock outpost buildings")

	var hero_id := ""
	for h in GameState.heroes:
		var hd: Dictionary = h as Dictionary
		if str(hd.get("status", "idle")) == "idle":
			hero_id = str(hd.get("id", ""))
			HeroSystem.mutate(hero_id, func(hx: Dictionary) -> void:
				hx["stamina"] = 100
				hx["satiety"] = 100
				hx["injury"] = 0
			)
			break
	if hero_id == "":
		ok = false
		errors.append("no idle hero")
	else:
		var stn: Dictionary = OutpostSystem.station("luanshan", [hero_id])
		if not bool(stn.get("ok", false)):
			ok = false
			errors.append("station failed: %s" % str(stn.get("reason", "")))
		else:
			## 有銀：舒適路徑 — 用 40s（< skirmish 48s）量淨耗，避開小戰額外扣體
			var sat0: float = float(HeroSystem.get_hero(hero_id).get("satiety", 0))
			var stam0: float = float(HeroSystem.get_hero(hero_id).get("stamina", 0))
			var tick_ok: Dictionary = OutpostSystem.tick_camps(40.0)
			if not bool(tick_ok.get("ok", false)):
				ok = false
				errors.append("tick_camps failed")
			var sat1: float = float(HeroSystem.get_hero(hero_id).get("satiety", 0))
			var stam1: float = float(HeroSystem.get_hero(hero_id).get("stamina", 0))
			var sat_drop: float = sat0 - sat1
			var stam_drop: float = stam0 - stam1
			## comfort ≈ (1.8*0.55 - 0.4)/min sat ≈ 0.39/min → ~0.26 in 40s
			## stamina ≈ 3.0*0.55/min → ~1.1 in 40s；舊雙重飽食會喺同級時間扣幾十點
			if sat_drop < -0.5 or sat_drop > 2.0:
				ok = false
				errors.append("comfort satiety drop out of band got %.2f (want ~0..2)" % sat_drop)
			if stam_drop < 0.4 or stam_drop > 2.5:
				ok = false
				errors.append("comfort stamina drop out of band got %.2f (want ~0.5..2)" % stam_drop)
			var st_snap: Dictionary = OutpostSystem.camp_station("luanshan")
			if not bool(st_snap.get("comfort", false)):
				ok = false
				errors.append("expected comfort=true while silver available")

			## UpkeepSystem 不應再扣 camped 飽食
			var sat_before_up: float = float(HeroSystem.get_hero(hero_id).get("satiety", 0))
			UpkeepSystem.tick(10.0)
			var sat_after_up: float = float(HeroSystem.get_hero(hero_id).get("satiety", 0))
			if absf(sat_after_up - sat_before_up) > 0.05:
				ok = false
				errors.append("UpkeepSystem must not drain camped satiety (delta %.3f)" % (sat_after_up - sat_before_up))

			## 欠餉：清空銀＋強制應繳袋，避免涓滴未入帳前測不準
			GameState.try_spend(GameState.silver, 0)
			if typeof(GameState.camp_stations.get("luanshan", null)) == TYPE_DICTIONARY:
				var st_force: Dictionary = (GameState.camp_stations["luanshan"] as Dictionary).duplicate(true)
				st_force["bag_upkeep"] = 5.0
				st_force["bag_silver"] = 0.0
				st_force["skirmish_accum"] = 0.0
				st_force["comfort"] = false
				GameState.camp_stations["luanshan"] = st_force
			HeroSystem.mutate(hero_id, func(hx: Dictionary) -> void:
				hx["satiety"] = 100
				hx["stamina"] = 100
			)
			var sat_u0: float = float(HeroSystem.get_hero(hero_id).get("satiety", 0))
			OutpostSystem.tick_camps(40.0)
			## 涓滴可能已入銀；再清空一次確保仍欠餉體感（本 tick 已用 unpaid）
			var sat_u1: float = float(HeroSystem.get_hero(hero_id).get("satiety", 0))
			var unpaid_drop: float = sat_u0 - sat_u1
			## unpaid: 1.8 * 1.15 ≈ 2.07/min → ~1.38 in 40s；應明顯高過舒適淨耗
			if unpaid_drop < 0.9:
				ok = false
				errors.append("unpaid satiety drain too low got %.2f" % unpaid_drop)
			if unpaid_drop <= sat_drop + 0.3:
				ok = false
				errors.append("unpaid drain should exceed comfort (unpaid %.2f comfort %.2f)" % [unpaid_drop, sat_drop])
			## 欠餉檔已用 unpaid_drop 對照舒適淨耗；涓滴入銀後 comfort 旗可翻真屬預期

			var panel: String = OutpostSystem.describe_camps_panel()
			if panel.find("唔疊村莊饑餓") < 0 and panel.find("單一") < 0:
				if panel.find("舒適") < 0:
					ok = false
					errors.append("panel missing comfort/single-path copy")

			## save/load keeps stations
			var saved: Dictionary = GameState.to_save_dict()
			if not saved.has("camp_stations"):
				ok = false
				errors.append("save missing camp_stations")
			OutpostSystem.recall("luanshan")

	## JSON tunables present
	var cdef: Dictionary = OutpostSystem.camp_by_id("luanshan")
	if float(cdef.get("comfort_drain_mult", 1.0)) >= 0.95:
		ok = false
		errors.append("luanshan comfort_drain_mult should be <1")
	if float(cdef.get("satiety_drain_per_min", 99)) > 2.2:
		ok = false
		errors.append("luanshan satiety_drain_per_min should be tuned down got %s" % str(cdef.get("satiety_drain_per_min")))

	if ok:
		print("SMOKE_V160_OK")
	else:
		print("SMOKE_V160_FAIL")
		for e in errors:
			print("  - ", e)
	get_tree().quit(0 if ok else 1)
