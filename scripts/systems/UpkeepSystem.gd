extends RefCounted
class_name UpkeepSystem
## 獵魔村式食／住／醫：先扣資源，再按建築等級恢復。
## 無建築或資源唔夠 → 唔恢復，出征成功率下跌。

static var _shortage_cd: float = 0.0
static var _bill_acc: float = 0.0

static func advance_shortage_cd(delta: float) -> void:
	_shortage_cd = maxf(0.0, _shortage_cd - delta)

static func tick(delta: float) -> Dictionary:
	if delta <= 0.0:
		return _empty_result()

	var inn_lv: int = BuildingSystem.building_level("inn")
	var manor_lv: int = BuildingSystem.building_level("manor")
	var clinic_lv: int = BuildingSystem.building_level("clinic")
	var has_lodge: bool = inn_lv >= 1 or manor_lv >= 1

	## 每秒費率（每人）
	var hunger_drain: float = maxf(0.15, 0.85 - float(inn_lv) * 0.08)
	var food_restore: float = 0.0 if inn_lv < 1 else (1.2 + float(inn_lv) * 1.1)
	var food_cost_ps: float = 0.0 if inn_lv < 1 else maxf(0.10, 0.40 - float(inn_lv) * 0.03)
	var stam_restore: float = 0.20 + float(manor_lv) * 0.30
	if inn_lv >= 1:
		stam_restore += 1.0 + float(inn_lv) * 0.9
	var lodge_cost_ps: float = 0.0 if not has_lodge else maxf(0.04, 0.16 - float(inn_lv) * 0.012)
	var heal_rate: float = 0.0 if clinic_lv < 1 else (0.55 + float(clinic_lv) * 0.85)
	var med_cost_ps: float = 0.0 if clinic_lv < 1 else maxf(0.08, 0.32 - float(clinic_lv) * 0.025)

	var need_food_n: int = 0
	var need_lodge_n: int = 0
	var need_med_n: int = 0
	for h in GameState.heroes:
		var hd: Dictionary = h as Dictionary
		if str(hd.get("status", "idle")) != "idle":
			continue
		if inn_lv >= 1 and float(hd.get("satiety", 100)) < 99.5:
			need_food_n += 1
		if has_lodge and float(hd.get("stamina", 100)) < float(hd.get("max_stamina", 100)) - 0.01:
			need_lodge_n += 1
		if clinic_lv >= 1 and float(hd.get("injury", 0)) > 0.05:
			need_med_n += 1

	_bill_acc += delta
	var pay_food: int = 0
	var pay_lodge: int = 0
	var pay_med: int = 0
	var serve_food: bool = inn_lv >= 1
	var serve_lodge: bool = has_lodge
	var serve_med: bool = clinic_lv >= 1

	## 每滿 1 秒結一次帳（易讀、易測）
	if _bill_acc >= 1.0:
		var steps: int = int(floor(_bill_acc))
		_bill_acc -= float(steps)
		var upkeep_m: float = AcademySystem.village_effect_mult("upkeep_silver_mult", 1.0)
		var food_due: int = int(ceil(food_cost_ps * float(need_food_n) * float(steps) * upkeep_m))
		var lodge_due: int = int(ceil(lodge_cost_ps * float(need_lodge_n) * float(steps)))
		var med_due: int = int(ceil(med_cost_ps * float(need_med_n) * float(steps) * upkeep_m))

		pay_food = mini(GameState.silver, food_due)
		var silver_left: int = GameState.silver - pay_food
		pay_med = mini(silver_left, med_due)
		pay_lodge = mini(GameState.wood, lodge_due)
		if pay_food + pay_med > 0 or pay_lodge > 0:
			GameState.try_spend(pay_food + pay_med, pay_lodge)

		if food_due > 0 and pay_food < food_due:
			serve_food = false
		if lodge_due > 0 and pay_lodge < lodge_due:
			serve_lodge = false
		if med_due > 0 and pay_med < med_due:
			serve_med = false
		if (food_due > 0 and not serve_food) or (lodge_due > 0 and not serve_lodge) or (med_due > 0 and not serve_med):
			_note_shortage(food_due > 0 and not serve_food, lodge_due > 0 and not serve_lodge, med_due > 0 and not serve_med)

	var fed: int = 0
	var lodged: int = 0
	var healed: int = 0
	var changed: bool = false

	for i in range(GameState.heroes.size()):
		var hd: Dictionary = (GameState.heroes[i] as Dictionary).duplicate(true)
		var status: String = str(hd.get("status", "idle"))
		var before_s: float = float(hd.get("stamina", 100))
		var before_a: float = float(hd.get("satiety", 100))
		var before_i: float = float(hd.get("injury", 0))
		var max_s: float = float(hd.get("max_stamina", 100))

		var drain: float = hunger_drain * delta * (1.35 if status == "hunting" else 1.0)
		hd["satiety"] = clampf(before_a - drain, 0.0, 100.0)

		if status == "idle":
			if serve_food and inn_lv >= 1 and before_a < 99.5:
				hd["satiety"] = clampf(float(hd["satiety"]) + food_restore * delta, 0.0, 100.0)
				fed += 1
			if serve_lodge and has_lodge and before_s < max_s - 0.01:
				hd["stamina"] = clampf(before_s + stam_restore * delta, 0.0, max_s)
				lodged += 1
			elif not has_lodge:
				hd["stamina"] = clampf(before_s + 0.15 * delta, 0.0, max_s)
			if serve_med and clinic_lv >= 1 and before_i > 0.05:
				hd["injury"] = clampf(before_i - heal_rate * delta, 0.0, 100.0)
				healed += 1

		GameState.heroes[i] = HeroSystem.normalize_hero(hd)
		if absf(float(hd.get("stamina", 0)) - before_s) > 0.01 \
				or absf(float(hd.get("satiety", 0)) - before_a) > 0.01 \
				or absf(float(hd.get("injury", 0)) - before_i) > 0.01:
			changed = true

	if changed:
		GameState.heroes_changed.emit()

	return {
		"food_silver": pay_food,
		"lodge_wood": pay_lodge,
		"med_silver": pay_med,
		"fed": fed,
		"lodged": lodged,
		"healed": healed,
	}

