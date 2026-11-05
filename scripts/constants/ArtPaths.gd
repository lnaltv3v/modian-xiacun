extends RefCounted
class_name ArtPaths
## 美術路徑 — 優先 64×64（walk 256×64）；唔見先 fallback _prev_48（48×48／192×48）

const HEROES_DIR := "res://assets/art/heroes/"
const HEROES_FALLBACK_DIR := "res://assets/art/heroes/_prev_48/"
const BUILDINGS_DIR := "res://assets/art/buildings/"
const UI_DIR := "res://assets/art/ui/"
const MONSTERS_DIR := "res://assets/art/monsters/"
const MONSTERS_FALLBACK_DIR := "res://assets/art/monsters/_prev_48/"
const TILES_DIR := "res://assets/art/tiles/"

const FRAME_PREFERRED := 64
const FRAME_FALLBACK := 48
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
	## 抽卡俠客用 art_key 指向開局六綠俠美術
	var hero: Dictionary = HeroSystem.get_hero(hero_id) if hero_id != "" else {}
	var art_key: String = str(hero.get("art_key", ""))
	if art_key != "" and HERO_ART.has(art_key):
		return str(HERO_ART[art_key])
	if art_key != "" and art_key.begins_with("hero_"):
		return str(HERO_ART.get(art_key, art_key))
	return str(HERO_ART.get(hero_id, hero_id))

static func hero_idle(hero_id: String) -> String:
	return _first_existing([
		HEROES_DIR + hero_stem(hero_id) + "_idle.png",
		HEROES_FALLBACK_DIR + hero_stem(hero_id) + "_idle.png",
	])

static func hero_walk(hero_id: String) -> String:
	return _first_existing([
		HEROES_DIR + hero_stem(hero_id) + "_walk.png",
		HEROES_FALLBACK_DIR + hero_stem(hero_id) + "_walk.png",
	])

static func building_icon(building_id: String) -> String:
	return BUILDINGS_DIR + building_id + ".png"

static func monster_idle(kind: String) -> String:
	var stem: String = str(MONSTER_ART.get(kind, "monster_" + kind))
	return _first_existing([
		MONSTERS_DIR + stem + "_idle.png",
		MONSTERS_FALLBACK_DIR + stem + "_idle.png",
	])

static func monster_attack(kind: String) -> String:
	var stem: String = str(MONSTER_ART.get(kind, "monster_" + kind))
	return _first_existing([
		MONSTERS_DIR + stem + "_attack.png",
		MONSTERS_FALLBACK_DIR + stem + "_attack.png",
	])

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
	return path != "" and ResourceLoader.exists(path)

static func load_tex(path: String) -> Texture2D:
	if not exists(path):
		return null
	return load(path) as Texture2D

static func _first_existing(paths: Array) -> String:
	for p in paths:
		var s: String = str(p)
		if ResourceLoader.exists(s):
			return s
	return str(paths[0]) if paths.size() > 0 else ""

static func detect_frame(tex: Texture2D) -> int:
	if tex == null:
		return FRAME_PREFERRED
	var h: int = tex.get_height()
	if h >= FRAME_PREFERRED:
		return FRAME_PREFERRED
	if h >= FRAME_FALLBACK:
		return FRAME_FALLBACK
	return maxi(1, h)

## 由 idle + walk sheet 組 SpriteFrames（idle / walk）；幀闊跟實際解像
static func make_hero_frames(hero_id: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 1.0)
	frames.set_animation_loop("idle", true)
	var idle_tex: Texture2D = load_tex(hero_idle(hero_id))
	var fw: int = detect_frame(idle_tex)
	if idle_tex != null:
		frames.add_frame("idle", idle_tex)

	frames.add_animation("walk")
	frames.set_animation_speed("walk", 6.0)
	frames.set_animation_loop("walk", true)
	var walk_tex: Texture2D = load_tex(hero_walk(hero_id))
	if walk_tex != null:
		var w: int = walk_tex.get_width()
		var h: int = walk_tex.get_height()
		fw = detect_frame(walk_tex) if idle_tex == null else fw
		## walk sheet 高度即幀高；闊度用幀高（方幀）或 detect
		var fh: int = h
		fw = fh if fh > 0 else fw
		var count: int = mini(WALK_FRAMES, int(w / maxi(1, fw)))
		for i in range(maxi(1, count)):
			var at := AtlasTexture.new()
			at.atlas = walk_tex
			at.region = Rect2(i * fw, 0, fw, fh)
			frames.add_frame("walk", at)
	elif idle_tex != null:
		frames.add_frame("walk", idle_tex)
	return frames

static func hero_frame_px(hero_id: String) -> int:
	var tex: Texture2D = load_tex(hero_idle(hero_id))
	return detect_frame(tex)
