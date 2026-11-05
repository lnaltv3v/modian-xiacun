extends Node
## headless 煙測 v0.4：食住醫消耗、成功率、練功場升級、Web 前置
## godot --headless --path . res://scenes/dev/smoke_v04.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- Upkeep: inn feeds, spends silver ---
	GameState.add_silver(50)
	GameState.add_wood(50)
	if not BuildingSystem.upgrade("inn"):
		ok = false
		errors.append("inn upgrade failed")
	## Drop satiety so food service engages
	for i in range(GameState.heroes.size()):
		var hd: Dictionary = (GameState.heroes[i] as Dictionary).duplicate(true)
		hd["satiety"] = 40.0
		hd["stamina"] = 40.0
		GameState.heroes[i] = HeroSystem.normalize_hero(hd)
	var silver_before: int = GameState.silver
	var wood_before: int = GameState.wood
	## Simulate ~3s of upkeep billing
	for _i in range(6):
		UpkeepSystem.tick(0.5)
	var silver_after: int = GameState.silver
	var wood_after: int = GameState.wood
	if silver_after >= silver_before:
		ok = false
		errors.append("expected food silver spend, before=%d after=%d" % [silver_before, silver_after])
	if wood_after >= wood_before:
		ok = false
		errors.append("expected lodge wood spend, before=%d after=%d" % [wood_before, wood_after])
	var sat_after: float = float((GameState.heroes[0] as Dictionary).get("satiety", 0))
	if sat_after <= 40.0:
		ok = false
		errors.append("expected satiety restore got %.1f" % sat_after)

	## --- Success chance reacts to satiety/injury ---
	var ids: Array = []
	for h in GameState.heroes:
		ids.append(str((h as Dictionary).get("id", "")))
	## Healthy party
	for i2 in range(GameState.heroes.size()):
		var h2: Dictionary = (GameState.heroes[i2] as Dictionary).duplicate(true)
		h2["satiety"] = 100.0
		h2["injury"] = 0.0
		h2["stamina"] = 100.0
		GameState.heroes[i2] = HeroSystem.normalize_hero(h2)
	var good: float = UpkeepSystem.party_success_chance(ids)
	for i3 in range(GameState.heroes.size()):
		var h3: Dictionary = (GameState.heroes[i3] as Dictionary).duplicate(true)
		h3["satiety"] = 5.0
		h3["injury"] = 70.0
		h3["stamina"] = 20.0
		GameState.heroes[i3] = HeroSystem.normalize_hero(h3)
	var bad: float = UpkeepSystem.party_success_chance(ids)
	if not (good > bad + 0.15):
		ok = false
		errors.append("success chance good=%.2f bad=%.2f" % [good, bad])

	## --- Training XP / level up ---
	GameState.add_silver(200)
	GameState.add_wood(200)
	if not BuildingSystem.upgrade("training"):
		ok = false
		errors.append("training upgrade failed")
	for i4 in range(GameState.heroes.size()):
		var h4: Dictionary = (GameState.heroes[i4] as Dictionary).duplicate(true)
		h4["status"] = "idle"
		h4["level"] = 1
		h4["xp"] = 35.0
		GameState.heroes[i4] = HeroSystem.normalize_hero(h4)
	var lv_before: int = int((GameState.heroes[0] as Dictionary).get("level", 1))
	## Need ~40 xp; rate at lv1 training = 2+3+0.75 = ~5.75/s → 10s enough
	for _j in range(20):
		TrainingSystem.tick(0.5)
	var lv_after: int = int((GameState.heroes[0] as Dictionary).get("level", 1))
	if lv_after <= lv_before:
		ok = false
		errors.append("expected level up got %d→%d xp=%s" % [
			lv_before, lv_after, str((GameState.heroes[0] as Dictionary).get("xp", 0))
		])

	## --- Clinic medicine spend ---
	if not BuildingSystem.upgrade("clinic"):
		ok = false
		errors.append("clinic upgrade failed")
	for i5 in range(GameState.heroes.size()):
		var h5: Dictionary = (GameState.heroes[i5] as Dictionary).duplicate(true)
		h5["injury"] = 40.0
		h5["status"] = "idle"
		GameState.heroes[i5] = HeroSystem.normalize_hero(h5)
	var sil_b: int = GameState.silver
	for _k in range(6):
		UpkeepSystem.tick(0.5)
	if GameState.silver >= sil_b:
		ok = false
		errors.append("expected med silver spend")
	var inj_after: float = float((GameState.heroes[0] as Dictionary).get("injury", 99))
	if inj_after >= 40.0:
		ok = false
		errors.append("expected injury heal got %.1f" % inj_after)

	## Normalize + save roundtrip with xp
	SaveManager.clear_save()
	if not SaveManager.save_game():
		ok = false
		errors.append("save failed")
	var xp_saved: float = float((GameState.heroes[0] as Dictionary).get("xp", -1))
	GameState._load_starter_data()
	if not SaveManager.load_game():
		ok = false
		errors.append("load failed")
	var xp_loaded: float = float((GameState.heroes[0] as Dictionary).get("xp", -2))
	if absf(xp_saved - xp_loaded) > 0.1:
		ok = false
		errors.append("xp not persisted %.1f vs %.1f" % [xp_saved, xp_loaded])

	if ok:
		print("SMOKE_V04_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V04_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
