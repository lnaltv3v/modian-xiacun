extends Control
## 短即時自動戰鬥：雙方靠近 → 攻擊幀循環 3–8 秒 → 結算摘要＋飄字

const _DamageFloater := preload("res://scripts/ui/DamageFloater.gd")

signal finished(summary: Dictionary)

@onready var title_label: Label = %TitleLabel
@onready var phase_label: Label = %PhaseLabel
@onready var arena: Control = %Arena
@onready var heroes_layer: Control = %HeroesLayer
@onready var enemies_layer: Control = %EnemiesLayer
@onready var summary_panel: Control = %SummaryPanel
@onready var summary_label: Label = %SummaryLabel
@onready var btn_ok: Button = %BtnOk

var _cfg: Dictionary = {}
var _summary: Dictionary = {}
var _playing: bool = false
var _hero_nodes: Array = []
var _enemy_nodes: Array = []
var _atk_timer: float = 0.0
var _atk_flip: bool = false
var _phase: String = "idle"  ## approach | fight | done
var _fight_left: float = 0.0
var _rng := RandomNumberGenerator.new()
var _bg_tex: TextureRect
var _bg_dim: ColorRect
var _bg_layers: Dictionary = {}  ## sky/mid/ground/props TextureRect
var _float_layer: Control
var _hit_tick: int = 0
var _arena_origin: Vector2 = Vector2.ZERO
var _shaking: bool = false
var _zone_key: String = "hills"

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	if summary_panel:
		summary_panel.visible = false
	if btn_ok:
		btn_ok.pressed.connect(_on_ok)
		btn_ok.visible = false
	_ensure_bg()

## config:
##  title, heroes: [hero_id], enemies: [{kind,name,scale?}],
##  success: bool, duration: float (clamp 3–8),
##  summary: Dictionary (loot text fields), show_summary: bool = true
func play(config: Dictionary) -> void:
	_cfg = config.duplicate(true)
	_summary = (_cfg.get("summary", {}) as Dictionary).duplicate(true)
	_playing = true
	_phase = "entrance"
	_atk_flip = false
	_atk_timer = 0.0
	_rng.randomize()
	var dur: float = float(_cfg.get("duration", _rng.randf_range(3.5, 6.5)))
	_fight_left = clampf(dur, 3.0, 8.0)
	visible = true
	move_to_front()
	_apply_zone_bg()
	_ensure_float_layer()
	_hit_tick = 0
	_clear_floaters()
	if summary_panel:
		summary_panel.visible = false
	if btn_ok:
		btn_ok.visible = false
	if title_label:
		title_label.text = str(_cfg.get("title", "交戰"))
	if phase_label:
		phase_label.text = "入場…"
	_clear_layers()
	_spawn_sides()
	set_process(true)
	## 入場淡入 → 逼近（不拖慢主戰鬥循環）
	_tween_entrance()

func _clear_layers() -> void:
	_hero_nodes.clear()
	_enemy_nodes.clear()
	if heroes_layer:
		for c in heroes_layer.get_children():
			c.queue_free()
	if enemies_layer:
		for c in enemies_layer.get_children():
			c.queue_free()

