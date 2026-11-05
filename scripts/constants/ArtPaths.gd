extends RefCounted
class_name ArtPaths
## 美術路徑 — 紅 → 橙 → 紫 → 綠 64 → _prev_48

const HEROES_DIR := "res://assets/art/heroes/"
const HEROES_RED_DIR := "res://assets/art/heroes/red/"
const HEROES_ORANGE_DIR := "res://assets/art/heroes/orange/"
const HEROES_PURPLE_DIR := "res://assets/art/heroes/purple/"
const HEROES_FALLBACK_DIR := "res://assets/art/heroes/_prev_48/"
const BUILDINGS_DIR := "res://assets/art/buildings/"
const UI_DIR := "res://assets/art/ui/"
const MONSTERS_DIR := "res://assets/art/monsters/"
const MONSTERS_FALLBACK_DIR := "res://assets/art/monsters/_prev_48/"
const TILES_DIR := "res://assets/art/tiles/"

const FRAME_PREFERRED := 64
const FRAME_FALLBACK := 48
const WALK_FRAMES := 4

## 紅階 template_id / 常用 id → red_* stem
const RED_ART := {
	"pool_r_zhangwuji": "red_zhangwuji",
	"pool_r_dongfang": "red_dongfang",
	"pool_r_dugu": "red_dugu",
	"pool_r_saodi": "red_saodi",
	"pool_r_wangchongyang": "red_wangchongyang",
	"pool_r_huangshang": "red_huangshang",
	"red_zhangwuji": "red_zhangwuji",
	"red_dongfang": "red_dongfang",
	"red_dugu": "red_dugu",
	"red_saodi": "red_saodi",
	"red_wangchongyang": "red_wangchongyang",
	"red_huangshang": "red_huangshang",
}

## 橙階 template_id / id → orange_* stem（檔未到亦可預約路徑）
const ORANGE_ART := {
	"pool_o_yangguo": "orange_yangguo",
	"pool_o_guojing": "orange_guojing",
	"pool_o_linghuzhong": "orange_linghuzhong",
	"pool_o_qiaofeng": "orange_qiaofeng",
	"pool_o_zhangsanfeng": "orange_zhangsanfeng",
	"pool_o_fengqingyang": "orange_fengqingyang",
	"pool_o_huangyaoshi": "orange_huangyaoshi",
	"pool_o_ouyangfeng": "orange_ouyangfeng",
	"pool_o_hongqigong": "orange_hongqigong",
	"pool_o_yideng": "orange_yideng",
	"pool_o_zhoubotong": "orange_zhoubotong",
	"pool_o_miejueshitai": "orange_miejueshitai",
	"orange_yangguo": "orange_yangguo",
	"orange_guojing": "orange_guojing",
	"orange_linghuzhong": "orange_linghuzhong",
	"orange_qiaofeng": "orange_qiaofeng",
	"orange_zhangsanfeng": "orange_zhangsanfeng",
	"orange_fengqingyang": "orange_fengqingyang",
	"orange_huangyaoshi": "orange_huangyaoshi",
	"orange_ouyangfeng": "orange_ouyangfeng",
	"orange_hongqigong": "orange_hongqigong",
	"orange_yideng": "orange_yideng",
	"orange_zhoubotong": "orange_zhoubotong",
	"orange_miejueshitai": "orange_miejueshitai",
}


## 紫階 template_id / id → purple_* stem（96×96）
const PURPLE_ART := {
	"pool_p_weixiaobao": "purple_weixiaobao",
	"pool_p_hufei": "purple_hufei",
	"pool_p_miaorenfeng": "purple_miaorenfeng",
	"pool_p_yuanchengzhi": "purple_yuanchengzhi",
	"pool_p_diyun": "purple_diyun",
	"pool_p_shipotian": "purple_shipotian",
	"pool_p_xuzhu": "purple_xuzhu",
	"pool_p_limochou": "purple_limochou",
	"pool_p_xiaolongnu": "purple_xiaolongnu",
	"pool_p_zhaomin": "purple_zhaomin",
	"pool_p_zhouzhiruo": "purple_zhouzhiruo",
	"pool_p_yuebuqun": "purple_yuebuqun",
	"purple_weixiaobao": "purple_weixiaobao",
	"purple_hufei": "purple_hufei",
	"purple_miaorenfeng": "purple_miaorenfeng",
	"purple_yuanchengzhi": "purple_yuanchengzhi",
	"purple_diyun": "purple_diyun",
	"purple_shipotian": "purple_shipotian",
	"purple_xuzhu": "purple_xuzhu",
	"purple_limochou": "purple_limochou",
	"purple_xiaolongnu": "purple_xiaolongnu",
	"purple_zhaomin": "purple_zhaomin",
	"purple_zhouzhiruo": "purple_zhouzhiruo",
	"purple_yuebuqun": "purple_yuebuqun",
}

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
	"snake": "monster_wolf",
	"python": "monster_boar",
}

static func hero_stem(hero_id: String) -> String:
	## 抽卡白／綠／藍用 art_key 指向開局六綠俠美術
	var hero: Dictionary = HeroSystem.get_hero(hero_id) if hero_id != "" else {}
	var art_key: String = str(hero.get("art_key", ""))
	if art_key != "" and HERO_ART.has(art_key):
		return str(HERO_ART[art_key])
	if art_key != "" and art_key.begins_with("hero_"):
		return str(HERO_ART.get(art_key, art_key))
	return str(HERO_ART.get(hero_id, ""))

