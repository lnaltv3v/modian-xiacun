extends Control
## 村莊場景：按 layout.json 分層 + 建築圖示錨點（設計稿 960×540，等比縮放）

signal building_clicked(building_id: String)

const LAYOUT_PATH := "res://data/buildings/layout.json"

var _layout: Dictionary = {}
var _design := Vector2(960, 540)
var _icon_off := Vector2(-48, -56)
var _layer_root: Node2D
var _buildings_root: Node2D
var _building_sprites: Dictionary = {}

func _ready() -> void:
	_load_layout()
	_build_world()
	resized.connect(_fit_to_viewport)
	call_deferred("_fit_to_viewport")
	GameState.buildings_changed.connect(_refresh_building_visuals)
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
	_icon_off = Vector2(float(off.get("x", -48)), float(off.get("y", -56)))

func _build_world() -> void:
	for c in get_children():
		c.queue_free()
	_layer_root = Node2D.new()
	_layer_root.name = "World"
	add_child(_layer_root)

	var layers: Array = _layout.get("layers", []) as Array
	for layer_v in layers:
		var layer: Dictionary = layer_v as Dictionary
		var lid: String = str(layer.get("id", ""))
		if lid == "fg":
			continue  ## fg 最後加，蓋過建築
		_add_layer_sprite(layer)

	_buildings_root = Node2D.new()
	_buildings_root.name = "Buildings"
	_buildings_root.z_index = 5
	_layer_root.add_child(_buildings_root)

	var buildings: Array = _layout.get("buildings", []) as Array
	for b_v in buildings:
		var b: Dictionary = b_v as Dictionary
		_add_building_icon(b)

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

func _add_building_icon(b: Dictionary) -> void:
	var bid: String = str(b.get("id", ""))
	var cx: float = float(b.get("cx", 0))
	var cy: float = float(b.get("cy", 0))
	var z: int = int(b.get("z", 5))
	var btn := TextureButton.new()
	btn.name = bid
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.z_index = z
	btn.position = Vector2(cx, cy) + _icon_off
	var tex: Texture2D = ArtPaths.load_tex(ArtPaths.building_icon(bid))
	if tex != null:
		btn.texture_normal = tex
		btn.custom_minimum_size = tex.get_size()
		btn.size = tex.get_size()
	else:
		btn.custom_minimum_size = Vector2(96, 96)
		btn.size = Vector2(96, 96)
	btn.pressed.connect(func() -> void: building_clicked.emit(bid))
	_buildings_root.add_child(btn)
	_building_sprites[bid] = btn

func _refresh_building_visuals() -> void:
	for bid in _building_sprites.keys():
		var btn: TextureButton = _building_sprites[bid] as TextureButton
		if btn == null:
			continue
		var lv: int = BuildingSystem.building_level(str(bid))
		var unlocked: bool = false
		if GameState.buildings.has(bid):
			unlocked = bool((GameState.buildings[bid] as Dictionary).get("unlocked", false)) or lv > 0
		btn.modulate = Color(1, 1, 1, 1) if unlocked else Color(1, 1, 1, 0.35)
		btn.tooltip_text = "%s Lv.%d" % [BuildingSystem.building_name(str(bid)), lv]

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
