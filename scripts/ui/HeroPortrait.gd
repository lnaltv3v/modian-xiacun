extends Control
class_name HeroPortrait
## 村莊列表用俠客頭像：idle／hunting→walk；紫卡無圖時色塊＋兵種標

const SCALE := 1.5

const RARITY_COLOR := {
	"白": Color(0.85, 0.82, 0.76),
	"綠": Color(0.25, 0.55, 0.35),
	"藍": Color(0.25, 0.4, 0.7),
	"紫": Color(0.45, 0.28, 0.65),
	"橙": Color(0.85, 0.45, 0.15),
	"紅": Color(0.75, 0.15, 0.12),
}

var hero_id: String = ""
var _sprite: AnimatedSprite2D
var _placeholder: ColorRect
var _weapon_lab: Label
var _frame: int = 64

func _ready() -> void:
	_apply_size()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_placeholder = ColorRect.new()
	_placeholder.visible = false
	add_child(_placeholder)
	_weapon_lab = Label.new()
	_weapon_lab.visible = false
	_weapon_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_weapon_lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_weapon_lab.add_theme_color_override("font_color", Color(0.95, 0.92, 0.86))
	_weapon_lab.add_theme_font_size_override("font_size", 11)
	add_child(_weapon_lab)
	if not hero_id.is_empty():
		setup(hero_id)

func _apply_size() -> void:
	var px: float = float(_frame) * SCALE
	custom_minimum_size = Vector2(px, px)
	if _sprite:
		_sprite.position = Vector2(px * 0.5, px * 0.5)
		_sprite.scale = Vector2(SCALE, SCALE)
	if _placeholder:
		_placeholder.position = Vector2.ZERO
		_placeholder.size = Vector2(px, px)
	if _weapon_lab:
		_weapon_lab.position = Vector2.ZERO
		_weapon_lab.size = Vector2(px, px)

static func frame_px() -> float:
	return float(ArtPaths.FRAME_PREFERRED) * SCALE

func setup(id: String) -> void:
	hero_id = id
	_frame = ArtPaths.hero_frame_px(hero_id)
	_apply_size()
	if _sprite == null:
		return
	var hero: Dictionary = HeroSystem.get_hero(hero_id)
	var use_ph: bool = bool(hero.get("placeholder", false)) or str(hero.get("art_key", "")) == ""
	## 有真實 idle 紋理則唔用 placeholder
	var idle_path: String = ArtPaths.hero_idle(hero_id)
	var has_tex: bool = ArtPaths.exists(idle_path) and str(hero.get("art_key", "")) != ""
	if use_ph and not has_tex:
		_show_placeholder(hero)
	else:
		_hide_placeholder()
		_sprite.sprite_frames = ArtPaths.make_hero_frames(hero_id)
		play_for_status("idle")

func _show_placeholder(hero: Dictionary) -> void:
	if _sprite:
		_sprite.visible = false
		_sprite.stop()
	if _placeholder:
		_placeholder.visible = true
		var rarity: String = str(hero.get("rarity", "紫"))
		_placeholder.color = RARITY_COLOR.get(rarity, Color(0.45, 0.28, 0.65))
	if _weapon_lab:
		_weapon_lab.visible = true
		_weapon_lab.text = "%s\n%s" % [str(hero.get("weapon", "?")), rarity_tag(str(hero.get("rarity", "")))]
	_apply_size()

func _hide_placeholder() -> void:
	if _sprite:
		_sprite.visible = true
	if _placeholder:
		_placeholder.visible = false
	if _weapon_lab:
		_weapon_lab.visible = false

static func rarity_tag(r: String) -> String:
	return "[%s]" % r if r != "" else ""

func play_for_status(status: String) -> void:
	if _placeholder and _placeholder.visible:
		return
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if status == "hunting" or status == "dungeon":
		if _sprite.sprite_frames.has_animation("walk"):
			_sprite.play("walk")
			return
	if _sprite.sprite_frames.has_animation("idle"):
		_sprite.play("idle")
