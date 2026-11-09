extends Control
## 同屏世界地圖：村莊＋野外區可拖移／滑動；俠客／怪物自由走動；建築／遇敵用 overlay 訊號

signal building_clicked(building_id: String)
signal building_placed(building_id: String, pos: Vector2)
signal place_cancelled
signal encounter_requested(payload: Dictionary)
signal map_action(action: String, payload: Dictionary)

const LAYOUT_PATH := "res://data/buildings/layout.json"
const MIN_SEPARATION := 120.0
const WORLD_SCALE := 0.62
const PAN_MARGIN := 48.0

var BUILDABLE := Rect2(100, 160, 760, 360)

var _layout: Dictionary = {}
var _design := Vector2(960, 540)
var _icon_off := Vector2(-80, -88)

var _world: Node2D
var _buildings_root: Node2D
var _actors_root: Node2D
var _overlay_root: Node2D
var _building_sprites: Dictionary = {}
var _zone_rects: Dictionary = {}  # id -> Rect2 in world design space
var _heroes: Array = []  # {node, id, target, speed, zone}
var _monsters: Array = []  # {node, kind, zone, origin, roam_r, speed, cd}
var _rng := RandomNumberGenerator.new()

var place_building_id: String = ""
var _dragging_id: String = ""
var _drag_grab: Vector2 = Vector2.ZERO
var _drag_moved: bool = false
var _ghost: Sprite2D
var _pad_hint: Polygon2D
var _place_hint_label: Label
var _hint_label: Label

var _panning: bool = false
var _pan_last: Vector2 = Vector2.ZERO
var _pan_moved: bool = false
var _cam: Vector2 = Vector2.ZERO  # top-left of view in world px (pre-scale)
var _world_size: Vector2 = Vector2(2200, 1400)
var _encounter_busy: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_rng.randomize()
	_load_layout()
	_build_world()
	resized.connect(_apply_camera)
	call_deferred("_apply_camera")
	call_deferred("_spawn_actors")
	GameState.buildings_changed.connect(_refresh_building_visuals)
	GameState.placements_changed.connect(_sync_positions_from_state)
	GameState.heroes_changed.connect(_sync_hero_actors)
	_refresh_building_visuals()
	set_process(true)

func _process(delta: float) -> void:
	if place_building_id != "":
		_update_ghost_at(_design_from_local(get_local_mouse_position()))
		if _ghost:
			_ghost.visible = true
		if _pad_hint:
			_pad_hint.visible = true
	else:
		if _ghost:
			_ghost.visible = false
		if _pad_hint:
			_pad_hint.visible = false
	_tick_heroes(delta)
	_tick_monsters(delta)

