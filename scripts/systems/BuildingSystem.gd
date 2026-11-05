extends RefCounted
class_name BuildingSystem
## 建築升級／解鎖

static func get_upgrade_cost(building_id: String) -> Dictionary:
	if not GameState.buildings.has(building_id):
		return {"silver": 999999, "wood": 999999}
	var b: Dictionary = GameState.buildings[building_id] as Dictionary
	var level: int = int(b.get("level", 0))
	var base_s: int = int(b.get("base_cost_silver", 50))
	var base_w: int = int(b.get("base_cost_wood", 20))
	var mult: float = 1.0
	for _i in range(maxi(0, level)):
		mult *= 1.5
	return {
		"silver": int(ceil(base_s * mult)),
		"wood": int(ceil(base_w * mult)),
	}

static func max_level(building_id: String) -> int:
	if not GameState.buildings.has(building_id):
		return 0
	return int((GameState.buildings[building_id] as Dictionary).get("max_level", 8))

static func can_upgrade(building_id: String) -> bool:
	if not GameState.buildings.has(building_id):
		return false
	var b: Dictionary = GameState.buildings[building_id] as Dictionary
	var level: int = int(b.get("level", 0))
	if level >= max_level(building_id):
		return false
	var cost: Dictionary = get_upgrade_cost(building_id)
	return GameState.silver >= int(cost.silver) and GameState.wood >= int(cost.wood)

static func upgrade(building_id: String) -> bool:
	if not can_upgrade(building_id):
		return false
	var cost: Dictionary = get_upgrade_cost(building_id)
	if not GameState.try_spend(int(cost.silver), int(cost.wood)):
		return false
	var b: Dictionary = GameState.buildings[building_id] as Dictionary
	b["level"] = int(b.get("level", 0)) + 1
	b["unlocked"] = true
	GameState.buildings[building_id] = b
	GameState.buildings_changed.emit()
	return true

static func building_level(building_id: String) -> int:
	if not GameState.buildings.has(building_id):
		return 0
	return int((GameState.buildings[building_id] as Dictionary).get("level", 0))

static func building_name(building_id: String) -> String:
	if not GameState.buildings.has(building_id):
		return building_id
	return str((GameState.buildings[building_id] as Dictionary).get("name", building_id))

static func sorted_building_ids() -> Array:
	var ids: Array = GameState.buildings.keys()
	ids.sort()
	## 固定顯示順序
	var preferred := ["manor", "inn", "forge", "clinic", "training", "bounty"]
	var out: Array = []
	for p in preferred:
		if GameState.buildings.has(p):
			out.append(p)
	for id in ids:
		if not out.has(id):
			out.append(id)
	return out
