extends Control
## 秘境三波簡演出（用現有怪 sprite；末波放大示意）

signal closed(rewards: Dictionary)

@onready var title_label: Label = %TitleLabel
@onready var wave_label: Label = %WaveLabel
@onready var flavor_label: Label = %FlavorLabel
@onready var enemies_box: HBoxContainer = %EnemiesBox
@onready var btn_ok: Button = %BtnOk
@onready var progress_label: Label = %ProgressLabel

var _waves: Array = []
var _rewards: Dictionary = {}
var _idx: int = 0
var _dungeon_name: String = "秘境"
var _playing: bool = false

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	if btn_ok:
		btn_ok.pressed.connect(_on_ok)
		btn_ok.text = "下一波"

func play_run(result: Dictionary) -> void:
	_waves = result.get("waves", []) as Array
	_rewards = (result.get("rewards", {}) as Dictionary).duplicate(true)
	_dungeon_name = str(result.get("dungeon_name", "秘境"))
	_idx = 0
	_playing = true
	visible = true
	move_to_front()
	title_label.text = "秘境 · %s" % _dungeon_name
	if btn_ok:
		btn_ok.disabled = false
	_show_wave()

func _show_wave() -> void:
	if _idx >= _waves.size():
		_show_summary()
		return
	var w: Dictionary = _waves[_idx] as Dictionary
	var success: bool = bool(w.get("success", false))
	wave_label.text = str(w.get("label", "波次 %d" % (_idx + 1)))
	progress_label.text = "波次 %d／%d　黨力 %d vs 敵勢 %d　成功率 %.0f%%" % [
		int(w.get("index", _idx + 1)),
		_waves.size() if _rewards.get("cleared", false) or _idx + 1 < _waves.size() else _idx + 1,
		int(w.get("party_power", 0)),
		int(w.get("enemy_power", 0)),
		float(w.get("success_chance", 0)) * 100.0,
	]
	## progress total from rewards if available
	var total_waves: int = maxi(_waves.size(), int(_rewards.get("waves_cleared", _waves.size())))
	progress_label.text = "波次 %d／3　黨力 %d vs 敵勢 %d　成功率 %.0f%%　%s" % [
		int(w.get("index", _idx + 1)),
		int(w.get("party_power", 0)),
		int(w.get("enemy_power", 0)),
		float(w.get("success_chance", 0)) * 100.0,
		("擊破" if success else "失手"),
	]
	flavor_label.text = ("此波得勝！" if success else "此波不敵…") + (
		"　（末波精英示意）" if bool(w.get("boss", false)) else ""
	)
	for c in enemies_box.get_children():
		c.queue_free()
	var enemies: Array = w.get("enemies", []) as Array
	for ev in enemies:
		var ed: Dictionary = ev as Dictionary
		var kind: String = str(ed.get("kind", "wolf"))
		var scale_m: float = float(ed.get("scale", 1.0))
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var tex_rect := TextureRect.new()
		var base: float = 96.0 * scale_m
		tex_rect.custom_minimum_size = Vector2(base, base)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var atk: Texture2D = ArtPaths.load_tex(ArtPaths.monster_attack(kind))
		var idle: Texture2D = ArtPaths.load_tex(ArtPaths.monster_idle(kind))
		tex_rect.texture = atk if atk != null else idle
		col.add_child(tex_rect)
		var lab := Label.new()
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.add_theme_color_override("font_color", Color(0.91, 0.86, 0.78))
		lab.add_theme_font_size_override("font_size", 13)
		var nm: String = str(ed.get("name", kind))
		if bool(ed.get("elite", false)):
			nm = "★ " + nm
		lab.text = nm
		col.add_child(lab)
		enemies_box.add_child(col)
	if btn_ok:
		if _idx >= _waves.size() - 1 or not success:
			btn_ok.text = "睇結果"
		else:
			btn_ok.text = "下一波"
	## attack → idle flash
	get_tree().create_timer(0.4).timeout.connect(func() -> void:
		if not visible:
			return
		var i: int = 0
		for child in enemies_box.get_children():
			if i >= enemies.size():
				break
			var kind2: String = str((enemies[i] as Dictionary).get("kind", "wolf"))
			var tr: TextureRect = child.get_child(0) as TextureRect if child.get_child_count() > 0 else null
			if tr:
				var idle2: Texture2D = ArtPaths.load_tex(ArtPaths.monster_idle(kind2))
				if idle2:
					tr.texture = idle2
			i += 1
	)

func _show_summary() -> void:
	wave_label.text = "結算"
	progress_label.text = "通關波數 %d　%s" % [
		int(_rewards.get("waves_cleared", 0)),
		("全破！" if bool(_rewards.get("cleared", false)) else "中途撤出"),
	]
	flavor_label.text = str(_rewards.get("flavor", ""))
	var iron: int = int(_rewards.get("iron", 0))
	var iron_txt: String = ("　鐵 %d" % iron) if iron > 0 else ""
	var loot := "戰利品：銀 %d　毛皮 %d　木 %d%s" % [
		int(_rewards.get("silver", 0)),
		int(_rewards.get("fur", 0)),
		int(_rewards.get("wood", 0)),
		iron_txt,
	]
	var injured: Array = _rewards.get("injured", []) as Array
	if injured.size() > 0:
		loot += "\n受傷：%s" % "、".join(PackedStringArray(injured))
	## reuse enemies box for a simple loot line via label child
	for c in enemies_box.get_children():
		c.queue_free()
	var lab := Label.new()
	lab.add_theme_color_override("font_color", Color(0.91, 0.86, 0.78))
	lab.add_theme_font_size_override("font_size", 14)
	lab.text = loot
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.custom_minimum_size = Vector2(480, 0)
	enemies_box.add_child(lab)
	if btn_ok:
		btn_ok.text = "關閉"

func _on_ok() -> void:
	if not _playing:
		visible = false
		closed.emit(_rewards)
		return
	if _idx < _waves.size():
		var w: Dictionary = _waves[_idx] as Dictionary
		var success: bool = bool(w.get("success", false))
		_idx += 1
		if success and _idx < _waves.size():
			_show_wave()
			return
		## last wave or fail → summary
		_show_summary()
		_playing = false
		return
	visible = false
	closed.emit(_rewards)
