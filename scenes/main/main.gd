extends Control
## 墨點俠村 v0.5 — 英雄帖／懸賞／兵器鋪

const VillageScene := preload("res://scenes/village/village.tscn")
const HuntResultScene := preload("res://scenes/combat/hunt_result.tscn")
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
@onready var icon_iron: TextureRect = %IconIron
@onready var monster_preview: TextureRect = %MonsterPreview
@onready var craft_box: VBoxContainer = %CraftBox
@onready var inv_label: Label = %InvLabel
@onready var title_label: Label = %Title
@onready var tutorial_banner: ColorRect = %TutorialBanner
@onready var tutorial_label: Label = %TutorialLabel
@onready var btn_skip_tutorial: Button = %BtnSkipTutorial
@onready var btn_gacha: Button = %BtnGacha
@onready var frag_label: Label = %FragLabel
@onready var opt_bounty: OptionButton = %OptBounty
@onready var chk_auto_shop: CheckBox = %ChkAutoShop
@onready var btn_shop_once: Button = %BtnShopOnce

var _dispatch: DispatchSystem
var _village: Control
var _hunt_result: Control
var _selected: Dictionary = {}
var _hero_rows: Dictionary = {}
var _craft_hero_id: String = ""

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

	if title_label:
		title_label.text = "墨點俠村 · v0.5"

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
	if opt_bounty:
		opt_bounty.item_selected.connect(_on_bounty_selected)
	if chk_auto_shop:
		chk_auto_shop.toggled.connect(_on_auto_shop_toggled)
		chk_auto_shop.button_pressed = GameState.auto_shop
	if btn_shop_once:
		btn_shop_once.pressed.connect(_on_shop_once_pressed)

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
	var st_cn := "在村" if st == "idle" else ("出征" if st == "hunting" else st)
	var gear: int = HeroSystem.equipment_power(h)
	var gear_txt: String = (" 裝+%d" % gear) if gear > 0 else ""
	return "%s Lv%d · %s · 力%d%s · 體%.0f 飽%.0f 傷%.0f · XP%.0f/%d · %s" % [
		str(h.get("name", "")),
		int(h.get("level", 1)),
		str(h.get("weapon", "")),
		HeroSystem.power_of(h),
		gear_txt,
		float(h.get("stamina", 0)),
		float(h.get("satiety", 0)),
		float(h.get("injury", 0)),
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

	var lines: PackedStringArray = PackedStringArray()
	lines.append("庫存 %d 件" % GameState.inventory.size())
	for i in range(mini(6, GameState.inventory.size())):
		var it: Dictionary = GameState.inventory[i] as Dictionary
		lines.append("· %s" % str(it.get("name", "?")))
	inv_label.text = "\n".join(lines)

func _refresh_hud() -> void:
	hud_label.text = "銀 %d　木 %d　毛皮 %d　鐵 %d　碎片 %d　駐紮 %d／%d　在村 %d　出征 %d" % [
		GameState.silver,
		GameState.wood,
		GameState.fur,
		GameState.iron,
		GameState.fragments,
		GameState.hero_count(),
		GameState.hero_capacity(),
		GameState.idle_hero_count(),
		GameState.hunting_hero_count(),
	]
	_refresh_gacha_shop()
	status_label.text = "%s　｜　練功+%.1f XP/s　｜　%s　｜　放＝自由放置（Esc 取消）" % [
		UpkeepSystem.describe_rates(),
		TrainingSystem.xp_per_sec(),
		ResourceLoop.describe_loop(),
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
	btn_dispatch.text = "出征亂山坡（已選 %d）" % n

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
		var res: Dictionary = _dispatch.dispatch_ready(int(spin_count.value), "luan_shan_po")
		if not bool(res.get("ok", false)):
			GameState.push_report("派遣失敗：%s" % str(res.get("reason", "")))
		else:
			ok = true
		_selected.clear()
		_rebuild_heroes()
	else:
		var res2: Dictionary = _dispatch.start_hunt(ids, "luan_shan_po")
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
		else:
			GameState.push_report("%s升至 Lv.%d" % [name_cn, after])
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
	## 結果演出
	var enemies: Array = rewards.get("enemies", []) as Array
	if enemies.size() > 0:
		var kind: String = str((enemies[0] as Dictionary).get("kind", "wolf"))
		_set_tex(monster_preview, ArtPaths.monster_attack(kind))
	if _hunt_result and _hunt_result.has_method("show_result"):
		_hunt_result.show_result(rewards)
	if GameState.tutorial_step == 3:
		GameState.tutorial_step = 0
		GameState.push_report("引導完成！之後可自由興建、放置、製作同自動出征。")
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
			tutorial_label.text = "③ 等下方倒數完 → 俠客回村，收銀／毛皮。跟住自由玩！"
		_:
			tutorial_label.text = "新手引導"

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
	if frag_label:
		frag_label.text = "碎片 %d" % GameState.fragments
	if btn_gacha:
		var chk: Dictionary = GachaSystem.can_pull()
		btn_gacha.disabled = not bool(chk.get("ok", false))
		btn_gacha.text = "英雄帖（%d銀）" % GachaSystem.pull_cost()
		btn_gacha.tooltip_text = str(chk.get("reason", "白／綠／藍池；重覆轉碎片"))
	if btn_shop_once:
		btn_shop_once.disabled = not ShopSystem.forge_ready()
		btn_shop_once.tooltip_text = "為在村俠客買一件更強裝" if ShopSystem.forge_ready() else "要先起鐵匠鋪"

func _on_gacha_pressed() -> void:
	var res: Dictionary = GachaSystem.pull_once()
	if not bool(res.get("ok", false)):
		GameState.push_report("英雄帖失敗：%s" % str(res.get("reason", "")))
	_rebuild_heroes()
	_refresh_hud()

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

