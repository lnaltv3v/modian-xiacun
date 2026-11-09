extends Control
## 墨點俠村 v0.18.1 — 開局六綠俠高密度美術接入

const VillageScene := preload("res://scenes/village/village.tscn")
const HuntResultScene := preload("res://scenes/combat/hunt_result.tscn")
const DungeonRunScene := preload("res://scenes/combat/dungeon_run.tscn")
const AutoCombatScene := preload("res://scenes/combat/auto_combat.tscn")
const HeroPortraitScript := preload("res://scripts/ui/HeroPortrait.gd")
const _GachaFlashScript := preload("res://scripts/ui/GachaFlash.gd")
const _OutpostScript := preload("res://scripts/systems/OutpostSystem.gd")

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
@onready var icon_iron: TextureRect = %IconIron
@onready var lab_silver: Label = %LabSilver
@onready var lab_wood: Label = %LabWood
@onready var lab_fur: Label = %LabFur
@onready var lab_iron: Label = %LabIron
@onready var monster_preview: TextureRect = %MonsterPreview
@onready var craft_box: VBoxContainer = %CraftBox
@onready var inv_label: Label = %InvLabel
@onready var title_label: Label = %Title
@onready var tutorial_banner: ColorRect = %TutorialBanner
@onready var tutorial_label: Label = %TutorialLabel
@onready var btn_skip_tutorial: Button = %BtnSkipTutorial
@onready var btn_gacha: Button = %BtnGacha
var btn_gacha10: Button
@onready var frag_label: Label = %FragLabel
@onready var opt_bounty: OptionButton = %OptBounty
@onready var chk_auto_shop: CheckBox = %ChkAutoShop
@onready var btn_shop_once: Button = %BtnShopOnce
@onready var btn_dungeon: Button = %BtnDungeon
@onready var btn_academy: Button = %BtnAcademy
@onready var opt_zone: OptionButton = %OptZone
@onready var btn_outpost: Button = %BtnOutpost
@onready var btn_arena: Button = %BtnArena

var _dispatch: DispatchSystem
var _village: Control
var _hunt_result: Control
var _dungeon_run: Control
var _auto_combat: Control
var _selected: Dictionary = {}
var _hero_rows: Dictionary = {}
var _craft_hero_id: String = ""
var _battle_queue: Array = []
var _battle_final: Dictionary = {}
var _battle_mode: String = ""
var _rng_ui := RandomNumberGenerator.new()
var _gacha_flash: Control
var _btn_upkeep: Button
var _upkeep_panel: ColorRect
var _upkeep_label: Label
var _dungeon_panel: ColorRect
var _dungeon_label: Label
var _dungeon_btns: HBoxContainer
var _dungeon_wave_btns: HBoxContainer
var _btn_dungeon_go: Button
var _outpost_panel: ColorRect
var _outpost_label: Label
var _outpost_btns: HBoxContainer
var _btn_outpost_go: Button
var _camp_btns: HBoxContainer
var _btn_camp_station: Button
var _btn_camp_recall: Button
var _btn_camp_upgrade: Button
var _btn_camp_patrol: Button
var _academy_panel: ColorRect
var _academy_label: Label
var _academy_btns: VBoxContainer
var _academy_preview: Label
var _academy_pick_node: String = ""
var _academy_branch_row: HBoxContainer
var _academy_unlock_flash: ColorRect
var _dense_hud_bg: TextureRect
var _chip_food_icon: TextureRect
var _chip_lodge_icon: TextureRect
var _chip_med_icon: TextureRect
var _chip_food_lab: Label
var _chip_lodge_lab: Label
var _chip_med_lab: Label
var _chip_ready_lab: Label
var _chip_dungeon_lab: Label
var _chip_outpost_lab: Label

func _ready() -> void:
	_dispatch = DispatchSystem.new()
	_dispatch.name = "DispatchSystem"
	add_child(_dispatch)

	_village = VillageScene.instantiate()
	village_host.add_child(_village)
	_village.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_village.building_clicked.connect(_on_building_clicked)
	if _village.has_signal("building_placed"):
		_village.building_placed.connect(_on_building_placed)

	_hunt_result = HuntResultScene.instantiate()
	add_child(_hunt_result)

	_dungeon_run = DungeonRunScene.instantiate()
	add_child(_dungeon_run)
	if _dungeon_run.has_signal("closed"):
		_dungeon_run.closed.connect(_on_dungeon_closed)

	_auto_combat = AutoCombatScene.instantiate()
	add_child(_auto_combat)
	if _auto_combat.has_signal("finished"):
		_auto_combat.finished.connect(_on_auto_combat_finished)
	_rng_ui.randomize()
	_gacha_flash = _GachaFlashScript.new()
	_gacha_flash.name = "GachaFlash"
	add_child(_gacha_flash)

	if title_label:
		title_label.text = "墨點俠村 · v0.18.1"

	_setup_resource_icons()
	_setup_ui_art()
	_setup_monster_reserve()

	if SaveManager.has_save():
		SaveManager.load_game()
		GameState.push_report("已讀取存檔。")
	else:
		GameState.push_report("歡迎返嚟墨點俠村。開局六綠俠已就位。")
		GameState.tutorial_step = 1

	_dispatch.resolve_due_hunts()

	GameState.resources_changed.connect(_refresh_hud)
	GameState.heroes_changed.connect(_on_heroes_changed)
	GameState.buildings_changed.connect(_on_buildings_changed)
	GameState.hunts_changed.connect(_refresh_hunts)
	GameState.reports_changed.connect(_refresh_reports)
	GameState.inventory_changed.connect(_refresh_craft)
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
	if btn_skip_tutorial:
		btn_skip_tutorial.pressed.connect(_on_skip_tutorial)

	_setup_bounty_options()
	if btn_gacha:
		btn_gacha.pressed.connect(_on_gacha_pressed)
		_ensure_gacha10_btn()
	if opt_bounty:
		opt_bounty.item_selected.connect(_on_bounty_selected)
	if chk_auto_shop:
		chk_auto_shop.toggled.connect(_on_auto_shop_toggled)
		chk_auto_shop.button_pressed = GameState.auto_shop
	if btn_shop_once:
		btn_shop_once.pressed.connect(_on_shop_once_pressed)
	if btn_dungeon:
		btn_dungeon.pressed.connect(_on_dungeon_pressed)
	if btn_academy:
		btn_academy.pressed.connect(_on_academy_pressed)
	_setup_zone_options()
	if opt_zone:
		opt_zone.item_selected.connect(_on_zone_selected)
	if btn_outpost:
		btn_outpost.pressed.connect(_on_outpost_pressed)
	if btn_arena:
		btn_arena.pressed.connect(_on_arena_pressed)
	_setup_upkeep_panel()
	_setup_dungeon_panel()
	_setup_outpost_panel()
	_setup_academy_panel()

	_rebuild_buildings()
	_rebuild_heroes()
	_refresh_craft()
	_refresh_hud()
	_refresh_hunts()
	_refresh_reports()
	_refresh_tutorial()

func _setup_resource_icons() -> void:
	## Pivot R6 drop-in：32×32 icons @ assets/art/ui/
	for pair in [
		[icon_silver, ArtPaths.ICON_SILVER],
		[icon_wood, ArtPaths.ICON_WOOD],
		[icon_fur, ArtPaths.ICON_FUR],
		[icon_iron, ArtPaths.ICON_IRON],
	]:
		var node: TextureRect = pair[0] as TextureRect
		var path: String = str(pair[1])
		if node == null:
			continue
		node.custom_minimum_size = Vector2(32, 32)
		node.size = Vector2(32, 32)
		_set_tex(node, path)

func _setup_ui_art() -> void:
	## HUD panel 320×64 behind resource strip
	var hud := get_node_or_null("HudPanel") as TextureRect
	if hud == null:
		hud = TextureRect.new()
		hud.name = "HudPanel"
		hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hud.stretch_mode = TextureRect.STRETCH_SCALE
		hud.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		## sit under InkBar content, left of resource icons
		hud.position = Vector2(300, 4)
		hud.size = Vector2(320, 64)
		hud.z_index = -1
		add_child(hud)
		move_child(hud, 1)
	_set_tex(hud, ArtPaths.HUD_PANEL)

	_apply_btn_art(btn_dispatch, ArtPaths.BTN_DISPATCH, Vector2(128, 40))
	_apply_btn_art(btn_dungeon, ArtPaths.BTN_DISPATCH, Vector2(108, 28))
	_apply_btn_art(btn_outpost, ArtPaths.BTN_DISPATCH, Vector2(108, 28))
	_apply_btn_art(btn_academy, ArtPaths.BTN_BUILD, Vector2(108, 28))
	_apply_btn_art(btn_arena, ArtPaths.BTN_BUILD, Vector2(98, 28))
	if btn_gacha:
		_apply_btn_art(btn_gacha, ArtPaths.BTN_BUILD, Vector2(96, 28))
	_setup_dense_hud()

