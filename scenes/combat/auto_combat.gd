extends Control
## 短即時自動戰鬥：雙方靠近 → 攻擊幀循環 3–8 秒 → 結算摘要可選

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

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	if summary_panel:
		summary_panel.visible = false
	if btn_ok:
		btn_ok.pressed.connect(_on_ok)
		btn_ok.visible = false

## config:
##  title, heroes: [hero_id], enemies: [{kind,name,scale?}],
##  success: bool, duration: float (clamp 3–8),
##  summary: Dictionary (loot text fields), show_summary: bool = true
func play(config: Dictionary) -> void:
	_cfg = config.duplicate(true)
	_summary = (_cfg.get("summary", {}) as Dictionary).duplicate(true)
	_playing = true
	_phase = "approach"
	_atk_flip = false
	_atk_timer = 0.0
	_rng.randomize()
	var dur: float = float(_cfg.get("duration", _rng.randf_range(3.5, 6.5)))
	_fight_left = clampf(dur, 3.0, 8.0)
	visible = true
	move_to_front()
	if summary_panel:
		summary_panel.visible = false
	if btn_ok:
		btn_ok.visible = false
	if title_label:
		title_label.text = str(_cfg.get("title", "交戰"))
	if phase_label:
		phase_label.text = "逼近…"
	_clear_layers()
	_spawn_sides()
	set_process(true)
	## approach tween ~0.55s
	_tween_approach()

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
		var spr2 := Sprite2D.new()
		spr2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr2.centered = true
		var idle: Texture2D = ArtPaths.load_tex(ArtPaths.monster_idle(kind))
		var atk: Texture2D = ArtPaths.load_tex(ArtPaths.monster_attack(kind))
		spr2.texture = idle if idle != null else atk
		var mds: float = (88.0 / 64.0) * scale_m
		spr2.scale = Vector2(mds, mds)
		## 面向左（對俠）
		spr2.flip_h = true
		spr2.position = Vector2(right_x + 80.0, mid_y + float(ei) * 32.0 - float(mini(enemies.size(), 4) - 1) * 16.0)
		spr2.set_meta("home", Vector2(right_x - 40.0 - float(ei) * 18.0, mid_y + float(ei) * 32.0 - float(mini(enemies.size(), 4) - 1) * 16.0))
		spr2.set_meta("kind", kind)
		spr2.set_meta("idle_tex", idle)
		spr2.set_meta("atk_tex", atk)
		spr2.set_meta("side", "enemy")
		enemies_layer.add_child(spr2)
		_enemy_nodes.append(spr2)
		ei += 1
		if ei >= 4:
			break

func _tween_approach() -> void:
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
		phase_label.text = "交鋒中…"
	## heroes: prefer walk as "attack" loop (no attack sheet yet); pulse scale
	for n in _hero_nodes:
		var spr: AnimatedSprite2D = n as AnimatedSprite2D
		if spr and spr.sprite_frames:
			if spr.sprite_frames.has_animation("walk"):
				spr.play("walk")
				spr.speed_scale = 1.35

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

func _end_fight() -> void:
	_phase = "done"
	set_process(false)
	var success: bool = bool(_cfg.get("success", true))
	if phase_label:
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
	if summary_panel:
		summary_panel.visible = true
	if summary_label:
		summary_label.text = _format_summary(_summary)
	if btn_ok:
		btn_ok.visible = true
		btn_ok.text = "收下戰利品"
	if phase_label:
		phase_label.text = "結算"

func _format_summary(s: Dictionary) -> String:
	if s.has("text") and str(s.get("text", "")) != "":
		return str(s.get("text", ""))
	var iron: int = int(s.get("iron", 0))
	var iron_txt: String = ("　鐵 %d" % iron) if iron > 0 else ""
	var lines: PackedStringArray = PackedStringArray()
	var flavor: String = str(s.get("flavor", ""))
	if flavor != "":
		lines.append(flavor)
	lines.append("戰利品：銀 %d　毛皮 %d　木 %d%s" % [
		int(s.get("silver", 0)), int(s.get("fur", 0)), int(s.get("wood", 0)), iron_txt
	])
	var injured: Array = s.get("injured", []) as Array
	if injured.size() > 0:
		lines.append("受傷：%s" % "、".join(PackedStringArray(injured)))
	return "\n".join(lines)

func _on_ok() -> void:
	_finish()

func _finish() -> void:
	_playing = false
	visible = false
	if summary_panel:
		summary_panel.visible = false
	if btn_ok:
		btn_ok.visible = false
	_clear_layers()
	finished.emit(_summary)

func is_busy() -> bool:
	return _playing and visible
