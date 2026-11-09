extends Label
class_name DamageFloater
## 戰鬥飄字：上浮淡出後自毀（hit／crit／heal／enemy／parry）

func setup(amount: int, pos: Vector2, kind: String = "hit") -> void:
	text = str(amount)
	position = pos
	z_index = 40
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font_sz: int = 22
	var col := Color(0.97, 0.94, 0.88)
	match kind:
		"crit":
			col = Color(1.0, 0.82, 0.25)
			text = str(amount) + "!"
			font_sz = 28
		"heal":
			col = Color(0.35, 0.85, 0.45)
			text = "+" + str(amount)
		"enemy":
			col = Color(0.95, 0.45, 0.4)
		"parry", "block":
			col = Color(0.55, 0.82, 1.0)
			text = "招架"
			font_sz = 20
		_:
			col = Color(0.97, 0.94, 0.88)
	add_theme_font_size_override("font_size", font_sz)
	add_theme_color_override("font_color", col)
	add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.04, 0.92))
	add_theme_constant_override("outline_size", 4)
	modulate.a = 1.0
	var rise: float = 40.0 if kind in ["parry", "block"] else 48.0
	var dur: float = 0.65 if kind in ["parry", "block"] else 0.75
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", position.y - rise, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, dur).set_delay(0.12)
	if kind in ["parry", "block"]:
		var base_x: float = position.x
		tw.tween_property(self, "position:x", base_x + 6.0, dur * 0.5).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(queue_free)
