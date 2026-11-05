extends RefCounted
class_name BountySystem
## 懸賞榜最小 — 指定目標匪／狼，擊中額外賞

const TARGETS_PATH := "res://data/bounty/targets.json"

static var _targets: Array = []
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_targets.clear()
	if not FileAccess.file_exists(TARGETS_PATH):
		push_warning("BountySystem: missing %s" % TARGETS_PATH)
		_loaded = true
		return
	var f := FileAccess.open(TARGETS_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_targets = (parsed as Array).duplicate(true)
	_loaded = true

static func all_targets() -> Array:
	ensure_loaded()
	return _targets.duplicate(true)

static func get_target(target_id: String) -> Dictionary:
	ensure_loaded()
	if target_id == "" or target_id == "none":
		return {}
	for t in _targets:
		var td: Dictionary = t as Dictionary
		if str(td.get("id", "")) == target_id:
			return td.duplicate(true)
	return {}

static func set_active(target_id: String) -> Dictionary:
	ensure_loaded()
	if BuildingSystem.building_level("bounty") < 1:
		return {"ok": false, "reason": "懸賞榜未啟用"}
	if target_id == "" or target_id == "none":
		GameState.bounty_target = ""
		GameState.push_report("懸賞榜：已取消指定目標。")
		return {"ok": true, "reason": "", "target": ""}
	var t: Dictionary = get_target(target_id)
	if t.is_empty():
		return {"ok": false, "reason": "未知懸賞目標"}
	GameState.bounty_target = target_id
	GameState.push_report("懸賞榜：鎖定「%s」——擊中有額外賞。" % str(t.get("name", target_id)))
	return {"ok": true, "reason": "", "target": target_id}

static func active_target() -> Dictionary:
	return get_target(GameState.bounty_target)

static func calc_bonus(enemies: Array) -> Dictionary:
	## { silver, fur, iron, hits, target_name }
	var t: Dictionary = active_target()
	if t.is_empty():
		return {"silver": 0, "fur": 0, "iron": 0, "hits": 0, "target_name": ""}
	var kind: String = str(t.get("kind", ""))
	var hits: int = 0
	for ev in enemies:
		if str((ev as Dictionary).get("kind", "")) == kind:
			hits += 1
	if hits <= 0:
		return {"silver": 0, "fur": 0, "iron": 0, "hits": 0, "target_name": str(t.get("name", ""))}
	var mult: float = 1.0 + float(BuildingSystem.building_level("bounty") - 1) * 0.1
	var silver: int = int(round(float(int(t.get("bonus_silver", 0)) * hits) * mult))
	var fur: int = int(round(float(int(t.get("bonus_fur", 0)) * hits) * mult))
	var iron: int = int(round(float(int(t.get("bonus_iron", 0)) * hits) * mult))
	return {
		"silver": silver,
		"fur": fur,
		"iron": iron,
		"hits": hits,
		"target_name": str(t.get("name", kind)),
	}