func _load_layout() -> void:
	if not FileAccess.file_exists(LAYOUT_PATH):
		push_warning("world_map: missing %s" % LAYOUT_PATH)
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
	_heroes.clear()
	_monsters.clear()

	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)

	## --- 村莊核心 (0,0) ---
	var village_root := Node2D.new()
	village_root.name = "VillageCore"
	village_root.position = Vector2(80, 80)
	_world.add_child(village_root)
	_zone_rects["village"] = Rect2(village_root.position, _design)

	var layers: Array = _layout.get("layers", []) as Array
	for layer_v in layers:
		var layer: Dictionary = layer_v as Dictionary
		if str(layer.get("id", "")) == "fg":
			continue
		_add_layer_sprite(village_root, layer)

	_buildings_root = Node2D.new()
	_buildings_root.name = "Buildings"
	_buildings_root.z_index = 5
	village_root.add_child(_buildings_root)
	for bid_v in BuildingSystem.sorted_building_ids():
		_add_building_icon(str(bid_v))

	_overlay_root = Node2D.new()
	_overlay_root.name = "PlaceOverlay"
	_overlay_root.z_index = 8
	village_root.add_child(_overlay_root)
	_make_pad_hint()
	_make_ghost()

	for layer_v2 in layers:
		var layer2: Dictionary = layer_v2 as Dictionary
		if str(layer2.get("id", "")) == "fg":
			_add_layer_sprite(village_root, layer2)

	## --- 亂山坡（右）---
	_add_wilderness_zone(
		"luan_shan_po", "亂山坡", "hills",
		Vector2(80 + _design.x + 40, 60), Vector2(920, 560),
		["wolf", "boar", "bandit"], 5
	)
	## --- 毒沼（右下）---
	_add_wilderness_zone(
		"du_zhao", "毒沼", "mire",
		Vector2(80 + _design.x + 40, 60 + 560 + 40), Vector2(920, 520),
		["snake", "python", "bandit"], 4
	)
	## --- 哨站郊野（左下）---
	_add_wilderness_zone(
		"outpost_fringe", "哨站外圍", "outpost",
		Vector2(60, 80 + _design.y + 40), Vector2(980, 520),
		["bandit", "wolf"], 3
	)

	_actors_root = Node2D.new()
	_actors_root.name = "Actors"
	_actors_root.z_index = 12
	_world.add_child(_actors_root)

	_world_size = Vector2(80 + _design.x + 40 + 920 + 80, 80 + _design.y + 40 + 520 + 80)

	_hint_label = Label.new()
	_hint_label.name = "MapHint"
	_hint_label.text = "拖移地圖｜點建築互動｜走近／點怪物開戰"
	_hint_label.position = Vector2(8, 8)
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color(0.12, 0.09, 0.06, 0.9))
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint_label)

	_place_hint_label = Label.new()
	_place_hint_label.name = "PlaceHint"
	_place_hint_label.visible = false
	_place_hint_label.add_theme_color_override("font_color", Color(0.788, 0.635, 0.153, 1))
	_place_hint_label.add_theme_font_size_override("font_size", 14)
	_place_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_hint_label.position = Vector2(8, 28)
	add_child(_place_hint_label)

	_cam = Vector2(40, 40)
	_apply_camera()

func _add_wilderness_zone(zone_id: String, title: String, bg_key: String, origin: Vector2, sz: Vector2, kinds: Array, count: int) -> void:
	var root := Node2D.new()
	root.name = "Zone_%s" % zone_id
	root.position = origin
	_world.add_child(root)
	_zone_rects[zone_id] = Rect2(origin, sz)

	var bg_path: String = ArtPaths.zone_bg(bg_key)
	var tex: Texture2D = ArtPaths.load_tex(bg_path)
	var spr := Sprite2D.new()
	spr.centered = false
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 0
	if tex != null:
		spr.texture = tex
		var ts: Vector2 = tex.get_size()
		if ts.x > 1.0 and ts.y > 1.0:
			spr.scale = Vector2(sz.x / ts.x, sz.y / ts.y)
	else:
		var placeholder := ColorRect.new()
		placeholder.size = sz
		placeholder.color = Color(0.35, 0.42, 0.32, 1) if bg_key == "hills" else Color(0.28, 0.36, 0.3, 1)
		root.add_child(placeholder)
	root.add_child(spr)

	var dim := ColorRect.new()
	dim.size = sz
	dim.color = Color(0.05, 0.06, 0.04, 0.18)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var lab := Label.new()
	lab.text = title
	lab.position = Vector2(16, 12)
	lab.add_theme_font_size_override("font_size", 18)
	lab.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75, 1))
	lab.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.04, 0.9))
	lab.add_theme_constant_override("outline_size", 4)
	root.add_child(lab)

	var btn := Button.new()
	btn.text = "進入獵場"
	btn.position = Vector2(16, 44)
	btn.size = Vector2(120, 36)
	btn.pressed.connect(func() -> void:
		map_action.emit("select_zone", {"zone_id": zone_id})
		GameState.selected_zone = zone_id if zone_id != "outpost_fringe" else "luan_shan_po"
		GameState.push_report("已望向「%s」——拖近怪物或點佢開戰。" % title)
	)
	root.add_child(btn)

	## 預留怪物生成點（實際 spawn 喺 _spawn_actors）
	root.set_meta("kinds", kinds)
	root.set_meta("spawn_count", count)
	root.set_meta("zone_id", zone_id)
	root.set_meta("area", Rect2(Vector2(40, 80), sz - Vector2(80, 120)))

