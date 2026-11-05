extends RefCounted
class_name TrainingSystem
## 練功場最小經驗升級：在村閒置俠客按練功場等級攞 XP，滿則升級。

static func xp_to_next(level: int) -> int:
	var lv: int = maxi(1, level)
	return 40 + (lv - 1) * 25

static func xp_per_sec() -> float:
	var lv: int = BuildingSystem.building_level("training")
	if lv < 1:
		return 0.0
	return 2.0 + float(lv) * 3.0 + float(ResourceLoop.training_bonus_xp()) * 0.15

static func tick(delta: float) -> Dictionary:
	if delta <= 0.0:
		return {"gained": 0, "levelups": []}
	var rate: float = xp_per_sec()
	if rate <= 0.0:
		return {"gained": 0, "levelups": []}

	var gained_total: int = 0
	var levelups: Array = []
	var changed: bool = false

	for i in range(GameState.heroes.size()):
		var hd: Dictionary = (GameState.heroes[i] as Dictionary).duplicate(true)
		if str(hd.get("status", "idle")) != "idle":
			continue
		var lv: int = int(hd.get("level", 1))
		var xp: float = float(hd.get("xp", 0))
		var need: float = float(xp_to_next(lv))
		var add: float = rate * delta
		xp += add
		gained_total += int(floor(add))
		var ups: int = 0
		while xp >= need and lv < 30:
			xp -= need
			lv += 1
			ups += 1
			need = float(xp_to_next(lv))
		hd["level"] = lv
		hd["xp"] = xp
		hd["xp_to_next"] = int(need)
		GameState.heroes[i] = HeroSystem.normalize_hero(hd)
		changed = true
		if ups > 0:
			levelups.append({"id": str(hd.get("id", "")), "name": str(hd.get("name", "")), "level": lv, "ups": ups})

	if changed:
		GameState.heroes_changed.emit()
	for lu in levelups:
		var d: Dictionary = lu as Dictionary
		GameState.push_report("%s 修煉有成，升至 Lv.%d！" % [str(d.get("name", "")), int(d.get("level", 1))])

	return {"gained": gained_total, "levelups": levelups}
