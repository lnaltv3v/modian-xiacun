extends RefCounted
class_name DispatchSystem
## 派遣出征／回村

signal dispatch_started(hero_ids: Array)
signal dispatch_finished(rewards: Dictionary)

var _pending_ids: Array = []
var _timer: SceneTreeTimer = null

func dispatch_idle(count: int = 1, duration_sec: float = 3.0, tree: SceneTree = null) -> bool:
	var idle: Array = HeroSystem.find_idle_heroes(count)
	if idle.is_empty():
		return false
	_pending_ids.clear()
	for h in idle:
		var hd: Dictionary = h as Dictionary
		var hid: String = str(hd.get("id", ""))
		_pending_ids.append(hid)
		HeroSystem.set_status(hid, "dispatch")
	dispatch_started.emit(_pending_ids.duplicate())
	if tree == null:
		_finish_dispatch()
		return true
	_timer = tree.create_timer(duration_sec)
	_timer.timeout.connect(_finish_dispatch, CONNECT_ONE_SHOT)
	return true

func _finish_dispatch() -> void:
	var total_power: int = 0
	for hid in _pending_ids:
		for h in GameState.heroes:
			var hd: Dictionary = h as Dictionary
			if str(hd.get("id", "")) == str(hid):
				total_power += HeroSystem.power_of(hd)
				HeroSystem.set_status(str(hid), "idle")
				break
	var silver_gain: int = 8 + int(total_power / 2.0)
	var wood_gain: int = 3 + int(total_power / 4.0)
	GameState.add_silver(silver_gain)
	GameState.add_wood(wood_gain)
	var rewards: Dictionary = {
		"silver": silver_gain,
		"wood": wood_gain,
		"heroes": _pending_ids.duplicate(),
	}
	_pending_ids.clear()
	dispatch_finished.emit(rewards)