func _add_layer_sprite(parent: Node2D, layer: Dictionary) -> void:
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
	parent.add_child(spr)

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

func _spawn_actors() -> void:
	_sync_hero_actors()
	## monsters per wilderness zone root
	for child in _world.get_children():
		if not str(child.name).begins_with("Zone_"):
			continue
		if not child.has_meta("kinds"):
			continue
		var kinds: Array = child.get_meta("kinds") as Array
		var n: int = int(child.get_meta("spawn_count"))
		var area: Rect2 = child.get_meta("area") as Rect2
		var zid: String = str(child.get_meta("zone_id"))
		for i in range(n):
			var kind: String = str(kinds[_rng.randi() % kinds.size()])
			var local := Vector2(
				_rng.randf_range(area.position.x, area.position.x + area.size.x),
				_rng.randf_range(area.position.y, area.position.y + area.size.y)
			)
			_spawn_monster(kind, zid, child.position + local, 110.0)

func _sync_hero_actors() -> void:
	## rebuild heroes on map from GameState (ready ones wander village)
	for h in _heroes:
		var n: Node = h.get("node")
		if n and is_instance_valid(n):
			n.queue_free()
	_heroes.clear()
	if _actors_root == null:
		return
	var village_origin: Vector2 = _zone_rects.get("village", Rect2()).position
	var i := 0
	for h in GameState.heroes:
		var hd: Dictionary = h as Dictionary
		var hid: String = str(hd.get("id", ""))
		var status: String = str(hd.get("status", "ready"))
		if status != "idle" and status != "ready":
			## still show but dimmer near inn
			pass
		var frames: SpriteFrames = ArtPaths.make_hero_frames(hid)
		var spr := AnimatedSprite2D.new()
		spr.sprite_frames = frames
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = true
		var px: int = ArtPaths.hero_frame_px(hid)
		var target_px := 52.0
		if px > 0:
			spr.scale = Vector2.ONE * (target_px / float(px))
		spr.position = village_origin + Vector2(220 + i * 70, 360 + (i % 2) * 30)
		spr.z_index = 12
		if frames.has_animation("idle"):
			spr.play("idle")
		_actors_root.add_child(spr)
		## clickable
		var area := Area2D.new()
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(48, 64)
		cs.shape = shape
		area.add_child(cs)
		area.input_pickable = true
		spr.add_child(area)
		_heroes.append({
			"node": spr,
			"id": hid,
			"target": spr.position,
			"speed": _rng.randf_range(28.0, 46.0),
			"zone": "village",
			"wait": _rng.randf_range(0.2, 1.5),
		})
		i += 1
		if i >= 8:
			break

func _spawn_monster(kind: String, zone_id: String, world_pos: Vector2, roam_r: float) -> void:
	var spr := Sprite2D.new()
	spr.centered = true
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex: Texture2D = ArtPaths.load_tex(ArtPaths.monster_idle(kind))
	if tex != null:
		## sheet: take first frame approx
		var h: int = tex.get_height()
		var fw: int = h
		if tex.get_width() >= fw:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(0, 0, fw, h)
			spr.texture = at
		else:
			spr.texture = tex
		spr.scale = Vector2.ONE * ArtPaths.monster_display_scale(kind, 56.0, 1.0)
	spr.position = world_pos
	spr.z_index = 11
	_actors_root.add_child(spr)

	var btn := TextureButton.new()
	btn.ignore_texture_size = true
	btn.custom_minimum_size = Vector2(56, 56)
	btn.size = Vector2(56, 56)
	btn.position = Vector2(-28, -28)
	btn.modulate = Color(1, 1, 1, 0.01)
	btn.pressed.connect(_on_monster_pressed.bind(kind, zone_id, spr))
	spr.add_child(btn)

	_monsters.append({
		"node": spr,
		"kind": kind,
		"zone": zone_id,
		"origin": world_pos,
		"roam_r": roam_r,
		"speed": _rng.randf_range(18.0, 34.0),
		"target": world_pos,
		"wait": _rng.randf_range(0.0, 2.0),
		"cd": 0.0,
	})

