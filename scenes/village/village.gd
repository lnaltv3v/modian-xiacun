extends Control
## 村莊場景：分層底圖 + 玩家自由放置建築（layout.json 只作預設／示範）

signal building_clicked(building_id: String)
signal building_placed(building_id: String, pos: Vector2)

const LAYOUT_PATH := "res://data/buildings/layout.json"

var _layout: Dictionary = {}
var _design := Vector2(960, 540)
var _icon_off := Vector2(-64, -72)
var _layer_root: Node2D
var _buildings_root: Node2D
var _building_sprites: Dictionary = {}
## 放置模式：點地後放呢棟（空＝升級點擊）
var place_building_id: String = ""
var _dragging_id: String = ""
var _drag_grab: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_layout()
	_build_world()
	resized.connect(_fit_to_viewport)
	call_deferred("_fit_to_viewport")
	GameState.buildings_changed.connect(_refresh_building_visuals)
	GameState.placements_changed.connect(_sync_positions_from_state)
	_refresh_building_visuals()

func _load_layout() -> void:
	if not FileAccess.file_exists(LAYOUT_PATH):
		push_warning("village: missing %s" % LAYOUT_PATH)
		return
	var f := FileAccess.open(LAYOUT_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_layout = parsed as Dictionary
	var ds: Dictionary = _layout.get("design_size", {}) as Dictionary
	_design = Vector2(float(ds.get("w", 960)), float(ds.get("h", 540)))
	var off: Dictionary = _layout.get("icon_anchor_offset", {}) as Dictionary
	_icon_off = Vector2(float(off.get("x", -64)), float(off.get("y", -72)))

func _build_world() -> void:
	for c in get_children():
		c.queue_free()
	_building_sprites.clear()
	_layer_root = Node2D.new()
	_layer_root.name = "World"
	add_child(_layer_root)

	var layers: Array = _layout.get("layers", []) as Array
	for layer_v in layers:
		var layer: Dictionary = layer_v as Dictionary
		var lid: String = str(layer.get("id", ""))
		if lid == "fg":
			continue
		_add_layer_sprite(layer)

	_buildings_root = Node2D.new()
	_buildings_root.name = "Buildings"
	_buildings_root.z_index = 5
	_layer_root.add_child(_buildings_root)

	## 以 GameState 建築表為準；位置優先玩家放置，否則 layout 預設
	for bid_v in BuildingSystem.sorted_building_ids():
		_add_building_icon(str(bid_v))

	for layer_v2 in layers:
		var layer2: Dictionary = layer_v2 as Dictionary
		if str(layer2.get("id", "")) == "fg":
			_add_layer_sprite(layer2)

func _add_layer_sprite(layer: Dictionary) -> void:
	var path: String = str(layer.get("path", ""))
	var spr := Sprite2D.new()
	spr.name = str(layer.get("id", "layer"))
	spr.centered = false
	spr.position = Vector2.ZERO
	spr.z_index = int(layer.get("z", 0))
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex: Texture2D = ArtPaths.load_tex(path)
	if tex != null:
		spr.texture = tex
	_layer_root.add_child(spr)

func _add_building_icon(bid: String) -> void:
	var pos: Vector2 = GameState.get_building_pos(bid)
	var btn := TextureButton.new()
	btn.name = bid
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.z_index = 5
	var tex: Texture2D = ArtPaths.load_tex(ArtPaths.building_icon(bid))
	var sz := Vector2(128, 128)
	if tex != null:
		btn.texture_normal = tex
		sz = tex.get_size()
	btn.custom_minimum_size = sz
	btn.size = sz
	_icon_off = Vector2(-sz.x * 0.5, -sz.y * 0.55)
	btn.position = pos + _icon_off
	btn.button_down.connect(_on_building_button_down.bind(bid))
	btn.pressed.connect(_on_building_pressed.bind(bid))
	_buildings_root.add_child(btn)
	_building_sprites[bid] = btn

func _sync_positions_from_state() -> void:
	for bid in _building_sprites.keys():
		var btn: TextureButton = _building_sprites[bid] as TextureButton
		if btn == null:
			continue
		var pos: Vector2 = GameState.get_building_pos(str(bid))
		var sz: Vector2 = btn.size
		btn.position = pos + Vector2(-sz.x * 0.5, -sz.y * 0.55)

func _refresh_building_visuals() -> void:
	## 若有新建築 id 未建 icon，重建
	var need_rebuild: bool = false
	for bid_v in BuildingSystem.sorted_building_ids():
		if not _building_sprites.has(str(bid_v)):
			need_rebuild = true
			break
	if need_rebuild:
		_build_world()
		_fit_to_viewport()
	for bid in _building_sprites.keys():
		var btn: TextureButton = _building_sprites[bid] as TextureButton
		if btn == null:
			continue
		var lv: int = BuildingSystem.building_level(str(bid))
		var unlocked: bool = false
		if GameState.buildings.has(bid):
			unlocked = bool((GameState.buildings[bid] as Dictionary).get("unlocked", false)) or lv > 0
		btn.modulate = Color(1, 1, 1, 1) if unlocked else Color(1, 1, 1, 0.35)
		btn.tooltip_text = "%s Lv.%d（拖移改位／點擊升級）" % [BuildingSystem.building_name(str(bid)), lv]

func _fit_to_viewport() -> void:
	if _layer_root == null:
		return
	var sz: Vector2 = size
	if sz.x < 1.0 or sz.y < 1.0:
		sz = get_viewport_rect().size
	var sx: float = sz.x / _design.x
	var sy: float = sz.y / _design.y
	var s: float = minf(sx, sy)
	_layer_root.scale = Vector2(s, s)
	_layer_root.position = Vector2((sz.x - _design.x * s) * 0.5, (sz.y - _design.y * s) * 0.5)

func _design_from_local(local: Vector2) -> Vector2:
	if _layer_root == null:
		return local
	var s: float = _layer_root.scale.x
	if s <= 0.0001:
		return local
	return (local - _layer_root.position) / s

func begin_place(building_id: String) -> void:
	place_building_id = building_id
	GameState.push_report("放置模式：點村莊地面放「%s」（再點取消）" % BuildingSystem.building_name(building_id))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if place_building_id != "":
				var design_pos: Vector2 = _design_from_local(mb.position)
				design_pos.x = clampf(design_pos.x, 64, _design.x - 64)
				design_pos.y = clampf(design_pos.y, 64, _design.y - 32)
				GameState.set_building_pos(place_building_id, design_pos)
				building_placed.emit(place_building_id, design_pos)
				GameState.push_report("已放置「%s」" % BuildingSystem.building_name(place_building_id))
				place_building_id = ""
				accept_event()
	if event is InputEventMouseMotion and _dragging_id != "":
		var mm := event as InputEventMouseMotion
		var design_pos2: Vector2 = _design_from_local(mm.position) - _drag_grab
		design_pos2.x = clampf(design_pos2.x, 64, _design.x - 64)
		design_pos2.y = clampf(design_pos2.y, 64, _design.y - 32)
		GameState.set_building_pos(_dragging_id, design_pos2)
		accept_event()

func _on_building_button_down(bid: String) -> void:
	_dragging_id = bid
	var btn: TextureButton = _building_sprites.get(bid) as TextureButton
	if btn:
		var local: Vector2 = get_local_mouse_position()
		var design_mouse: Vector2 = _design_from_local(local)
		_drag_grab = design_mouse - GameState.get_building_pos(bid)

func _on_building_pressed(bid: String) -> void:
	## 短按＝升級；拖移時唔觸發明顯位移就不額外處理
	if _dragging_id == bid:
		_dragging_id = ""
	if place_building_id != "":
		return
	building_clicked.emit(bid)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_dragging_id = ""
