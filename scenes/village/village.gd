extends Control
## 村莊場景：分層底圖 + 自由放置（幽靈預覽／可建區／碰撞／取消）

signal building_clicked(building_id: String)
signal building_placed(building_id: String, pos: Vector2)
signal place_cancelled

const LAYOUT_PATH := "res://data/buildings/layout.json"
## 兩棟建築中心最短距離（設計座標），避免疊太歪
const MIN_SEPARATION := 120.0
## 可建區（預設對齊 Pivot R2 pad；可被 layout.json 覆寫）
var BUILDABLE := Rect2(100, 160, 760, 360)

var _layout: Dictionary = {}
var _design := Vector2(960, 540)
var _icon_off := Vector2(-80, -88)
var _layer_root: Node2D
var _buildings_root: Node2D
var _overlay_root: Node2D
var _building_sprites: Dictionary = {}
## 放置模式：點地後放呢棟（空＝升級點擊）
var place_building_id: String = ""
var _dragging_id: String = ""
var _drag_grab: Vector2 = Vector2.ZERO
var _drag_moved: bool = false
var _ghost: Sprite2D
var _pad_hint: Polygon2D
var _place_hint_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_layout()
	_build_world()
	resized.connect(_fit_to_viewport)
	call_deferred("_fit_to_viewport")
	GameState.buildings_changed.connect(_refresh_building_visuals)
	GameState.placements_changed.connect(_sync_positions_from_state)
	_refresh_building_visuals()
	set_process(true)

func _process(_delta: float) -> void:
	if place_building_id == "":
		if _ghost:
			_ghost.visible = false
		if _pad_hint:
			_pad_hint.visible = false
		return
	_update_ghost_at(_design_from_local(get_local_mouse_position()))

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
	var br: Dictionary = _layout.get("buildable_rect", {}) as Dictionary
	if not br.is_empty():
		BUILDABLE = Rect2(
			float(br.get("x", 100)), float(br.get("y", 160)),
			float(br.get("w", 760)), float(br.get("h", 360))
		)

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

	for bid_v in BuildingSystem.sorted_building_ids():
		_add_building_icon(str(bid_v))

	_overlay_root = Node2D.new()
	_overlay_root.name = "PlaceOverlay"
	_overlay_root.z_index = 8
	_layer_root.add_child(_overlay_root)
	_make_pad_hint()
	_make_ghost()

	for layer_v2 in layers:
		var layer2: Dictionary = layer_v2 as Dictionary
		if str(layer2.get("id", "")) == "fg":
			_add_layer_sprite(layer2)

	## UI 提示（唔跟世界縮放，掛喺 Control 上）
	if _place_hint_label == null or not is_instance_valid(_place_hint_label):
		_place_hint_label = Label.new()
		_place_hint_label.name = "PlaceHint"
		_place_hint_label.visible = false
		_place_hint_label.add_theme_color_override("font_color", Color(0.788, 0.635, 0.153, 1))
		_place_hint_label.add_theme_font_size_override("font_size", 14)
		_place_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_place_hint_label)

func _make_pad_hint() -> void:
	_pad_hint = Polygon2D.new()
	_pad_hint.name = "PadHint"
	_pad_hint.color = Color(0.165, 0.416, 0.416, 0.18)
	var r := BUILDABLE
	_pad_hint.polygon = PackedVector2Array([
		r.position,
		r.position + Vector2(r.size.x, 0),
		r.position + r.size,
		r.position + Vector2(0, r.size.y),
	])
	_pad_hint.visible = false
	_overlay_root.add_child(_pad_hint)
	var border := Line2D.new()
	border.width = 2.0
	border.default_color = Color(0.165, 0.416, 0.416, 0.55)
	border.points = PackedVector2Array([
		r.position,
		r.position + Vector2(r.size.x, 0),
		r.position + r.size,
		r.position + Vector2(0, r.size.y),
		r.position,
	])
	_pad_hint.add_child(border)