func _apply_btn_art(btn: Button, path: String, size: Vector2) -> void:
	if btn == null:
		return
	var tex: Texture2D = ArtPaths.load_tex(path)
	if tex == null:
		return
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 10.0
	sb.texture_margin_top = 8.0
	sb.texture_margin_right = 10.0
	sb.texture_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.custom_minimum_size = size
	btn.size = Vector2(maxf(btn.size.x, size.x), size.y)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _setup_dense_hud() -> void:
	## 頂欄下資訊帶：重用 hud_panel／資源圖示，食住醫＋就緒／秘境／前哨可掃
	_dense_hud_bg = get_node_or_null("DenseHudBg") as TextureRect
	if _dense_hud_bg == null:
		_dense_hud_bg = TextureRect.new()
		_dense_hud_bg.name = "DenseHudBg"
		_dense_hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dense_hud_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_dense_hud_bg.stretch_mode = TextureRect.STRETCH_SCALE
		_dense_hud_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_dense_hud_bg.position = Vector2(4, 68)
		_dense_hud_bg.size = Vector2(1272, 34)
		_dense_hud_bg.modulate = Color(1, 1, 1, 0.88)
		add_child(_dense_hud_bg)
		var status_i: int = status_label.get_index() if status_label else -1
		if status_i >= 0:
			move_child(_dense_hud_bg, status_i)
	_set_tex(_dense_hud_bg, ArtPaths.HUD_PANEL)

	## 騰出 chip 帶：狀態列同左欄微移
	if status_label:
		status_label.position = Vector2(16, 102)
		status_label.size = Vector2(1248, 22)
	var left_panel := get_node_or_null("LeftPanel") as Control
	if left_panel and left_panel.position.y < 110:
		left_panel.position.y = 118
	var left_title := get_node_or_null("LeftTitle") as Control
	if left_title and left_title.position.y < 110:
		left_title.position.y = 118
	var bscroll := get_node_or_null("BuildingsScroll") as Control
	if bscroll and bscroll.position.y < 140:
		bscroll.position.y = 146
	var vhost := village_host
	if vhost and vhost.position.y < 110:
		vhost.position.y = 118
	var right_panel := get_node_or_null("RightPanel") as Control
	if right_panel and right_panel.position.y < 110:
		right_panel.position.y = 118
	var right_title := get_node_or_null("RightTitle") as Control
	if right_title and right_title.position.y < 110:
		right_title.position.y = 118
	var hscroll := get_node_or_null("HeroesScroll") as Control
	if hscroll and hscroll.position.y < 150:
		hscroll.position.y = 146

	var chip_y: float = 72.0
	var x: float = 16.0
	_chip_food_icon = _ensure_chip_icon("ChipFoodIcon", ArtPaths.ICON_SILVER, Vector2(x, chip_y))
	x += 22.0
	_chip_food_lab = _ensure_chip_label("ChipFoodLab", Vector2(x, chip_y), 56.0)
	x += 58.0
	_chip_lodge_icon = _ensure_chip_icon("ChipLodgeIcon", ArtPaths.ICON_WOOD, Vector2(x, chip_y))
	x += 22.0
	_chip_lodge_lab = _ensure_chip_label("ChipLodgeLab", Vector2(x, chip_y), 56.0)
	x += 58.0
	_chip_med_icon = _ensure_chip_icon("ChipMedIcon", ArtPaths.ICON_HERB, Vector2(x, chip_y))
	x += 22.0
	_chip_med_lab = _ensure_chip_label("ChipMedLab", Vector2(x, chip_y), 56.0)
	x += 64.0
	_chip_ready_lab = _ensure_chip_label("ChipReadyLab", Vector2(x, chip_y), 200.0)
	x += 204.0
	_chip_dungeon_lab = _ensure_chip_label("ChipDungeonLab", Vector2(x, chip_y), 200.0)
	x += 204.0
	_chip_outpost_lab = _ensure_chip_label("ChipOutpostLab", Vector2(x, chip_y), 220.0)


func _ensure_chip_icon(n: String, path: String, pos: Vector2) -> TextureRect:
	var node := get_node_or_null(n) as TextureRect
	if node == null:
		node = TextureRect.new()
		node.name = n
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		node.custom_minimum_size = Vector2(20, 20)
		node.size = Vector2(20, 20)
		node.position = pos
		add_child(node)
	_set_tex(node, path)
	return node


func _ensure_chip_label(n: String, pos: Vector2, w: float) -> Label:
	var lab := get_node_or_null(n) as Label
	if lab == null:
		lab = Label.new()
		lab.name = n
		lab.position = pos
		lab.size = Vector2(w, 22)
		lab.add_theme_color_override("font_color", Color(0.12, 0.09, 0.06, 0.92))
		lab.add_theme_font_size_override("font_size", 12)
		lab.clip_text = false
		add_child(lab)
	return lab


func _refresh_dense_chips() -> void:
	var snap: Dictionary = UpkeepSystem.panel_snapshot()
	if _chip_food_lab:
		var mark: String = "⚠" if bool(snap.get("food_alert", false)) else ("✓" if int(snap.get("inn_lv", 0)) >= 1 else "·")
		_chip_food_lab.text = "%s食 Lv%d" % [mark, int(snap.get("inn_lv", 0))]
		_chip_food_lab.tooltip_text = str(snap.get("status_line", "食"))
		_chip_food_lab.add_theme_color_override("font_color", Color(0.75, 0.2, 0.15) if bool(snap.get("food_alert", false)) else Color(0.12, 0.09, 0.06, 0.92))
	if _chip_lodge_lab:
		var mark2: String = "⚠" if bool(snap.get("lodge_alert", false)) else ("✓" if int(snap.get("inn_lv", 0)) >= 1 or int(snap.get("manor_lv", 0)) >= 1 else "·")
		_chip_lodge_lab.text = "%s住" % mark2
		_chip_lodge_lab.add_theme_color_override("font_color", Color(0.75, 0.2, 0.15) if bool(snap.get("lodge_alert", false)) else Color(0.12, 0.09, 0.06, 0.92))
	if _chip_med_lab:
		var mark3: String = "⚠" if bool(snap.get("med_alert", false)) else ("✓" if int(snap.get("clinic_lv", 0)) >= 1 else "·")
		_chip_med_lab.text = "%s醫 Lv%d" % [mark3, int(snap.get("clinic_lv", 0))]
		_chip_med_lab.add_theme_color_override("font_color", Color(0.75, 0.2, 0.15) if bool(snap.get("med_alert", false)) else Color(0.12, 0.09, 0.06, 0.92))
	var ready_n: int = HeroSystem.find_ready_heroes(-1).size()
	var hunt_n: int = GameState.hunting_hero_count()
	var sel_n: int = _selected_ids(99).size()
	if _chip_ready_lab:
		_chip_ready_lab.text = "派遣就緒 %d｜出征 %d｜已選 %d" % [ready_n, hunt_n, sel_n]
		_chip_ready_lab.tooltip_text = "可派體力足夠嘅在村俠客數"
	var diff: Dictionary = DungeonSystem.difficulty_by_id(str(GameState.dungeon_pick_diff))
	var wset: Dictionary = DungeonSystem.wave_set_by_id(str(GameState.dungeon_pick_waves))
	if _chip_dungeon_lab:
		var dmark: String = "▶" if GameState.dungeon_busy else ("✓" if ResourceLoop.dungeon_gate_ok() and ready_n > 0 else "·")
		_chip_dungeon_lab.text = "%s秘境·%s·%d波" % [dmark, str(diff.get("name", "普通")), int(wset.get("max_waves", 3))]
		if not ResourceLoop.dungeon_gate_ok():
			_chip_dungeon_lab.tooltip_text = "興建懸賞榜後可入秘境（揀難度／波次）"
		elif GameState.dungeon_busy:
			_chip_dungeon_lab.tooltip_text = "秘境自動戰鬥進行中"
		else:
			_chip_dungeon_lab.tooltip_text = "剔選俠客 → 秘境按鈕揀難度／波次"
	if _chip_outpost_lab:
		if not OutpostSystem.is_unlocked():
			_chip_outpost_lab.text = "·前哨鎖（府＋懸賞）"
			_chip_outpost_lab.tooltip_text = "村長府＋懸賞榜達標後解鎖前哨防衛"
		else:
			var od: Dictionary = OutpostSystem.difficulty_by_id(str(GameState.outpost_pick_diff))
			var camp_n: int = OutpostSystem.stationed_count()
			var omark: String = ("駐%d" % camp_n) if camp_n > 0 else ("✓" if ready_n > 0 else "·")
			_chip_outpost_lab.text = "%s前哨·%s" % [omark, str(od.get("name", "普通"))]
			_chip_outpost_lab.tooltip_text = "撳前哨：一波防衛或外派駐守（亂山／官道）"
		if AcademySystem.academy_ready():
			_chip_outpost_lab.text += "｜書院✓"


func _setup_monster_reserve() -> void:
	_set_tex(monster_preview, ArtPaths.monster_idle("wolf"))
	monster_preview.tooltip_text = "亂山坡敵人（狼／野豬／山賊）"

func _set_tex(node: TextureRect, path: String) -> void:
	if node == null:
		return
	var tex: Texture2D = ArtPaths.load_tex(path)
	if tex != null:
		node.texture = tex
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _on_heroes_changed() -> void:
	if _hero_rows.size() != GameState.hero_count():
		_rebuild_heroes()
	else:
		_refresh_hud()

func _on_buildings_changed() -> void:
	_rebuild_buildings()
	_refresh_craft()

func _rebuild_buildings() -> void:
	for c in buildings_box.get_children():
		c.queue_free()
	for bid_v in BuildingSystem.sorted_building_ids():
		var bid: String = str(bid_v)
		var b: Dictionary = GameState.buildings[bid] as Dictionary
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 28)
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
		info.add_theme_font_size_override("font_size", 12)
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

		var btn_place := Button.new()
		btn_place.text = "放"
		btn_place.tooltip_text = "自由放置：點村莊可建區｜再撳取消"
		btn_place.pressed.connect(_on_place_building.bind(bid))
		row.add_child(btn_place)

		var btn := Button.new()
		btn.text = "升級" if lv > 0 or bool(b.get("unlocked", false)) else "興建"
		btn.disabled = not BuildingSystem.can_upgrade(bid)
		btn.pressed.connect(_on_upgrade.bind(bid))
		_apply_btn_art(btn, ArtPaths.BTN_BUILD, Vector2(64, 28))
		row.add_child(btn)
		buildings_box.add_child(row)

func _rebuild_heroes() -> void:
	var prev_sel: Dictionary = _selected.duplicate()
	_selected.clear()
	_hero_rows.clear()
	for c in heroes_box.get_children():
		c.queue_free()

	for h_v in GameState.heroes:
		var h: Dictionary = h_v as Dictionary
		var hid: String = str(h.get("id", ""))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
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
		var rar_c: Color = HeroPortraitScript.rarity_color(str(h.get("rarity", "綠")))
		## 字色偏墨，稀有用邊框辨識；紫無圖時字略帶稀有色
		if str(h.get("rarity", "")) in ["紫", "橙", "紅"] and bool(h.get("placeholder", false)):
			lab.add_theme_color_override("font_color", rar_c.darkened(0.15))
		else:
			lab.add_theme_color_override("font_color", Color(0.101961, 0.0823529, 0.0627451, 1))
		lab.add_theme_font_size_override("font_size", 12)
		lab.text = _hero_line(h)
		lab.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
				_craft_hero_id = hid
				_refresh_craft()
		)
		row.add_child(lab)

		heroes_box.add_child(row)
		_hero_rows[hid] = {"check": chk, "portrait": portrait, "label": lab}

func _hero_line(h: Dictionary) -> String:
	var st: String = str(h.get("status", "idle"))
	var st_cn := "在村" if st == "idle" else ("出征" if st == "hunting" else ("秘境" if st == "dungeon" else ("駐守" if st == "camped" else st)))
	var gear: int = HeroSystem.equipment_power(h)
	var gear_txt: String = (" 裝+%d" % gear) if gear > 0 else ""
	var pas: String = str(h.get("passive_name", ""))
	var pas_txt: String = (" ·技%s" % pas) if pas != "" else ""
	var rar: String = str(h.get("rarity", ""))
	var rar_txt: String = ("[%s]" % rar) if rar != "" else ""
	var cond: String = UpkeepSystem.hero_condition_label(h)
	var cond_txt: String = (" ·%s" % cond) if cond != "" else ""
	return "%s%s Lv%d · %s · 力%d%s%s · 體%.0f 飽%.0f 傷%.0f%s · XP%.0f/%d · %s" % [
		str(h.get("name", "")),
		rar_txt,
		int(h.get("level", 1)),
		str(h.get("weapon", "")),
		HeroSystem.power_of(h),
		gear_txt,
		pas_txt,
		float(h.get("stamina", 0)),
		float(h.get("satiety", 0)),
		float(h.get("injury", 0)),
		cond_txt,
		float(h.get("xp", 0)),
		int(h.get("xp_to_next", TrainingSystem.xp_to_next(int(h.get("level", 1))))),
		st_cn,
	]