func _tick_heroes(delta: float) -> void:
	var village: Rect2 = _zone_rects.get("village", Rect2(80, 80, 960, 540))
	var walkable := Rect2(village.position + Vector2(120, 200), village.size - Vector2(220, 260))
	for h in _heroes:
		var spr: AnimatedSprite2D = h.get("node") as AnimatedSprite2D
		if spr == null or not is_instance_valid(spr):
			continue
		h["wait"] = float(h.get("wait", 0.0)) - delta
		if float(h["wait"]) <= 0.0:
			h["target"] = Vector2(
				_rng.randf_range(walkable.position.x, walkable.position.x + walkable.size.x),
				_rng.randf_range(walkable.position.y, walkable.position.y + walkable.size.y)
			)
			h["wait"] = _rng.randf_range(1.8, 4.5)
			if spr.sprite_frames and spr.sprite_frames.has_animation("walk"):
				spr.play("walk")
		var tgt: Vector2 = h.get("target") as Vector2
		var pos: Vector2 = spr.position
		var dist: float = pos.distance_to(tgt)
		if dist < 4.0:
			if spr.sprite_frames and spr.sprite_frames.has_animation("idle"):
				spr.play("idle")
			continue
		var step: float = float(h.get("speed", 36.0)) * delta
		spr.position = pos.move_toward(tgt, step)
		spr.flip_h = tgt.x < pos.x

func _tick_monsters(delta: float) -> void:
	for m in _monsters:
		var spr: Sprite2D = m.get("node") as Sprite2D
		if spr == null or not is_instance_valid(spr):
			continue
		m["cd"] = maxf(0.0, float(m.get("cd", 0.0)) - delta)
		m["wait"] = float(m.get("wait", 0.0)) - delta
		if float(m["wait"]) <= 0.0:
			var origin: Vector2 = m.get("origin") as Vector2
			var rr: float = float(m.get("roam_r", 80.0))
			m["target"] = origin + Vector2(_rng.randf_range(-rr, rr), _rng.randf_range(-rr, rr))
			m["wait"] = _rng.randf_range(1.2, 3.5)
		var tgt: Vector2 = m.get("target") as Vector2
		spr.position = spr.position.move_toward(tgt, float(m.get("speed", 24.0)) * delta)
		## proximity encounter vs any hero
		if _encounter_busy or float(m["cd"]) > 0.0:
			continue
		for h in _heroes:
			var hs: Node2D = h.get("node") as Node2D
			if hs == null or not is_instance_valid(hs):
				continue
			if spr.position.distance_to(hs.position) < 42.0:
				m["cd"] = 8.0
				_request_encounter(str(m.get("kind")), str(m.get("zone")), spr)
				break

func _on_monster_pressed(kind: String, zone_id: String, spr: Node2D) -> void:
	if _encounter_busy:
		return
	_request_encounter(kind, zone_id, spr)

func _request_encounter(kind: String, zone_id: String, spr: Node2D) -> void:
	if _encounter_busy:
		return
	_encounter_busy = true
	var zid: String = zone_id if zone_id != "outpost_fringe" else "luan_shan_po"
	var party: Array = []
	for h in GameState.heroes:
		var hd: Dictionary = h as Dictionary
		if str(hd.get("status", "idle")) in ["idle", "ready", ""]:
			party.append(hd.duplicate(true))
		if party.size() >= 3:
			break
	if party.is_empty() and GameState.heroes.size() > 0:
		party.append((GameState.heroes[0] as Dictionary).duplicate(true))
	var enemies: Array = [{"kind": kind, "name": _monster_name(kind), "weight": 1}]
	## sometimes +1 buddy
	if _rng.randf() < 0.45:
		enemies.append({"kind": kind, "name": _monster_name(kind), "weight": 1})
	var payload := {
		"zone_id": zid,
		"zone_name": _zone_title(zid),
		"heroes": party,
		"enemies": enemies,
		"kind": kind,
		"marker": spr,
	}
	encounter_requested.emit(payload)
	## auto clear busy after a beat if main doesn't; main should call notify_encounter_done
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		## keep busy until notify; soft unlock after 30s safety
		pass
	)
	get_tree().create_timer(30.0).timeout.connect(func() -> void:
		_encounter_busy = false
	)

