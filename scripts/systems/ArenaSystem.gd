extends RefCounted
class_name ArenaSystem
## 比武台 stub（獵魔村式村內切磋）— v0.8.1：規則＋結算，未接完整 UI／演出

const DATA_PATH := "res://data/arena/core.json"

static var _cfg: Dictionary = {}
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_cfg = {}
	if FileAccess.file_exists(DATA_PATH):
		var f := FileAccess.open(DATA_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			_cfg = parsed as Dictionary
	_loaded = true

static func arena_ready() -> bool:
	ensure_loaded()
	var need: String = str(_cfg.get("require_building", "training"))
	var lv: int = int(_cfg.get("require_level", 1))
	return BuildingSystem.building_level(need) >= lv

static func stamina_cost() -> float:
	ensure_loaded()
	return float(_cfg.get("stamina_cost", 12))

static func can_spar(hero_a: String, hero_b: String) -> Dictionary:
	## { ok, reason }
	if not arena_ready():
		return {"ok": false, "reason": "先興建練功場（比武台依附）"}
	if hero_a == "" or hero_b == "" or hero_a == hero_b:
		return {"ok": false, "reason": "要揀兩名唔同俠客"}
	var a: Dictionary = HeroSystem.get_hero(hero_a)
	var b: Dictionary = HeroSystem.get_hero(hero_b)
	if a.is_empty() or b.is_empty():
		return {"ok": false, "reason": "俠客不存在"}
	if not HeroSystem.can_hunt(a) or not HeroSystem.can_hunt(b):
		return {"ok": false, "reason": "雙方要在村、狀態可用"}
	var cost: float = stamina_cost()
	if float(a.get("stamina", 0)) < cost or float(b.get("stamina", 0)) < cost:
		return {"ok": false, "reason": "體力唔夠（各要 %.0f）" % cost}
	return {"ok": true, "reason": ""}

static func spar(hero_a: String, hero_b: String) -> Dictionary:
	## 即時結算 stub：戰力＋少許亂數；勝者 XP／敗者少 XP；扣體力
	var chk: Dictionary = can_spar(hero_a, hero_b)
	if not bool(chk.get("ok", false)):
		return {"ok": false, "reason": str(chk.get("reason", "")), "winner": "", "loser": ""}
	ensure_loaded()
	var a: Dictionary = HeroSystem.get_hero(hero_a)
	var b: Dictionary = HeroSystem.get_hero(hero_b)
	var pa: int = HeroSystem.power_of(a)
	var pb: int = HeroSystem.power_of(b)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var score_a: float = float(pa) * rng.randf_range(0.85, 1.15)
	var score_b: float = float(pb) * rng.randf_range(0.85, 1.15)
	var winner: String = hero_a if score_a >= score_b else hero_b
	var loser: String = hero_b if winner == hero_a else hero_a
	var cost: float = stamina_cost()
	var xp_win: float = float(_cfg.get("xp_winner", 18))
	var xp_lose: float = float(_cfg.get("xp_loser", 8))

	for hid in [hero_a, hero_b]:
		HeroSystem.mutate(hid, func(hd: Dictionary) -> void:
			hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - cost)
			var add: float = xp_win if hid == winner else xp_lose
			hd["xp"] = float(hd.get("xp", 0)) + add
		)

	var wname: String = str(HeroSystem.get_hero(winner).get("name", winner))
	var lname: String = str(HeroSystem.get_hero(loser).get("name", loser))
	GameState.push_report("比武台：%s 勝 %s（切磋 XP 已入）" % [wname, lname])
	return {
		"ok": true,
		"reason": "",
		"winner": winner,
		"loser": loser,
		"score_a": score_a,
		"score_b": score_b,
		"xp_winner": xp_win,
		"xp_loser": xp_lose,
		"stub": true,
	}