func _refresh_craft() -> void:
	for c in craft_box.get_children():
		c.queue_free()
	var target_name: String = "（點俠客名作目標）"
	if _craft_hero_id != "":
		var th: Dictionary = HeroSystem.get_hero(_craft_hero_id)
		if not th.is_empty():
			target_name = str(th.get("name", _craft_hero_id))
	var head := Label.new()
	head.add_theme_color_override("font_color", Color(0.101961, 0.0823529, 0.0627451, 1))
	head.add_theme_font_size_override("font_size", 12)
	head.text = "製作目標：%s" % target_name
	craft_box.add_child(head)

	for rv in CraftSystem.all_recipes():
		var recipe: Dictionary = rv as Dictionary
		var rid: String = str(recipe.get("id", ""))
		var cost: Dictionary = recipe.get("cost", {}) as Dictionary
		var row := HBoxContainer.new()
		var lab := Label.new()
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.add_theme_color_override("font_color", Color(0.101961, 0.0823529, 0.0627451, 1))
		lab.add_theme_font_size_override("font_size", 11)
		lab.text = "%s（毛%d 木%d 鐵%d 銀%d）" % [
			str(recipe.get("name", rid)),
			int(cost.get("fur", 0)),
			int(cost.get("wood", 0)),
			int(cost.get("iron", 0)),
			int(cost.get("silver", 0)),
		]
		lab.tooltip_text = str(recipe.get("desc", ""))
		row.add_child(lab)
		var btn := Button.new()
		btn.text = "製"
		var chk: Dictionary = CraftSystem.can_craft(rid)
		btn.disabled = not bool(chk.get("ok", false))
		btn.tooltip_text = str(chk.get("reason", ""))
		btn.pressed.connect(_on_craft.bind(rid))
		row.add_child(btn)
		craft_box.add_child(row)

	var inv_head := Label.new()
	inv_head.add_theme_color_override("font_color", Color(0.101961, 0.0823529, 0.0627451, 1))
	inv_head.add_theme_font_size_override("font_size", 12)
	inv_head.text = "庫存 %d 件（揀目標後可裝／用／賣）" % GameState.inventory.size()
	craft_box.add_child(inv_head)
	var show_n: int = mini(8, GameState.inventory.size())
	for i in range(show_n):
		var it: Dictionary = GameState.inventory[i] as Dictionary
		var kind: String = str(it.get("kind", ""))
		var row_i := HBoxContainer.new()
		var lab_i := Label.new()
		lab_i.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab_i.add_theme_color_override("font_color", Color(0.101961, 0.0823529, 0.0627451, 1))
		lab_i.add_theme_font_size_override("font_size", 11)
		var extra: String = ""
		if kind == "equip":
			extra = " [%s＋%d]" % [str(it.get("slot", "?")), int(it.get("power", 0))]
		elif kind == "consumable":
			extra = " [傷%+d]" % int(it.get("injury", 0))
		lab_i.text = "· %s%s" % [str(it.get("name", "?")), extra]
		row_i.add_child(lab_i)
		if kind == "equip" or kind == "consumable":
			var btn_use := Button.new()
			btn_use.text = "裝" if kind == "equip" else "用"
			btn_use.disabled = _craft_hero_id == ""
			btn_use.tooltip_text = "需要先點選俠客名作目標" if _craft_hero_id == "" else ("裝備／使用於 %s" % target_name)
			btn_use.pressed.connect(_on_inv_use.bind(i))
			row_i.add_child(btn_use)
		var btn_sell := Button.new()
		btn_sell.text = "賣"
		btn_sell.tooltip_text = "賣出換銀"
		btn_sell.pressed.connect(_on_inv_sell.bind(i))
		row_i.add_child(btn_sell)
		craft_box.add_child(row_i)
	if inv_label:
		inv_label.visible = false

func _refresh_hud() -> void:
	if lab_silver:
		lab_silver.text = str(GameState.silver)
	if lab_wood:
		lab_wood.text = str(GameState.wood)
	if lab_fur:
		lab_fur.text = str(GameState.fur)
	if lab_iron:
		lab_iron.text = str(GameState.iron)
	## 次列：碎片／駐紮／狀態（唔同圖示行搶位，避免裁切）
	hud_label.text = "鑽 %d　　碎片 %d　　駐紮 %d／%d　　在村 %d　　出征 %d" % [
		GameState.diamonds,
		GameState.fragments,
		GameState.hero_count(),
		GameState.hero_capacity(),
		GameState.idle_hero_count(),
		GameState.hunting_hero_count(),
	]
	hud_label.clip_text = false
	_refresh_gacha_shop()
	var sel_ids: Array = _selected_ids(99)
	var party_txt := ""
	if sel_ids.size() > 0:
		var pch: float = UpkeepSystem.party_success_chance(sel_ids)
		party_txt = "　｜　已選成功率 %d%%" % int(round(pch * 100.0))
	status_label.text = "%s　｜　練功+%.1f XP/s　｜　%s　｜　放＝Esc取消" % [
		ResourceLoop.describe_readiness(sel_ids.size()),
		TrainingSystem.xp_per_sec(),
		party_txt if party_txt != "" else UpkeepSystem.describe_status(),
	]
	_refresh_dense_chips()
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
	_refresh_dungeon_btn()
	_refresh_craft()
	_refresh_upkeep_panel()

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
	var zname: String = str(GameState.get_zone(GameState.selected_zone).get("name", "野外"))
	btn_dispatch.text = "出征%s（已選 %d）" % [zname, n]
	_refresh_dungeon_btn()
	_refresh_outpost_btn()
	_refresh_arena_btn()

func _on_hero_toggled(pressed: bool, hid: String) -> void:
	if pressed:
		_selected[hid] = true
		_craft_hero_id = hid
		_refresh_craft()
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
	var ok := false
	if ids.is_empty():
		var res: Dictionary = _dispatch.dispatch_ready(int(spin_count.value), GameState.selected_zone)
		if not bool(res.get("ok", false)):
			GameState.push_report("派遣失敗：%s" % str(res.get("reason", "")))
		else:
			ok = true
		_selected.clear()
		_rebuild_heroes()
	else:
		var res2: Dictionary = _dispatch.start_hunt(ids, GameState.selected_zone)
		if not bool(res2.get("ok", false)):
			GameState.push_report("派遣失敗：%s" % str(res2.get("reason", "")))
		else:
			ok = true
		_selected.clear()
		_rebuild_heroes()
	if ok and GameState.tutorial_step == 2:
		GameState.tutorial_step = 3
		GameState.push_report("引導③：等俠客回村收資源（睇下方倒數）。")
		_refresh_tutorial()

func _on_upgrade(building_id: String) -> void:
	var before: int = BuildingSystem.building_level(building_id)
	var name_cn: String = BuildingSystem.building_name(building_id)
	if BuildingSystem.upgrade(building_id):
		var after: int = BuildingSystem.building_level(building_id)
		if before == 0:
			GameState.push_report("%s落成！Lv.%d（駐紮上限 %d）" % [name_cn, after, GameState.hero_capacity()])
			if building_id == "inn" and GameState.tutorial_step == 1:
				GameState.tutorial_step = 2
				GameState.push_report("引導②：剔選右邊俠客，撳「出征亂山坡」。")
				_refresh_tutorial()
			elif GameState.tutorial_step == 4:
				_complete_tutorial_build_or_gacha("興建")
		else:
			GameState.push_report("%s升至 Lv.%d" % [name_cn, after])
			if GameState.tutorial_step == 4:
				_complete_tutorial_build_or_gacha("升級")
	else:
		GameState.push_report("資源唔夠或已滿級：%s" % name_cn)
	_rebuild_buildings()

func _on_place_building(building_id: String) -> void:
	if _village and _village.has_method("begin_place"):
		_village.begin_place(building_id)

func _on_building_clicked(building_id: String) -> void:
	_on_upgrade(building_id)

func _on_craft(recipe_id: String) -> void:
	var res: Dictionary = CraftSystem.craft(recipe_id, _craft_hero_id)
	if not bool(res.get("ok", false)):
		GameState.push_report("製作失敗：%s" % str(res.get("reason", "")))
	_refresh_hud()
	_rebuild_heroes()

func _on_hunt_finished(rewards: Dictionary) -> void:
	_rebuild_heroes()
	_refresh_hud()
	_refresh_hunts()
	var enemies: Array = rewards.get("enemies", []) as Array
	if enemies.size() > 0:
		var kind: String = str((enemies[0] as Dictionary).get("kind", "wolf"))
		_set_tex(monster_preview, ArtPaths.monster_attack(kind))
	## v0.8 短自動戰鬥＋結算摘要
	if _auto_combat and _auto_combat.has_method("play"):
		_battle_mode = "hunt"
		_battle_queue.clear()
		_battle_final = rewards.duplicate(true)
		var zid: String = str(rewards.get("zone_id", GameState.selected_zone))
		var zbg: String = str((GameState.get_zone(zid) as Dictionary).get("bg_key", ""))
		if zbg == "":
			zbg = ArtPaths.zone_bg_key_for(zid, "hunt")
		_auto_combat.play({
			"title": "野外 · %s" % str(rewards.get("zone_name", "獵場")),
			"heroes": rewards.get("heroes", []),
			"enemies": enemies,
			"success": bool(rewards.get("success", true)),
			"duration": _rng_ui.randf_range(3.5, 6.5),
			"summary": rewards,
			"show_summary": true,
			"zone_id": zid,
			"zone_bg": zbg,
			"battle_mode": "hunt",
		})
	elif _hunt_result and _hunt_result.has_method("show_result"):
		_hunt_result.show_result(rewards)
	if GameState.tutorial_step == 3:
		GameState.tutorial_step = 4
		GameState.push_report("引導④：撳「英雄帖」抽一次，或興建／升級另一座建築。")
		_refresh_tutorial()

func _on_save_pressed() -> void:
	if SaveManager.save_game():
		GameState.push_report("已存檔 v%d（含放置／庫存）" % SaveManager.SAVE_VERSION)
	else:
		GameState.push_report("存檔失敗。")