func _spawn_sides() -> void:
	var hero_ids: Array = _cfg.get("heroes", []) as Array
	var enemies: Array = _cfg.get("enemies", []) as Array
	if enemies.is_empty():
		enemies = [{"kind": "wolf", "name": "野狼"}]
	var arena_w: float = 640.0
	var arena_h: float = 220.0
	if arena:
		arena_w = maxf(320.0, arena.size.x)
		arena_h = maxf(160.0, arena.size.y)
	var left_x: float = 48.0
	var right_x: float = arena_w - 48.0
	var mid_y: float = arena_h * 0.55

	var hi: int = 0
	for hid_v in hero_ids:
		var hid: String = str(hid_v)
		var spr := AnimatedSprite2D.new()
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = true
		var idle_ok: bool = ArtPaths.exists(ArtPaths.hero_idle(hid))
		if idle_ok:
			spr.sprite_frames = ArtPaths.make_hero_frames(hid)
			if spr.sprite_frames.has_animation("walk"):
				spr.play("walk")
			elif spr.sprite_frames.has_animation("idle"):
				spr.play("idle")
		else:
			## 無圖：用單色方塊代理（橙／紫未出圖時）
			var frames := SpriteFrames.new()
			frames.remove_animation("default")
			frames.add_animation("idle")
			frames.set_animation_loop("idle", true)
			var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
			var hero: Dictionary = HeroSystem.get_hero(hid)
			var rarity: String = str(hero.get("rarity", "紫"))
			var col := Color(0.85, 0.45, 0.15) if rarity == "橙" else (Color(0.75, 0.15, 0.12) if rarity == "紅" else Color(0.45, 0.28, 0.65))
			img.fill(col)
			var tex := ImageTexture.create_from_image(img)
			frames.add_frame("idle", tex)
			frames.add_animation("walk")
			frames.set_animation_loop("walk", true)
			frames.add_frame("walk", tex)
			spr.sprite_frames = frames
			spr.play("walk")
		var ds: float = ArtPaths.display_scale_for(hid, 88.0) if idle_ok else (88.0 / 32.0)
		spr.scale = Vector2(ds, ds)
		spr.position = Vector2(left_x - 80.0, mid_y + float(hi) * 36.0 - float(hero_ids.size() - 1) * 18.0)
		spr.set_meta("home", Vector2(left_x + 40.0 + float(hi) * 22.0, mid_y + float(hi) * 36.0 - float(hero_ids.size() - 1) * 18.0))
		spr.set_meta("hero_id", hid)
		spr.set_meta("side", "hero")
		heroes_layer.add_child(spr)
		_hero_nodes.append(spr)
		hi += 1
		if hi >= 5:
			break

	var ei: int = 0
	for ev in enemies:
		var ed: Dictionary = ev as Dictionary
		var kind: String = str(ed.get("kind", "wolf"))
		var scale_m: float = float(ed.get("scale", 1.0))
		var duel_hid: String = str(ed.get("hero_id", "")).strip_edges()
		var home_y: float = mid_y + float(ei) * 32.0 - float(mini(enemies.size(), 4) - 1) * 16.0
		if duel_hid != "":
			## 比武台：對手用俠客精靈（右方、面向左）
			var sprh := AnimatedSprite2D.new()
			sprh.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprh.centered = true
			var idle_ok2: bool = ArtPaths.exists(ArtPaths.hero_idle(duel_hid))
			if idle_ok2:
				sprh.sprite_frames = ArtPaths.make_hero_frames(duel_hid)
				if sprh.sprite_frames.has_animation("walk"):
					sprh.play("walk")
				elif sprh.sprite_frames.has_animation("idle"):
					sprh.play("idle")
			else:
				var frames2 := SpriteFrames.new()
				frames2.remove_animation("default")
				frames2.add_animation("idle")
				frames2.set_animation_loop("idle", true)
				var img2 := Image.create(32, 32, false, Image.FORMAT_RGBA8)
				img2.fill(Color(0.55, 0.22, 0.18))
				var tex2 := ImageTexture.create_from_image(img2)
				frames2.add_frame("idle", tex2)
				frames2.add_animation("walk")
				frames2.set_animation_loop("walk", true)
				frames2.add_frame("walk", tex2)
				sprh.sprite_frames = frames2
				sprh.play("walk")
			var ds2: float = ArtPaths.display_scale_for(duel_hid, 88.0) if idle_ok2 else (88.0 / 32.0)
			sprh.scale = Vector2(ds2, ds2)
			sprh.flip_h = true
			sprh.position = Vector2(right_x + 80.0, home_y)
			sprh.set_meta("home", Vector2(right_x - 40.0 - float(ei) * 18.0, home_y))
			sprh.set_meta("kind", kind)
			sprh.set_meta("hero_id", duel_hid)
			sprh.set_meta("side", "enemy")
			sprh.set_meta("duelist", true)
			enemies_layer.add_child(sprh)
			_enemy_nodes.append(sprh)
		else:
			var spr2 := Sprite2D.new()
			spr2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			spr2.centered = true
			var idle: Texture2D = ArtPaths.load_tex(ArtPaths.monster_idle(kind))
			var atk: Texture2D = ArtPaths.load_tex(ArtPaths.monster_attack(kind))
			spr2.texture = idle if idle != null else atk
			var mds: float = ArtPaths.monster_display_scale(kind, 88.0, scale_m)
			spr2.scale = Vector2(mds, mds)
			## 面向左（對俠）
			spr2.flip_h = true
			spr2.position = Vector2(right_x + 80.0, home_y)
			spr2.set_meta("home", Vector2(right_x - 40.0 - float(ei) * 18.0, home_y))
			spr2.set_meta("kind", kind)
			spr2.set_meta("idle_tex", idle)
			spr2.set_meta("atk_tex", atk)
			spr2.set_meta("side", "enemy")
			spr2.set_meta("duelist", false)
			enemies_layer.add_child(spr2)
			_enemy_nodes.append(spr2)
		ei += 1
		if ei >= 4:
			break
	## 入場前全透明（由 _tween_entrance 淡入）
	for n_all in _hero_nodes + _enemy_nodes:
		var nd: CanvasItem = n_all as CanvasItem
		if nd:
			var m: Color = nd.modulate
			m.a = 0.0
			nd.modulate = m
			nd.set_meta("base_scale", (n_all as Node2D).scale if n_all is Node2D else Vector2.ONE)

