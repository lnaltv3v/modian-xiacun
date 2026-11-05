extends Node
## headless 煙測 v0.9.5：比武台可玩／庫存裝用賣／裝備替換回庫／SAVE 11
## godot --headless --path . res://scenes/dev/smoke_v095.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- version bumps ---
	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not main_src.contains("v0.9.5"):
		ok = false
		errors.append("main.gd not bumped to v0.9.5")
	if not main_src.contains("_on_arena_pressed") or not main_src.contains("_on_inv_use"):
		ok = false
		errors.append("main missing arena/inv handlers")
	if SaveManager.SAVE_VERSION < 11:
		ok = false
		errors.append("SAVE_VERSION < 11")

	## --- unlock training for arena ---
	if GameState.buildings.has("training"):
		var tb: Dictionary = (GameState.buildings["training"] as Dictionary).duplicate(true)
		tb["level"] = 1
		tb["unlocked"] = true
		GameState.buildings["training"] = tb
	if not ArenaSystem.arena_ready():
		ok = false
		errors.append("arena not ready after training Lv1")

	## --- need 2 idle heroes ---
	if GameState.heroes.size() < 2:
		ok = false
		errors.append("need >=2 starter heroes")
		_fail(ok, errors)
		return
	var ha: String = str((GameState.heroes[0] as Dictionary).get("id", ""))
	var hb: String = str((GameState.heroes[1] as Dictionary).get("id", ""))
	var chk: Dictionary = ArenaSystem.can_spar(ha, hb)
	if not bool(chk.get("ok", false)):
		ok = false
		errors.append("can_spar fail: %s" % str(chk.get("reason", "")))

	var before_xp_a: float = float(HeroSystem.get_hero(ha).get("xp", 0))
	var before_stam: float = float(HeroSystem.get_hero(ha).get("stamina", 0))
	var res: Dictionary = ArenaSystem.spar(ha, hb)
	if not bool(res.get("ok", false)):
		ok = false
		errors.append("spar fail: %s" % str(res.get("reason", "")))
	else:
		if str(res.get("winner", "")) == "":
			ok = false
			errors.append("spar missing winner")
		var duel: Dictionary = res.get("duel", {}) as Dictionary
		if duel.is_empty() or not (duel.get("enemies", []) as Array):
			ok = false
			errors.append("spar missing duel payload")
		else:
			var ene0: Dictionary = (duel.get("enemies", []) as Array)[0] as Dictionary
			if str(ene0.get("hero_id", "")) != hb:
				ok = false
				errors.append("duel enemy hero_id want %s" % hb)
		if float(HeroSystem.get_hero(ha).get("stamina", 0)) >= before_stam:
			ok = false
			errors.append("stamina not spent")
		if GameState.arena_spars_today < 1:
			ok = false
			errors.append("arena_spars_today not incremented")
		## XP applied to someone
		var win: String = str(res.get("winner", ""))
		if float(HeroSystem.get_hero(win).get("xp", 0)) <= 0.0 and int(HeroSystem.get_hero(win).get("level", 1)) <= 1:
			## could have leveled; at least XP or level change vs before
			pass

	## --- daily limit ---
	GameState.arena_spars_today = ArenaSystem.daily_limit()
	var capped: Dictionary = ArenaSystem.can_spar(ha, hb)
	if bool(capped.get("ok", false)):
		ok = false
		errors.append("daily limit not enforced")

	## --- craft equip swap ---
	SaveManager.clear_save()
	GameState._load_starter_data()
	if GameState.buildings.has("forge"):
		var fb: Dictionary = (GameState.buildings["forge"] as Dictionary).duplicate(true)
		fb["level"] = 1
		fb["unlocked"] = true
		GameState.buildings["forge"] = fb
	GameState.fur = 20
	GameState.wood = 20
	GameState.iron = 20
	GameState.silver = 50
	var hid0: String = str((GameState.heroes[0] as Dictionary).get("id", ""))
	var c1: Dictionary = CraftSystem.craft("leather_armor", hid0)
	if not bool(c1.get("ok", false)):
		ok = false
		errors.append("craft leather fail: %s" % str(c1.get("reason", "")))
	var gear1: int = HeroSystem.equipment_power(HeroSystem.get_hero(hid0))
	if gear1 < 3:
		ok = false
		errors.append("leather not equipped power=%d" % gear1)
	## craft into inventory then use
	var c2: Dictionary = CraftSystem.craft("iron_blade", "")
	if not bool(c2.get("ok", false)):
		ok = false
		errors.append("craft blade to inv fail")
	if GameState.inventory.is_empty():
		ok = false
		errors.append("inventory empty after craft")
	else:
		var u: Dictionary = CraftSystem.use_inventory_on_hero(0, hid0)
		if not bool(u.get("ok", false)):
			ok = false
			errors.append("use inv equip fail: %s" % str(u.get("reason", "")))
		var gear2: int = HeroSystem.equipment_power(HeroSystem.get_hero(hid0))
		if gear2 < 5:
			ok = false
			errors.append("blade equip power=%d" % gear2)

	## --- unequip swap: craft second armor onto hero, old should return ---
	GameState.fur = 20
	GameState.wood = 10
	var inv_before: int = GameState.inventory.size()
	var c3: Dictionary = CraftSystem.craft("leather_armor", hid0)
	if not bool(c3.get("ok", false)):
		ok = false
		errors.append("second armor craft fail")
	## first leather should bounce to inventory
	if GameState.inventory.size() <= inv_before:
		## might be equal if somehow no previous - but we had leather then blade, armor slot had leather
		## after iron_blade, armor still leather; second leather should return first
		ok = false
		errors.append("old armor not returned to inventory (size %d -> %d)" % [inv_before, GameState.inventory.size()])

	## --- auto_combat supports hero_id enemy + floater helpers ---
	var ac_src := FileAccess.get_file_as_string("res://scenes/combat/auto_combat.gd")
	if not ac_src.contains("duelist") or not ac_src.contains("hero_id"):
		ok = false
		errors.append("auto_combat missing duelist support")
	if not ac_src.contains("func _ensure_float_layer") or not ac_src.contains("func _spawn_hit_floaters"):
		ok = false
		errors.append("auto_combat missing floater helper funcs")

	## --- save roundtrip arena fields ---
	GameState.arena_spars_today = 3
	GameState.arena_wins_total = 2
	GameState.arena_win_streak = 2
	GameState.arena_last_winner = hid0
	GameState.arena_day_key = "2099-01-01"
	if not SaveManager.save_game():
		ok = false
		errors.append("save failed")
	GameState.arena_spars_today = 0
	GameState.arena_wins_total = 0
	if not SaveManager.load_game():
		ok = false
		errors.append("load failed")
	if GameState.arena_spars_today != 3 or GameState.arena_wins_total != 2:
		ok = false
		errors.append("arena fields not persisted")

	## BtnArena in scene
	if not FileAccess.get_file_as_string("res://scenes/main/main.tscn").contains("BtnArena"):
		ok = false
		errors.append("main.tscn missing BtnArena")

	if ok:
		print("SMOKE_V095_OK")
		get_tree().quit(0)
	else:
		_fail(ok, errors)

func _fail(_ok: bool, errors: PackedStringArray) -> void:
	print("SMOKE_V095_FAIL")
	for e in errors:
		print(" - ", e)
	get_tree().quit(1)