func _on_load_pressed() -> void:
	if SaveManager.load_game():
		_dispatch.resolve_due_hunts()
		chk_auto.button_pressed = GameState.auto_dispatch
		if chk_auto_shop:
			chk_auto_shop.button_pressed = GameState.auto_shop
		_sync_bounty_option()
		_selected.clear()
		_rebuild_buildings()
		_rebuild_heroes()
		_refresh_craft()
		_refresh_hud()
		_refresh_hunts()
		_refresh_reports()
		_refresh_tutorial()
		GameState.push_report("已讀檔。")
	else:
		GameState.push_report("冇存檔可讀。")

func _on_building_placed(_building_id: String, _pos: Vector2) -> void:
	if GameState.tutorial_step == 4:
		_complete_tutorial_build_or_gacha("放置")
	_refresh_hud()

func _on_skip_tutorial() -> void:
	GameState.tutorial_step = 0
	GameState.push_report("已跳過新手引導。")
	_refresh_tutorial()

func _refresh_tutorial() -> void:
	if tutorial_banner == null or tutorial_label == null:
		return
	var step: int = GameState.tutorial_step
	if step <= 0:
		tutorial_banner.visible = false
		return
	tutorial_banner.visible = true
	match step:
		1:
			tutorial_label.text = "① 新手：左邊撳客棧「興建」（銀50／木25），建立村莊循環。"
		2:
			tutorial_label.text = "② 剔選右邊俠客（可多選），再撳「出征亂山坡」。"
		3:
			tutorial_label.text = "③ 等下方倒數完 → 俠客回村，收銀／毛皮。"
		4:
			tutorial_label.text = "④ 撳「英雄帖」抽一次，或興建醫館／貨棧／懸賞榜／書院。"
		5:
			tutorial_label.text = "⑤ 秘境：剔選俠客 → 撳「秘境」開選擇（難度／波次）→「入秘境」。未建懸賞榜先興建。"
		6:
			tutorial_label.text = "⑥ 前哨：撳「前哨」睇難度（鎖住會顯示解鎖條件）；有書院可撳開技能樹 stub。"
		_:
			tutorial_label.text = "新手引導"

func _complete_tutorial_build_or_gacha(via: String) -> void:
	if GameState.tutorial_step != 4:
		return
	GameState.tutorial_step = 5
	GameState.push_report("引導⑤（%s）：剔選俠客 → 撳「秘境」開難度／波次選擇（要懸賞榜）。" % via)
	_refresh_tutorial()


func _advance_tutorial(from_step: int, to_step: int, report: String) -> void:
	if GameState.tutorial_step != from_step:
		return
	GameState.tutorial_step = to_step
	if report != "":
		GameState.push_report(report)
	_refresh_tutorial()


func _finish_tutorial(via: String) -> void:
	if GameState.tutorial_step <= 0:
		return
	GameState.tutorial_step = 0
	GameState.push_report("引導完成（%s）！之後可自由興建、秘境、前哨、書院技能樹同自動出征。" % via)
	_refresh_tutorial()

func _setup_bounty_options() -> void:
	if opt_bounty == null:
		return
	opt_bounty.clear()
	opt_bounty.add_item("（無指定）", 0)
	opt_bounty.set_item_metadata(0, "")
	var i: int = 1
	for tv in BountySystem.all_targets():
		var td: Dictionary = tv as Dictionary
		opt_bounty.add_item(str(td.get("name", td.get("id", "?"))), i)
		opt_bounty.set_item_metadata(i, str(td.get("id", "")))
		i += 1
	_sync_bounty_option()

func _sync_bounty_option() -> void:
	if opt_bounty == null:
		return
	var cur: String = GameState.bounty_target
	for idx in range(opt_bounty.item_count):
		if str(opt_bounty.get_item_metadata(idx)) == cur:
			opt_bounty.select(idx)
			return
	opt_bounty.select(0)

func _refresh_gacha_shop() -> void:
	_setup_zone_options()
	if frag_label:
		frag_label.text = "碎片 %d｜%s" % [GameState.fragments, GachaSystem.status_line()]
	if btn_gacha:
		var chk: Dictionary = GachaSystem.can_pull()
		var free_n: int = GachaSystem.free_pulls_remaining()
		btn_gacha.disabled = not bool(chk.get("ok", false))
		if free_n > 0:
			btn_gacha.text = "英雄帖（免費）"
		else:
			btn_gacha.text = "英雄帖（%d銀）" % GachaSystem.pull_cost()
		btn_gacha.tooltip_text = str(chk.get("reason", "白→紅")) + "｜" + GachaSystem.status_line()
	if btn_gacha10:
		var chk10: Dictionary = GachaSystem.can_pull_diamond(10)
		btn_gacha10.disabled = not bool(chk10.get("ok", false))
		btn_gacha10.text = "十連（%d鑽）" % GachaSystem.diamond_ten_cost()
		btn_gacha10.tooltip_text = str(chk10.get("reason", "鑽石十連 stub"))
	if btn_shop_once:
		btn_shop_once.disabled = not ShopSystem.forge_ready()
		btn_shop_once.tooltip_text = "為在村俠客買一件更強裝" if ShopSystem.forge_ready() else "要先起鐵匠鋪"

func _ensure_gacha10_btn() -> void:
	if btn_gacha10 != null or btn_gacha == null:
		return
	btn_gacha10 = Button.new()
	btn_gacha10.name = "BtnGacha10"
	btn_gacha10.text = "十連（鑽）"
	btn_gacha10.position = Vector2(btn_gacha.position.x, btn_gacha.position.y - 32.0)
	btn_gacha10.size = Vector2(184, 28)
	btn_gacha10.pressed.connect(_on_gacha10_pressed)
	add_child(btn_gacha10)

func _on_gacha_pressed() -> void:
	var res: Dictionary = GachaSystem.pull_once()
	if not bool(res.get("ok", false)):
		GameState.push_report("英雄帖失敗：%s" % str(res.get("reason", "")))
	else:
		_flash_gacha_result(res)
		if GameState.tutorial_step == 4:
			_complete_tutorial_build_or_gacha("抽卡")
	_rebuild_heroes()
	_refresh_hud()

func _on_gacha10_pressed() -> void:
	var res: Dictionary = GachaSystem.pull_diamond(10)
	if not bool(res.get("ok", false)):
		GameState.push_report("十連失敗：%s" % str(res.get("reason", "")))
	else:
		var news: int = 0
		var dupes: int = 0
		for r in res.get("results", []) as Array:
			var rd: Dictionary = r as Dictionary
			if str(rd.get("result", "")) == "new":
				news += 1
			else:
				dupes += 1
		GameState.push_report("十連完成：新俠 %d／重覆 %d（耗鑽 %d）" % [news, dupes, int(res.get("cost", 0))])
		if _gacha_flash and _gacha_flash.has_method("play_batch"):
			_gacha_flash.play_batch(res.get("results", []) as Array)
		if GameState.tutorial_step == 4:
			_complete_tutorial_build_or_gacha("抽卡")
	_rebuild_heroes()
	_refresh_hud()

func _flash_gacha_result(res: Dictionary) -> void:
	if _gacha_flash == null:
		return
	var rarity: String = str(res.get("rarity", "白"))
	var h: Dictionary = res.get("hero", {}) as Dictionary
	var nm: String = str(h.get("name", ""))
	var dupe: bool = str(res.get("result", "")) == "dupe"
	if _gacha_flash.has_method("play"):
		_gacha_flash.play(rarity, nm, dupe)

func _on_bounty_selected(index: int) -> void:
	if opt_bounty == null:
		return
	var tid: String = str(opt_bounty.get_item_metadata(index))
	var res: Dictionary = BountySystem.set_active(tid)
	if not bool(res.get("ok", false)):
		GameState.push_report("懸賞失敗：%s" % str(res.get("reason", "")))
		_sync_bounty_option()

func _on_auto_shop_toggled(pressed: bool) -> void:
	GameState.auto_shop = pressed
	GameState.push_report("兵器鋪自動買裝：%s" % ("開" if pressed else "關"))

func _on_shop_once_pressed() -> void:
	var res: Dictionary = ShopSystem.auto_buy_for_idle(1)
	if int(res.get("bought", 0)) <= 0:
		GameState.push_report("兵器鋪：冇可買升級（%s）" % str(res.get("reason", "銀／等級／已最強")))
	_rebuild_heroes()
	_refresh_hud()

func _selected_ids(limit: int = 99) -> Array:
	var ids: Array = []
	for hid in _selected.keys():
		if bool(_selected[hid]):
			ids.append(hid)
			if ids.size() >= limit:
				break
	return ids

func _refresh_dungeon_btn() -> void:
	if btn_dungeon == null:
		return
	var n: int = _selected_ids(99).size()
	var diff: Dictionary = DungeonSystem.difficulty_by_id(str(GameState.dungeon_pick_diff))
	var wset: Dictionary = DungeonSystem.wave_set_by_id(str(GameState.dungeon_pick_waves))
	var waves_n: int = int(wset.get("max_waves", 3))
	var dname: String = str(diff.get("name", "普通"))
	var chk: Dictionary = DungeonSystem.can_enter(_selected_ids(DungeonSystem.max_party())) if n > 0 else {"ok": false, "reason": "剔選 1～%d 俠入秘境" % DungeonSystem.max_party()}
	if GameState.dungeon_busy:
		btn_dungeon.disabled = true
		btn_dungeon.text = "秘境進行中"
		btn_dungeon.tooltip_text = "自動戰鬥未完"
	else:
		## 按鈕永遠可撳開選擇面板；出發條件喺面板內檢查
		btn_dungeon.disabled = false
		btn_dungeon.text = "秘境·%s·%d波" % [dname, waves_n]
		var tip: String = "亂山秘境 · %s／%s（撳開選擇）" % [dname, str(wset.get("name", ""))]
		if n > 0 and not bool(chk.get("ok", false)):
			tip = str(chk.get("reason", tip))
		btn_dungeon.tooltip_text = tip
	if btn_academy:
		var alv: int = BuildingSystem.building_level("academy")
		btn_academy.disabled = not AcademySystem.academy_ready()
		if AcademySystem.academy_ready():
			btn_academy.text = "書院 Lv%d" % maxi(1, alv)
			btn_academy.tooltip_text = "技能樹／授徒／全村心法"
		else:
			btn_academy.text = "書院（未建）"
			btn_academy.tooltip_text = "左邊興建「師門書院」後可開技能樹"
	_refresh_dungeon_panel()
	_refresh_academy_panel()

func _on_dungeon_pressed() -> void:
	if _dungeon_panel == null:
		_run_dungeon_now()
		return
	## 開／關選擇面板；隱藏其他卡
	var show: bool = not _dungeon_panel.visible
	_hide_side_panels()
	_dungeon_panel.visible = show
	if show:
		_dungeon_panel.move_to_front()
		_refresh_dungeon_panel()
		_advance_tutorial(5, 6, "引導⑥：撳「前哨」睇難度／解鎖條件；有書院可開技能樹。")

