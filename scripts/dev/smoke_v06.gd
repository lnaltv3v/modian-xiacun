extends Node
## headless 煙測 v0.6：秘境三波／紫池／書院被動
## godot --headless --path . res://scenes/dev/smoke_v06.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- Purple pool present ---
	var weights: Dictionary = GachaSystem.rarity_weights()
	if int(weights.get("紫", 0)) < 1:
		ok = false
		errors.append("purple weight missing %s" % str(weights))
	var purples: Array = GachaSystem.heroes_of_rarity("紫")
	if purples.size() < 3:
		ok = false
		errors.append("expected >=3 purple templates got %d" % purples.size())
	var names: PackedStringArray = PackedStringArray()
	for p in purples:
		names.append(str((p as Dictionary).get("name", "")))
	for need in ["韋小保", "胡飛", "苗人風"]:
		if not need in names:
			ok = false
			errors.append("missing purple %s in %s" % [need, "、".join(names)])
	if GachaSystem.fragment_for("紫") < 50:
		ok = false
		errors.append("purple dupe frags too low %d" % GachaSystem.fragment_for("紫"))

	## Force purple pull by temporarily replacing weights via direct inject
	## Pull until purple or inject manually
	var injected := HeroSystem.normalize_hero({
		"id": "purple_test",
		"template_id": "pool_p_weixiaobao",
		"name": "韋小保",
		"weapon": "暗器",
		"rarity": "紫",
		"base_power": 24,
		"placeholder": true,
		"art_key": "",
	})
	GameState.heroes.append(injected)
	GameState.heroes_changed.emit()
	if not bool(injected.get("placeholder", false)):
		ok = false
		errors.append("placeholder flag lost in normalize")

	## --- Academy passive slot ---
	GameState.add_silver(500)
	GameState.add_wood(300)
	if BuildingSystem.building_level("academy") > 0:
		ok = false
		errors.append("academy should start locked")
	if AcademySystem.academy_ready():
		ok = false
		errors.append("academy_ready before build")
	if not BuildingSystem.upgrade("academy"):
		ok = false
		errors.append("academy upgrade failed silver=%d wood=%d" % [GameState.silver, GameState.wood])
	if not AcademySystem.academy_ready():
		ok = false
		errors.append("academy not ready after upgrade")
	if AcademySystem.passive_slots_unlocked() != 1:
		ok = false
		errors.append("expected 1 passive slot got %d" % AcademySystem.passive_slots_unlocked())
	var hid: String = "purple_test"
	var asg: Dictionary = AcademySystem.assign_passive(hid, "chenzhuo")
	if not bool(asg.get("ok", false)):
		ok = false
		errors.append("assign passive failed: %s" % str(asg.get("reason", "")))
	var h2: Dictionary = HeroSystem.get_hero(hid)
	if str(h2.get("passive_id", "")) != "chenzhuo":
		ok = false
		errors.append("passive_id not set got %s" % str(h2.get("passive_id", "")))
	var pow1: int = HeroSystem.power_of(h2)
	AcademySystem.assign_passive(hid, "xueqi")
	var pow2: int = HeroSystem.power_of(HeroSystem.get_hero(hid))
	if pow2 <= pow1:
		ok = false
		errors.append("xueqi should raise power %d→%d" % [pow1, pow2])

	## --- Dungeon 3 waves ---
	## Ensure party ready
	for i in range(GameState.heroes.size()):
		var hh: Dictionary = (GameState.heroes[i] as Dictionary).duplicate(true)
		hh["status"] = "idle"
		hh["stamina"] = 100
		hh["satiety"] = 100
		hh["injury"] = 0
		GameState.heroes[i] = HeroSystem.normalize_hero(hh)
	var party: Array = []
	for i2 in range(mini(5, GameState.heroes.size())):
		party.append(str((GameState.heroes[i2] as Dictionary).get("id", "")))
	var can: Dictionary = DungeonSystem.can_enter(party)
	if not bool(can.get("ok", false)):
		ok = false
		errors.append("can_enter failed: %s" % str(can.get("reason", "")))
	var too_many: Array = party.duplicate()
	too_many.append("fake_extra")
	## fake will fail on missing hero — use 6 real by duplicating ids shouldn't: use max check
	if party.size() >= 5:
		var over: Array = party.duplicate()
		## add another idle if exists else clone id for size check only via can_enter size
		over.append(str(party[0]))  ## duplicate id
		var can_over: Dictionary = DungeonSystem.can_enter(over)
		if bool(can_over.get("ok", false)):
			ok = false
			errors.append("should reject >5 or dup")
	var run: Dictionary = DungeonSystem.run_dungeon(party)
	if not bool(run.get("ok", false)):
		ok = false
		errors.append("run_dungeon failed: %s" % str(run.get("reason", "")))
	else:
		var waves: Array = run.get("waves", []) as Array
		if waves.is_empty():
			ok = false
			errors.append("no waves returned")
		else:
			var last: Dictionary = waves[waves.size() - 1] as Dictionary
			## if cleared all 3, last should be boss; if failed earlier, check first waves structure
			var found_boss_def := false
			var defs: Array = DungeonSystem.dungeon_def().get("waves", []) as Array
			if defs.size() != 3:
				ok = false
				errors.append("dungeon def waves != 3 got %d" % defs.size())
			if defs.size() >= 3 and not bool((defs[2] as Dictionary).get("boss", false)):
				ok = false
				errors.append("wave3 should be boss")
			## enemies use existing kinds
			for wv in waves:
				for ev in (wv as Dictionary).get("enemies", []) as Array:
					var kind: String = str((ev as Dictionary).get("kind", ""))
					if kind not in ["wolf", "boar", "bandit"]:
						ok = false
						errors.append("unknown monster kind %s" % kind)
		var rewards: Dictionary = run.get("rewards", {}) as Dictionary
		if not rewards.has("silver"):
			ok = false
			errors.append("rewards missing silver")
		## heroes back to idle
		for pid in party:
			var st: String = str(HeroSystem.get_hero(str(pid)).get("status", ""))
			if st != "idle":
				ok = false
				errors.append("hero %s status after dungeon %s" % [pid, st])

	## empty party reject
	var empty: Dictionary = DungeonSystem.can_enter([])
	if bool(empty.get("ok", false)):
		ok = false
		errors.append("empty party should fail")

	## Save roundtrip passive
	GameState.fragments = 7
	SaveManager.clear_save()
	if not SaveManager.save_game():
		ok = false
		errors.append("save failed")
	var pas_before: String = str(HeroSystem.get_hero(hid).get("passive_id", ""))
	GameState._load_starter_data()
	if not SaveManager.load_game():
		ok = false
		errors.append("load failed")
	## purple_test may still be in save
	var found_pas := false
	for hv in GameState.heroes:
		var hd: Dictionary = hv as Dictionary
		if str(hd.get("id", "")) == hid:
			found_pas = true
			if str(hd.get("passive_id", "")) != pas_before:
				ok = false
				errors.append("passive not saved %s vs %s" % [str(hd.get("passive_id", "")), pas_before])
	if not found_pas:
		ok = false
		errors.append("purple_test missing after load")

	if ok:
		print("SMOKE_V06_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V06_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
