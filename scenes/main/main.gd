extends Control
## 墨點俠村 v0.1 — 村莊核心循環 UI

const VillageScene := preload("res://scenes/village/village.tscn")
const HeroPortraitScript := preload("res://scripts/ui/HeroPortrait.gd")

@onready var hud_label: Label = %HudLabel
@onready var status_label: Label = %StatusLabel
@onready var report_label: Label = %ReportLabel
@onready var buildings_box: VBoxContainer = %BuildingsBox
@onready var heroes_box: VBoxContainer = %HeroesBox
@onready var hunt_label: Label = %HuntLabel
@onready var chk_auto: CheckBox = %ChkAuto
@onready var spin_count: SpinBox = %SpinCount
@onready var btn_dispatch: Button = %BtnDispatch
@onready var btn_save: Button = %BtnSave
@onready var btn_load: Button = %BtnLoad
@onready var village_host: Control = %VillageHost
@onready var icon_silver: TextureRect = %IconSilver
@onready var icon_wood: TextureRect = %IconWood
@onready var icon_fur: TextureRect = %IconFur
@onready var monster_preview: TextureRect = %MonsterPreview

var _dispatch: DispatchSystem
var _village: Control
var _selected: Dictionary = {}  ## hero_id -> bool
var _hero_rows: Dictionary = {}  ## hero_id -> { check, portrait, label }

