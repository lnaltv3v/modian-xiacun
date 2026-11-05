extends Control
class_name HeroPortrait
## 村莊列表用俠客頭像：idle／hunting→walk（跟 ArtPaths 實際幀尺寸）

const SCALE := 1.5

var hero_id: String = ""
var _sprite: AnimatedSprite2D
var _frame: int = 64

func _ready() -> void:
	_apply_size()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	if not hero_id.is_empty():
		setup(hero_id)

func _apply_size() -> void:
	var px: float = float(_frame) * SCALE
	custom_minimum_size = Vector2(px, px)
	if _sprite:
		_sprite.position = Vector2(px * 0.5, px * 0.5)
		_sprite.scale = Vector2(SCALE, SCALE)

static func frame_px() -> float:
	return float(ArtPaths.FRAME_PREFERRED) * SCALE

func setup(id: String) -> void:
	hero_id = id
	_frame = ArtPaths.hero_frame_px(hero_id)
	_apply_size()
	if _sprite == null:
		return
	_sprite.sprite_frames = ArtPaths.make_hero_frames(hero_id)
	play_for_status("idle")

func play_for_status(status: String) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if status == "hunting" and _sprite.sprite_frames.has_animation("walk"):
		_sprite.play("walk")
	elif _sprite.sprite_frames.has_animation("idle"):
		_sprite.play("idle")
