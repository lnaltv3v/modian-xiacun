extends Control
## 墨點俠村 — 村莊總覽根（Control 占位 prototype）

const _BuildingSystem = preload("res://scripts/systems/BuildingSystem.gd")
const _HeroSystem = preload("res://scripts/systems/HeroSystem.gd")
const _DispatchSystem = preload("res://scripts/systems/DispatchSystem.gd")

@onready var hud_label: Label = %HudLabel
@onready var log_label: Label = %LogLabel
@onready var btn_dispatch: Button = %BtnDispatch
@onready var btn_inn: Button = %BtnInn
@onready var btn_save: Button = %BtnSave

var _dispatch: RefCounted = null
var _busy: bool = false

func _ready() -> void:
	_dispatch = _DispatchSystem.new()
	GameState.resources_changed.connect(_refresh_hud)
	GameState.heroes_changed.connect(_refresh_hud)
	GameState.buildings_changed.connect(_refresh_hud)
	_dispatch.dispatch_finished.connect(_on_dispatch_finished)
	btn_dispatch.pressed.connect(_on_dispatch_pressed)
	btn_inn.pressed.connect(_on_inn_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	_refresh_hud()
	_log("歡迎返嚟墨點俠村。開局六綠俠已就位。")

func _refresh_hud() -> void:
	var inn_lv: int = _BuildingSystem.building_level("inn")
	hud_label.text = "銀兩 %d　｜　木材 %d　｜　俠客 %d（閒 %d）　｜　客棧 Lv.%d" % [
		GameState.silver,
		GameState.wood,
		GameState.hero_count(),
		GameState.idle_hero_count(),
		inn_lv,
	]
	btn_dispatch.disabled = _busy or GameState.idle_hero_count() < 1
	var cost: Dictionary = _BuildingSystem.get_upgrade_cost("inn")
	btn_inn.text = "建／升客棧（銀%d 木%d）" % [int(cost.silver), int(cost.wood)]
	btn_inn.disabled = not _BuildingSystem.can_upgrade("inn")

func _on_dispatch_pressed() -> void:
	if _busy:
		return
	_busy = true
	_refresh_hud()
	_log("派出一名閒俠出征……（約 3 秒）")
	var ok: bool = _dispatch.dispatch_idle(1, 3.0, get_tree())
	if not ok:
		_busy = false
		_log("冇閒俠可派。")
		_refresh_hud()

func _on_dispatch_finished(rewards: Dictionary) -> void:
	_busy = false
	_log("回村！＋銀兩 %d、＋木材 %d" % [int(rewards.get("silver", 0)), int(rewards.get("wood", 0))])
	_refresh_hud()

func _on_inn_pressed() -> void:
	var before: int = _BuildingSystem.building_level("inn")
	if _BuildingSystem.upgrade("inn"):
		var after: int = _BuildingSystem.building_level("inn")
		if before == 0:
			_log("客棧落成！Lv.%d" % after)
		else:
			_log("客棧升至 Lv.%d" % after)
	else:
		_log("資源唔夠，升唔到客棧。")
	_refresh_hud()

func _on_save_pressed() -> void:
	if SaveManager.save_game():
		_log("已存檔（user://save_slot_0.json）")
	else:
		_log("存檔失敗。")

func _log(msg: String) -> void:
	log_label.text = msg
