extends RefCounted
class_name HeroSystem
## 俠客系統 — 六兵種

enum WeaponType {
	DAO,    ## 刀
	JIAN,   ## 劍
	QIANG,  ## 長槍
	GUN,    ## 棍
	ANQI,   ## 暗器
	QUAN,   ## 拳腳
}

const WEAPON_NAMES := {
	WeaponType.DAO: "刀",
	WeaponType.JIAN: "劍",
	WeaponType.QIANG: "長槍",
	WeaponType.GUN: "棍",
	WeaponType.ANQI: "暗器",
	WeaponType.QUAN: "拳腳",
}

static func weapon_from_string(s: String) -> int:
	match s:
		"刀", "dao", "DAO":
			return WeaponType.DAO
		"劍", "jian", "JIAN":
			return WeaponType.JIAN
		"長槍", "槍", "qiang", "QIANG":
			return WeaponType.QIANG
		"棍", "gun", "GUN":
			return WeaponType.GUN
		"暗器", "anqi", "ANQI":
			return WeaponType.ANQI
		"拳腳", "拳", "quan", "QUAN":
			return WeaponType.QUAN
		_:
			return WeaponType.DAO

static func find_idle_heroes(limit: int = -1) -> Array:
	var result: Array = []
	for h in GameState.heroes:
		var hd: Dictionary = h as Dictionary
		if str(hd.get("status", "idle")) == "idle":
			result.append(hd)
			if limit > 0 and result.size() >= limit:
				break
	return result

static func set_status(hero_id: String, status: String) -> void:
	for i in range(GameState.heroes.size()):
		var hd: Dictionary = GameState.heroes[i] as Dictionary
		if str(hd.get("id", "")) == hero_id:
			hd["status"] = status
			GameState.heroes[i] = hd
			GameState.heroes_changed.emit()
			return

static func power_of(hero: Dictionary) -> int:
	var level: int = int(hero.get("level", 1))
	var base: int = int(hero.get("base_power", 10))
	return base + (level - 1) * 3