func _run_dungeon_now() -> void:
	var ids: Array = _selected_ids(DungeonSystem.max_party())
	var res: Dictionary = DungeonSystem.run_dungeon(ids)
	if not bool(res.get("ok", false)):
		GameState.push_report("秘境失敗：%s" % str(res.get("reason", "")))
		return
	if _dungeon_panel:
		_dungeon_panel.visible = false
	_advance_tutorial(5, 6, "引導⑥：秘境已出發；接著撳「前哨」或「書院」睇技能樹。")
	GameState.dungeon_busy = true
	_selected.clear()
	_rebuild_heroes()
	_refresh_hud()
	var d_waves: Array = res.get("waves", []) as Array
	var d_rewards: Dictionary = (res.get("rewards", {}) as Dictionary).duplicate(true)
	d_rewards["run_mode"] = "dungeon"
	d_rewards["battle_mode"] = "dungeon"
	d_rewards["waves"] = d_waves
	d_rewards["cleared"] = bool(res.get("cleared", d_rewards.get("cleared", false)))
	d_rewards["total_waves"] = int(res.get("total_waves", d_waves.size()))
	d_rewards["zone_name"] = str(res.get("dungeon_name", d_rewards.get("zone_name", "秘境")))
	d_rewards["run_title"] = str(d_rewards["zone_name"])
	d_rewards["difficulty_id"] = str(res.get("difficulty_id", d_rewards.get("difficulty_id", "")))
	d_rewards["difficulty_name"] = str(res.get("difficulty_name", d_rewards.get("difficulty_name", "")))
	d_rewards["wave_set_id"] = str(res.get("wave_set_id", d_rewards.get("wave_set_id", "")))
	d_rewards["wave_set_name"] = str(res.get("wave_set_name", d_rewards.get("wave_set_name", "")))
	_start_wave_battles(
		"dungeon",
		str(res.get("dungeon_name", "秘境")),
		d_waves,
		res.get("heroes", ids),
		d_rewards
	)

func _on_dungeon_closed(_rewards: Dictionary) -> void:
	GameState.dungeon_busy = false
	_rebuild_heroes()
	_refresh_hud()
	_refresh_hunts()

func _on_academy_pressed() -> void:
	if not AcademySystem.academy_ready():
		GameState.push_report("書院：先興建師門書院")
		return
	if _academy_panel == null:
		return
	var show: bool = not _academy_panel.visible
	_hide_side_panels()
	_academy_panel.visible = show
	if show:
		_academy_panel.move_to_front()
		_refresh_academy_panel()
		if GameState.tutorial_step == 6:
			_finish_tutorial("書院技能樹")
		elif GameState.tutorial_step == 5:
			## 允許略過秘境直接睇書院，再去前哨
			_advance_tutorial(5, 6, "引導⑥：書院已開；再撳「前哨」睇解鎖／難度即完成引導。")

func _setup_zone_options() -> void:
	if opt_zone == null:
		return
	opt_zone.clear()
	var keys: Array = GameState.zones.keys()
	keys.sort()
	var idx := 0
	var select_i := 0
	for kid in keys:
		var z: Dictionary = GameState.zones[kid] as Dictionary
		var label: String = str(z.get("name", kid))
		var need: int = int(z.get("unlock_bounty_level", 1))
		if BuildingSystem.building_level("bounty") < need:
			label += "（鎖 Lv.%d）" % need
		opt_zone.add_item(label)
		opt_zone.set_item_metadata(idx, str(kid))
		if str(kid) == GameState.selected_zone:
			select_i = idx
		idx += 1
	if opt_zone.item_count > 0:
		opt_zone.select(select_i)

func _on_zone_selected(index: int) -> void:
	if opt_zone == null:
		return
	var zid: String = str(opt_zone.get_item_metadata(index))
	var z: Dictionary = GameState.get_zone(zid)
	var need: int = int(z.get("unlock_bounty_level", 1))
	if BuildingSystem.building_level("bounty") < need:
		GameState.push_report("野外未解鎖：%s 要懸賞榜 Lv.%d" % [str(z.get("name", zid)), need])
		_setup_zone_options()
		return
	GameState.selected_zone = zid
	GameState.push_report("野外改為「%s」" % str(z.get("name", zid)))
	_refresh_dispatch_btn()

func _refresh_outpost_btn() -> void:
	if btn_outpost == null:
		return
	var n: int = _selected_ids(99).size()
	var wn: int = _OutpostScript.wave_count()
	var need_m: int = 2
	var need_b: int = 2
	var odef: Dictionary = _OutpostScript.def()
	if not odef.is_empty():
		need_m = int(odef.get("unlock_manor_level", 2))
		need_b = int(odef.get("unlock_bounty_level", 2))
	var cur_m: int = BuildingSystem.building_level("manor")
	var cur_b: int = BuildingSystem.building_level("bounty")
	if not _OutpostScript.is_unlocked():
		## 仍可撳：顯示解鎖條件（新手⑥／資訊密度）
		btn_outpost.disabled = false
		btn_outpost.text = "前哨（鎖）"
		btn_outpost.tooltip_text = "解鎖：村長府 Lv.%d（而家%d）＋懸賞榜 Lv.%d（而家%d）→ 守 %d 波" % [
			need_m, cur_m, need_b, cur_b, wn
		]
		return
	var od: Dictionary = _OutpostScript.difficulty_by_id(str(GameState.outpost_pick_diff))
	btn_outpost.disabled = false
	btn_outpost.text = "前哨·%s·%d波" % [str(od.get("name", "普通")), wn]
	if n < 1:
		btn_outpost.tooltip_text = "撳開難度選擇 · %d 波" % wn
	else:
		var chk: Dictionary = _OutpostScript.can_defend(_selected_ids(6))
		var tip2: String = str(chk.get("reason", ""))
		if tip2 == "":
			tip2 = "前哨防衛 · %d 波 · 撳開選擇" % wn
		btn_outpost.tooltip_text = tip2
	_refresh_outpost_panel()

func _refresh_arena_btn() -> void:
	if btn_arena == null:
		return
	var n_all: int = _selected_ids(99).size()
	var ids: Array = _selected_ids(2)
	if not ArenaSystem.arena_ready():
		btn_arena.disabled = true
		btn_arena.text = "比武（鎖）"
		btn_arena.tooltip_text = "先興建練功場"
		return
	var left: int = ArenaSystem.spars_left()
	if n_all != 2:
		btn_arena.disabled = true
		btn_arena.text = "比武" if n_all < 2 else "比武（要2人）"
		btn_arena.tooltip_text = "剔選剛好兩名在村俠客切磋（今日剩 %d）" % left
	else:
		var chk: Dictionary = ArenaSystem.can_spar(str(ids[0]), str(ids[1]))
		btn_arena.disabled = not bool(chk.get("ok", false))
		btn_arena.text = "比武（%d）" % left
		btn_arena.tooltip_text = str(chk.get("reason", "村內切磋"))

func _on_arena_pressed() -> void:
	var ids: Array = _selected_ids(2)
	if ids.size() != 2:
		GameState.push_report("比武要剔選剛好兩名俠客。")
		return
	if _auto_combat != null and _auto_combat.has_method("is_busy") and _auto_combat.is_busy():
		GameState.push_report("戰鬥演出中，稍候。")
		return
	var res: Dictionary = ArenaSystem.spar(str(ids[0]), str(ids[1]))
	if not bool(res.get("ok", false)):
		GameState.push_report("比武失敗：%s" % str(res.get("reason", "")))
		_refresh_arena_btn()
		return
	_selected.clear()
	_rebuild_heroes()
	_refresh_hud()
	var duel: Dictionary = res.get("duel", {}) as Dictionary
	var summary: Dictionary = res.get("summary", {}) as Dictionary
	if _auto_combat != null and _auto_combat.has_method("play") and not duel.is_empty():
		_battle_mode = "arena"
		_battle_queue.clear()
		_battle_final = summary.duplicate(true)
		_auto_combat.play({
			"title": str(duel.get("title", "比武台")),
			"heroes": duel.get("heroes", []),
			"enemies": duel.get("enemies", []),
			"success": bool(duel.get("success", true)),
			"duration": float(duel.get("duration", 4.2)),
			"summary": summary,
			"show_summary": true,
			"zone_bg": str(duel.get("zone_bg", "hills")),
			"battle_mode": "arena",
		})
	else:
		_refresh_arena_btn()

func _on_inv_use(inv_index: int) -> void:
	if _craft_hero_id == "":
		GameState.push_report("先點俠客名作製作／裝備目標。")
		return
	var res: Dictionary = CraftSystem.use_inventory_on_hero(inv_index, _craft_hero_id)
	if not bool(res.get("ok", false)):
		GameState.push_report("用唔到：%s" % str(res.get("reason", "")))
	_refresh_craft()
	_rebuild_heroes()
	_refresh_hud()

func _on_inv_sell(inv_index: int) -> void:
	var res: Dictionary = CraftSystem.sell_inventory_at(inv_index)
	if not bool(res.get("ok", false)):
		GameState.push_report("賣唔成：%s" % str(res.get("reason", "")))
	_refresh_craft()
	_refresh_hud()

func _on_outpost_pressed() -> void:
	if not _OutpostScript.is_unlocked():
		var odef: Dictionary = _OutpostScript.def()
		GameState.push_report("前哨未解鎖：村長府 Lv.%d＋懸賞榜 Lv.%d（而家 %d／%d）" % [
			int(odef.get("unlock_manor_level", 2)), int(odef.get("unlock_bounty_level", 2)),
			BuildingSystem.building_level("manor"), BuildingSystem.building_level("bounty"),
		])
		if GameState.tutorial_step == 6:
			_finish_tutorial("前哨解鎖提示")
		elif GameState.tutorial_step == 5:
			_advance_tutorial(5, 6, "引導⑥：先升級府／懸賞解鎖前哨；或撳「書院」睇技能樹。")
		return
	if _outpost_panel == null:
		_run_outpost_now()
		return
	var show: bool = not _outpost_panel.visible
	_hide_side_panels()
	_outpost_panel.visible = show
	if show:
		_outpost_panel.move_to_front()
		_rebuild_outpost_pick_buttons()
		_rebuild_camp_pick_buttons()
		_refresh_outpost_panel()
		if GameState.tutorial_step == 6:
			_finish_tutorial("前哨選擇")
		elif GameState.tutorial_step == 5:
			_advance_tutorial(5, 6, "引導⑥：前哨面板已開；再開「書院」或關閉即完成。")

