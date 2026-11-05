extends Node
const _OutpostScript = preload("res://scripts/systems/OutpostSystem.gd")
## headless 煙測 v0.7：橙紅池＋軟保底／毒沼／前哨 stub
## godot --headless --path . res://scenes/dev/smoke_v07.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- Orange / Red pool ---
	var weights: Dictionary = GachaSystem.rarity_weights()
	if int(weights.get("橙", 0)) < 1 or int(weights.get("紅", 0)) < 1:
		ok = false
		errors.append("orange/red weight missing %s" % str(weights))
	var oranges: Array = GachaSystem.heroes_of_rarity("橙")
	var reds: Array = GachaSystem.heroes_of_rarity("紅")
	if oranges.size() < 12:
		ok = false
		errors.append("expected >=12 orange got %d" % oranges.size())
	if reds.size() < 6:
		ok = false
		errors.append("expected >=6 red got %d" % reds.size())
	var onames: PackedStringArray = PackedStringArray()
	for o in oranges:
		onames.append(str((o as Dictionary).get("name", "")))
	for need in ["楊菓", "郭靚", "令狐忠", "喬風", "張三風", "風青羊", "黃藥獅", "歐陽峰", "洪喫公", "一登大師", "周伯同", "滅絕師態"]:
		if not need in onames:
			ok = false
			errors.append("missing orange %s" % need)
	var rnames: PackedStringArray = PackedStringArray()
	for r in reds:
		rnames.append(str((r as Dictionary).get("name", "")))
	for need2 in ["張無記", "東方唔敗", "獨孤求拜", "掃地僧", "王重揚", "黃裳"]:
		if not need2 in rnames:
			ok = false
			errors.append("missing red %s" % need2)
	if GachaSystem.fragment_for("橙") < 100 or GachaSystem.fragment_for("紅") < 200:
		ok = false
		errors.append("dupe frags too low o=%d r=%d" % [GachaSystem.fragment_for("橙"), GachaSystem.fragment_for("紅")])

	## Soft pity fields
	if not ("pity_red" in GameState.to_save_dict()):
		ok = false
		errors.append("pity_red not in save dict")
	GameState.pity_red = 119
	GameState.pity_orange = 0
	GameState.add_silver(5000)
	## Force many pulls until red or hit forced — with pity_red 119 next pull should force red if threshold 120
	## Actually _apply increments AFTER pick; _pick checks >= threshold BEFORE. So pity_red=120 forces.
	GameState.pity_red = 120
	var pulled_red := false
	for _i in range(3):
		var res: Dictionary = GachaSystem.pull_once()
		if not bool(res.get("ok", false)):
			ok = false
			errors.append("pity pull fail: %s" % str(res.get("reason", "")))
			break
		if str(res.get("rarity", "")) == "紅":
			pulled_red = true
			if GameState.pity_red != 0:
				ok = false
				errors.append("pity_red should reset after red got %d" % GameState.pity_red)
			break
	if not pulled_red:
		ok = false
		errors.append("soft pity did not force red within 3 pulls at pity_red=120")

	## Orange pity
	GameState.pity_orange = 40
	GameState.add_silver(500)
	var pulled_o := false
	for _j in range(3):
		var res2: Dictionary = GachaSystem.pull_once()
		if not bool(res2.get("ok", false)):
			ok = false
			errors.append("orange pity pull fail: %s" % str(res2.get("reason", "")))
			break
		var rr: String = str(res2.get("rarity", ""))
		if rr == "橙" or rr == "紅":
			pulled_o = true
			break
	if not pulled_o:
		ok = false
		errors.append("soft pity did not force orange/red at pity_orange=40")

	## --- Zone 毒沼 ---
	if not GameState.zones.has("du_zhao"):
		ok = false
		errors.append("du_zhao zone missing")
	else:
		var dz: Dictionary = GameState.get_zone("du_zhao")
		if str(dz.get("name", "")) != "毒沼":
			ok = false
			errors.append("du_zhao name %s" % str(dz.get("name", "")))
		var kinds: PackedStringArray = PackedStringArray()
		for e in dz.get("enemies", []) as Array:
			kinds.append(str((e as Dictionary).get("kind", "")))
		if not ("snake" in kinds and "python" in kinds):
			ok = false
			errors.append("毒沼 enemies missing snake/python got %s" % "、".join(kinds))

	## locked before bounty 2
	GameState.selected_zone = "du_zhao"
	var lock_res: Dictionary = DispatchSystem.new().start_hunt([str((GameState.heroes[0] as Dictionary).get("id", ""))], "du_zhao")
	## heroes may not be ready / bounty may be 1 — expect fail for unlock
	if BuildingSystem.building_level("bounty") < 2:
		if bool(lock_res.get("ok", false)):
			ok = false
			errors.append("du_zhao should lock at bounty < 2")
	## unlock bounty to 2
	GameState.add_silver(500)
	GameState.add_wood(300)
	while BuildingSystem.building_level("bounty") < 2:
		if not BuildingSystem.upgrade("bounty"):
			ok = false
			errors.append("cannot upgrade bounty")
			break
	## ready heroes
	for i in range(GameState.heroes.size()):
		var hh: Dictionary = (GameState.heroes[i] as Dictionary).duplicate(true)
		hh["status"] = "idle"
		hh["stamina"] = 100
		hh["satiety"] = 100
		hh["injury"] = 0
		GameState.heroes[i] = HeroSystem.normalize_hero(hh)
	var hid0: String = str((GameState.heroes[0] as Dictionary).get("id", ""))
	var ds := DispatchSystem.new()
	add_child(ds)
	var ok_hunt: Dictionary = ds.start_hunt([hid0], "du_zhao")
	if not bool(ok_hunt.get("ok", false)):
		ok = false
		errors.append("du_zhao hunt fail after unlock: %s" % str(ok_hunt.get("reason", "")))
	else:
		## force complete
		var hunt: Dictionary = (GameState.active_hunts[0] as Dictionary).duplicate(true)
		hunt["return_at"] = 0
		GameState.active_hunts[0] = hunt
		ds.resolve_due_hunts()
		if str(HeroSystem.get_hero(hid0).get("status", "")) != "idle":
			ok = false
			errors.append("hero not idle after du_zhao")

	## --- Outpost stub ---
	if _OutpostScript.is_unlocked():
		ok = false
		errors.append("outpost should start locked")
	while BuildingSystem.building_level("manor") < 2:
		if not BuildingSystem.upgrade("manor"):
			GameState.add_silver(200)
			GameState.add_wood(100)
			if not BuildingSystem.upgrade("manor"):
				ok = false
				errors.append("manor upgrade fail")
				break
	if not _OutpostScript.is_unlocked():
		ok = false
		errors.append("outpost still locked after manor2 bounty2")
	var party: Array = []
	for i2 in range(mini(3, GameState.heroes.size())):
		var hx: Dictionary = (GameState.heroes[i2] as Dictionary).duplicate(true)
		hx["status"] = "idle"
		hx["stamina"] = 100
		hx["satiety"] = 100
		hx["injury"] = 0
		GameState.heroes[i2] = HeroSystem.normalize_hero(hx)
		party.append(str(hx.get("id", "")))
	var wave: Dictionary = _OutpostScript.run_wave(party)
	if not bool(wave.get("ok", false)):
		ok = false
		errors.append("outpost wave fail: %s" % str(wave.get("reason", "")))
	elif not wave.has("rewards"):
		ok = false
		errors.append("outpost no rewards")

	## docs exist (filesystem)
	if not FileAccess.file_exists("res://docs/heroes/index.json"):
		ok = false
		errors.append("docs/heroes/index.json missing")
	if not FileAccess.file_exists("res://docs/heroes/red_zhangwuji.md"):
		ok = false
		errors.append("red_zhangwuji.md missing")
	if not FileAccess.file_exists("res://docs/heroes/orange_yangguo.json"):
		ok = false
		errors.append("orange_yangguo.json missing")

	## Save pity roundtrip
	GameState.pity_red = 33
	GameState.pity_orange = 12
	GameState.selected_zone = "du_zhao"
	SaveManager.clear_save()
	if not SaveManager.save_game():
		ok = false
		errors.append("save fail")
	GameState._load_starter_data()
	if not SaveManager.load_game():
		ok = false
		errors.append("load fail")
	if GameState.pity_red != 33 or GameState.pity_orange != 12:
		ok = false
		errors.append("pity not saved %d/%d" % [GameState.pity_red, GameState.pity_orange])
	if GameState.selected_zone != "du_zhao":
		ok = false
		errors.append("selected_zone not saved %s" % GameState.selected_zone)

	if ok:
		print("SMOKE_V07_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V07_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
