extends Control
class_name HeroPortrait
## 村莊列表用俠客頭像：idle／hunting→walk

const SCALE := 2

var hero_id: String = ""
var _sprite: AnimatedSprite2D

func _ready() -> void:
	custom_minimum_size = Vector2(frame_px(), frame_px())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	_sprite.position = Vector2(frame_px() * 0.5, frame_px() * 0.5)
	_sprite.scale = Vector2(SCALE, SCALE)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	if not hero_id.is_empty():
		setup(hero_id)

static func frame_px() -> float:
	return float(ArtPaths.FRAME * SCALE)

func setup(id: String) -> void:
	hero_id = id
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