func _tween_entrance() -> void:
	_phase = "entrance"
	if phase_label:
		phase_label.text = "入場…"
	## 短 pose：優先 idle，淡入＋輕彈縮放
	for n in _hero_nodes:
		var spr: AnimatedSprite2D = n as AnimatedSprite2D
		if spr and spr.sprite_frames and spr.sprite_frames.has_animation("idle"):
			spr.play("idle")
			spr.speed_scale = 1.0
	for n_e in _enemy_nodes:
		if not bool(n_e.get_meta("duelist", false)):
			continue
		var spr_e: AnimatedSprite2D = n_e as AnimatedSprite2D
		if spr_e and spr_e.sprite_frames and spr_e.sprite_frames.has_animation("idle"):
			spr_e.play("idle")
			spr_e.speed_scale = 1.0
	var tw := create_tween()
	tw.set_parallel(true)
	for n2 in _hero_nodes + _enemy_nodes:
		var node: Node2D = n2 as Node2D
		if node == null:
			continue
		var base_s: Vector2 = node.get_meta("base_scale", node.scale) as Vector2
		node.scale = base_s * 0.92
		tw.tween_property(node, "modulate:a", 1.0, 0.26).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", base_s, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(_after_entrance)

func _after_entrance() -> void:
	if not _playing:
		return
	## 轉 walk 再逼近
	for n in _hero_nodes:
		var spr: AnimatedSprite2D = n as AnimatedSprite2D
		if spr and spr.sprite_frames and spr.sprite_frames.has_animation("walk"):
			spr.play("walk")
	for n_e in _enemy_nodes:
		if not bool(n_e.get_meta("duelist", false)):
			continue
		var spr_e: AnimatedSprite2D = n_e as AnimatedSprite2D
		if spr_e and spr_e.sprite_frames and spr_e.sprite_frames.has_animation("walk"):
			spr_e.play("walk")
	if phase_label:
		phase_label.text = "逼近…"
	_tween_approach()

