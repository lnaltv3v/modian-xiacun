extends Node
const _LootText = preload("res://scripts/ui/LootText.gd")
## headless 煙測 v0.9.3：鑽石／日節奏／秘境獎勵表／怪 stem
## godot --headless --path . res://scenes/dev/smoke_v093.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- diamonds baseline ---
	if GameState.diamonds < 1:
		ok = false
		errors.append("starter diamonds missing")

	## --- gacha free then silver pacing ---
	GachaSystem.ensure_day()
	if GachaSystem.free_pulls_remaining() < 1:
		ok = false
		errors.append("expected free pull")
	var free_res: Dictionary = GachaSystem.pull_once()
	if not bool(free_res.get("ok", false)):
		ok = false
		errors.append("free pull failed: %s" % str(free_res.get("reason", "")))
	if GachaSystem.free_pulls_remaining() != 0:
		ok = false
		errors.append("free pull not consumed")

	## force near daily cap
	GameState.gacha_silver_today = GachaSystem.daily_silver_limit()
	GameState.silver = 9999
	var capped: Dictionary = GachaSystem.can_pull()
	if bool(capped.get("ok", false)):
		ok = false
		errors.append("daily silver cap not enforced")

	## diamond ten pull stub
	GameState.diamonds = 50
	var ten: Dictionary = GachaSystem.pull_diamond(10)
	if not bool(ten.get("ok", false)):
		ok = false
		errors.append("diamond ten failed: %s" % str(ten.get("reason", "")))
	elif int(ten.get("count", 0)) != 10:
		ok = false
		errors.append("ten pull count != 10")
	elif (ten.get("results", []) as Array).size() != 10:
		ok = false
		errors.append("ten pull results size")

	## --- dungeon reward table ---
	var def: Dictionary = DungeonSystem.dungeon_def()
	if not def.has("reward_table"):
		ok = false
		errors.append("dungeon missing reward_table")
	else:
		var rt: Dictionary = def["reward_table"] as Dictionary
		if not rt.has("clear_bonus") or not rt.has("rare_drops"):
			ok = false
			errors.append("reward_table incomplete")
	## boss kinds ready for art
	var boss_kinds: PackedStringArray = PackedStringArray()
	for wv in def.get("waves", []) as Array:
		var wd: Dictionary = wv as Dictionary
		if bool(wd.get("boss", false)):
			for ev in wd.get("enemies", []) as Array:
				boss_kinds.append(str((ev as Dictionary).get("kind", "")))
	if not ("wolf_king" in boss_kinds and "bandit_chief" in boss_kinds):
		ok = false
		errors.append("boss kinds not wolf_king/bandit_chief got %s" % ",".join(boss_kinds))

	## unlock bounty + make party strong for clear chance
	if GameState.buildings.has("bounty"):
		var b: Dictionary = GameState.buildings["bounty"] as Dictionary
		b["level"] = 2
		b["unlocked"] = true
		GameState.buildings["bounty"] = b
	## pump hero power
	for i in range(GameState.heroes.size()):
		var h: Dictionary = GameState.heroes[i] as Dictionary
		h["level"] = 20
		h["base_power"] = 40
		h["stamina"] = 100
		h["satiety"] = 100
		h["injury"] = 0
		h["status"] = "idle"
		GameState.heroes[i] = h
	var party: Array = []
	for i2 in range(mini(5, GameState.heroes.size())):
		party.append(str((GameState.heroes[i2] as Dictionary).get("id", "")))
	var before_d: int = GameState.diamonds
	var before_f: int = GameState.fragments
	var before_inv: int = GameState.inventory.size()
	## run several times to hit probabilistic rewards
	var any_ok := false
	for _n in range(8):
		for i3 in range(GameState.heroes.size()):
			var hx: Dictionary = GameState.heroes[i3] as Dictionary
			hx["status"] = "idle"
			hx["stamina"] = 100
			hx["satiety"] = 100
			GameState.heroes[i3] = hx
		var dr: Dictionary = DungeonSystem.run_dungeon(party)
		if bool(dr.get("ok", false)):
			any_ok = true
			var rw: Dictionary = dr.get("rewards", {}) as Dictionary
			if not rw.has("diamonds") or not rw.has("fragments"):
				ok = false
				errors.append("dungeon rewards missing diamonds/fragments keys")
				break
	if not any_ok:
		ok = false
		errors.append("dungeon run never ok")

	## LootText diamonds
	var loot_txt: String = _LootText.format_loot_block({
		"silver": 1, "fur": 0, "wood": 0, "iron": 0, "diamonds": 2, "fragments": 5,
		"enemies": [{"kind": "wolf_king", "name": "狼王"}],
	})
	if not loot_txt.contains("×2") or not loot_txt.contains("×5"):
		ok = false
		errors.append("LootText missing diamond/fragment counts: %s" % loot_txt)
	if not loot_txt.contains("狼王"):
		ok = false
		errors.append("LootText missing wolf_king hint")

	## monster stem fallback
	var wk: String = ArtPaths.monster_idle("wolf_king")
	if not wk.contains("monster_wolf"):
		## either dedicated or fallback wolf
		if not ResourceLoader.exists(wk):
			ok = false
			errors.append("wolf_king idle path missing resource %s" % wk)
	var sn: String = ArtPaths.monster_idle("snake")
	if not ResourceLoader.exists(sn):
		ok = false
		errors.append("snake idle fallback missing %s" % sn)

	## save/load diamonds + day key
	GameState.diamonds = 17
	GameState.gacha_silver_today = 9
	GameState.gacha_free_used_today = true
	GameState.gacha_day_key = GachaSystem._today_key()
	if not SaveManager.save_game():
		ok = false
		errors.append("save failed")
	GameState.diamonds = 0
	GameState.gacha_silver_today = 0
	GameState.gacha_free_used_today = false
	if not SaveManager.load_game():
		ok = false
		errors.append("load failed")
	if GameState.diamonds != 17:
		ok = false
		errors.append("diamonds not persisted got %d" % GameState.diamonds)
	if GameState.gacha_silver_today != 9:
		ok = false
		errors.append("gacha_silver_today not persisted")
	if not GameState.gacha_free_used_today:
		ok = false
		errors.append("gacha_free_used_today not persisted")

	## version bump
	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not main_src.contains("v0.9.3"):
		ok = false
		errors.append("main.gd not bumped to v0.9.3")
	if SaveManager.SAVE_VERSION < 9:
		ok = false
		errors.append("SaveManager version < 9")

	## pool pacing present
	var pool_txt := FileAccess.get_file_as_string("res://data/gacha/pool.json")
	if not pool_txt.contains("daily_silver_limit"):
		ok = false
		errors.append("pool missing pacing")

	if ok:
		print("SMOKE_V093_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V093_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
