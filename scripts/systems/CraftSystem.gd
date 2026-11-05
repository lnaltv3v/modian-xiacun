extends RefCounted
class_name CraftSystem
## 貨棧／鐵匠／醫館製作鏈（最小版）

const RECIPES_PATH := "res://data/crafts/recipes.json"

static var _recipes: Array = []
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_recipes.clear()
	if not FileAccess.file_exists(RECIPES_PATH):
		push_warning("CraftSystem: missing %s" % RECIPES_PATH)
		_loaded = true
		return
	var f := FileAccess.open(RECIPES_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_recipes = (parsed as Array).duplicate(true)
	_loaded = true

static func all_recipes() -> Array:
	ensure_loaded()
	return _recipes.duplicate(true)

static func get_recipe(recipe_id: String) -> Dictionary:
	ensure_loaded()
	for r in _recipes:
		var rd: Dictionary = r as Dictionary
		if str(rd.get("id", "")) == recipe_id:
			return rd.duplicate(true)
	return {}

static func can_craft(recipe_id: String) -> Dictionary:
	## { ok, reason }
	var recipe: Dictionary = get_recipe(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "reason": "未知配方"}
	var bid: String = str(recipe.get("require_building", ""))
	var need_lv: int = int(recipe.get("require_level", 1))
	if bid != "" and BuildingSystem.building_level(bid) < need_lv:
		return {"ok": false, "reason": "%s 未達 Lv.%d" % [BuildingSystem.building_name(bid) if bid != "" else bid, need_lv]}
	var cost: Dictionary = recipe.get("cost", {}) as Dictionary
	var cs: int = int(cost.get("silver", 0))
	var cw: int = int(cost.get("wood", 0))
	var cf: int = int(cost.get("fur", 0))
	var ci: int = int(cost.get("iron", 0))
	if GameState.silver < cs or GameState.wood < cw or GameState.fur < cf or GameState.iron < ci:
		return {"ok": false, "reason": "材料唔夠"}
	return {"ok": true, "reason": ""}

static func craft(recipe_id: String, hero_id: String = "") -> Dictionary:
	## 回傳 { ok, reason, crafted }
	var check: Dictionary = can_craft(recipe_id)
	if not bool(check.get("ok", false)):
		return {"ok": false, "reason": str(check.get("reason", "")), "crafted": {}}
	var recipe: Dictionary = get_recipe(recipe_id)
	var cost: Dictionary = recipe.get("cost", {}) as Dictionary
	if not GameState.try_spend(
		int(cost.get("silver", 0)),
		int(cost.get("wood", 0)),
		int(cost.get("fur", 0)),
		int(cost.get("iron", 0))
	):
		return {"ok": false, "reason": "扣材料失敗", "crafted": {}}

	var result: Dictionary = recipe.get("result", {}) as Dictionary
	var kind: String = str(result.get("kind", ""))
	var item_id: String = str(result.get("item_id", recipe_id))
	var name_cn: String = str(recipe.get("name", item_id))
	var crafted: Dictionary = {
		"item_id": item_id,
		"name": name_cn,
		"kind": kind,
		"recipe_id": recipe_id,
	}

	match kind:
		"sell":
			var gain: int = int(result.get("silver", 0))
			GameState.add_silver(gain)
			crafted["silver_gained"] = gain
			GameState.push_report("製作「%s」售出＋銀%d" % [name_cn, gain])
		"consumable":
			## 若指定俠客則即用；否則入背包可稍後用／賣
			if hero_id != "":
				var inj: float = float(result.get("injury", 0))
				HeroSystem.mutate(hero_id, func(hd: Dictionary) -> void:
					hd["injury"] = clampf(float(hd.get("injury", 0)) + inj, 0.0, 100.0)
				)
				crafted["applied_to"] = hero_id
				GameState.push_report("製作「%s」並用於 %s" % [
					name_cn, str(HeroSystem.get_hero(hero_id).get("name", hero_id))
				])
			else:
				GameState.add_inventory_item({
					"id": item_id,
					"name": name_cn,
					"kind": "consumable",
					"injury": float(result.get("injury", 0)),
					"sell_silver": int(result.get("sell_silver", 0)),
				})
				GameState.push_report("製作「%s」入庫" % name_cn)
		"equip":
			var slot: String = str(result.get("slot", "armor"))
			var power: int = int(result.get("power", 0))
			if hero_id != "":
				HeroSystem.equip_item(hero_id, slot, {
					"id": item_id,
					"name": name_cn,
					"power": power,
				})
				crafted["equipped_to"] = hero_id
				GameState.push_report("製作「%s」裝備俾 %s（%s＋%d）" % [
					name_cn,
					str(HeroSystem.get_hero(hero_id).get("name", hero_id)),
					slot,
					power,
				])
			else:
				GameState.add_inventory_item({
					"id": item_id,
					"name": name_cn,
					"kind": "equip",
					"slot": slot,
					"power": power,
				})
				GameState.push_report("製作「%s」入庫" % name_cn)
		_:
			GameState.add_inventory_item({"id": item_id, "name": name_cn, "kind": kind})
			GameState.push_report("製作「%s」" % name_cn)

	return {"ok": true, "reason": "", "crafted": crafted}

static func use_inventory_on_hero(inv_index: int, hero_id: String) -> Dictionary:
	if inv_index < 0 or inv_index >= GameState.inventory.size():
		return {"ok": false, "reason": "冇呢件貨"}
	var item: Dictionary = (GameState.inventory[inv_index] as Dictionary).duplicate(true)
	var kind: String = str(item.get("kind", ""))
	if kind == "consumable":
		var inj: float = float(item.get("injury", 0))
		HeroSystem.mutate(hero_id, func(hd: Dictionary) -> void:
			hd["injury"] = clampf(float(hd.get("injury", 0)) + inj, 0.0, 100.0)
		)
		GameState.remove_inventory_at(inv_index)
		GameState.push_report("用「%s」喺 %s" % [
			str(item.get("name", "")), str(HeroSystem.get_hero(hero_id).get("name", hero_id))
		])
		return {"ok": true, "reason": ""}
	if kind == "equip":
		HeroSystem.equip_item(hero_id, str(item.get("slot", "armor")), {
			"id": str(item.get("id", "")),
			"name": str(item.get("name", "")),
			"power": int(item.get("power", 0)),
		})
		GameState.remove_inventory_at(inv_index)
		return {"ok": true, "reason": ""}
	return {"ok": false, "reason": "唔能用喺俠客"}

static func sell_inventory_at(inv_index: int) -> Dictionary:
	if inv_index < 0 or inv_index >= GameState.inventory.size():
		return {"ok": false, "reason": "冇呢件貨"}
	var item: Dictionary = GameState.inventory[inv_index] as Dictionary
	var gain: int = int(item.get("sell_silver", 0))
	if gain <= 0:
		gain = 5
	GameState.remove_inventory_at(inv_index)
	GameState.add_silver(gain)
	GameState.push_report("賣出「%s」＋銀%d" % [str(item.get("name", "")), gain])
	return {"ok": true, "reason": "", "silver": gain}