func _tween_approach() -> void:
	_phase = "approach"
	var tw := create_tween()
	tw.set_parallel(true)
	for n in _hero_nodes:
		var spr: Node2D = n as Node2D
		var home: Vector2 = spr.get_meta("home") as Vector2
		tw.tween_property(spr, "position", home, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for n2 in _enemy_nodes:
		var spr2: Node2D = n2 as Node2D
		var home2: Vector2 = spr2.get_meta("home") as Vector2
		tw.tween_property(spr2, "position", home2, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(_begin_fight)

func _begin_fight() -> void:
	if not _playing:
		return
	_phase = "fight"
	if phase_label:
		var mode: String = str(_cfg.get("battle_mode", ""))
		phase_label.text = "切磋中…" if mode == "arena" else "交鋒中…"
	## heroes: prefer attack sheet；無則 walk；pulse scale
	for n in _hero_nodes:
		var spr: AnimatedSprite2D = n as AnimatedSprite2D
		if spr and spr.sprite_frames:
			if spr.sprite_frames.has_animation("attack") and spr.sprite_frames.get_frame_count("attack") > 0:
				spr.play("attack")
				spr.speed_scale = 1.15
			elif spr.sprite_frames.has_animation("walk"):
				spr.play("walk")
				spr.speed_scale = 1.35
	for n_e in _enemy_nodes:
		if not bool(n_e.get_meta("duelist", false)):
			continue
		var spr_e: AnimatedSprite2D = n_e as AnimatedSprite2D
		if spr_e and spr_e.sprite_frames:
			if spr_e.sprite_frames.has_animation("attack") and spr_e.sprite_frames.get_frame_count("attack") > 0:
				spr_e.play("attack")
				spr_e.speed_scale = 1.15
			elif spr_e.sprite_frames.has_animation("walk"):
				spr_e.play("walk")
				spr_e.speed_scale = 1.35

func _process(delta: float) -> void:
	if not _playing or _phase != "fight":
		return
	_fight_left -= delta
	_atk_timer += delta
	if _atk_timer >= 0.28:
		_atk_timer = 0.0
		_atk_flip = not _atk_flip
		_pulse_frames()
	if phase_label:
		phase_label.text = "交鋒中… %.1fs" % maxf(0.0, _fight_left)
	if _fight_left <= 0.0:
		_end_fight()

func _pulse_frames() -> void:
	for n in _enemy_nodes:
		if bool(n.get_meta("duelist", false)):
			var spr_d: Node2D = n as Node2D
			if spr_d:
				spr_d.position.x += -3.0 if _atk_flip else 3.0
			continue
		var spr: Sprite2D = n as Sprite2D
		if spr == null:
			continue
		var idle: Texture2D = spr.get_meta("idle_tex") as Texture2D
		var atk: Texture2D = spr.get_meta("atk_tex") as Texture2D
		if _atk_flip:
			spr.texture = atk if atk != null else idle
			spr.position.x -= 4.0
		else:
			spr.texture = idle if idle != null else atk
			spr.position.x += 4.0
	for n2 in _hero_nodes:
		var spr2: AnimatedSprite2D = n2 as AnimatedSprite2D
		if spr2 == null:
			continue
		## 輕微前後晃
		spr2.position.x += 3.0 if _atk_flip else -3.0
	_spawn_hit_floaters()

func _end_fight() -> void:
	_phase = "done"
	set_process(false)
	var success: bool = bool(_cfg.get("success", true))
	if phase_label:
		var mode2: String = str(_cfg.get("battle_mode", ""))
		if mode2 == "arena":
			phase_label.text = "挑戰方勝！" if success else "對手勝！"
		else:
			phase_label.text = "得勝！" if success else "失利…"
	## 勝：敵退後淡出；敗：俠退後
	var tw := create_tween()
	tw.set_parallel(true)
	if success:
		for n in _enemy_nodes:
			var spr: Node2D = n as Node2D
			tw.tween_property(spr, "modulate:a", 0.15, 0.45)
			tw.tween_property(spr, "position:x", spr.position.x + 60.0, 0.45)
		for n2 in _hero_nodes:
			var spr2: AnimatedSprite2D = n2 as AnimatedSprite2D
			if spr2 and spr2.sprite_frames and spr2.sprite_frames.has_animation("idle"):
				spr2.play("idle")
				spr2.speed_scale = 1.0
		for n_de in _enemy_nodes:
			if not bool(n_de.get_meta("duelist", false)):
				continue
			var spr_de: AnimatedSprite2D = n_de as AnimatedSprite2D
			if spr_de and spr_de.sprite_frames and spr_de.sprite_frames.has_animation("idle"):
				spr_de.play("idle")
				spr_de.speed_scale = 1.0
	else:
		for n3 in _hero_nodes:
			var spr3: Node2D = n3 as Node2D
			tw.tween_property(spr3, "modulate:a", 0.25, 0.45)
			tw.tween_property(spr3, "position:x", spr3.position.x - 50.0, 0.45)
	tw.chain().tween_callback(_after_outro)

func _after_outro() -> void:
	var show_sum: bool = bool(_cfg.get("show_summary", true))
	if show_sum and not _summary.is_empty():
		_show_summary()
	else:
		_finish()

func _show_summary() -> void:
	var mode3: String = str(_cfg.get("battle_mode", ""))
	var tall: bool = mode3 in ["dungeon", "outpost"] or _summary.has("waves")
	if summary_panel:
		summary_panel.visible = true
		if tall:
			summary_panel.offset_top = 300.0
			summary_panel.offset_bottom = 560.0
		else:
			summary_panel.offset_top = 430.0
			summary_panel.offset_bottom = 540.0
	if summary_label:
		if tall:
			summary_label.offset_top = 308.0
			summary_label.offset_bottom = 548.0
			summary_label.add_theme_font_size_override("font_size", 13)
		else:
			summary_label.offset_top = 440.0
			summary_label.offset_bottom = 530.0
			summary_label.add_theme_font_size_override("font_size", 14)
		summary_label.text = _format_summary(_summary)
	if btn_ok:
		btn_ok.visible = true
		btn_ok.text = "完場" if mode3 == "arena" else "收下戰利品"
	if phase_label:
		if tall:
			var wc: int = int(_summary.get("waves_cleared", 0))
			var wt: int = int(_summary.get("total_waves", (_summary.get("waves", []) as Array).size()))
			phase_label.text = "結算 · 波次 %d／%d" % [wc, maxi(wt, 1)]
		else:
			phase_label.text = "結算"

func _format_summary(s: Dictionary) -> String:
	var mode: String = str(_cfg.get("battle_mode", s.get("run_mode", "")))
	if mode in ["dungeon", "outpost"] or s.has("waves"):
		var pack: Dictionary = s.duplicate(true)
		if not pack.has("run_mode"):
			pack["run_mode"] = mode
		if not pack.has("battle_mode"):
			pack["battle_mode"] = mode
		return LootText.format_run_result(pack)
	return LootText.format_summary(s)

func _on_ok() -> void:
	_finish()

func _finish() -> void:
	_playing = false
	visible = false
	_clear_floaters()
	if summary_panel:
		summary_panel.visible = false
	if btn_ok:
		btn_ok.visible = false
	_clear_layers()
	finished.emit(_summary)


func _ensure_bg() -> void:
	if arena == null:
		return
	if _bg_tex != null and is_instance_valid(_bg_tex):
		return
	## 隱藏純色底，改用野外分層／合成圖
	var old_bg := arena.get_node_or_null("ArenaBg")
	if old_bg:
		old_bg.visible = false
	var z_base: int = -6
	for layer_name in ["sky", "mid", "ground", "props"]:
		var tr := TextureRect.new()
		tr.name = "ArenaBg_" + layer_name
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.z_index = z_base
		tr.visible = false
		arena.add_child(tr)
		arena.move_child(tr, 0)
		_bg_layers[layer_name] = tr
		z_base += 1
	_bg_tex = TextureRect.new()
	_bg_tex.name = "ArenaBgTex"
	_bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_tex.z_index = -2
	arena.add_child(_bg_tex)
	arena.move_child(_bg_tex, 0)
	_bg_dim = ColorRect.new()
	_bg_dim.name = "ArenaBgDim"
	_bg_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_dim.color = Color(0.06, 0.05, 0.04, 0.22)
	_bg_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_dim.z_index = -1
	arena.add_child(_bg_dim)
	arena.move_child(_bg_dim, mini(arena.get_child_count() - 1, 5))
	_arena_origin = arena.position

func _apply_zone_bg() -> void:
	_ensure_bg()
	if _bg_tex == null:
		return
	var key: String = str(_cfg.get("zone_bg", "")).strip_edges()
	if key == "":
		key = ArtPaths.zone_bg_key_for(
			str(_cfg.get("zone_id", "")),
			str(_cfg.get("battle_mode", ""))
		)
	_zone_key = key
	var layered: int = 0
	for layer_name in ["sky", "mid", "ground", "props"]:
		var tr: TextureRect = _bg_layers.get(layer_name) as TextureRect
		if tr == null or not is_instance_valid(tr):
			continue
		var lp: String = ArtPaths.zone_bg_layer(key, layer_name)
		var ltex: Texture2D = ArtPaths.load_tex(lp)
		if ltex != null:
			tr.texture = ltex
			tr.visible = true
			## 輕微分層：用 offset 拉開 sky／mid／ground／props 景深
			tr.offset_left = 0.0
			tr.offset_right = 0.0
			match layer_name:
				"sky":
					tr.offset_top = -10.0
					tr.offset_bottom = -4.0
					tr.modulate = Color(1, 1, 1, 1)
				"mid":
					tr.offset_top = -2.0
					tr.offset_bottom = 2.0
					tr.modulate = Color(1, 1, 1, 0.98)
				"ground":
					tr.offset_top = 6.0
					tr.offset_bottom = 10.0
					tr.modulate = Color(1, 1, 1, 1)
				"props":
					tr.offset_top = 10.0
					tr.offset_bottom = 14.0
					tr.modulate = Color(1, 1, 1, 1)
			layered += 1
		else:
			tr.visible = false
			tr.texture = null
	var path: String = ArtPaths.zone_bg(key)
	var tex: Texture2D = ArtPaths.load_tex(path)
	if layered >= 2:
		## 有分層就隱藏合成圖，避免糊叠
		_bg_tex.visible = false
	elif tex != null:
		_bg_tex.texture = tex
		_bg_tex.visible = true
	else:
		_bg_tex.visible = false

func is_busy() -> bool:
	return _playing and visible

func _ensure_float_layer() -> void:
	if arena == null:
		return
	if _float_layer != null and is_instance_valid(_float_layer):
		return
	_float_layer = Control.new()
	_float_layer.name = "FloatLayer"
	_float_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_float_layer.z_index = 30
	arena.add_child(_float_layer)

func _clear_floaters() -> void:
	if _float_layer == null or not is_instance_valid(_float_layer):
		return
	for c in _float_layer.get_children():
		c.queue_free()

func _spawn_hit_floaters() -> void:
	_ensure_float_layer()
	if _float_layer == null:
		return
	_hit_tick += 1
	## 每隔一拍左右各噴一兩個飄字；偶發招架取代受傷
	var spawn_hero: bool = (_hit_tick % 2) == 0
	var spawn_enemy: bool = (_hit_tick % 2) == 1 or str(_cfg.get("battle_mode", "")) == "arena"
	if spawn_hero and not _hero_nodes.is_empty():
		var hn: Node2D = _hero_nodes[_rng.randi_range(0, _hero_nodes.size() - 1)] as Node2D
		if hn:
			var do_parry: bool = _rng.randf() < 0.20
			if do_parry:
				var flp = _DamageFloater.new()
				_float_layer.add_child(flp)
				flp.setup(0, hn.position + Vector2(_rng.randf_range(-10, 10), -34), "parry")
				_fx_parry(hn)
			else:
				var amt: int = _rng.randi_range(6, 28)
				var kind: String = "crit" if _rng.randf() < 0.12 else "hit"
				var fl = _DamageFloater.new()
				_float_layer.add_child(fl)
				fl.setup(amt, hn.position + Vector2(_rng.randf_range(-12, 12), -30), kind)
				_fx_hurt(hn, true, kind == "crit")
	if spawn_enemy and not _enemy_nodes.is_empty():
		var en: Node2D = _enemy_nodes[_rng.randi_range(0, _enemy_nodes.size() - 1)] as Node2D
		if en:
			var amt2: int = _rng.randi_range(5, 24)
			var fl2 = _DamageFloater.new()
			_float_layer.add_child(fl2)
			fl2.setup(amt2, en.position + Vector2(_rng.randf_range(-12, 12), -28), "enemy")
			_fx_hurt(en, false, _rng.randf() < 0.10)

func _fx_hurt(node: Node2D, hit_from_right: bool, heavy: bool = false) -> void:
	##  procedural 受傷閃紅／微擊退（無專用 hurt 幀時）
	if node == null or not is_instance_valid(node):
		return
	var base_a: float = 1.0
	var flash := Color(1.45, 0.42, 0.38, base_a) if heavy else Color(1.28, 0.55, 0.48, base_a)
	node.modulate = flash
	var knock: float = (6.0 if heavy else 4.0) * (-1.0 if hit_from_right else 1.0)
	## 敵人在右、被打應向右退；俠在左、被打應向左退
	if hit_from_right:
		knock = -absf(knock)
	else:
		knock = absf(knock)
	var ox: float = node.position.x
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "position:x", ox + knock, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(node, "position:x", ox, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var tw2 := create_tween()
	tw2.tween_property(node, "modulate", Color(1, 1, 1, base_a), 0.16)
	if heavy:
		_fx_micro_shake()

func _fx_parry(node: Node2D) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.modulate = Color(0.65, 0.88, 1.25, 1.0)
	var tw := create_tween()
	tw.tween_property(node, "modulate", Color(1, 1, 1, 1), 0.18)
	## 招架微亮圈感：短暫放大再回
	var base_s: Vector2 = node.get_meta("base_scale", node.scale) as Vector2
	var tws := create_tween()
	tws.tween_property(node, "scale", base_s * 1.06, 0.06)
	tws.tween_property(node, "scale", base_s, 0.12)

func _fx_micro_shake() -> void:
	## Lemon：鏡頭震動要細 — 只微移 Arena 1～2px
	if arena == null or _shaking:
		return
	_shaking = true
	var origin: Vector2 = _arena_origin if _arena_origin != Vector2.ZERO else arena.position
	var tw := create_tween()
	tw.tween_property(arena, "position", origin + Vector2(1.5, -1.0), 0.035)
	tw.tween_property(arena, "position", origin + Vector2(-1.2, 0.8), 0.035)
	tw.tween_property(arena, "position", origin, 0.045)
	tw.tween_callback(func() -> void:
		if arena:
			arena.position = origin
		_shaking = false
	)
