extends RefCounted
class_name ArenaSystem
## 比武台（獵魔村式村內切磋）— v0.9.5：可玩對決＋自動戰鬥演出＋日限

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

static func _today_key() -> String:
	## 跟抽卡一樣用本地曆日（箱鐘＝Asia/Hong_Kong）
	return Time.get_date_string_from_system()

static func ensure_day() -> void:
	var today: String = _today_key()
	if GameState.arena_day_key == today:
		return
	GameState.arena_day_key = today
	GameState.arena_spars_today = 0

static func daily_limit() -> int:
	ensure_loaded()
	return int(_cfg.get("daily_limit", 12))

static func spars_left() -> int:
	ensure_day()
	return maxi(0, daily_limit() - GameState.arena_spars_today)

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
	ensure_day()
	if not arena_ready():
		return {"ok": false, "reason": "先興建練功場（比武台依附）"}
	if spars_left() <= 0:
		return {"ok": false, "reason": "今日比武已達上限（%d）" % daily_limit()}
	if hero_a == "" or hero_b == "" or hero_a == hero_b:
		return {"ok": false, "reason": "剔選兩名唔同俠客切磋"}
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
	## 即時結算：戰力＋亂數；扣體力；勝者／敗者 XP（含升級）；回傳自動戰鬥用 duel 包
	var chk: Dictionary = can_spar(hero_a, hero_b)
	if not bool(chk.get("ok", false)):
		return {"ok": false, "reason": str(chk.get("reason", "")), "winner": "", "loser": ""}
	ensure_loaded()
	ensure_day()
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
	## 連勝微加成（最多 +6 XP）
	## 連勝微加成（以「即將寫入前」的 streak 計；最多 +6）
	var streak_bonus: float = minf(6.0, float(GameState.arena_win_streak) * 1.0)
	xp_win += streak_bonus * 0.5

	for hid in [hero_a, hero_b]:
		HeroSystem.mutate(hid, func(hd: Dictionary) -> void:
			hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - cost)
		)

	TrainingSystem.apply_xp_to_hero(winner, xp_win)
	TrainingSystem.apply_xp_to_hero(loser, xp_lose)

	GameState.arena_spars_today += 1
	if winner == GameState.arena_last_winner:
		GameState.arena_win_streak += 1
	else:
		GameState.arena_win_streak = 1
	GameState.arena_last_winner = winner
	GameState.arena_wins_total += 1

	var wname: String = str(HeroSystem.get_hero(winner).get("name", winner))
	var lname: String = str(HeroSystem.get_hero(loser).get("name", loser))
	var aname: String = str(HeroSystem.get_hero(hero_a).get("name", hero_a))
	var bname: String = str(HeroSystem.get_hero(hero_b).get("name", hero_b))
	var streak_txt: String = ""
	if GameState.arena_win_streak >= 2:
		streak_txt = "（%s 連勝 ×%d）" % [wname, GameState.arena_win_streak]
	GameState.push_report("比武台：%s 勝 %s%s · 今日剩 %d 場" % [
		wname, lname, streak_txt, spars_left()
	])

	var a_won: bool = winner == hero_a
	var summary := {
		"text": "比武結算\n%s（力%d／分%.0f） vs %s（力%d／分%.0f）\n勝者：%s　＋XP %.0f\n敗者：%s　＋XP %.0f%s\n今日剩餘比武：%d／%d" % [
			aname, pa, score_a,
			bname, pb, score_b,
			wname, xp_win,
			lname, xp_lose,
			streak_txt,
			spars_left(), daily_limit(),
		],
		"flavor": "練功場上刀劍相交，塵土微揚——此乃村內切磋，點到即止。",
		"silver": 0,
		"fur": 0,
		"success": true,
		"arena": true,
		"winner": winner,
		"loser": loser,
	}

	return {
		"ok": true,
		"reason": "",
		"winner": winner,
		"loser": loser,
		"hero_a": hero_a,
		"hero_b": hero_b,
		"score_a": score_a,
		"score_b": score_b,
		"power_a": pa,
		"power_b": pb,
		"xp_winner": xp_win,
		"xp_loser": xp_lose,
		"a_won": a_won,
		"summary": summary,
		"duel": {
			"title": "比武台 · %s vs %s" % [aname, bname],
			"heroes": [hero_a],
			"enemies": [{
				"kind": "duelist",
				"name": bname,
				"hero_id": hero_b,
				"scale": 1.0,
			}],
			"success": a_won,
			"duration": 4.2,
			"zone_bg": "hills",
			"battle_mode": "arena",
		},
		"stub": false,
	}
