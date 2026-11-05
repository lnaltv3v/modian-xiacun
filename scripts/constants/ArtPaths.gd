extends RefCounted
class_name ArtPaths
## 美術路徑常數 — 對齊 P1 實際檔名（48×48；walk 為 192×48 四幀 sheet）

const HEROES_DIR := "res://assets/art/heroes/"
const BUILDINGS_DIR := "res://assets/art/buildings/"
const UI_DIR := "res://assets/art/ui/"
const MONSTERS_DIR := "res://assets/art/monsters/"
const TILES_DIR := "res://assets/art/tiles/"

const FRAME := 48
const WALK_FRAMES := 4

## hero_id → 美術 stem（weapon_slug）
const HERO_ART := {
	"hero_atie": "hero_dao_atie",
	"hero_aqing": "hero_jian_aqing",
	"hero_achang": "hero_qiang_achang",
	"hero_dali": "hero_gun_dali",
	"hero_azhen": "hero_anqi_azhen",
	"hero_aniu": "hero_quan_aniu",
}

const MONSTER_ART := {
	"wolf": "monster_wolf",
	"boar": "monster_boar",
	"bandit": "monster_bandit",
}

static func hero_stem(hero_id: String) -> String:
	return str(HERO_ART.get(hero_id, hero_id))

static func hero_idle(hero_id: String) -> String:
	return HEROES_DIR + hero_stem(hero_id) + "_idle.png"

static func hero_walk(hero_id: String) -> String:
	return HEROES_DIR + hero_stem(hero_id) + "_walk.png"

static func building_icon(building_id: String) -> String:
	return BUILDINGS_DIR + building_id + ".png"

static func monster_idle(kind: String) -> String:
	var stem: String = str(MONSTER_ART.get(kind, "monster_" + kind))
	return MONSTERS_DIR + stem + "_idle.png"

static func monster_attack(kind: String) -> String:
	var stem: String = str(MONSTER_ART.get(kind, "monster_" + kind))
	return MONSTERS_DIR + stem + "_attack.png"

const ICON_SILVER := UI_DIR + "icon_silver.png"
const ICON_WOOD := UI_DIR + "icon_wood.png"
const ICON_FUR := UI_DIR + "icon_hide.png"
const ICON_IRON := UI_DIR + "icon_iron.png"
const ICON_HERB := UI_DIR + "icon_herb.png"
const BTN_DISPATCH := UI_DIR + "btn_dispatch.png"
const BTN_BUILD := UI_DIR + "btn_build.png"
const HUD_PANEL := UI_DIR + "hud_panel.png"
const VILLAGE_COMPOSED := TILES_DIR + "village_composed.png"
const VILLAGE_GROUND := TILES_DIR + "village_ground.png"

static func exists(path: String) -> bool:
	return ResourceLoader.exists(path)

static func load_tex(path: String) -> Texture2D:
	if not exists(path):
		return null
	return load(path) as Texture2D

## 由 idle + walk sheet 組 SpriteFrames（idle / walk）
static func make_hero_frames(hero_id: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 1.0)
	frames.set_animation_loop("idle", true)
	var idle_tex: Texture2D = load_tex(hero_idle(hero_id))
	if idle_tex != null:
		frames.add_frame("idle", idle_tex)

	frames.add_animation("walk")
	frames.set_animation_speed("walk", 6.0)
	frames.set_animation_loop("walk", true)
	var walk_tex: Texture2D = load_tex(hero_walk(hero_id))
	if walk_tex != null:
		var w: int = walk_tex.get_width()
		var h: int = walk_tex.get_height()
		var fw: int = FRAME
		var fh: int = FRAME if h >= FRAME else h
		var count: int = mini(WALK_FRAMES, int(w / maxi(1, fw)))
		for i in range(maxi(1, count)):
			var at := AtlasTexture.new()
			at.atlas = walk_tex
			at.region = Rect2(i * fw, 0, fw, fh)
			frames.add_frame("walk", at)
	elif idle_tex != null:
		frames.add_frame("walk", idle_tex)
	return frames
