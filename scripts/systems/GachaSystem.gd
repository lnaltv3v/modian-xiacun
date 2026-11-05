extends RefCounted
class_name GachaSystem
## 英雄帖／抽卡 — 白→紅；日節奏；銀／免費／鑽石；重覆轉碎片；軟保底

const POOL_PATH := "res://data/gacha/pool.json"

static var _pool: Dictionary = {}
static var _loaded: bool = false
static var _rng := RandomNumberGenerator.new()
static var _rng_ready: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_pool = {}
	if not FileAccess.file_exists(POOL_PATH):
		push_warning("GachaSystem: missing %s" % POOL_PATH)
		_loaded = true
		return
	var f := FileAccess.open(POOL_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_pool = (parsed as Dictionary).duplicate(true)
	_loaded = true
	if not _rng_ready:
		_rng.randomize()
		_rng_ready = true

static func pacing() -> Dictionary:
	ensure_loaded()
	var p: Variant = _pool.get("pacing", {})
	if typeof(p) == TYPE_DICTIONARY:
		return (p as Dictionary).duplicate(true)
	return {
		"daily_silver_limit": 30,
		"free_pull_per_day": 1,
		"diamond_single_cost": 3,
		"diamond_ten_cost": 28,
	}

static func _today_key() -> String:
	## 箱鐘已係 Asia/Hong_Kong；用系統日曆日
	return Time.get_date_string_from_system()

static func ensure_day() -> void:
	var today: String = _today_key()
	if GameState.gacha_day_key == today:
		return
	GameState.gacha_day_key = today
	GameState.gacha_silver_today = 0
	GameState.gacha_free_used_today = false

static func pull_cost() -> int:
	ensure_loaded()
	return int(_pool.get("pull_cost_silver", 40))

static func diamond_single_cost() -> int:
	return int(pacing().get("diamond_single_cost", 3))

static func diamond_ten_cost() -> int:
	return int(pacing().get("diamond_ten_cost", 28))

static func daily_silver_limit() -> int:
	return int(pacing().get("daily_silver_limit", 30))

static func free_pulls_remaining() -> int:
	ensure_day()
	var per: int = int(pacing().get("free_pull_per_day", 1))
	if GameState.gacha_free_used_today:
		return 0
	return maxi(0, per)

static func silver_pulls_remaining() -> int:
	ensure_day()
	return maxi(0, daily_silver_limit() - GameState.gacha_silver_today)

static func can_pull() -> Dictionary:
	## 銀抽（或免費抽）可否
	ensure_loaded()
	ensure_day()
	var bid: String = str(_pool.get("require_building", "manor"))
	var need_lv: int = int(_pool.get("require_level", 1))
	if bid != "" and BuildingSystem.building_level(bid) < need_lv:
		return {"ok": false, "reason": "%s 未達 Lv.%d" % [BuildingSystem.building_name(bid), need_lv]}
	if free_pulls_remaining() > 0:
		return {"ok": true, "reason": "今日免費抽", "mode": "free"}
	if silver_pulls_remaining() <= 0:
		return {"ok": false, "reason": "今日銀抽已達上限（%d），改用鑽石" % daily_silver_limit(), "mode": "capped"}
	var cost: int = pull_cost()
	if GameState.silver < cost:
		return {"ok": false, "reason": "銀兩唔夠（要 %d）" % cost, "mode": "silver"}
	return {"ok": true, "reason": "", "mode": "silver"}

static func can_pull_diamond(count: int = 1) -> Dictionary:
	ensure_loaded()
	ensure_day()
	var bid: String = str(_pool.get("require_building", "manor"))
	var need_lv: int = int(_pool.get("require_level", 1))
	if bid != "" and BuildingSystem.building_level(bid) < need_lv:
		return {"ok": false, "reason": "%s 未達 Lv.%d" % [BuildingSystem.building_name(bid), need_lv]}
	var cost: int = diamond_ten_cost() if count >= 10 else diamond_single_cost() * maxi(1, count)
	if count >= 10:
		cost = diamond_ten_cost()
	elif count > 1:
		cost = diamond_single_cost() * count
	else:
		cost = diamond_single_cost()
	if GameState.diamonds < cost:
		return {"ok": false, "reason": "鑽石唔夠（要 %d）" % cost, "cost": cost}
	return {"ok": true, "reason": "", "cost": cost}

static func rarity_weights() -> Dictionary:
	ensure_loaded()
	var w: Variant = _pool.get("weights", {})
	if typeof(w) == TYPE_DICTIONARY:
		return (w as Dictionary).duplicate(true)
	return {"白": 45, "綠": 28, "藍": 14, "紫": 8, "橙": 4, "紅": 1}

static func soft_pity() -> Dictionary:
	ensure_loaded()
	var sp: Variant = _pool.get("soft_pity", {})
	if typeof(sp) == TYPE_DICTIONARY:
		return (sp as Dictionary).duplicate(true)
	return {"red_threshold": 120, "orange_threshold": 40}

static func heroes_of_rarity(rarity: String) -> Array:
	ensure_loaded()
	var out: Array = []
	var arr: Array = _pool.get("heroes", []) as Array
	for h in arr:
		var hd: Dictionary = h as Dictionary
		if str(hd.get("rarity", "")) == rarity:
			out.append(hd.duplicate(true))
	return out

static func _pick_rarity() -> String:
	var sp: Dictionary = soft_pity()
	var red_th: int = int(sp.get("red_threshold", 120))
	var orange_th: int = int(sp.get("orange_threshold", 40))
	if GameState.pity_red >= red_th and not heroes_of_rarity("紅").is_empty():
		return "紅"
	if GameState.pity_orange >= orange_th and not heroes_of_rarity("橙").is_empty():
		return "橙"

	var weights: Dictionary = rarity_weights()
	if GameState.pity_orange >= int(orange_th * 0.75) and weights.has("橙"):
		weights["橙"] = int(weights["橙"]) * 2
	if GameState.pity_red >= int(red_th * 0.85) and weights.has("紅"):
		weights["紅"] = maxi(1, int(weights["紅"]) * 3)

	var total: int = 0
	for k in weights.keys():
		total += int(weights[k])
	if total <= 0:
		return "白"
	var roll: int = _rng.randi_range(1, total)
	var acc: int = 0
	for k2 in weights.keys():
		acc += int(weights[k2])
		if roll <= acc:
			return str(k2)
	return "白"

static func _find_owned_by_template(template_id: String) -> int:
	for i in range(GameState.heroes.size()):
		var h: Dictionary = GameState.heroes[i] as Dictionary
		if str(h.get("template_id", "")) == template_id and template_id != "":
			return i
	return -1

static func fragment_for(rarity: String) -> int:
	ensure_loaded()
	var table: Variant = _pool.get("fragment_per_dupe", {})
	if typeof(table) == TYPE_DICTIONARY:
		return int((table as Dictionary).get(rarity, 5))
	return 5

static func _apply_pity_after(rarity: String) -> void:
	GameState.pity_red += 1
	GameState.pity_orange += 1
	if rarity == "紅":
		GameState.pity_red = 0
		GameState.pity_orange = 0
	elif rarity == "橙":
		GameState.pity_orange = 0
	GameState.gacha_pulls_total += 1

static func _resolve_one(paid_note: String = "") -> Dictionary:
	## 唔扣費；呼叫端已扣。回傳同 pull_once 結構
	var rarity: String = _pick_rarity()
	var pity_forced: bool = false
	var sp: Dictionary = soft_pity()
	if rarity == "紅" and GameState.pity_red >= int(sp.get("red_threshold", 120)):
		pity_forced = true
	if rarity == "橙" and GameState.pity_orange >= int(sp.get("orange_threshold", 40)):
		pity_forced = true

	var candidates: Array = heroes_of_rarity(rarity)
	if candidates.is_empty():
		candidates = _pool.get("heroes", []) as Array
	if candidates.is_empty():
		return {"ok": false, "reason": "卡池空", "result": "", "hero": {}, "fragments_gained": 0}

	var pick: Dictionary = (candidates[_rng.randi_range(0, candidates.size() - 1)] as Dictionary).duplicate(true)
	var template_id: String = str(pick.get("template_id", ""))
	var owned_idx: int = _find_owned_by_template(template_id)

	_apply_pity_after(rarity)
	var prefix: String = paid_note if paid_note != "" else ""

	if owned_idx >= 0:
		var frags: int = fragment_for(rarity)
		GameState.add_fragments(frags)
		var owned_name: String = str((GameState.heroes[owned_idx] as Dictionary).get("name", template_id))
		var pity_txt: String = "（保底）" if pity_forced else ""
		GameState.push_report("英雄帖%s%s：重覆「%s」（%s）→ 碎片＋%d｜紅保%d／橙保%d" % [
			prefix, pity_txt, owned_name, rarity, frags, GameState.pity_red, GameState.pity_orange
		])
		return {
			"ok": true,
			"reason": "",
			"result": "dupe",
			"hero": (GameState.heroes[owned_idx] as Dictionary).duplicate(true),
			"fragments_gained": frags,
			"rarity": rarity,
			"template_id": template_id,
			"pity_forced": pity_forced,
		}

	var new_hero: Dictionary = {
		"id": "gacha_%s_%d" % [template_id, Time.get_ticks_msec()],
		"template_id": template_id,
		"name": str(pick.get("name", template_id)),
		"weapon": str(pick.get("weapon", "刀")),
		"rarity": rarity,
		"level": 1,
		"base_power": int(pick.get("base_power", 8)),
		"personality": str(pick.get("personality", "")),
		"status": "idle",
		"stamina": 100,
		"max_stamina": 100,
		"satiety": 100,
		"injury": 0,
		"art_key": str(pick.get("art_key", "")),
		"art_stem": str(pick.get("art_stem", "")),
		"placeholder": false if str(pick.get("art_key", "")) != "" else bool(pick.get("placeholder", false)),
		"equipment": {},
		"passive_id": "",
		"passive_name": "",
	}
	new_hero = HeroSystem.normalize_hero(new_hero)
	GameState.heroes.append(new_hero)
	GameState.heroes_changed.emit()
	var pity_txt2: String = "（保底）" if pity_forced else ""
	GameState.push_report("英雄帖%s%s：新俠「%s」（%s）加入！｜紅保%d／橙保%d" % [
		prefix, pity_txt2, str(new_hero.get("name", "")), rarity, GameState.pity_red, GameState.pity_orange
	])
	return {
		"ok": true,
		"reason": "",
		"result": "new",
		"hero": new_hero.duplicate(true),
		"fragments_gained": 0,
		"rarity": rarity,
		"template_id": template_id,
		"pity_forced": pity_forced,
	}

static func pull_once() -> Dictionary:
	## 優先免費 → 銀抽
	var check: Dictionary = can_pull()
	if not bool(check.get("ok", false)):
		return {"ok": false, "reason": str(check.get("reason", "")), "result": "", "hero": {}, "fragments_gained": 0}

	ensure_day()
	var mode: String = str(check.get("mode", "silver"))
	if mode == "free":
		GameState.gacha_free_used_today = true
		return _resolve_one("（免費）")

	var cost: int = pull_cost()
	if not GameState.try_spend(cost, 0, 0, 0):
		return {"ok": false, "reason": "扣銀失敗", "result": "", "hero": {}, "fragments_gained": 0}
	GameState.gacha_silver_today += 1
	return _resolve_one("")

static func pull_diamond(count: int = 1) -> Dictionary:
	## 鑽石單抽／十連 stub
	var n: int = clampi(count, 1, 10)
	var check: Dictionary = can_pull_diamond(n)
	if not bool(check.get("ok", false)):
		return {"ok": false, "reason": str(check.get("reason", "")), "results": [], "cost": 0}
	var cost: int = int(check.get("cost", diamond_single_cost()))
	if not GameState.try_spend_diamonds(cost):
		return {"ok": false, "reason": "扣鑽失敗", "results": [], "cost": cost}
	var results: Array = []
	var note: String = "（鑽×%d）" % cost
	for _i in range(n):
		results.append(_resolve_one(note if n == 1 else "（十連）"))
	return {"ok": true, "reason": "", "results": results, "cost": cost, "count": n}

static func status_line() -> String:
	ensure_day()
	return "鑽%d｜今銀%d／%d｜免%d｜紅保%d 橙保%d" % [
		GameState.diamonds,
		GameState.gacha_silver_today,
		daily_silver_limit(),
		free_pulls_remaining(),
		GameState.pity_red,
		GameState.pity_orange,
	]
