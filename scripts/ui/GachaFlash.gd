extends Control
class_name GachaFlash
## 抽卡稀有閃光：中央色爆＋稀有字，短暫後淡出

const RARITY_COLOR := {
	"白": Color(0.85, 0.82, 0.76),
	"綠": Color(0.25, 0.55, 0.35),
	"藍": Color(0.25, 0.4, 0.7),
	"紫": Color(0.55, 0.32, 0.78),
	"橙": Color(1.0, 0.55, 0.12),
	"紅": Color(0.95, 0.18, 0.14),
}

var _veil: ColorRect
var _burst: ColorRect
var _lab: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 80
	_veil = ColorRect.new()
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.color = Color(0.05, 0.04, 0.03, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)
	_burst = ColorRect.new()
	_burst.size = Vector2(280, 280)
	_burst.position = Vector2(500, 180)
	_burst.color = Color(1, 1, 1, 0)
	_burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_burst)
	_lab = Label.new()
	_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lab.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_lab.offset_left = -200
	_lab.offset_right = 200
	_lab.offset_top = -40
	_lab.offset_bottom = 40
	_lab.add_theme_font_size_override("font_size", 36)
	_lab.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.04, 0.95))
	_lab.add_theme_constant_override("outline_size", 6)
	_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lab)
	visible = false

func play(rarity: String, hero_name: String = "", is_dupe: bool = false) -> void:
	var col: Color = RARITY_COLOR.get(rarity, RARITY_COLOR["白"]) as Color
	## 紫／橙／紅加強爆發；白綠藍較淡
	var boost: float = 0.35
	match rarity:
		"紫":
			boost = 0.55
		"橙":
			boost = 0.7
		"紅":
			boost = 0.9
		"藍":
			boost = 0.45
		_:
			boost = 0.28
	_burst.color = Color(col.r, col.g, col.b, 0.0)
	_veil.color = Color(col.r * 0.15, col.g * 0.1, col.b * 0.12, 0.0)
	var tag: String = rarity
	if hero_name != "":
		tag = "%s　%s" % [rarity, hero_name]
	if is_dupe:
		tag += "（重覆→碎片）"
	_lab.text = tag
	_lab.add_theme_color_override("font_color", col.lightened(0.25))
	visible = true
	modulate.a = 1.0
	var parent_sz: Vector2 = size
	if parent_sz.x < 8.0 and get_parent() is Control:
		parent_sz = (get_parent() as Control).size
	_burst.size = Vector2(220 + boost * 120.0, 220 + boost * 120.0)
	_burst.pivot_offset = _burst.size * 0.5
	_burst.position = Vector2(parent_sz.x * 0.5 - _burst.size.x * 0.5, parent_sz.y * 0.38 - _burst.size.y * 0.5)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_veil, "color:a", boost * 0.55, 0.12)
	tw.tween_property(_burst, "color:a", boost, 0.1)
	tw.tween_property(_burst, "scale", Vector2(1.35, 1.35), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(_veil, "color:a", 0.0, 0.45)
	tw.parallel().tween_property(_burst, "color:a", 0.0, 0.45)
	tw.parallel().tween_property(_lab, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(_hide_flash)
	_lab.modulate.a = 1.0
	_burst.scale = Vector2.ONE

func play_batch(results: Array) -> void:
	## 十連：閃最高稀有
	var order := {"白": 0, "綠": 1, "藍": 2, "紫": 3, "橙": 4, "紅": 5}
	var best_r := "白"
	var best_name := ""
	var best_score := -1
	var any_dupe := true
	for r in results:
		var rd: Dictionary = r as Dictionary
		if not bool(rd.get("ok", false)):
			continue
		var rarity: String = str(rd.get("rarity", "白"))
		var score: int = int(order.get(rarity, 0))
		if score > best_score:
			best_score = score
			best_r = rarity
			var h: Dictionary = rd.get("hero", {}) as Dictionary
			best_name = str(h.get("name", ""))
		if str(rd.get("result", "")) == "new":
			any_dupe = false
	play(best_r, best_name if best_score >= 3 else ("十連·最高%s" % best_r), false if best_score >= 3 else any_dupe)

func _hide_flash() -> void:
	visible = false
	_burst.scale = Vector2.ONE
	_lab.modulate.a = 1.0
