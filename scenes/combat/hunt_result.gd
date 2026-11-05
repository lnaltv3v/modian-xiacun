extends Control
## 亂山坡回村簡短戰鬥／結果演出（模擬結算＋怪 sprite）

signal closed

@onready var title_label: Label = %TitleLabel
@onready var flavor_label: Label = %FlavorLabel
@onready var loot_label: Label = %LootLabel
@onready var enemies_box: HBoxContainer = %EnemiesBox
@onready var btn_ok: Button = %BtnOk

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	if btn_ok:
		btn_ok.pressed.connect(_on_ok)

func show_result(rewards: Dictionary) -> void:
	visible = true
	move_to_front()
	title_label.text = "回村 · %s" % str(rewards.get("zone_name", "獵場"))
	flavor_label.text = str(rewards.get("flavor", "戰鬥結束。"))
	loot_label.text = LootText.format_loot_block(rewards)
	var bounty: Dictionary = rewards.get("bounty_bonus", {}) as Dictionary
	if int(bounty.get("hits", 0)) > 0:
		loot_label.text += "\n懸賞「%s」命中 ×%d" % [
			str(bounty.get("target_name", "目標")), int(bounty.get("hits", 0))
		]
	var injured: Array = rewards.get("injured", []) as Array
	if injured.size() > 0:
		loot_label.text += "\n受傷回村：%s（醫館可療）" % "、".join(PackedStringArray(injured))
	elif bool(rewards.get("success", true)):
		loot_label.text += "\n全員無大礙。"

	for c in enemies_box.get_children():
		c.queue_free()
	var enemies: Array = rewards.get("enemies", []) as Array
	if enemies.is_empty():
		enemies = [{"kind": "wolf", "name": "野狼"}]
	for ev in enemies:
		var ed: Dictionary = ev as Dictionary
		var kind: String = str(ed.get("kind", "wolf"))
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(96, 96)
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
		lab.text = str(ed.get("name", kind))
		col.add_child(lab)
		enemies_box.add_child(col)

	## 短暫閃一下 attack → 可選：0.4s 後切 idle
	get_tree().create_timer(0.45).timeout.connect(func() -> void:
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

func _on_ok() -> void:
	visible = false
	closed.emit()