func notify_encounter_done(success: bool = true, marker: Node = null) -> void:
	_encounter_busy = false
	if marker != null and is_instance_valid(marker):
		## remove defeated monster marker
		for i in range(_monsters.size() - 1, -1, -1):
			var m: Dictionary = _monsters[i]
			if m.get("node") == marker:
				marker.queue_free()
				_monsters.remove_at(i)
				break
	if success:
		## soft respawn later
		get_tree().create_timer(12.0).timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			## respawn a wolf on hills if sparse
			var hills: Rect2 = _zone_rects.get("luan_shan_po", Rect2())
			if hills.size.x > 0.0 and _monsters.size() < 10:
				_spawn_monster("wolf", "luan_shan_po", hills.position + hills.size * 0.5 + Vector2(_rng.randf_range(-80, 80), _rng.randf_range(-40, 40)), 100.0)
		)

func _monster_name(kind: String) -> String:
	match kind:
		"wolf":
			return "野狼"
		"boar":
			return "野豬"
		"bandit":
			return "山賊"
		"snake":
			return "毒蛇"
		"python":
			return "巨蟒"
		_:
			return kind

func _zone_title(zid: String) -> String:
	var z: Dictionary = GameState.get_zone(zid)
	if not z.is_empty():
		return str(z.get("name", zid))
	return zid

func _apply_camera() -> void:
	if _world == null:
		return
	_world.scale = Vector2(WORLD_SCALE, WORLD_SCALE)
	_clamp_cam()
	_world.position = -_cam * WORLD_SCALE

func _clamp_cam() -> void:
	var view: Vector2 = size
	if view.x < 1.0:
		view = Vector2(640, 360)
	var max_x: float = maxf(0.0, _world_size.x - view.x / WORLD_SCALE + PAN_MARGIN)
	var max_y: float = maxf(0.0, _world_size.y - view.y / WORLD_SCALE + PAN_MARGIN)
	_cam.x = clampf(_cam.x, -PAN_MARGIN, max_x)
	_cam.y = clampf(_cam.y, -PAN_MARGIN, max_y)

func pan_to_zone(zone_id: String) -> void:
	var r: Rect2 = _zone_rects.get(zone_id, Rect2()) as Rect2
	if r.size == Vector2.ZERO:
		return
	_cam = r.position - Vector2(40, 40)
	_apply_camera()

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
		var keep_cam := _cam
		_build_world()
		_cam = keep_cam
		_apply_camera()
		call_deferred("_spawn_actors")
	for bid in _building_sprites.keys():
		var btn: TextureButton = _building_sprites[bid] as TextureButton
		if btn == null:
			continue
		var lv: int = BuildingSystem.building_level(str(bid))
		var unlocked: bool = false
		if GameState.buildings.has(bid):
			unlocked = bool((GameState.buildings[bid] as Dictionary).get("unlocked", false)) or lv > 0
		btn.modulate = Color(1, 1, 1, 1) if unlocked else Color(1, 1, 1, 0.35)
		btn.tooltip_text = "%s Lv.%d（點擊互動／拖移改位）" % [BuildingSystem.building_name(str(bid)), lv]

func _make_pad_hint() -> void:
	_pad_hint = Polygon2D.new()
	_pad_hint.name = "PadHint"
	_pad_hint.color = Color(0.165, 0.416, 0.416, 0.18)
	var r := BUILDABLE
	_pad_hint.polygon = PackedVector2Array([
		r.position, r.position + Vector2(r.size.x, 0), r.position + r.size, r.position + Vector2(0, r.size.y),
	])
	_pad_hint.visible = false
	_overlay_root.add_child(_pad_hint)