func _make_ghost() -> void:
	_ghost = Sprite2D.new()
	_ghost.name = "Ghost"
	_ghost.centered = true
	_ghost.modulate = Color(1, 1, 1, 0.55)
	_ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ghost.z_index = 9
	_ghost.visible = false
	_overlay_root.add_child(_ghost)

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
	var sz := Vector2(160, 160)
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
	if _place_hint_label:
		_place_hint_label.position = Vector2(8, 8)
		_place_hint_label.size = Vector2(sz.x - 16, 28)

func _design_from_local(local: Vector2) -> Vector2:
	if _layer_root == null:
		return local
	var s: float = _layer_root.scale.x
	if s <= 0.0001:
		return local
	return (local - _layer_root.position) / s

func begin_place(building_id: String) -> void:
	## 再撳同一棟＝取消
	if place_building_id == building_id:
		cancel_place()
		return
	place_building_id = building_id
	var tex: Texture2D = ArtPaths.load_tex(ArtPaths.building_icon(building_id))
	if _ghost and tex != null:
		_ghost.texture = tex
	if _pad_hint:
		_pad_hint.visible = true
	if _place_hint_label:
		_place_hint_label.visible = true
		_place_hint_label.text = "放置「%s」：綠＝可放｜紅＝撞／出界｜右鍵或 Esc 取消" % BuildingSystem.building_name(building_id)
	GameState.push_report("放置模式：點村莊可建區放「%s」（右鍵／Esc 取消）" % BuildingSystem.building_name(building_id))

func cancel_place() -> void:
	if place_building_id == "":
		return
	var name_cn: String = BuildingSystem.building_name(place_building_id)
	place_building_id = ""
	if _ghost:
		_ghost.visible = false
	if _pad_hint:
		_pad_hint.visible = false
	if _place_hint_label:
		_place_hint_label.visible = false
	GameState.push_report("已取消放置「%s」" % name_cn)
	place_cancelled.emit()

func is_placing() -> bool:
	return place_building_id != ""

func can_place_at(pos: Vector2, ignore_id: String = "") -> Dictionary:
	## 回傳 {ok:bool, reason:String}
	if not BUILDABLE.has_point(pos):
		return {"ok": false, "reason": "出咗可建區"}
	var check_id: String = ignore_id if ignore_id != "" else place_building_id
	for bid in _building_sprites.keys():
		var other: String = str(bid)
		if other == check_id:
			continue
		## 未解鎖／0 級可以當未佔地，允許靠近預設位
		var lv: int = BuildingSystem.building_level(other)
		var unlocked: bool = false
		if GameState.buildings.has(other):
			unlocked = bool((GameState.buildings[other] as Dictionary).get("unlocked", false)) or lv > 0
		if not unlocked:
			continue
		var op: Vector2 = GameState.get_building_pos(other)
		if op.distance_to(pos) < MIN_SEPARATION:
			return {"ok": false, "reason": "同「%s」太近" % BuildingSystem.building_name(other)}
	return {"ok": true, "reason": ""}

func _clamp_design(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, BUILDABLE.position.x, BUILDABLE.position.x + BUILDABLE.size.x),
		clampf(pos.y, BUILDABLE.position.y, BUILDABLE.position.y + BUILDABLE.size.y)
	)

func _update_ghost_at(design_pos: Vector2) -> void:
	if _ghost == null or place_building_id == "":
		return
	_ghost.visible = true
	_ghost.position = design_pos
	var chk: Dictionary = can_place_at(design_pos)
	if bool(chk.get("ok", false)):
		_ghost.modulate = Color(0.45, 0.85, 0.55, 0.65)
	else:
		_ghost.modulate = Color(0.9, 0.35, 0.3, 0.65)