func _run_outpost_now() -> void:
	var ids: Array = _selected_ids(6)
	var res: Dictionary = _OutpostScript.run_defense(ids)
	if not bool(res.get("ok", false)):
		GameState.push_report("前哨失敗：%s" % str(res.get("reason", "")))
		return
	if GameState.tutorial_step >= 5:
		_finish_tutorial("前哨出發")
	if _outpost_panel:
		_outpost_panel.visible = false
	_selected.clear()
	_rebuild_heroes()
	_refresh_hud()
	var o_waves: Array = res.get("waves", []) as Array
	var rewards: Dictionary = (res.get("rewards", {}) as Dictionary).duplicate(true)
	rewards["flavor"] = str(res.get("flavor", rewards.get("flavor", "")))
	rewards["injured"] = rewards.get("injured", [])
	rewards["run_mode"] = "outpost"
	rewards["battle_mode"] = "outpost"
	rewards["waves"] = o_waves
	rewards["waves_cleared"] = int(res.get("waves_cleared", rewards.get("waves_cleared", 0)))
	rewards["cleared"] = bool(res.get("cleared", rewards.get("cleared", false)))
	rewards["success"] = bool(res.get("success", rewards.get("cleared", false)))
	rewards["total_waves"] = maxi(o_waves.size(), _OutpostScript.wave_count())
	rewards["zone_name"] = str(_OutpostScript.def().get("name", "前哨防衛"))
	rewards["run_title"] = str(rewards["zone_name"])
	rewards["difficulty_id"] = str(res.get("difficulty_id", rewards.get("difficulty_id", "")))
	rewards["difficulty_name"] = str(res.get("difficulty_name", rewards.get("difficulty_name", "")))
	_start_wave_battles(
		"outpost",
		"前哨防衛",
		o_waves,
		res.get("heroes", ids),
		rewards
	)

func _start_wave_battles(mode: String, title: String, waves: Array, hero_ids: Array, final_rewards: Dictionary) -> void:
	_battle_mode = mode
	_battle_final = final_rewards.duplicate(true)
	_battle_queue.clear()
	var total_w: int = maxi(waves.size(), int(final_rewards.get("total_waves", waves.size())))
	_battle_final["waves"] = waves
	_battle_final["run_mode"] = mode
	_battle_final["battle_mode"] = mode
	_battle_final["total_waves"] = total_w
	if not _battle_final.has("zone_name") or str(_battle_final.get("zone_name", "")) == "":
		_battle_final["zone_name"] = title
	var wi: int = 0
	for wv in waves:
		var w: Dictionary = (wv as Dictionary).duplicate(true)
		wi += 1
		var idx: int = int(w.get("index", wi))
		var lab: String = str(w.get("label", "波次%d" % idx))
		w["_title"] = "%s · %d／%d　%s" % [title, idx, total_w, lab]
		w["_heroes"] = hero_ids.duplicate()
		_battle_queue.append(w)
	if _battle_queue.is_empty():
		_on_wave_battles_done()
		return
	_play_next_wave_battle()

func _play_next_wave_battle() -> void:
	if _battle_queue.is_empty():
		_on_wave_battles_done()
		return
	if _auto_combat == null or not _auto_combat.has_method("play"):
		_battle_queue.clear()
		_on_wave_battles_done()
		return
	var w: Dictionary = _battle_queue.pop_front() as Dictionary
	var is_last: bool = _battle_queue.is_empty()
	var summary: Dictionary = {}
	if is_last:
		summary = _battle_final.duplicate(true)
	var zbg2: String = ArtPaths.zone_bg_key_for("", _battle_mode)
	if _battle_mode == "dungeon":
		zbg2 = "crypt"
	elif _battle_mode == "outpost":
		zbg2 = "outpost"
	_auto_combat.play({
		"title": str(w.get("_title", "交戰")),
		"heroes": w.get("_heroes", []),
		"enemies": w.get("enemies", []),
		"success": bool(w.get("success", true)),
		"duration": _rng_ui.randf_range(3.2, 5.8),
		"summary": summary,
		"show_summary": is_last,
		"zone_bg": zbg2,
		"battle_mode": _battle_mode,
	})

func _on_auto_combat_finished(_summary: Dictionary) -> void:
	if _battle_mode == "hunt":
		_battle_mode = ""
		_rebuild_heroes()
		_refresh_hud()
		return
	if _battle_mode == "arena":
		_battle_mode = ""
		_battle_queue.clear()
		_rebuild_heroes()
		_refresh_hud()
		_refresh_arena_btn()
		return
	if not _battle_queue.is_empty():
		_play_next_wave_battle()
		return
	_on_wave_battles_done()

func _on_wave_battles_done() -> void:
	var mode: String = _battle_mode
	_battle_mode = ""
	_battle_queue.clear()
	if mode == "dungeon":
		GameState.dungeon_busy = false
	_rebuild_heroes()
	_refresh_hud()
	_refresh_hunts()

func _setup_upkeep_panel() -> void:
	_btn_upkeep = Button.new()
	_btn_upkeep.name = "BtnUpkeep"
	_btn_upkeep.text = "維護"
	_btn_upkeep.tooltip_text = "村莊維護：食／住／醫狀態與日耗預覽"
	_btn_upkeep.position = Vector2(1188, 72)
	_btn_upkeep.size = Vector2(72, 26)
	_btn_upkeep.pressed.connect(_on_upkeep_pressed)
	add_child(_btn_upkeep)
	_apply_btn_art(_btn_upkeep, ArtPaths.BTN_BUILD, Vector2(72, 26))

	_upkeep_panel = ColorRect.new()
	_upkeep_panel.name = "UpkeepPanel"
	_upkeep_panel.color = Color(0.08, 0.06, 0.05, 0.94)
	_upkeep_panel.position = Vector2(880, 104)
	_upkeep_panel.size = Vector2(380, 168)
	_upkeep_panel.visible = false
	_upkeep_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_upkeep_panel)

	_upkeep_label = Label.new()
	_upkeep_label.name = "UpkeepLabel"
	_upkeep_label.position = Vector2(12, 10)
	_upkeep_label.size = Vector2(356, 148)
	_upkeep_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_upkeep_label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.78))
	_upkeep_label.add_theme_font_size_override("font_size", 13)
	_upkeep_panel.add_child(_upkeep_label)
	_refresh_upkeep_panel()


func _on_upkeep_pressed() -> void:
	if _upkeep_panel == null:
		return
	var show: bool = not _upkeep_panel.visible
	_hide_side_panels()
	_upkeep_panel.visible = show
	if _upkeep_panel.visible:
		_upkeep_panel.move_to_front()
		_refresh_upkeep_panel()


func _refresh_upkeep_panel() -> void:
	if _btn_upkeep:
		var snap: Dictionary = UpkeepSystem.panel_snapshot()
		if bool(snap.get("has_alert", false)):
			_btn_upkeep.text = "維護⚠"
			_btn_upkeep.tooltip_text = "有短缺／未建 — " + str(snap.get("status_line", ""))
		else:
			_btn_upkeep.text = "維護"
			_btn_upkeep.tooltip_text = "村莊維護：食／住／醫 · " + str(snap.get("status_line", ""))
	if _upkeep_label and _upkeep_panel and _upkeep_panel.visible:
		_upkeep_label.text = UpkeepSystem.describe_panel()
	_refresh_dense_chips()



func _hide_side_panels() -> void:
	if _upkeep_panel:
		_upkeep_panel.visible = false
	if _dungeon_panel:
		_dungeon_panel.visible = false
	if _outpost_panel:
		_outpost_panel.visible = false
	if _academy_panel:
		_academy_panel.visible = false


func _setup_dungeon_panel() -> void:
	_dungeon_panel = ColorRect.new()
	_dungeon_panel.name = "DungeonPickPanel"
	_dungeon_panel.color = Color(0.07, 0.06, 0.08, 0.95)
	_dungeon_panel.position = Vector2(420, 96)
	_dungeon_panel.size = Vector2(440, 280)
	_dungeon_panel.visible = false
	_dungeon_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dungeon_panel)

	_dungeon_label = Label.new()
	_dungeon_label.position = Vector2(12, 8)
	_dungeon_label.size = Vector2(416, 120)
	_dungeon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dungeon_label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.78))
	_dungeon_label.add_theme_font_size_override("font_size", 13)
	_dungeon_panel.add_child(_dungeon_label)

	_dungeon_btns = HBoxContainer.new()
	_dungeon_btns.position = Vector2(12, 136)
	_dungeon_btns.size = Vector2(416, 32)
	_dungeon_btns.add_theme_constant_override("separation", 6)
	_dungeon_panel.add_child(_dungeon_btns)

	_dungeon_wave_btns = HBoxContainer.new()
	_dungeon_wave_btns.position = Vector2(12, 176)
	_dungeon_wave_btns.size = Vector2(416, 32)
	_dungeon_wave_btns.add_theme_constant_override("separation", 6)
	_dungeon_panel.add_child(_dungeon_wave_btns)

	_btn_dungeon_go = Button.new()
	_btn_dungeon_go.text = "入秘境"
	_btn_dungeon_go.position = Vector2(12, 228)
	_btn_dungeon_go.size = Vector2(120, 36)
	_btn_dungeon_go.pressed.connect(_run_dungeon_now)
	_dungeon_panel.add_child(_btn_dungeon_go)

	var btn_close := Button.new()
	btn_close.text = "關閉"
	btn_close.position = Vector2(148, 228)
	btn_close.size = Vector2(80, 36)
	btn_close.pressed.connect(func() -> void: _dungeon_panel.visible = false)
	_dungeon_panel.add_child(btn_close)
	_rebuild_dungeon_pick_buttons()


func _rebuild_dungeon_pick_buttons() -> void:
	if _dungeon_btns == null:
		return
	for c in _dungeon_btns.get_children():
		c.queue_free()
	for c2 in _dungeon_wave_btns.get_children():
		c2.queue_free()
	for d in DungeonSystem.difficulties():
		var dd: Dictionary = d as Dictionary
		var idd: String = str(dd.get("id", ""))
		var b := Button.new()
		var lock: bool = not DungeonSystem.is_difficulty_unlocked(idd)
		b.text = str(dd.get("name", idd)) + ("鎖" if lock else "")
		b.disabled = lock
		b.toggle_mode = true
		b.button_pressed = idd == str(GameState.dungeon_pick_diff)
		b.tooltip_text = str(dd.get("desc", ""))
		b.pressed.connect(_on_pick_dungeon_diff.bind(idd))
		_dungeon_btns.add_child(b)
	for w in DungeonSystem.wave_sets():
		var ww: Dictionary = w as Dictionary
		var iid: String = str(ww.get("id", ""))
		var b2 := Button.new()
		b2.text = str(ww.get("name", iid))
		b2.toggle_mode = true
		b2.button_pressed = iid == str(GameState.dungeon_pick_waves)
		b2.tooltip_text = str(ww.get("desc", ""))
		b2.pressed.connect(_on_pick_dungeon_waves.bind(iid))
		_dungeon_wave_btns.add_child(b2)


