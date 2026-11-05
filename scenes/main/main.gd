extends Control
## 墨點俠村 v0.9.9 — academy Pivot R4＋食住醫／秘境前哨 UI 釐清（橙紫 art 見 v0.9.8）

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
		title_label.text = "墨點俠村 · v0.9.9"

	_setup_resource_icons()
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

	_rebuild_buildings()
	_rebuild_heroes()
	_refresh_craft()
	_refresh_hud()
	_refresh_hunts()
	_refresh_reports()
	_refresh_tutorial()

func _setup_resource_icons() -> void:
	_set_tex(icon_silver, ArtPaths.ICON_SILVER)
	_set_tex(icon_wood, ArtPaths.ICON_WOOD)
	_set_tex(icon_fur, ArtPaths.ICON_FUR)
	_set_tex(icon_iron, ArtPaths.ICON_IRON)

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
	var st_cn := "在村" if st == "idle" else ("出征" if st == "hunting" else ("秘境" if st == "dungeon" else st))
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
	status_label.text = "%s　｜　練功+%.1f XP/s　｜　%s%s　｜　放＝自由放置（Esc 取消）" % [
		UpkeepSystem.describe_status(),
		TrainingSystem.xp_per_sec(),
		ResourceLoop.describe_loop(),
		party_txt,
	]
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
			tutorial_label.text = "④ 撳「英雄帖」抽一次，或興建醫館／貨棧／書院；之後可試秘境／前哨。"
		_:
			tutorial_label.text = "新手引導"

func _complete_tutorial_build_or_gacha(via: String) -> void:
	if GameState.tutorial_step != 4:
		return
	GameState.tutorial_step = 0
	GameState.push_report("引導完成（%s）！之後可自由興建、放置、抽卡、製作同自動出征。" % via)
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
	var waves_n: int = 3
	var ddef: Dictionary = DungeonSystem.dungeon_def()
	if not ddef.is_empty():
		waves_n = maxi(1, (ddef.get("waves", []) as Array).size())
	var chk: Dictionary = DungeonSystem.can_enter(_selected_ids(DungeonSystem.max_party())) if n > 0 else {"ok": false, "reason": "剔選 1～%d 俠入秘境（%d 波）" % [DungeonSystem.max_party(), waves_n]}
	if GameState.dungeon_busy:
		btn_dungeon.disabled = true
		btn_dungeon.text = "秘境進行中"
		btn_dungeon.tooltip_text = "三波自動戰鬥未完"
	elif n < 1:
		btn_dungeon.disabled = true
		btn_dungeon.text = "秘境·%d波" % waves_n
		btn_dungeon.tooltip_text = "剔選 1～%d 名在村俠客 → 亂山秘境（%d 波自動戰鬥）" % [DungeonSystem.max_party(), waves_n]
	elif n > DungeonSystem.max_party():
		btn_dungeon.disabled = true
		btn_dungeon.text = "秘境（最多%d）" % DungeonSystem.max_party()
		btn_dungeon.tooltip_text = "最多 %d 俠" % DungeonSystem.max_party()
	else:
		btn_dungeon.disabled = not bool(chk.get("ok", false))
		btn_dungeon.text = "秘境·%d波（%d）" % [waves_n, n] if bool(chk.get("ok", false)) else "秘境（未可）"
		var tip: String = str(chk.get("reason", ""))
		if tip == "":
			tip = "亂山秘境 · %d 波自動戰鬥" % waves_n
		btn_dungeon.tooltip_text = tip
	if btn_academy:
		var alv: int = BuildingSystem.building_level("academy")
		btn_academy.disabled = not AcademySystem.academy_ready()
		if AcademySystem.academy_ready():
			btn_academy.text = "書院 Lv%d" % maxi(1, alv)
			btn_academy.tooltip_text = "剔選一名俠客 → 授／輪換被動技"
		else:
			btn_academy.text = "書院（未建）"
			btn_academy.tooltip_text = "左邊興建「師門書院」後可授被動技"

