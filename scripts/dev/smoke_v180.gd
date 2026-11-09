extends Node
## headless 煙測 v0.18.0：營地升級（槽／涓滴／舒適）＋手動巡哨 stub
## godot --headless --path . res://scenes/dev/smoke_v180.tscn

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
	if not SmokeUtil.version_at_least(main_src, 0, 18, 0):
		ok = false
		errors.append("main.gd title should be >= v0.18.0")
	if not main_src.contains("_on_camp_upgrade_pressed") or not main_src.contains("_on_camp_patrol_pressed"):
		ok = false
		errors.append("main missing camp upgrade/patrol handlers")
	if not main_src.contains("effective_slots"):
		ok = false
		errors.append("main should use effective_slots")

	if int(GameState.SAVE_VERSION) < 15:
		ok = false
		errors.append("SAVE_VERSION should be >= 15 got %d" % int(GameState.SAVE_VERSION))
	if int(SaveManager.SAVE_VERSION) < 15:
		ok = false
		errors.append("SaveManager SAVE_VERSION should be >= 15")

	var out_src := FileAccess.get_file_as_string("res://scripts/systems/OutpostSystem.gd")
	if not out_src.contains("upgrade_camp") or not out_src.contains("run_manual_skirmish"):
		ok = false
		errors.append("OutpostSystem missing upgrade/manual skirmish API")
	if not out_src.contains("camp_trickle_mult") or not out_src.contains("camp_comfort_drain_scale"):
		ok = false
		errors.append("OutpostSystem missing upgrade effect helpers")

	## JSON ladder
	var ups: Array = OutpostSystem.camp_upgrade_levels()
	if ups.size() < 3:
		ok = false
		errors.append("need >=3 camp upgrade levels got %d" % ups.size())
	var mdef: Dictionary = {}
	## probe via can_manual after station — first check def exists in core
	var core_txt := FileAccess.get_file_as_string("res://data/outpost/core.json")
	if not core_txt.contains("camp_upgrades") or not core_txt.contains("manual_skirmish"):
		ok = false
		errors.append("core.json missing camp_upgrades/manual_skirmish")

	## migrate old save without camp_levels
	var migrated: Dictionary = SaveManager.migrate_state({
		"silver": 10,
		"heroes": GameState.heroes.duplicate(true),
		"buildings": GameState.buildings.duplicate(true),
		"camp_stations": {},
	}, 14)
	if not migrated.has("camp_levels") or typeof(migrated["camp_levels"]) != TYPE_DICTIONARY:
		ok = false
		errors.append("migrate should default camp_levels")

	GameState.add_silver(8000)
	GameState.add_wood(4000)
	GameState.add_iron(200)
	if not _upgrade_to("manor", 2) or not _upgrade_to("bounty", 2):
		ok = false
		errors.append("cannot unlock outpost buildings")

	## freshen heroes
	for i in range(GameState.heroes.size()):
		var hx: Dictionary = (GameState.heroes[i] as Dictionary).duplicate(true)
		hx["status"] = "idle"
		hx["stamina"] = 100
		hx["satiety"] = 100
		hx["injury"] = 0
		hx["level"] = 8
		GameState.heroes[i] = HeroSystem.normalize_hero(hx)

	## base slots before upgrade
	var base_slots: int = OutpostSystem.effective_slots("luanshan")
	var cdef: Dictionary = OutpostSystem.camp_by_id("luanshan")
	if base_slots != int(cdef.get("slots", 3)):
		ok = false
		errors.append("base effective_slots want %d got %d" % [int(cdef.get("slots", 3)), base_slots])

	## upgrade Lv1
	var u1: Dictionary = OutpostSystem.upgrade_camp("luanshan")
	if not bool(u1.get("ok", false)):
		ok = false
		errors.append("upgrade1 fail: %s" % str(u1.get("reason", "")))
	else:
		if OutpostSystem.camp_level("luanshan") != 1:
			ok = false
			errors.append("camp_level want 1 got %d" % OutpostSystem.camp_level("luanshan"))
		var slots1: int = OutpostSystem.effective_slots("luanshan")
		if slots1 != base_slots + 1:
			ok = false
			errors.append("Lv1 slots want %d got %d" % [base_slots + 1, slots1])
		if OutpostSystem.camp_trickle_mult("luanshan") <= 1.0:
			ok = false
			errors.append("Lv1 trickle_mult should be >1")
		if OutpostSystem.camp_comfort_drain_scale("luanshan") >= 1.0:
			ok = false
			errors.append("Lv1 comfort_drain_scale should be <1")

	## cannot afford check: drain then try
	var silver_keep: int = GameState.silver
	GameState.try_spend(GameState.silver, GameState.wood, 0, GameState.iron)
	var u_fail: Dictionary = OutpostSystem.can_upgrade_camp("luanshan")
	if bool(u_fail.get("ok", false)):
		ok = false
		errors.append("upgrade should fail when broke")
	GameState.add_silver(maxi(500, silver_keep))
	GameState.add_wood(500)
	GameState.add_iron(50)

	## upgrade to max
	while OutpostSystem.camp_level("luanshan") < OutpostSystem.camp_max_level():
		var ux: Dictionary = OutpostSystem.upgrade_camp("luanshan")
		if not bool(ux.get("ok", false)):
			ok = false
			errors.append("upgrade loop fail at Lv%d: %s" % [
				OutpostSystem.camp_level("luanshan"), str(ux.get("reason", ""))
			])
			break
	var u_max: Dictionary = OutpostSystem.can_upgrade_camp("luanshan")
	if bool(u_max.get("ok", false)):
		ok = false
		errors.append("should be max level")
	var slots_max: int = OutpostSystem.effective_slots("luanshan")
	if slots_max < base_slots + 2:
		ok = false
		errors.append("max slots should gain +2 from ladder got %d (base %d)" % [slots_max, base_slots])

	## station + manual skirmish
	var ready: Array = HeroSystem.find_ready_heroes(2)
	if ready.size() < 2:
		ok = false
		errors.append("need 2 ready heroes")
	else:
		var party: Array = [str(ready[0].get("id", "")), str(ready[1].get("id", ""))]
		var stn: Dictionary = OutpostSystem.station("luanshan", party)
		if not bool(stn.get("ok", false)):
			ok = false
			errors.append("station fail: %s" % str(stn.get("reason", "")))
		else:
			var sil0: int = GameState.silver
			var sk: Dictionary = OutpostSystem.run_manual_skirmish("luanshan")
			if not bool(sk.get("ok", false)):
				ok = false
				errors.append("manual skirmish fail: %s" % str(sk.get("reason", "")))
			else:
				var waves: Array = sk.get("waves", []) as Array
				if waves.is_empty():
					ok = false
					errors.append("manual skirmish should return a wave for auto_combat")
				var st_snap: Dictionary = OutpostSystem.camp_station("luanshan")
				if int(st_snap.get("manual_skirmishes", 0)) < 1:
					ok = false
					errors.append("manual_skirmishes counter not bumped")
				## cooldown blocks immediate re-run
				var sk2: Dictionary = OutpostSystem.can_manual_skirmish("luanshan")
				if bool(sk2.get("ok", false)):
					ok = false
					errors.append("manual skirmish should be on cooldown")
				## heroes still camped
				for hid in party:
					if str(HeroSystem.get_hero(str(hid)).get("status", "")) != "camped":
						ok = false
						errors.append("hero should stay camped after patrol")
						break

			## save/load keeps levels
			var saved: Dictionary = GameState.to_save_dict()
			if int((saved.get("camp_levels", {}) as Dictionary).get("luanshan", 0)) < OutpostSystem.camp_max_level():
				ok = false
				errors.append("save missing camp_levels luanshan")
			SaveManager.save_game()
			var lv_before: int = OutpostSystem.camp_level("luanshan")
			GameState.camp_levels = {}
			if not SaveManager.load_game():
				ok = false
				errors.append("load_game failed")
			elif OutpostSystem.camp_level("luanshan") != lv_before:
				ok = false
				errors.append("loaded camp_level want %d got %d" % [lv_before, OutpostSystem.camp_level("luanshan")])

			var panel: String = OutpostSystem.describe_camps_panel()
			if panel.find("升級") < 0 and panel.find("Lv") < 0:
				ok = false
				errors.append("panel should show upgrade/level")
			if panel.find("巡") < 0:
				ok = false
				errors.append("panel should mention 巡哨")

			OutpostSystem.recall("luanshan")

	## guandao upgrade gate when locked
	if OutpostSystem.is_camp_unlocked("guandao"):
		## may unlock if clears already — soft
		pass
	else:
		var ug: Dictionary = OutpostSystem.can_upgrade_camp("guandao")
		if bool(ug.get("ok", false)):
			ok = false
			errors.append("locked guandao should not upgrade")

	SaveManager.clear_save()

	if ok:
		print("SMOKE_V180_OK")
	else:
		print("SMOKE_V180_FAIL")
		for e in errors:
			print("  - ", e)
	get_tree().quit(0 if ok else 1)