static func _empty_result() -> Dictionary:
	return {"food_silver": 0, "lodge_wood": 0, "med_silver": 0, "fed": 0, "lodged": 0, "healed": 0}

static func _note_shortage(food: bool, lodge: bool, med: bool) -> void:
	if _shortage_cd > 0.0:
		return
	var parts: PackedStringArray = PackedStringArray()
	if food:
		parts.append("食（銀）")
	if lodge:
		parts.append("住（木）")
	if med:
		parts.append("醫（銀）")
	if parts.is_empty():
		return
	_shortage_cd = 12.0
	GameState.push_report("食住醫短缺：%s — 恢復暫停，出征成功率會跌。" % "、".join(parts))

static func party_success_chance(hero_ids: Array) -> float:
	if hero_ids.is_empty():
		return 0.5
	var sum: float = 0.0
	var n: int = 0
	for hid_v in hero_ids:
		var h: Dictionary = HeroSystem.get_hero(str(hid_v))
		if h.is_empty():
			continue
		var sat: float = clampf(float(h.get("satiety", 100)) / 100.0, 0.0, 1.0)
		var inj: float = clampf(float(h.get("injury", 0)) / 100.0, 0.0, 1.0)
		var stam: float = clampf(float(h.get("stamina", 100)) / maxf(1.0, float(h.get("max_stamina", 100))), 0.0, 1.0)
		sum += sat * 0.50 + (1.0 - inj) * 0.35 + stam * 0.15
		sum += AcademySystem.passive_success_bonus(h)
		n += 1
	if n <= 0:
		return 0.5
	return clampf(sum / float(n), 0.35, 1.0)

static func describe_rates() -> String:
	var inn: int = BuildingSystem.building_level("inn")
	var clinic: int = BuildingSystem.building_level("clinic")
	var manor: int = BuildingSystem.building_level("manor")
	var lodge_lv: int = maxi(inn, 1 if manor >= 1 else 0)
	return "食客棧%d 住%d 醫館%d" % [inn, lodge_lv, clinic]

static func describe_status() -> String:
	## HUD 用：食住醫等級＋短缺提示
	var base: String = describe_rates()
	var inn: int = BuildingSystem.building_level("inn")
	var clinic: int = BuildingSystem.building_level("clinic")
	var tips: PackedStringArray = PackedStringArray()
	if inn < 1:
		tips.append("未建客棧＝唔供飯")
	if clinic < 1:
		tips.append("未建醫館＝難療傷")
	if GameState.silver < 5 and inn >= 1:
		tips.append("銀緊＝食停")
	if GameState.wood < 3 and inn >= 1:
		tips.append("木緊＝住停")
	if tips.is_empty():
		return base + " · 循環正常"
	return base + " · " + "／".join(tips)

