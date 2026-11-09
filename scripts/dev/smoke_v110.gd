extends Node
## headless 煙測 v0.11.0：秘境難度／波次選擇＋書院技能樹 stub
## godot --headless --path . res://scenes/dev/smoke_v110.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- data: difficulties / wave sets ---
	var diffs: Array = DungeonSystem.difficulties()
	if diffs.size() < 3:
		ok = false
		errors.append("dungeon difficulties < 3 got %d" % diffs.size())
	var wsets: Array = DungeonSystem.wave_sets()
	if wsets.size() < 3:
		ok = false
		errors.append("dungeon wave_sets < 3 got %d" % wsets.size())
	if not DungeonSystem.is_difficulty_unlocked("normal"):
		ok = false
		errors.append("normal should be unlocked")
	if DungeonSystem.is_difficulty_unlocked("hard"):
		ok = false
		errors.append("hard should start locked")

	## --- prepare buildings / heroes ---
	GameState.add_silver(8000)
	GameState.add_wood(4000)
	GameState.add_fragments(80)
	for bid in ["inn", "clinic", "bounty", "manor", "academy", "training"]:
		var need: int = 2 if bid in ["bounty", "manor"] else 1
		while BuildingSystem.building_level(bid) < need:
			if not BuildingSystem.upgrade(bid):
				ok = false
				errors.append("cannot upgrade %s" % bid)
				break

	var heroes: Array = []
	for i in range(GameState.heroes.size()):
		var hx: Dictionary = (GameState.heroes[i] as Dictionary).duplicate(true)
		hx["status"] = "idle"
		hx["stamina"] = 100
		hx["satiety"] = 100
		hx["injury"] = 0
		hx["level"] = 8
		GameState.heroes[i] = HeroSystem.normalize_hero(hx)
		heroes.append(str(hx.get("id", "")))
		if heroes.size() >= 4:
			break
	if heroes.size() < 3:
		ok = false
		errors.append("need heroes")

	## --- wave set probe: only 1 wave ---
	GameState.dungeon_pick_diff = "normal"
	GameState.dungeon_pick_waves = "probe"
	var probe: Dictionary = DungeonSystem.run_dungeon(heroes)
	if not bool(probe.get("ok", false)):
		ok = false
		errors.append("probe run fail: %s" % str(probe.get("reason", "")))
	else:
		var pw: Array = probe.get("waves", []) as Array
		if pw.size() > 1:
			ok = false
			errors.append("probe should <=1 wave got %d" % pw.size())
		if int(probe.get("total_waves", 0)) != 1:
			ok = false
			errors.append("probe total_waves want 1")

	## reset heroes
	for i2 in range(GameState.heroes.size()):
		var hx2: Dictionary = (GameState.heroes[i2] as Dictionary).duplicate(true)
		hx2["status"] = "idle"
		hx2["stamina"] = 100
		hx2["satiety"] = 100
		hx2["injury"] = 0
		GameState.heroes[i2] = HeroSystem.normalize_hero(hx2)

	## --- force clear normal full to unlock hard ---
	GameState.dungeon_diff_clears["normal"] = 1
	if not DungeonSystem.is_difficulty_unlocked("hard"):
		ok = false
		errors.append("hard should unlock after normal clear")

	## --- compare enemy power hard vs normal (deterministic defs) ---
	var dn: Dictionary = DungeonSystem.difficulty_by_id("normal")
	var dh: Dictionary = DungeonSystem.difficulty_by_id("hard")
	if float(dh.get("power_mult", 1.0)) <= float(dn.get("power_mult", 1.0)):
		ok = false
		errors.append("hard power_mult should > normal")
	if float(dh.get("reward_mult", 1.0)) <= float(dn.get("reward_mult", 1.0)):
		ok = false
		errors.append("hard reward_mult should > normal")

	## seed RNG-ish by running hard full once (may fail; just check ok path structure)
	GameState.dungeon_pick_diff = "hard"
	GameState.dungeon_pick_waves = "full"
	for i3 in range(GameState.heroes.size()):
		var hx3: Dictionary = (GameState.heroes[i3] as Dictionary).duplicate(true)
		hx3["status"] = "idle"
		hx3["stamina"] = 100
		hx3["satiety"] = 100
		hx3["injury"] = 0
		hx3["level"] = 12
		GameState.heroes[i3] = HeroSystem.normalize_hero(hx3)
	var hard_run: Dictionary = DungeonSystem.run_dungeon(heroes, "hard", "full")
	if not bool(hard_run.get("ok", false)):
		ok = false
		errors.append("hard run fail: %s" % str(hard_run.get("reason", "")))
	else:
		var hw: Array = hard_run.get("waves", []) as Array
		if hw.is_empty():
			ok = false
			errors.append("hard run no waves")
		else:
			var ep: int = int((hw[0] as Dictionary).get("enemy_power", 0))
			## base wave1 power 18 * 1.4 = 25
			if ep < 24:
				ok = false
				errors.append("hard wave1 enemy_power too low %d" % ep)
		var pack: Dictionary = (hard_run.get("rewards", {}) as Dictionary).duplicate(true)
		pack["run_mode"] = "dungeon"
		pack["waves"] = hard_run.get("waves", [])
		pack["total_waves"] = int(hard_run.get("total_waves", 3))
		pack["difficulty_name"] = str(hard_run.get("difficulty_name", ""))
		pack["wave_set_name"] = str(hard_run.get("wave_set_name", ""))
		var txt: String = LootText.format_run_result(pack)
		if txt.find("困難") < 0 and txt.find("普通") < 0:
			## difficulty name should appear in title
			if str(hard_run.get("difficulty_name", "")) != "" and txt.find(str(hard_run.get("difficulty_name", ""))) < 0:
				ok = false
				errors.append("run_result missing difficulty name")

	## --- outpost difficulties ---
	var odiffs: Array = OutpostSystem.difficulties()
	if odiffs.size() < 3:
		ok = false
		errors.append("outpost difficulties < 3")
	if OutpostSystem.is_difficulty_unlocked("hard"):
		ok = false
		errors.append("outpost hard should start locked")
	GameState.outpost_diff_clears["normal"] = 1
	if not OutpostSystem.is_difficulty_unlocked("hard"):
		ok = false
		errors.append("outpost hard unlock fail")

	for i4 in range(GameState.heroes.size()):
		var hx4: Dictionary = (GameState.heroes[i4] as Dictionary).duplicate(true)
		hx4["status"] = "idle"
		hx4["stamina"] = 100
		hx4["satiety"] = 100
		hx4["injury"] = 0
		GameState.heroes[i4] = HeroSystem.normalize_hero(hx4)
	GameState.outpost_pick_diff = "hard"
	var ores: Dictionary = OutpostSystem.run_defense(heroes, "hard")
	if not bool(ores.get("ok", false)):
		ok = false
		errors.append("outpost hard fail: %s" % str(ores.get("reason", "")))
	elif str(ores.get("difficulty_name", "")) == "":
		ok = false
		errors.append("outpost missing difficulty_name")

	## --- academy skill tree ---
	if not AcademySystem.academy_ready():
		ok = false
		errors.append("academy not ready")
	if not AcademySystem.is_node_unlocked("n_tiegu"):
		ok = false
		errors.append("starter n_tiegu not unlocked")
	if AcademySystem.is_skill_unlocked("jifeng"):
		ok = false
		errors.append("jifeng should start locked")
	var u1: Dictionary = AcademySystem.unlock_node("n_jifeng")
	if not bool(u1.get("ok", false)):
		ok = false
		errors.append("unlock jifeng fail: %s" % str(u1.get("reason", "")))
	if not AcademySystem.is_skill_unlocked("jifeng"):
		ok = false
		errors.append("jifeng still locked after unlock")
	## chenzhuo requires n_tiegu (have) 
	var u2: Dictionary = AcademySystem.unlock_node("n_chenzhuo")
	if not bool(u2.get("ok", false)):
		ok = false
		errors.append("unlock chenzhuo fail: %s" % str(u2.get("reason", "")))
	## village ledger
	var before_m: float = AcademySystem.village_effect_mult("upkeep_silver_mult", 1.0)
	if absf(before_m - 1.0) > 0.001:
		ok = false
		errors.append("upkeep mult should be 1 before ledger")
	var u3: Dictionary = AcademySystem.unlock_node("n_village_ledger")
	if not bool(u3.get("ok", false)):
		ok = false
		errors.append("unlock ledger fail: %s" % str(u3.get("reason", "")))
	var after_m: float = AcademySystem.village_effect_mult("upkeep_silver_mult", 1.0)
	if after_m >= 0.999:
		ok = false
		errors.append("upkeep mult should drop after ledger got %s" % str(after_m))

	## assign only unlocked
	var hid: String = str(heroes[0])
	var bad: Dictionary = AcademySystem.assign_passive(hid, "xueqi")
	if bool(bad.get("ok", false)):
		ok = false
		errors.append("xueqi assign should fail when locked")
	var good: Dictionary = AcademySystem.assign_passive(hid, "jifeng")
	if not bool(good.get("ok", false)):
		ok = false
		errors.append("jifeng assign fail: %s" % str(good.get("reason", "")))

	var preview: String = AcademySystem.preview_node("n_village_store")
	if preview.find("出征") < 0 and preview.find("銀") < 0:
		ok = false
		errors.append("preview missing village effect text")

	var panel: String = AcademySystem.describe_panel(hid)
	if panel.find("技能樹") < 0:
		ok = false
		errors.append("academy panel missing 技能樹")

	var dp: String = DungeonSystem.describe_pick_panel()
	if dp.find("入場選擇") < 0:
		ok = false
		errors.append("dungeon pick panel text missing")

	## --- main / save fields ---
	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not ("v0.11.0" in main_src):
		ok = false
		errors.append("main.gd not bumped to v0.11.0")
	if not main_src.contains("_setup_dungeon_panel"):
		ok = false
		errors.append("main missing dungeon panel")
	if not main_src.contains("_setup_academy_panel"):
		ok = false
		errors.append("main missing academy panel")
	if not main_src.contains("_setup_outpost_panel"):
		ok = false
		errors.append("main missing outpost panel")

	var save_d: Dictionary = GameState.to_save_dict()
	if not save_d.has("dungeon_diff_clears") or not save_d.has("academy_unlocked_nodes"):
		ok = false
		errors.append("save dict missing new keys")
	if int(GameState.SAVE_VERSION) < 12:
		ok = false
		errors.append("SAVE_VERSION should be >= 12")

	if ok:
		print("SMOKE_V110_OK")
	else:
		print("SMOKE_V110_FAIL")
		for e in errors:
			print("  - ", e)
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if ok else 1)