static func _stem_from_gacha_id(hero_id: String, table: Dictionary) -> String:
	if not hero_id.begins_with("gacha_"):
		return ""
	var rest: String = hero_id.substr(6)
	var cut: int = rest.rfind("_")
	if cut <= 0:
		return ""
	var maybe: String = rest.substr(0, cut)
	if table.has(maybe):
		return str(table[maybe])
	return ""

static func red_stem_for(hero_id: String) -> String:
	var hero: Dictionary = HeroSystem.get_hero(hero_id) if hero_id != "" else {}
	var art_stem: String = str(hero.get("art_stem", ""))
	if art_stem.begins_with("red_"):
		return art_stem
	if art_stem != "" and RED_ART.has(art_stem):
		return str(RED_ART[art_stem])
	var tid: String = str(hero.get("template_id", ""))
	if RED_ART.has(tid):
		return str(RED_ART[tid])
	if RED_ART.has(hero_id):
		return str(RED_ART[hero_id])
	var from_gacha: String = _stem_from_gacha_id(hero_id, RED_ART)
	if from_gacha != "":
		return from_gacha
	if art_stem != "" and art_stem.begins_with("red"):
		return art_stem
	return ""

static func orange_stem_for(hero_id: String) -> String:
	var hero: Dictionary = HeroSystem.get_hero(hero_id) if hero_id != "" else {}
	var art_stem: String = str(hero.get("art_stem", ""))
	if art_stem.begins_with("orange_"):
		return art_stem
	if art_stem != "" and ORANGE_ART.has(art_stem):
		return str(ORANGE_ART[art_stem])
	var tid: String = str(hero.get("template_id", ""))
	if ORANGE_ART.has(tid):
		return str(ORANGE_ART[tid])
	if ORANGE_ART.has(hero_id):
		return str(ORANGE_ART[hero_id])
	return _stem_from_gacha_id(hero_id, ORANGE_ART)

static func purple_stem_for(hero_id: String) -> String:
	var hero: Dictionary = HeroSystem.get_hero(hero_id) if hero_id != "" else {}
	var art_stem: String = str(hero.get("art_stem", ""))
	if art_stem.begins_with("purple_"):
		return art_stem
	if art_stem != "" and PURPLE_ART.has(art_stem):
		return str(PURPLE_ART[art_stem])
	var tid: String = str(hero.get("template_id", ""))
	if PURPLE_ART.has(tid):
		return str(PURPLE_ART[tid])
	if PURPLE_ART.has(hero_id):
		return str(PURPLE_ART[hero_id])
	return _stem_from_gacha_id(hero_id, PURPLE_ART)

static func _hero_path_candidates(hero_id: String, suffix: String) -> Array:
	## 紅 → 橙 → 紫 → 一般 64 → 48 fallback
	var stem: String = hero_stem(hero_id)
	var red: String = red_stem_for(hero_id)
	var orange: String = orange_stem_for(hero_id)
	var purple: String = purple_stem_for(hero_id)
	var out: Array = []
	var seen: Dictionary = {}
	if red != "":
		var rp: String = HEROES_RED_DIR + red + suffix
		if not seen.has(rp):
			seen[rp] = true
			out.append(rp)
	if orange != "":
		var op: String = HEROES_ORANGE_DIR + orange + suffix
		if not seen.has(op):
			seen[op] = true
			out.append(op)
	if purple != "":
		var pp: String = HEROES_PURPLE_DIR + purple + suffix
		if not seen.has(pp):
			seen[pp] = true
			out.append(pp)
	if stem != "":
		var gp: String = HEROES_DIR + stem + suffix
		var fp: String = HEROES_FALLBACK_DIR + stem + suffix
		if not seen.has(gp):
			seen[gp] = true
			out.append(gp)
		if not seen.has(fp):
			seen[fp] = true
			out.append(fp)
	## 萬一全空，仍畀一個可診斷路徑
	if out.is_empty():
		out.append(HEROES_DIR + hero_id + suffix)
	return out

static func hero_idle(hero_id: String) -> String:
	return _first_existing(_hero_path_candidates(hero_id, "_idle.png"))

static func hero_walk(hero_id: String) -> String:
	return _first_existing(_hero_path_candidates(hero_id, "_walk.png"))

static func has_red_art(hero_id: String) -> bool:
	var red: String = red_stem_for(hero_id)
	if red != "" and ResourceLoader.exists(HEROES_RED_DIR + red + "_idle.png"):
		return true
	return false

static func has_orange_art(hero_id: String) -> bool:
	var orange: String = orange_stem_for(hero_id)
	if orange != "" and ResourceLoader.exists(HEROES_ORANGE_DIR + orange + "_idle.png"):
		return true
	return false

static func has_purple_art(hero_id: String) -> bool:
	var purple: String = purple_stem_for(hero_id)
	if purple != "" and ResourceLoader.exists(HEROES_PURPLE_DIR + purple + "_idle.png"):
		return true
	return false

static func display_scale_for(hero_id: String, target_px: float = 72.0) -> float:
	var fw: int = hero_frame_px(hero_id)
	return target_px / float(maxi(1, fw))

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
	## 用實際幀高（支援 64／96／128／256）
	if h >= 32:
		return h
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
		var fh: int = h if h > 0 else fw
		fw = fh
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
