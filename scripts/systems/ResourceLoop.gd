extends RefCounted
class_name ResourceLoop
## 資源循環：建築 → 服務俠客 → 變強 → 帶回資源 → 村莊升級

static func describe_loop() -> String:
	return "建築服務俠客 → 俠客變強 → 派遣帶回資源 → 升級村莊"

static func inn_bonus_silver_per_tick() -> int:
	var lv: int = BuildingSystem.building_level("inn")
	return lv * 1

static func forge_bonus_power() -> int:
	var lv: int = BuildingSystem.building_level("forge")
	return lv * 2

static func training_bonus_xp() -> int:
	var lv: int = BuildingSystem.building_level("training")
	return lv * 5
