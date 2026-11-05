extends RefCounted
class_name ShopSystem
## 兵器鋪／商店 — 銀購裝；俠客可自動買裝（簡）

const GOODS_PATH := "res://data/shop/goods.json"

static var _goods: Array = []
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_goods.clear()
	if not FileAccess.file_exists(GOODS_PATH):
		push_warning("ShopSystem: missing %s" % GOODS_PATH)
		_loaded = true
		return
	var f := FileAccess.open(GOODS_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_goods = (parsed as Array).duplicate(true)
	_loaded = true

static func all_goods() -> Array:
	ensure_loaded()
	return _goods.duplicate(true)

static func get_good(good_id: String) -> Dictionary:
	ensure_loaded()
	for g in _goods:
		var gd: Dictionary = g as Dictionary
		if str(gd.get("id", "")) == good_id:
			return gd.duplicate(true)
	return {}

static func forge_ready() -> bool:
	return BuildingSystem.building_level("forge") >= 1

static func can_buy(good_id: String) -> Dictionary:
	var good: Dictionary = get_good(good_id)
	if good.is_empty():
		return {"ok": false, "reason": "未知貨品"}
	var need_forge: int = int(good.get("require_forge_level", 1))
	if BuildingSystem.building_level("forge") < need_forge:
		return {"ok": false, "reason": "鐵匠鋪未達 Lv.%d" % need_forge}
	var cost: int = int(good.get("cost_silver", 0))
	if GameState.silver < cost:
		return {"ok": false, "reason": "銀兩唔夠"}
	return {"ok": true, "reason": ""}

static func buy_for_hero(good_id: String, hero_id: String) -> Dictionary:
	var check: Dictionary = can_buy(good_id)
	if not bool(check.get("ok", false)):
		return {"ok": false, "reason": str(check.get("reason", ""))}
	if HeroSystem.find_hero_index(hero_id) < 0:
		return {"ok": false, "reason": "俠客不存在"}
	var good: Dictionary = get_good(good_id)
	var cost: int = int(good.get("cost_silver", 0))
	if not GameState.try_spend(cost, 0, 0, 0):
		return {"ok": false, "reason": "扣銀失敗"}
	var slot: String = str(good.get("slot", "weapon"))
	var power: int = int(good.get("power", 0))
	var name_cn: String = str(good.get("name", good_id))
	HeroSystem.equip_item(hero_id, slot, {
		"id": str(good.get("id", good_id)),
		"name": name_cn,
		"power": power,
		"source": "shop",
	})
	GameState.push_report("兵器鋪：%s 買「%s」裝俾 %s（%s＋%d）" % [
		"耗銀%d" % cost,
		name_cn,
		str(HeroSystem.get_hero(hero_id).get("name", hero_id)),
		slot,
		power,
	])
	return {"ok": true, "reason": "", "good": good}

static func _slot_power(hero: Dictionary, slot: String) -> int:
	var eq: Variant = hero.get("equipment", {})
	if typeof(eq) != TYPE_DICTIONARY:
		return 0
	var it: Variant = (eq as Dictionary).get(slot, {})
	if typeof(it) == TYPE_DICTIONARY:
		return int((it as Dictionary).get("power", 0))
	return 0

static func best_upgrade_for(hero: Dictionary) -> Dictionary:
	## 回傳可負擔、比現有強嘅最佳貨；空＝無
	ensure_loaded()
	var best: Dictionary = {}
	var best_gain: int = 0
	for g in _goods:
		var gd: Dictionary = g as Dictionary
		var gid: String = str(gd.get("id", ""))
		var chk: Dictionary = can_buy(gid)
		if not bool(chk.get("ok", false)):
			continue
		var slot: String = str(gd.get("slot", "weapon"))
		var power: int = int(gd.get("power", 0))
		var cur: int = _slot_power(hero, slot)
		var gain: int = power - cur
		if gain > best_gain:
			best_gain = gain
			best = gd.duplicate(true)
	return best

static func auto_buy_for_idle(max_purchases: int = 3) -> Dictionary:
	## 在村閒置俠客自動買更強裝；回傳 { bought, spent, details }
	if not forge_ready():
		return {"bought": 0, "spent": 0, "details": [], "reason": "鐵匠鋪未開"}
	var bought: int = 0
	var spent: int = 0
	var details: Array = []
	for h in GameState.heroes:
		if bought >= max_purchases:
			break
		var hd: Dictionary = h as Dictionary
		if str(hd.get("status", "idle")) != "idle":
			continue
		var hid: String = str(hd.get("id", ""))
		var good: Dictionary = best_upgrade_for(hd)
		if good.is_empty():
			continue
		var cost: int = int(good.get("cost_silver", 0))
		var res: Dictionary = buy_for_hero(str(good.get("id", "")), hid)
		if bool(res.get("ok", false)):
			bought += 1
			spent += cost
			details.append({
				"hero_id": hid,
				"good_id": str(good.get("id", "")),
				"name": str(good.get("name", "")),
			})
			## refresh hero snapshot for next comparison in loop — GameState already mutated
	return {"bought": bought, "spent": spent, "details": details, "reason": ""}