func _on_pick_dungeon_diff(diff_id: String) -> void:
	GameState.dungeon_pick_diff = diff_id
	_rebuild_dungeon_pick_buttons()
	_refresh_dungeon_panel()
	_refresh_dungeon_btn()


func _on_pick_dungeon_waves(ws_id: String) -> void:
	GameState.dungeon_pick_waves = ws_id
	_rebuild_dungeon_pick_buttons()
	_refresh_dungeon_panel()
	_refresh_dungeon_btn()


func _refresh_dungeon_panel() -> void:
	if _dungeon_label and _dungeon_panel and _dungeon_panel.visible:
		_dungeon_label.text = DungeonSystem.describe_pick_panel()
		var n: int = _selected_ids(DungeonSystem.max_party()).size()
		var chk: Dictionary = DungeonSystem.can_enter(_selected_ids(DungeonSystem.max_party())) if n > 0 else {"ok": false, "reason": "未揀俠"}
		if _btn_dungeon_go:
			_btn_dungeon_go.disabled = not bool(chk.get("ok", false)) or GameState.dungeon_busy
			_btn_dungeon_go.tooltip_text = str(chk.get("reason", "出發"))


func _setup_outpost_panel() -> void:
	_outpost_panel = ColorRect.new()
	_outpost_panel.name = "OutpostPickPanel"
	_outpost_panel.color = Color(0.07, 0.06, 0.08, 0.95)
	_outpost_panel.position = Vector2(400, 72)
	_outpost_panel.size = Vector2(440, 460)
	_outpost_panel.visible = false
	_outpost_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_outpost_panel)

	_outpost_label = Label.new()
	_outpost_label.position = Vector2(12, 8)
	_outpost_label.size = Vector2(416, 216)
	_outpost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_outpost_label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.78))
	_outpost_label.add_theme_font_size_override("font_size", 12)
	_outpost_panel.add_child(_outpost_label)

	_outpost_btns = HBoxContainer.new()
	_outpost_btns.position = Vector2(12, 232)
	_outpost_btns.size = Vector2(416, 28)
	_outpost_btns.add_theme_constant_override("separation", 6)
	_outpost_panel.add_child(_outpost_btns)

	_camp_btns = HBoxContainer.new()
	_camp_btns.name = "CampPickRow"
	_camp_btns.position = Vector2(12, 268)
	_camp_btns.size = Vector2(416, 28)
	_camp_btns.add_theme_constant_override("separation", 6)
	_outpost_panel.add_child(_camp_btns)

	_btn_outpost_go = Button.new()
	_btn_outpost_go.text = "守前哨"
	_btn_outpost_go.position = Vector2(12, 308)
	_btn_outpost_go.size = Vector2(100, 36)
	_btn_outpost_go.pressed.connect(_run_outpost_now)
	_outpost_panel.add_child(_btn_outpost_go)

	_btn_camp_station = Button.new()
	_btn_camp_station.text = "駐守"
	_btn_camp_station.position = Vector2(120, 308)
	_btn_camp_station.size = Vector2(88, 36)
	_btn_camp_station.pressed.connect(_on_camp_station_pressed)
	_outpost_panel.add_child(_btn_camp_station)

	_btn_camp_recall = Button.new()
	_btn_camp_recall.text = "召回"
	_btn_camp_recall.position = Vector2(216, 308)
	_btn_camp_recall.size = Vector2(88, 36)
	_btn_camp_recall.pressed.connect(_on_camp_recall_pressed)
	_outpost_panel.add_child(_btn_camp_recall)

	var btn_close2 := Button.new()
	btn_close2.text = "關閉"
	btn_close2.position = Vector2(312, 308)
	btn_close2.size = Vector2(80, 36)
	btn_close2.pressed.connect(func() -> void: _outpost_panel.visible = false)
	_outpost_panel.add_child(btn_close2)

	_btn_camp_upgrade = Button.new()
	_btn_camp_upgrade.text = "升級營"
	_btn_camp_upgrade.position = Vector2(12, 352)
	_btn_camp_upgrade.size = Vector2(100, 36)
	_btn_camp_upgrade.pressed.connect(_on_camp_upgrade_pressed)
	_outpost_panel.add_child(_btn_camp_upgrade)

	_btn_camp_patrol = Button.new()
	_btn_camp_patrol.text = "巡哨"
	_btn_camp_patrol.position = Vector2(120, 352)
	_btn_camp_patrol.size = Vector2(88, 36)
	_btn_camp_patrol.pressed.connect(_on_camp_patrol_pressed)
	_outpost_panel.add_child(_btn_camp_patrol)

	var hint := Label.new()
	hint.position = Vector2(12, 396)
	hint.size = Vector2(416, 52)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.75, 0.7, 0.62))
	hint.add_theme_font_size_override("font_size", 11)
	hint.text = "駐守＝長期外派；升級營耗銀／木／鐵加槽或舒適／涓滴；巡哨＝駐軍一鍵小戰（自動戰鬥）。召回先清位。一波「守前哨」仍要在村閒置俠。"
	_outpost_panel.add_child(hint)

	_rebuild_outpost_pick_buttons()
	_rebuild_camp_pick_buttons()


func _rebuild_outpost_pick_buttons() -> void:
	if _outpost_btns == null:
		return
	for c in _outpost_btns.get_children():
		c.queue_free()
	for d in _OutpostScript.difficulties():
		var dd: Dictionary = d as Dictionary
		var idd: String = str(dd.get("id", ""))
		var b := Button.new()
		var lock: bool = not _OutpostScript.is_difficulty_unlocked(idd)
		b.text = str(dd.get("name", idd)) + ("鎖" if lock else "")
		b.disabled = lock
		b.toggle_mode = true
		b.button_pressed = idd == str(GameState.outpost_pick_diff)
		b.tooltip_text = str(dd.get("desc", ""))
		b.pressed.connect(_on_pick_outpost_diff.bind(idd))
		_outpost_btns.add_child(b)


func _rebuild_camp_pick_buttons() -> void:
	if _camp_btns == null:
		return
	for c in _camp_btns.get_children():
		c.queue_free()
	var pick: String = str(GameState.camp_pick_id)
	if pick == "" or _OutpostScript.camp_by_id(pick).is_empty():
		pick = _OutpostScript.default_camp_id()
		GameState.camp_pick_id = pick
	for cdata in _OutpostScript.camps():
		var cd: Dictionary = cdata as Dictionary
		var cid: String = str(cd.get("id", ""))
		var b := Button.new()
		var lock: bool = not _OutpostScript.is_camp_unlocked(cid)
		b.text = str(cd.get("name", cid)) + ("鎖" if lock else "")
		b.disabled = lock
		b.toggle_mode = true
		b.button_pressed = cid == pick
		var lv: int = _OutpostScript.camp_level(cid)
		b.tooltip_text = "%s｜Lv%d 槽%d" % [str(cd.get("desc", "")), lv, _OutpostScript.effective_slots(cid)]
		b.pressed.connect(_on_pick_camp.bind(cid))
		_camp_btns.add_child(b)


func _on_pick_outpost_diff(diff_id: String) -> void:
	GameState.outpost_pick_diff = diff_id
	_rebuild_outpost_pick_buttons()
	_refresh_outpost_panel()
	_refresh_outpost_btn()


func _on_pick_camp(camp_id: String) -> void:
	GameState.camp_pick_id = camp_id
	_rebuild_camp_pick_buttons()
	_refresh_outpost_panel()


func _on_camp_station_pressed() -> void:
	var camp_id: String = str(GameState.camp_pick_id)
	if camp_id == "":
		camp_id = _OutpostScript.default_camp_id()
	var slots: int = _OutpostScript.effective_slots(camp_id)
	var ids: Array = _selected_ids(slots)
	var res: Dictionary = _OutpostScript.station(camp_id, ids)
	if not bool(res.get("ok", false)):
		GameState.push_report("駐守失敗：%s" % str(res.get("reason", "")))
		return
	_selected.clear()
	_rebuild_heroes()
	_refresh_hud()
	_refresh_outpost_panel()
	_rebuild_camp_pick_buttons()


func _on_camp_recall_pressed() -> void:
	var camp_id: String = str(GameState.camp_pick_id)
	if camp_id == "":
		camp_id = _OutpostScript.default_camp_id()
	var res: Dictionary = _OutpostScript.recall(camp_id)
	if not bool(res.get("ok", false)):
		GameState.push_report("召回失敗：%s" % str(res.get("reason", "")))
		return
	_rebuild_heroes()
	_refresh_hud()
	_refresh_outpost_panel()
	_rebuild_camp_pick_buttons()


func _on_camp_upgrade_pressed() -> void:
	var camp_id: String = str(GameState.camp_pick_id)
	if camp_id == "":
		camp_id = _OutpostScript.default_camp_id()
	var res: Dictionary = _OutpostScript.upgrade_camp(camp_id)
	if not bool(res.get("ok", false)):
		GameState.push_report("升級失敗：%s" % str(res.get("reason", "")))
		_refresh_outpost_panel()
		return
	_refresh_hud()
	_refresh_outpost_panel()
	_rebuild_camp_pick_buttons()


func _on_camp_patrol_pressed() -> void:
	var camp_id: String = str(GameState.camp_pick_id)
	if camp_id == "":
		camp_id = _OutpostScript.default_camp_id()
	var res: Dictionary = _OutpostScript.run_manual_skirmish(camp_id)
	if not bool(res.get("ok", false)):
		GameState.push_report("巡哨失敗：%s" % str(res.get("reason", "")))
		_refresh_outpost_panel()
		return
	if _outpost_panel:
		_outpost_panel.visible = false
	_rebuild_heroes()
	_refresh_hud()
	var waves: Array = res.get("waves", []) as Array
	var rewards: Dictionary = (res.get("rewards", {}) as Dictionary).duplicate(true)
	rewards["flavor"] = str(res.get("flavor", rewards.get("flavor", "")))
	rewards["run_mode"] = "camp_skirmish"
	rewards["battle_mode"] = "outpost"
	rewards["waves"] = waves
	rewards["waves_cleared"] = int(res.get("waves_cleared", 1 if bool(res.get("success", false)) else 0))
	rewards["cleared"] = bool(res.get("cleared", res.get("success", false)))
	rewards["success"] = bool(res.get("success", false))
	rewards["total_waves"] = maxi(1, waves.size())
	rewards["zone_name"] = str(rewards.get("zone_name", "巡哨 · %s" % str(res.get("camp_name", camp_id))))
	rewards["run_title"] = str(rewards["zone_name"])
	_start_wave_battles(
		"outpost",
		str(rewards["zone_name"]),
		waves,
		res.get("heroes", []),
		rewards
	)