func _ready() -> void:
	_dispatch = DispatchSystem.new()
	_dispatch.name = "DispatchSystem"
	add_child(_dispatch)

	_village = VillageScene.instantiate()
	village_host.add_child(_village)
	_village.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_village.building_clicked.connect(_on_building_clicked)

	_setup_resource_icons()
	_setup_monster_reserve()

	if SaveManager.has_save():
		SaveManager.load_game()
		GameState.push_report("已讀取存檔。")
	else:
		GameState.push_report("歡迎返嚟墨點俠村。開局六綠俠已就位。")

	_dispatch.resolve_due_hunts()

	GameState.resources_changed.connect(_refresh_hud)
	GameState.heroes_changed.connect(_on_heroes_changed)
	GameState.buildings_changed.connect(_rebuild_buildings)
	GameState.hunts_changed.connect(_refresh_hunts)
	GameState.reports_changed.connect(_refresh_reports)
	_dispatch.hunt_tick.connect(_refresh_hunts)
	_dispatch.hunt_finished.connect(_on_hunt_finished)

	chk_auto.toggled.connect(_on_auto_toggled)
	chk_auto.button_pressed = GameState.auto_dispatch
	spin_count.min_value = 1
	spin_count.max_value = 6
	spin_count.value = 1
	btn_dispatch.pressed.connect(_on_dispatch_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	btn_load.pressed.connect(_on_load_pressed)

	_rebuild_buildings()
	_rebuild_heroes()
	_refresh_hud()
	_refresh_hunts()
	_refresh_reports()

func _setup_resource_icons() -> void:
	_set_tex(icon_silver, ArtPaths.ICON_SILVER)
	_set_tex(icon_wood, ArtPaths.ICON_WOOD)
	_set_tex(icon_fur, ArtPaths.ICON_FUR)

func _setup_monster_reserve() -> void:
	## 預留戰鬥結果卡：先顯示亂山坡狼 idle
	_set_tex(monster_preview, ArtPaths.monster_idle("wolf"))
	monster_preview.tooltip_text = "戰鬥結果卡預留（狼／野豬／山賊）"

func _set_tex(node: TextureRect, path: String) -> void:
	var tex: Texture2D = ArtPaths.load_tex(path)
	if tex != null:
		node.texture = tex
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _on_heroes_changed() -> void:
	if _hero_rows.size() != GameState.hero_count():
		_rebuild_heroes()
	else:
		_refresh_hud()

func _rebuild_buildings() -> void:
	for c in buildings_box.get_children():
		c.queue_free()
	for bid_v in BuildingSystem.sorted_building_ids():
		var bid: String = str(bid_v)
		var b: Dictionary = GameState.buildings[bid] as Dictionary
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var itex: Texture2D = ArtPaths.load_tex(ArtPaths.building_icon(bid))
		if itex != null:
			icon.texture = itex
		row.add_child(icon)

		var lv: int = int(b.get("level", 0))
		var info := Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_color_override("font_color", Color(0.101961, 0.0823529, 0.0627451, 1))
		info.add_theme_font_size_override("font_size", 14)
		var cost: Dictionary = BuildingSystem.get_upgrade_cost(bid)
		var max_lv: int = BuildingSystem.max_level(bid)
		if lv >= max_lv:
			info.text = "%s  Lv.%d（滿）" % [str(b.get("name", bid)), lv]
		else:
			info.text = "%s  Lv.%d → 銀%d 木%d" % [
				str(b.get("name", bid)), lv, int(cost.silver), int(cost.wood)
			]
		info.tooltip_text = str(b.get("desc", ""))
		row.add_child(info)

		var btn := Button.new()
		btn.text = "升級" if lv > 0 or bool(b.get("unlocked", false)) else "興建"
		btn.disabled = not BuildingSystem.can_upgrade(bid)
		btn.pressed.connect(_on_upgrade.bind(bid))
		row.add_child(btn)
		buildings_box.add_child(row)

func _rebuild_heroes() -> void:
	## 保留選取
	var prev_sel: Dictionary = _selected.duplicate()
	_selected.clear()
	_hero_rows.clear()
	for c in heroes_box.get_children():
		c.queue_free()

	for h_v in GameState.heroes:
		var h: Dictionary = h_v as Dictionary
		var hid: String = str(h.get("id", ""))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.custom_minimum_size = Vector2(0, HeroPortraitScript.frame_px())

		var portrait: Control = HeroPortraitScript.new()
		row.add_child(portrait)
		portrait.setup(hid)
		portrait.play_for_status(str(h.get("status", "idle")))

		var chk := CheckBox.new()
		var can: bool = HeroSystem.can_hunt(h)
		chk.disabled = not can
		chk.button_pressed = bool(prev_sel.get(hid, false)) and can
		if chk.button_pressed:
			_selected[hid] = true
		chk.toggled.connect(_on_hero_toggled.bind(hid))
		row.add_child(chk)

		var lab := Label.new()
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.add_theme_color_override("font_color", Color(0.101961, 0.0823529, 0.0627451, 1))
		lab.add_theme_font_size_override("font_size", 13)
		lab.text = _hero_line(h)
		row.add_child(lab)

		heroes_box.add_child(row)
		_hero_rows[hid] = {"check": chk, "portrait": portrait, "label": lab}

func _hero_line(h: Dictionary) -> String:
	var st: String = str(h.get("status", "idle"))
	var st_cn := "在村" if st == "idle" else ("出征" if st == "hunting" else st)
	return "%s · %s · 力%d · 體%.0f 飽%.0f 傷%.0f · %s" % [
		str(h.get("name", "")),
		str(h.get("weapon", "")),
		HeroSystem.power_of(h),
		float(h.get("stamina", 0)),
		float(h.get("satiety", 0)),
		float(h.get("injury", 0)),
		st_cn,
	]

func _refresh_hud() -> void:
	hud_label.text = "銀兩 %d　　木材 %d　　毛皮 %d　　駐紮 %d／%d　　在村 %d　出征 %d" % [
		GameState.silver,
		GameState.wood,
		GameState.fur,
		GameState.hero_count(),
		GameState.hero_capacity(),
		GameState.idle_hero_count(),
		GameState.hunting_hero_count(),
	]
	status_label.text = "恢復：體+%.1f/s 飽+%.1f/s 傷-%.1f/s　｜　%s" % [
		GameState.recovery_stamina_per_sec(),
		GameState.recovery_satiety_per_sec(),
		GameState.recovery_injury_per_sec(),
		ResourceLoop.describe_loop(),
	]
	## 輕量更新俠客文字／動畫，唔拆行
	for hid in _hero_rows.keys():
		var hero: Dictionary = HeroSystem.get_hero(str(hid))
		if hero.is_empty():
			continue
		var row: Dictionary = _hero_rows[hid] as Dictionary
		var lab: Label = row.get("label") as Label
		var portrait = row.get("portrait")
		var chk: CheckBox = row.get("check") as CheckBox
		if lab:
			lab.text = _hero_line(hero)
		if portrait and portrait.has_method("play_for_status"):
			portrait.play_for_status(str(hero.get("status", "idle")))
		if chk:
			var can: bool = HeroSystem.can_hunt(hero)
			chk.disabled = not can
			if not can:
				chk.button_pressed = false
				_selected.erase(hid)
	_refresh_dispatch_btn()

func _refresh_hunts() -> void:
	if GameState.active_hunts.is_empty():
		hunt_label.text = "出征中：無"
	else:
		var parts: PackedStringArray = PackedStringArray()
		for hv in GameState.active_hunts:
			var hunt: Dictionary = hv as Dictionary
			var left: float = _dispatch.seconds_left(hunt)
			var names: PackedStringArray = PackedStringArray()
			for idv in hunt.get("hero_ids", []):
				names.append(str(HeroSystem.get_hero(str(idv)).get("name", idv)))
			parts.append("%s［%s］剩 %.1fs" % [
				str(hunt.get("zone_name", "")), "、".join(names), left
			])
		hunt_label.text = "出征中：" + " ｜ ".join(parts)
	_refresh_dispatch_btn()

func _refresh_reports() -> void:
	var lines: PackedStringArray = PackedStringArray()
	for i in range(mini(8, GameState.reports.size())):
		lines.append(str(GameState.reports[i]))
	report_label.text = "\n".join(lines) if lines.size() > 0 else "（尚無回報）"

func _refresh_dispatch_btn() -> void:
	var n: int = 0
	for k in _selected.keys():
		if bool(_selected[k]):
			n += 1
	btn_dispatch.disabled = n < 1 and not GameState.auto_dispatch
	btn_dispatch.text = "出征亂山坡（已選 %d）" % n

func _on_hero_toggled(pressed: bool, hid: String) -> void:
	if pressed:
		_selected[hid] = true
	else:
		_selected.erase(hid)
	_refresh_dispatch_btn()

func _on_auto_toggled(pressed: bool) -> void:
	GameState.auto_dispatch = pressed
	GameState.push_report("自動出征：%s" % ("開" if pressed else "關"))

func _on_dispatch_pressed() -> void:
	var ids: Array = []
	for hid in _selected.keys():
		if bool(_selected[hid]):
			ids.append(hid)
	if ids.is_empty():
		## 無選取則按 spin 派 ready
		var res: Dictionary = _dispatch.dispatch_ready(int(spin_count.value), "luan_shan_po")
		if not bool(res.get("ok", false)):
			GameState.push_report("派遣失敗：%s" % str(res.get("reason", "")))
		_selected.clear()
		_rebuild_heroes()
		return
	var res2: Dictionary = _dispatch.start_hunt(ids, "luan_shan_po")
	if not bool(res2.get("ok", false)):
		GameState.push_report("派遣失敗：%s" % str(res2.get("reason", "")))
	_selected.clear()
	_rebuild_heroes()

func _on_upgrade(building_id: String) -> void:
	var before: int = BuildingSystem.building_level(building_id)
	var name_cn: String = BuildingSystem.building_name(building_id)
	if BuildingSystem.upgrade(building_id):
		var after: int = BuildingSystem.building_level(building_id)
		if before == 0:
			GameState.push_report("%s落成！Lv.%d（駐紮上限 %d）" % [name_cn, after, GameState.hero_capacity()])
		else:
			GameState.push_report("%s升至 Lv.%d" % [name_cn, after])
	else:
		GameState.push_report("資源唔夠或已滿級：%s" % name_cn)
	_rebuild_buildings()

func _on_building_clicked(building_id: String) -> void:
	_on_upgrade(building_id)

func _on_hunt_finished(_rewards: Dictionary) -> void:
	_rebuild_heroes()
	_refresh_hud()
	_refresh_hunts()

func _on_save_pressed() -> void:
	if SaveManager.save_game():
		GameState.push_report("已存檔 v%d（user://save_slot_0.json）" % SaveManager.SAVE_VERSION)
	else:
		GameState.push_report("存檔失敗。")

func _on_load_pressed() -> void:
	if SaveManager.load_game():
		_dispatch.resolve_due_hunts()
		chk_auto.button_pressed = GameState.auto_dispatch
		_selected.clear()
		_rebuild_buildings()
		_rebuild_heroes()
		_refresh_hud()
		_refresh_hunts()
		_refresh_reports()
		GameState.push_report("已讀檔。")
	else:
		GameState.push_report("冇存檔可讀。")