func _make_ghost() -> void:
	_ghost = Sprite2D.new()
	_ghost.name = "Ghost"
	_ghost.centered = true
	_ghost.modulate = Color(1, 1, 1, 0.55)
	_ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ghost.z_index = 9
	_ghost.visible = false
	_overlay_root.add_child(_ghost)

func _design_from_local(local: Vector2) -> Vector2:
	## convert control-local → village design coords
	if _world == null:
		return local
	var world_pt: Vector2 = (local - _world.position) / WORLD_SCALE
	var village_origin: Vector2 = _zone_rects.get("village", Rect2()).position
	return world_pt - village_origin

func begin_place(building_id: String) -> void:
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
		_place_hint_label.text = "放置「%s」：點村莊可建區｜右鍵／Esc 取消" % BuildingSystem.building_name(building_id)
	pan_to_zone("village")
	GameState.push_report("放置模式：點村莊可建區放「%s」" % BuildingSystem.building_name(building_id))

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
	if not BUILDABLE.has_point(pos):
		return {"ok": false, "reason": "出咗可建區"}
	var check_id: String = ignore_id if ignore_id != "" else place_building_id
	for bid in _building_sprites.keys():
		var other: String = str(bid)
		if other == check_id:
			continue
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
	_ghost.modulate = Color(0.45, 0.85, 0.55, 0.65) if bool(chk.get("ok", false)) else Color(0.9, 0.35, 0.3, 0.65)

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
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if place_building_id != "":
					var design_pos: Vector2 = _design_from_local(mb.position)
					_try_place_at(design_pos)
					accept_event()
					return
				_panning = true
				_pan_moved = false
				_pan_last = mb.position
				accept_event()
			else:
				_panning = false
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging_id != "":
			_drag_moved = true
			var design_pos2: Vector2 = _design_from_local(mm.position) - _drag_grab
			design_pos2 = _clamp_design(design_pos2)
			GameState.set_building_pos(_dragging_id, design_pos2)
			accept_event()
			return
		if _panning and place_building_id == "":
			var delta: Vector2 = mm.position - _pan_last
			if delta.length() > 2.0:
				_pan_moved = true
			_pan_last = mm.position
			_cam -= delta / WORLD_SCALE
			_apply_camera()
			accept_event()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_panning = true
			_pan_moved = false
			_pan_last = st.position
		else:
			_panning = false
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if place_building_id == "" and _dragging_id == "":
			_pan_moved = true
			_cam -= sd.relative / WORLD_SCALE
			_apply_camera()
			accept_event()

func _on_building_button_down(bid: String) -> void:
	if place_building_id != "":
		return
	_dragging_id = bid
	_drag_moved = false
	_panning = false
	var design_mouse: Vector2 = _design_from_local(get_local_mouse_position())
	_drag_grab = design_mouse - GameState.get_building_pos(bid)

func _on_building_pressed(bid: String) -> void:
	var was_drag: bool = _drag_moved
	if _dragging_id == bid:
		_dragging_id = ""
	if place_building_id != "":
		_try_place_at(GameState.get_building_pos(bid))
		return
	if was_drag:
		var pos2: Vector2 = GameState.get_building_pos(bid)
		var chk: Dictionary = can_place_at(pos2, bid)
		if not bool(chk.get("ok", false)):
			GameState.set_building_pos(bid, _find_nearby_free(pos2, bid))
		return
	if _pan_moved:
		return
	building_clicked.emit(bid)

func _find_nearby_free(from: Vector2, ignore_id: String) -> Vector2:
	var offsets: Array = [
		Vector2.ZERO, Vector2(110, 0), Vector2(-110, 0), Vector2(0, 110), Vector2(0, -110),
		Vector2(110, 110), Vector2(-110, 110), Vector2(110, -110), Vector2(-110, -110),
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
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if _dragging_id != "":
				var bid: String = _dragging_id
				_dragging_id = ""
				if _drag_moved:
					var pos2: Vector2 = GameState.get_building_pos(bid)
					if not bool(can_place_at(pos2, bid).get("ok", false)):
						GameState.set_building_pos(bid, _find_nearby_free(pos2, bid))