func _refresh_outpost_panel() -> void:
	if _outpost_label and _outpost_panel and _outpost_panel.visible:
		_outpost_label.text = _OutpostScript.describe_pick_panel_full()
		var n: int = _selected_ids(6).size()
		var chk: Dictionary = _OutpostScript.can_defend(_selected_ids(6)) if n > 0 else {"ok": false, "reason": "未揀俠"}
		if _btn_outpost_go:
			_btn_outpost_go.disabled = not bool(chk.get("ok", false))
			_btn_outpost_go.tooltip_text = str(chk.get("reason", "出發"))
		var camp_id: String = str(GameState.camp_pick_id)
		if camp_id == "":
			camp_id = _OutpostScript.default_camp_id()
		var slots: int = _OutpostScript.effective_slots(camp_id)
		var schk: Dictionary = _OutpostScript.can_station(camp_id, _selected_ids(slots)) if _selected_ids(slots).size() > 0 else {"ok": false, "reason": "未揀俠"}
		if _btn_camp_station:
			_btn_camp_station.disabled = not bool(schk.get("ok", false))
			_btn_camp_station.tooltip_text = str(schk.get("reason", "駐守"))
		var rchk: Dictionary = _OutpostScript.can_recall(camp_id)
		if _btn_camp_recall:
			_btn_camp_recall.disabled = not bool(rchk.get("ok", false))
			_btn_camp_recall.tooltip_text = str(rchk.get("reason", "召回"))
		var uchk: Dictionary = _OutpostScript.can_upgrade_camp(camp_id)
		if _btn_camp_upgrade:
			_btn_camp_upgrade.disabled = not bool(uchk.get("ok", false))
			var utip: String = str(uchk.get("reason", "升級營"))
			if bool(uchk.get("ok", false)):
				var ud: Dictionary = uchk.get("upgrade", {}) as Dictionary
				utip = "升級「%s」銀%d 木%d 鐵%d" % [
					str(ud.get("name", "升級")), int(ud.get("silver", 0)),
					int(ud.get("wood", 0)), int(ud.get("iron", 0)),
				]
			_btn_camp_upgrade.tooltip_text = utip
		var pchk: Dictionary = _OutpostScript.can_manual_skirmish(camp_id)
		if _btn_camp_patrol:
			_btn_camp_patrol.disabled = not bool(pchk.get("ok", false))
			_btn_camp_patrol.tooltip_text = str(pchk.get("reason", "巡哨"))


func _setup_academy_panel() -> void:
	_academy_panel = ColorRect.new()
	_academy_panel.name = "AcademyTreePanel"
	_academy_panel.color = Color(0.07, 0.06, 0.08, 0.95)
	_academy_panel.position = Vector2(300, 56)
	_academy_panel.size = Vector2(620, 460)
	_academy_panel.visible = false
	_academy_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_academy_panel)

	_academy_label = Label.new()
	_academy_label.position = Vector2(12, 8)
	_academy_label.size = Vector2(300, 150)
	_academy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_academy_label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.78))
	_academy_label.add_theme_font_size_override("font_size", 12)
	_academy_panel.add_child(_academy_label)

	_academy_preview = Label.new()
	_academy_preview.position = Vector2(320, 8)
	_academy_preview.size = Vector2(286, 150)
	_academy_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_academy_preview.add_theme_color_override("font_color", Color(0.85, 0.9, 0.78))
	_academy_preview.add_theme_font_size_override("font_size", 12)
	_academy_preview.text = "撳下方節點預覽（武學／經世）"
	_academy_panel.add_child(_academy_preview)

	_academy_branch_row = HBoxContainer.new()
	_academy_branch_row.position = Vector2(12, 162)
	_academy_branch_row.size = Vector2(596, 22)
	_academy_branch_row.add_theme_constant_override("separation", 12)
	_academy_panel.add_child(_academy_branch_row)

	_academy_btns = VBoxContainer.new()
	_academy_btns.position = Vector2(12, 188)
	_academy_btns.size = Vector2(596, 220)
	_academy_btns.add_theme_constant_override("separation", 4)
	_academy_panel.add_child(_academy_btns)

	_academy_unlock_flash = ColorRect.new()
	_academy_unlock_flash.name = "AcademyUnlockFlash"
	_academy_unlock_flash.color = Color(0.95, 0.85, 0.45, 0.0)
	_academy_unlock_flash.position = Vector2(0, 0)
	_academy_unlock_flash.size = _academy_panel.size
	_academy_unlock_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_academy_panel.add_child(_academy_unlock_flash)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_academy_panel.add_child(row)
	row.position = Vector2(12, 418)
	row.size = Vector2(596, 32)

	var btn_unlock := Button.new()
	btn_unlock.text = "解鎖節點"
	btn_unlock.tooltip_text = "消耗碎片解鎖揀中節點（需滿足前置）"
	btn_unlock.pressed.connect(_on_academy_unlock_pressed)
	row.add_child(btn_unlock)

	var btn_rotate := Button.new()
	btn_rotate.text = "授／輪換"
	btn_rotate.tooltip_text = "對剔選俠客輪換已解鎖被動"
	btn_rotate.pressed.connect(_on_academy_rotate_pressed)
	row.add_child(btn_rotate)

	var btn_close3 := Button.new()
	btn_close3.text = "關閉"
	btn_close3.pressed.connect(func() -> void: _academy_panel.visible = false)
	row.add_child(btn_close3)


func _academy_branch_color(branch_id: String) -> Color:
	if branch_id == "wuxue":
		return Color(0.78, 0.42, 0.34)
	if branch_id == "jingshi":
		return Color(0.42, 0.62, 0.48)
	return Color(0.7, 0.7, 0.72)


func _refresh_academy_panel() -> void:
	if _academy_panel == null or not _academy_panel.visible:
		return
	var hid: String = ""
	var ids: Array = _selected_ids(1)
	if ids.is_empty() and _craft_hero_id != "":
		hid = _craft_hero_id
	elif ids.size() > 0:
		hid = str(ids[0])
	if _academy_label:
		_academy_label.text = AcademySystem.describe_panel(hid)
	if _academy_preview:
		if _academy_pick_node != "":
			_academy_preview.text = AcademySystem.preview_node(_academy_pick_node)
		else:
			_academy_preview.text = "撳節點預覽效果\n武學＝攻防招架　經世＝村務營帳秘境"
	if _academy_branch_row:
		for c0 in _academy_branch_row.get_children():
			c0.queue_free()
		for br in AcademySystem.branches():
			var bd: Dictionary = br as Dictionary
			var lab := Label.new()
			lab.text = "● %s　%s" % [str(bd.get("name", "")), str(bd.get("desc", ""))]
			lab.add_theme_color_override("font_color", _academy_branch_color(str(bd.get("id", ""))))
			lab.add_theme_font_size_override("font_size", 12)
			_academy_branch_row.add_child(lab)
	## 按 row 重建網格（col 對齊）
	for c in _academy_btns.get_children():
		c.queue_free()
	var by_row: Dictionary = {}
	var max_col: int = 0
	for n in AcademySystem.tree_nodes_sorted():
		var nd: Dictionary = n as Dictionary
		var r: int = int(nd.get("row", 0))
		var col: int = int(nd.get("col", 0))
		max_col = maxi(max_col, col)
		if not by_row.has(r):
			by_row[r] = {}
		(by_row[r] as Dictionary)[col] = nd
	var rows: Array = by_row.keys()
	rows.sort()
	for r2 in rows:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 4)
		_academy_btns.add_child(h)
		var row_map: Dictionary = by_row[r2] as Dictionary
		for col_i in range(max_col + 1):
			if not row_map.has(col_i):
				var spacer := Control.new()
				spacer.custom_minimum_size = Vector2(108, 28)
				h.add_child(spacer)
				continue
			var nd2: Dictionary = row_map[col_i] as Dictionary
			var nid: String = str(nd2.get("id", ""))
			var b := Button.new()
			var unlocked: bool = AcademySystem.is_node_unlocked(nid)
			var cost: int = int(nd2.get("cost", 0))
			var branch: String = str(nd2.get("branch", ""))
			var mark: String = "✓" if unlocked else ("◇" if bool(AcademySystem.can_unlock_node(nid).get("ok", false)) else "·")
			var cost_txt: String = "" if unlocked or cost <= 0 else " %d碎" % cost
			b.text = "%s%s%s" % [mark, str(nd2.get("name", nid)), cost_txt]
			b.custom_minimum_size = Vector2(108, 28)
			b.toggle_mode = true
			b.button_pressed = nid == _academy_pick_node
			b.tooltip_text = AcademySystem.preview_node(nid)
			b.add_theme_color_override("font_color", _academy_branch_color(branch) if not unlocked else Color(0.95, 0.9, 0.7))
			if unlocked:
				b.modulate = Color(1.05, 1.02, 0.9)
			elif not bool(AcademySystem.can_unlock_node(nid).get("ok", false)):
				b.modulate = Color(0.72, 0.72, 0.74)
			b.pressed.connect(_on_academy_pick_node.bind(nid))
			h.add_child(b)


func _on_academy_pick_node(node_id: String) -> void:
	_academy_pick_node = node_id
	_refresh_academy_panel()


func _academy_play_unlock_flash() -> void:
	if _academy_unlock_flash == null or not is_instance_valid(_academy_unlock_flash):
		return
	_academy_unlock_flash.color = Color(0.95, 0.82, 0.4, 0.35)
	var tw := create_tween()
	tw.tween_property(_academy_unlock_flash, "color:a", 0.0, 0.45)


func _on_academy_unlock_pressed() -> void:
	if _academy_pick_node == "":
		GameState.push_report("書院：先揀一個節點")
		return
	var res: Dictionary = AcademySystem.unlock_node(_academy_pick_node)
	if not bool(res.get("ok", false)):
		GameState.push_report("書院解鎖失敗：%s" % str(res.get("reason", "")))
	else:
		_academy_play_unlock_flash()
	_refresh_hud()
	_refresh_academy_panel()


func _on_academy_rotate_pressed() -> void:
	var ids: Array = _selected_ids(1)
	if ids.is_empty() and _craft_hero_id != "":
		ids = [_craft_hero_id]
	if ids.is_empty():
		GameState.push_report("書院：先剔選／點一名俠客")
		return
	var res: Dictionary = AcademySystem.rotate_passive(str(ids[0]))
	if not bool(res.get("ok", false)):
		GameState.push_report("書院失敗：%s" % str(res.get("reason", "")))
	_rebuild_heroes()
	_refresh_hud()
	_refresh_academy_panel()