func _on_dungeon_pressed() -> void:
	var ids: Array = _selected_ids(DungeonSystem.max_party())
	var res: Dictionary = DungeonSystem.run_dungeon(ids)
	if not bool(res.get("ok", false)):
		GameState.push_report("秘境失敗：%s" % str(res.get("reason", "")))
		return
	GameState.dungeon_busy = true
	_selected.clear()
	_rebuild_heroes()
	_refresh_hud()
	_start_wave_battles(
		"dungeon",
		str(res.get("dungeon_name", "秘境")),
		res.get("waves", []) as Array,
		res.get("heroes", ids),
		(res.get("rewards", {}) as Dictionary).duplicate(true)
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
	var ids: Array = _selected_ids(1)
	if ids.is_empty() and _craft_hero_id != "":
		ids = [_craft_hero_id]
	if ids.is_empty():
		GameState.push_report("書院：先剔選／點一名俠客")
		return
	var hid: String = str(ids[0])
	var skills: Array = AcademySystem.all_skills()
	if skills.is_empty():
		GameState.push_report("書院：技能表空")
		return
	## 最小：輪換下一招（按現有 passive 循環）
	var cur: String = str(HeroSystem.get_hero(hid).get("passive_id", ""))
	var idx: int = 0
	for i in range(skills.size()):
		if str((skills[i] as Dictionary).get("id", "")) == cur:
			idx = (i + 1) % skills.size()
			break
	var sk: Dictionary = skills[idx] as Dictionary
	var res: Dictionary = AcademySystem.assign_passive(hid, str(sk.get("id", "")))
	if not bool(res.get("ok", false)):
		GameState.push_report("書院失敗：%s" % str(res.get("reason", "")))
	_rebuild_heroes()
	_refresh_hud()

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
		btn_outpost.disabled = true
		btn_outpost.text = "前哨（鎖）"
		btn_outpost.tooltip_text = "解鎖：村長府 Lv.%d（而家%d）＋懸賞榜 Lv.%d（而家%d）→ 守 %d 波" % [
			need_m, cur_m, need_b, cur_b, wn
		]
		return
	if n < 1:
		btn_outpost.disabled = true
		btn_outpost.text = "前哨·%d波" % wn
		btn_outpost.tooltip_text = "剔選在村俠客守點（%d 波山賊／獸潮自動戰鬥）" % wn
	else:
		var chk: Dictionary = _OutpostScript.can_defend(_selected_ids(6))
		btn_outpost.disabled = not bool(chk.get("ok", false))
		btn_outpost.text = "前哨·%d波（%d）" % [wn, n] if bool(chk.get("ok", false)) else "前哨（未可）"
		var tip2: String = str(chk.get("reason", ""))
		if tip2 == "":
			tip2 = "前哨防衛 · %d 波" % wn
		btn_outpost.tooltip_text = tip2

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
	var ids: Array = _selected_ids(6)
	var res: Dictionary = _OutpostScript.run_defense(ids)
	if not bool(res.get("ok", false)):
		GameState.push_report("前哨失敗：%s" % str(res.get("reason", "")))
		return
	_selected.clear()
	_rebuild_heroes()
	_refresh_hud()
	var rewards: Dictionary = (res.get("rewards", {}) as Dictionary).duplicate(true)
	rewards["flavor"] = str(res.get("flavor", rewards.get("flavor", "")))
	rewards["injured"] = rewards.get("injured", [])
	_start_wave_battles(
		"outpost",
		"前哨防衛",
		res.get("waves", []) as Array,
		res.get("heroes", ids),
		rewards
	)

func _start_wave_battles(mode: String, title: String, waves: Array, hero_ids: Array, final_rewards: Dictionary) -> void:
	_battle_mode = mode
	_battle_final = final_rewards.duplicate(true)
	_battle_queue.clear()
	for wv in waves:
		var w: Dictionary = (wv as Dictionary).duplicate(true)
		w["_title"] = "%s · %s" % [title, str(w.get("label", "波次"))]
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