func _try_place_at(design_pos: Vector2) -> bool:
	var chk: Dictionary = can_place_at(design_pos)
	if not bool(chk.get("ok", false)):
		GameState.push_report("放唔到：%s" % str(chk.get("reason", "")))
		return false
	GameState.set_building_pos(place_building_id, design_pos)
	building_placed.emit(place_building_id, design_pos)
	GameState.push_report("已放置「%s」" % BuildingSystem.building_name(place_building_id))
	place_building_id = ""
	if _ghost:
		_ghost.visible = false
	if _pad_hint:
		_pad_hint.visible = false
	if _place_hint_label:
		_place_hint_label.visible = false
	return true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if place_building_id != "":
				cancel_place()
				accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if place_building_id != "":
				var design_pos: Vector2 = _design_from_local(mb.position)
				_try_place_at(design_pos)
				accept_event()
	if event is InputEventMouseMotion and _dragging_id != "":
		var mm := event as InputEventMouseMotion
		_drag_moved = true
		var design_pos2: Vector2 = _design_from_local(mm.position) - _drag_grab
		design_pos2 = _clamp_design(design_pos2)
		## 拖移時即時預覽（碰撞唔通過就唔寫入，留喺上個合法位附近）
		var chk: Dictionary = can_place_at(design_pos2, _dragging_id)
		if bool(chk.get("ok", false)):
			GameState.set_building_pos(_dragging_id, design_pos2)
		else:
			## 仍更新顯示但推返可建區邊緣
			var soft: Vector2 = design_pos2
			GameState.set_building_pos(_dragging_id, soft)
		accept_event()

func _on_building_button_down(bid: String) -> void:
	if place_building_id != "":
		return
	_dragging_id = bid
	_drag_moved = false
	var local: Vector2 = get_local_mouse_position()
	var design_mouse: Vector2 = _design_from_local(local)
	_drag_grab = design_mouse - GameState.get_building_pos(bid)

func _on_building_pressed(bid: String) -> void:
	var was_drag: bool = _drag_moved
	if _dragging_id == bid:
		_dragging_id = ""
	if place_building_id != "":
		## 放置模式點喺其他建築上：當放喺嗰個位置試
		var pos: Vector2 = GameState.get_building_pos(bid)
		_try_place_at(pos)
		return
	if was_drag:
		## 拖完鬆手：若最終位碰撞，彈返最近合法（簡化：回到 clamp）
		var pos2: Vector2 = GameState.get_building_pos(bid)
		var chk: Dictionary = can_place_at(pos2, bid)
		if not bool(chk.get("ok", false)):
			## 搵附近空位
			var fixed: Vector2 = _find_nearby_free(pos2, bid)
			GameState.set_building_pos(bid, fixed)
			GameState.push_report("位置太擠，已微調「%s」" % BuildingSystem.building_name(bid))
		return
	building_clicked.emit(bid)

func _find_nearby_free(from: Vector2, ignore_id: String) -> Vector2:
	var offsets: Array = [
		Vector2.ZERO, Vector2(110, 0), Vector2(-110, 0), Vector2(0, 110), Vector2(0, -110),
		Vector2(110, 110), Vector2(-110, 110), Vector2(110, -110), Vector2(-110, -110),
		Vector2(160, 0), Vector2(-160, 0), Vector2(0, 160), Vector2(0, -160),
	]
	for o in offsets:
		var p: Vector2 = _clamp_design(from + (o as Vector2))
		if bool(can_place_at(p, ignore_id).get("ok", false)):
			return p
	return _clamp_design(from)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_ESCAPE and place_building_id != "":
			cancel_place()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if _dragging_id != "":
				var bid: String = _dragging_id
				_dragging_id = ""
				if _drag_moved:
					var pos2: Vector2 = GameState.get_building_pos(bid)
					var chk: Dictionary = can_place_at(pos2, bid)
					if not bool(chk.get("ok", false)):
						var fixed: Vector2 = _find_nearby_free(pos2, bid)
						GameState.set_building_pos(bid, fixed)
