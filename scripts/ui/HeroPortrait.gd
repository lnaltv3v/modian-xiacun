extends Control
class_name HeroPortrait
## 村莊列表用俠客頭像：idle／hunting→walk；無圖時色塊＋兵種標；稀有色邊（白→紅）

const TARGET_PX := 72.0
const BORDER_PX := 3.0

const RARITY_COLOR := {
	"白": Color(0.85, 0.82, 0.76),
	"綠": Color(0.25, 0.55, 0.35),
	"藍": Color(0.25, 0.4, 0.7),
	"紫": Color(0.45, 0.28, 0.65),
	"橙": Color(0.85, 0.45, 0.15),
	"紅": Color(0.75, 0.15, 0.12),
}

## 兵種短標（色塊時一眼認）
const WEAPON_SHORT := {
	"刀": "刀",
	"劍": "劍",
	"長槍": "槍",
	"槍": "槍",
	"棍": "棍",
	"暗器": "暗",
	"拳腳": "拳",
	"拳": "拳",
	"鞭": "鞭",
	"扇": "扇",
	"針": "暗",
}

var hero_id: String = ""
var _border: ColorRect
var _sprite: AnimatedSprite2D
var _placeholder: ColorRect
var _weapon_lab: Label
var _frame: int = 64
var _disp_scale: float = 1.0

func _ready() -> void:
	_apply_size()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_border = ColorRect.new()
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_border.color = RARITY_COLOR["綠"]
	add_child(_border)
	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_placeholder = ColorRect.new()
	_placeholder.visible = false
	_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_placeholder)
	_weapon_lab = Label.new()
	_weapon_lab.visible = false
	_weapon_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_weapon_lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_weapon_lab.add_theme_color_override("font_color", Color(0.97, 0.94, 0.88))
	_weapon_lab.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.04, 0.9))
	_weapon_lab.add_theme_constant_override("outline_size", 4)
	_weapon_lab.add_theme_font_size_override("font_size", 13)
	_weapon_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_weapon_lab)
	if not hero_id.is_empty():
		setup(hero_id)

func _apply_size() -> void:
	var outer: float = TARGET_PX + BORDER_PX * 2.0
	custom_minimum_size = Vector2(outer, outer)
	if _border:
		_border.position = Vector2.ZERO
		_border.size = Vector2(outer, outer)
	if _sprite:
		_sprite.position = Vector2(outer * 0.5, outer * 0.5)
		_sprite.scale = Vector2(_disp_scale, _disp_scale)
	if _placeholder:
		_placeholder.position = Vector2(BORDER_PX, BORDER_PX)
		_placeholder.size = Vector2(TARGET_PX, TARGET_PX)
	if _weapon_lab:
		_weapon_lab.position = Vector2(BORDER_PX, BORDER_PX)
		_weapon_lab.size = Vector2(TARGET_PX, TARGET_PX)

static func frame_px() -> float:
	return TARGET_PX + BORDER_PX * 2.0

static func rarity_color(r: String) -> Color:
	return RARITY_COLOR.get(r, RARITY_COLOR["綠"])

static func weapon_short(weapon: String) -> String:
	if WEAPON_SHORT.has(weapon):
		return str(WEAPON_SHORT[weapon])
	if weapon.length() >= 1:
		return weapon.substr(0, 1)
	return "?"

func setup(id: String) -> void:
	hero_id = id
	_frame = ArtPaths.hero_frame_px(hero_id)
	_disp_scale = ArtPaths.display_scale_for(hero_id, TARGET_PX)
	_apply_size()
	if _sprite == null:
		return
	var hero: Dictionary = HeroSystem.get_hero(hero_id)
	_set_border_rarity(str(hero.get("rarity", "綠")))
	var idle_path: String = ArtPaths.hero_idle(hero_id)
	var has_tex: bool = ArtPaths.exists(idle_path)
	## 紫階：有 purple art 用圖；無圖先色塊＋兵種短標
	var rarity: String = str(hero.get("rarity", ""))
	var force_ph: bool = false
	if rarity == "紫":
		if ArtPaths.has_purple_art(hero_id):
			force_ph = false
		elif bool(hero.get("placeholder", false)) or not has_tex:
			force_ph = true
	if has_tex and not force_ph:
		_hide_placeholder()
		_sprite.sprite_frames = ArtPaths.make_hero_frames(hero_id)
		play_for_status("idle")
	else:
		_show_placeholder(hero)

func _set_border_rarity(rarity: String) -> void:
	if _border:
		_border.color = rarity_color(rarity)

func _show_placeholder(hero: Dictionary) -> void:
	if _sprite:
		_sprite.visible = false
		_sprite.stop()
	var rarity: String = str(hero.get("rarity", "紫"))
	_set_border_rarity(rarity)
	if _placeholder:
		_placeholder.visible = true
		var base: Color = rarity_color(rarity)
		## 內芯稍暗，邊框更搶眼
		_placeholder.color = Color(base.r * 0.55, base.g * 0.55, base.b * 0.55, 1.0)
	if _weapon_lab:
		_weapon_lab.visible = true
		var wpn: String = str(hero.get("weapon", "?"))
		var short: String = weapon_short(wpn)
		## 兩行：大兵種短標 + 稀有；tooltip 用全名
		_weapon_lab.text = "%s\n%s" % [short, rarity]
		tooltip_text = "%s · %s[%s]" % [str(hero.get("name", "")), wpn, rarity]
	_apply_size()

func _hide_placeholder() -> void:
	if _sprite:
		_sprite.visible = true
	if _placeholder:
		_placeholder.visible = false
	if _weapon_lab:
		_weapon_lab.visible = false
	tooltip_text = ""

static func rarity_tag(r: String) -> String:
	return "[%s]" % r if r != "" else ""

func play_for_status(status: String) -> void:
	if _placeholder and _placeholder.visible:
		return
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if status == "hunting" or status == "dungeon" or status == "camped":
		if _sprite.sprite_frames.has_animation("walk"):
			_sprite.play("walk")
			return
	if _sprite.sprite_frames.has_animation("idle"):
		_sprite.play("idle")