static func panel_snapshot() -> Dictionary:
	## 村莊維護面板用結構化狀態
	var inn: int = BuildingSystem.building_level("inn")
	var manor: int = BuildingSystem.building_level("manor")
	var clinic: int = BuildingSystem.building_level("clinic")
	var has_lodge: bool = inn >= 1 or manor >= 1
	var need_food: int = 0
	var need_lodge: int = 0
	var need_med: int = 0
	var idle_n: int = 0
	for h in GameState.heroes:
		var hd: Dictionary = h as Dictionary
		if str(hd.get("status", "idle")) != "idle":
			continue
		idle_n += 1
		if inn >= 1 and float(hd.get("satiety", 100)) < 99.5:
			need_food += 1
		if has_lodge and float(hd.get("stamina", 100)) < float(hd.get("max_stamina", 100)) - 0.01:
			need_lodge += 1
		if clinic >= 1 and float(hd.get("injury", 0)) > 0.05:
			need_med += 1
	var food_cost_ps: float = 0.0 if inn < 1 else maxf(0.10, 0.40 - float(inn) * 0.03)
	var lodge_cost_ps: float = 0.0 if not has_lodge else maxf(0.04, 0.16 - float(inn) * 0.012)
	var med_cost_ps: float = 0.0 if clinic < 1 else maxf(0.08, 0.32 - float(clinic) * 0.025)
	var food_ok: bool = inn >= 1 and (need_food <= 0 or GameState.silver >= 1)
	var lodge_ok: bool = has_lodge and (need_lodge <= 0 or GameState.wood >= 1)
	var med_ok: bool = clinic >= 1 and (need_med <= 0 or GameState.silver >= 1)
	if inn < 1:
		food_ok = false
	if not has_lodge:
		lodge_ok = false
	if clinic < 1:
		med_ok = false
	## 短缺紅點：有需求但資源／建築唔夠
	var food_alert: bool = (inn < 1) or (need_food > 0 and GameState.silver < maxi(1, int(ceil(food_cost_ps * float(need_food)))))
	var lodge_alert: bool = (not has_lodge) or (need_lodge > 0 and GameState.wood < maxi(1, int(ceil(lodge_cost_ps * float(need_lodge)))))
	var med_alert: bool = (clinic < 1 and _any_injured()) or (need_med > 0 and GameState.silver < maxi(1, int(ceil(med_cost_ps * float(need_med)))))
	return {
		"inn_lv": inn,
		"manor_lv": manor,
		"clinic_lv": clinic,
		"idle": idle_n,
		"need_food": need_food,
		"need_lodge": need_lodge,
		"need_med": need_med,
		"food_cost_ps": food_cost_ps * float(maxi(need_food, 0)),
		"lodge_cost_ps": lodge_cost_ps * float(maxi(need_lodge, 0)),
		"med_cost_ps": med_cost_ps * float(maxi(need_med, 0)),
		"food_ok": food_ok and not food_alert,
		"lodge_ok": lodge_ok and not lodge_alert,
		"med_ok": med_ok and not med_alert,
		"food_alert": food_alert,
		"lodge_alert": lodge_alert,
		"med_alert": med_alert,
		"has_alert": food_alert or lodge_alert or med_alert,
		"status_line": describe_status(),
	}


static func _any_injured() -> bool:
	for h in GameState.heroes:
		if float((h as Dictionary).get("injury", 0)) > 0.5:
			return true
	return false


static func describe_panel() -> String:
	## 獨立「村莊維護」卡文案
	var s: Dictionary = panel_snapshot()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("【村莊維護】食／住／醫")
	lines.append("在村閒置 %d 人　｜　%s" % [int(s.get("idle", 0)), str(s.get("status_line", ""))])
	var food_mark: String = "⚠" if bool(s.get("food_alert", false)) else ("✓" if int(s.get("inn_lv", 0)) >= 1 else "·")
	var lodge_mark: String = "⚠" if bool(s.get("lodge_alert", false)) else ("✓" if int(s.get("inn_lv", 0)) >= 1 or int(s.get("manor_lv", 0)) >= 1 else "·")
	var med_mark: String = "⚠" if bool(s.get("med_alert", false)) else ("✓" if int(s.get("clinic_lv", 0)) >= 1 else "·")
	lines.append("%s 食　客棧 Lv%d　缺飯 %d　約 %.1f 銀/秒　銀庫 %d" % [
		food_mark, int(s.get("inn_lv", 0)), int(s.get("need_food", 0)),
		float(s.get("food_cost_ps", 0)), GameState.silver,
	])
	lines.append("%s 住　客棧/府　缺睡 %d　約 %.1f 木/秒　木庫 %d" % [
		lodge_mark, int(s.get("need_lodge", 0)),
		float(s.get("lodge_cost_ps", 0)), GameState.wood,
	])
	lines.append("%s 醫　醫館 Lv%d　療傷 %d　約 %.1f 銀/秒" % [
		med_mark, int(s.get("clinic_lv", 0)), int(s.get("need_med", 0)),
		float(s.get("med_cost_ps", 0)),
	])
	if bool(s.get("has_alert", false)):
		lines.append("紅點：有短缺或未建 — 出征成功率會跌。")
	else:
		lines.append("循環正常：保持銀木庫存，閒置俠會自動恢復。")
	return "\n".join(lines)


static func hero_condition_label(hero: Dictionary) -> String:
	## 單俠狀態短標：成／危／疲
	if hero.is_empty():
		return ""
	var chance: float = party_success_chance([str(hero.get("id", ""))])
	var pct: int = int(round(chance * 100.0))
	var sat: float = float(hero.get("satiety", 100))
	var inj: float = float(hero.get("injury", 0))
	var stam: float = float(hero.get("stamina", 100))
	var tag := "穩"
	if inj >= 35.0 or sat < 35.0 or stam < 25.0:
		tag = "危"
	elif inj >= 15.0 or sat < 55.0 or stam < 45.0:
		tag = "疲"
	return "%s%d%%" % [tag, pct]
