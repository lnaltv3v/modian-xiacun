extends Node
class_name DispatchSystem
## 派遣出征／回村（倒數、離線結算、自動再出征、戰鬥結果模擬）

signal hunt_started(hunt: Dictionary)
signal hunt_finished(rewards: Dictionary)
signal hunt_tick

const DEFAULT_ZONE := "luan_shan_po"

var _rng := RandomNumberGenerator.new()
var _ui_tick_accum: float = 0.0
var _recover_accum: float = 0.0
var _recover_pending: float = 0.0
var _shop_accum: float = 0.0
var _warehouse_accum: float = 0.0

func _ready() -> void:
	_rng.randomize()
	set_process(true)
	call_deferred("resolve_due_hunts")

func _process(delta: float) -> void:
	_recover_pending += delta
	_recover_accum += delta
	UpkeepSystem.advance_shortage_cd(delta)
	if _recover_accum >= 0.5:
		UpkeepSystem.tick(_recover_pending)
		TrainingSystem.tick(_recover_pending)
		_shop_accum += _recover_pending
		if GameState.auto_shop and _shop_accum >= 2.0:
			_shop_accum = 0.0
			ShopSystem.auto_buy_for_idle(1)
		_warehouse_accum += _recover_pending
		if _warehouse_accum >= 4.0:
			_warehouse_accum = 0.0
			if CraftSystem.warehouse_ready() and GameState.fur >= 5:
				CraftSystem.auto_sell_fur(2)
		_recover_pending = 0.0
		_recover_accum = 0.0
	resolve_due_hunts()
	if GameState.auto_dispatch:
		_try_auto_dispatch()
	_ui_tick_accum += delta
	if _ui_tick_accum >= 0.25:
		_ui_tick_accum = 0.0
		hunt_tick.emit()

func resolve_due_hunts() -> void:
	if GameState.active_hunts.is_empty():
		return
	var now: float = Time.get_unix_time_from_system()
	var remain: Array = []
	var finished_any: bool = false
	for hunt_v in GameState.active_hunts:
		var hunt: Dictionary = hunt_v as Dictionary
		if float(hunt.get("return_at", now + 9999.0)) <= now:
			_complete_hunt(hunt)
			finished_any = true
		else:
			remain.append(hunt)
	if finished_any:
		GameState.active_hunts = remain
		GameState.hunts_changed.emit()

func start_hunt(hero_ids: Array, zone_id: String = DEFAULT_ZONE) -> Dictionary:
	if hero_ids.is_empty():
		return {"ok": false, "reason": "未揀俠客"}
	var zone: Dictionary = GameState.get_zone(zone_id)
	if zone.is_empty():
		return {"ok": false, "reason": "未知獵場"}
	if BuildingSystem.building_level("bounty") < 1:
		return {"ok": false, "reason": "懸賞榜未啟用"}
	var need_bounty: int = int(zone.get("unlock_bounty_level", 1))
	if BuildingSystem.building_level("bounty") < need_bounty:
		return {"ok": false, "reason": "%s 要懸賞榜 Lv.%d" % [str(zone.get("name", zone_id)), need_bounty]}

	var valid_ids: Array = []
	for hid_v in hero_ids:
		var hid: String = str(hid_v)
		var hero: Dictionary = HeroSystem.get_hero(hid)
		if hero.is_empty():
			return {"ok": false, "reason": "俠客不存在：%s" % hid}
		if not HeroSystem.can_hunt(hero):
			return {"ok": false, "reason": "%s 而家派唔到（狀態／體力／傷勢）" % str(hero.get("name", hid))}
		valid_ids.append(hid)

	var now: float = Time.get_unix_time_from_system()
	var duration: float = float(zone.get("duration_sec", 8))
	var hunt: Dictionary = {
		"id": GameState.next_hunt_id(),
		"zone_id": zone_id,
		"zone_name": str(zone.get("name", zone_id)),
		"hero_ids": valid_ids.duplicate(),
		"started_at": now,
		"return_at": now + duration,
		"duration": duration,
	}
	for hid2 in valid_ids:
		HeroSystem.set_status(str(hid2), "hunting")
	GameState.active_hunts.append(hunt)
	GameState.hunts_changed.emit()
	var names: PackedStringArray = PackedStringArray()
	for hid3 in valid_ids:
		names.append(str(HeroSystem.get_hero(str(hid3)).get("name", hid3)))
	GameState.push_report("出征「%s」：%s（約 %.0f 秒）" % [
		str(hunt["zone_name"]), "、".join(names), duration
	])
	hunt_started.emit(hunt)
	return {"ok": true, "reason": "", "hunt": hunt}

func dispatch_ready(count: int = 1, zone_id: String = DEFAULT_ZONE) -> Dictionary:
	var ready: Array = HeroSystem.find_ready_heroes(count)
	var ids: Array = []
	for h in ready:
		ids.append(str((h as Dictionary).get("id", "")))
	return start_hunt(ids, zone_id)

func seconds_left(hunt: Dictionary) -> float:
	var now: float = Time.get_unix_time_from_system()
	return maxf(0.0, float(hunt.get("return_at", now)) - now)

func _pick_enemies(zone: Dictionary, party_size: int) -> Array:
	var pool: Array = zone.get("enemies", []) as Array
	if pool.is_empty():
		pool = [
			{"kind": "wolf", "weight": 50, "name": "野狼"},
			{"kind": "boar", "weight": 30, "name": "野豬"},
			{"kind": "bandit", "weight": 20, "name": "山賊"},
		]
	var amin: int = int(zone.get("enemy_count_min", 1))
	var amax: int = int(zone.get("enemy_count_max", 3))
	var count: int = clampi(_rng.randi_range(amin, amax), 1, maxi(1, party_size + 1))
	var total_w: int = 0
	for e in pool:
		total_w += int((e as Dictionary).get("weight", 1))
	var out: Array = []
	for _i in range(count):
		var roll: int = _rng.randi_range(1, maxi(1, total_w))
		var acc: int = 0
		var chosen: Dictionary = pool[0] as Dictionary
		for e2 in pool:
			acc += int((e2 as Dictionary).get("weight", 1))
			if roll <= acc:
				chosen = e2 as Dictionary
				break
		out.append({
			"kind": str(chosen.get("kind", "wolf")),
			"name": str(chosen.get("name", chosen.get("kind", "敵"))),
		})
	return out

func _complete_hunt(hunt: Dictionary) -> void:
	var zone_id: String = str(hunt.get("zone_id", DEFAULT_ZONE))
	var zone: Dictionary = GameState.get_zone(zone_id)
	var hero_ids: Array = hunt.get("hero_ids", []) as Array
	var total_power: int = 0
	var injured_names: PackedStringArray = PackedStringArray()

	var stamina_cost: float = float(zone.get("stamina_cost", 18))
	var satiety_cost: float = float(zone.get("satiety_cost", 12))
	var injury_chance: float = float(zone.get("injury_chance", 0.15))
	var injury_amount: float = float(zone.get("injury_amount", 8))
	var power_bonus_per: float = float(zone.get("power_bonus_per", 0.35))

	for hid_v in hero_ids:
		var hid: String = str(hid_v)
		var hero: Dictionary = HeroSystem.get_hero(hid)
		if hero.is_empty():
			continue
		total_power += HeroSystem.power_of(hero)
		var got_hurt: bool = _rng.randf() < injury_chance
		HeroSystem.mutate(hid, func(hd: Dictionary) -> void:
			hd["status"] = "idle"
			hd["stamina"] = maxf(0.0, float(hd.get("stamina", 100)) - stamina_cost)
			hd["satiety"] = maxf(0.0, float(hd.get("satiety", 100)) - satiety_cost)
			if got_hurt:
				hd["injury"] = clampf(float(hd.get("injury", 0)) + injury_amount, 0.0, 100.0)
		)
		if got_hurt:
			injured_names.append(str(hero.get("name", hid)))

	var enemies: Array = _pick_enemies(zone, maxi(1, hero_ids.size()))
	var success_chance: float = UpkeepSystem.party_success_chance(hero_ids)
	var success: bool = _rng.randf() <= success_chance
	var mult: float = ResourceLoop.bounty_reward_mult()
	var n: int = maxi(1, hero_ids.size())
	var silver_gain: int = int(round((float(zone.get("base_silver", 10)) + float(total_power) * power_bonus_per) * mult))
	var fur_gain: int = int(round(float(zone.get("base_fur", 1)) * float(n) * mult))
	var wood_gain: int = int(round(float(zone.get("base_wood", 0)) * mult))
	var iron_gain: int = int(round(float(zone.get("base_iron", 0)) * mult))
	## 山賊較易掉鐵；野豬多毛皮
	for ev in enemies:
		var kind: String = str((ev as Dictionary).get("kind", ""))
		if kind == "bandit" and _rng.randf() < 0.55:
			iron_gain += 1
		if kind == "boar":
			fur_gain += 1
		if kind == "wolf" and _rng.randf() < 0.35:
			fur_gain += 1
		if kind == "snake":
			fur_gain += 1  ## 毒囊近似毛皮
			if _rng.randf() < 0.4:
				iron_gain += 1
		if kind == "python":
			fur_gain += 2
			if _rng.randf() < 0.55:
				iron_gain += 1

	## 懸賞目標額外賞
	var bounty_bonus: Dictionary = BountySystem.calc_bonus(enemies)
	if int(bounty_bonus.get("hits", 0)) > 0:
		silver_gain += int(bounty_bonus.get("silver", 0))
		fur_gain += int(bounty_bonus.get("fur", 0))
		iron_gain += int(bounty_bonus.get("iron", 0))

	var enemy_names: PackedStringArray = PackedStringArray()
	for ev2 in enemies:
		enemy_names.append(str((ev2 as Dictionary).get("name", "")))

	if not success:
		## 失敗：收益大幅縮水，額外受傷風險
		silver_gain = maxi(0, int(round(float(silver_gain) * 0.30)))
		fur_gain = maxi(0, int(round(float(fur_gain) * 0.25)))
		wood_gain = maxi(0, int(round(float(wood_gain) * 0.25)))
		iron_gain = maxi(0, int(round(float(iron_gain) * 0.20)))
		for hid_f in hero_ids:
			if _rng.randf() < 0.45:
				HeroSystem.mutate(str(hid_f), func(hd: Dictionary) -> void:
					hd["injury"] = clampf(float(hd.get("injury", 0)) + 10.0, 0.0, 100.0)
				)
				var hn: String = str(HeroSystem.get_hero(str(hid_f)).get("name", hid_f))
				var already: bool = false
				for existing in injured_names:
					if str(existing) == hn:
						already = true
						break
				if not already:
					injured_names.append(hn)
	else:
		silver_gain = maxi(1, silver_gain)
		fur_gain = maxi(0, fur_gain)

	GameState.add_silver(silver_gain)
	GameState.add_fur(fur_gain)
	if wood_gain > 0:
		GameState.add_wood(wood_gain)
	if iron_gain > 0:
		GameState.add_iron(iron_gain)

	## 成功額外練功 XP
	if success:
		for hid_x in hero_ids:
			HeroSystem.mutate(str(hid_x), func(hd: Dictionary) -> void:
				var add_xp: float = 8.0 + float(BuildingSystem.building_level("training")) * 4.0
				var lv: int = int(hd.get("level", 1))
				var xp: float = float(hd.get("xp", 0)) + add_xp
				var need: float = float(TrainingSystem.xp_to_next(lv))
				while xp >= need and lv < 30:
					xp -= need
					lv += 1
					need = float(TrainingSystem.xp_to_next(lv))
				hd["level"] = lv
				hd["xp"] = xp
				hd["xp_to_next"] = int(need)
			)

	var flavor: String
	if success:
		flavor = "擊退「%s」！（成功率 %.0f%%）" % ["、".join(enemy_names), success_chance * 100.0]
	else:
		flavor = "不敵「%s」，狼狽撤回。（成功率僅 %.0f%%）" % ["、".join(enemy_names), success_chance * 100.0]

	var rewards: Dictionary = {
		"silver": silver_gain,
		"fur": fur_gain,
		"wood": wood_gain,
		"iron": iron_gain,
		"heroes": hero_ids.duplicate(),
		"zone_id": zone_id,
		"zone_name": str(hunt.get("zone_name", zone_id)),
		"injured": injured_names,
		"enemies": enemies,
		"success": success,
		"success_chance": success_chance,
		"flavor": flavor,
		"bounty_bonus": bounty_bonus,
	}
	var injure_txt: String = ""
	if injured_names.size() > 0:
		injure_txt = "；受傷：%s" % "、".join(injured_names)
	var iron_txt: String = (" 鐵%d" % iron_gain) if iron_gain > 0 else ""
	var result_word: String = "得勝" if success else "失利"
	var bounty_txt: String = ""
	if int(bounty_bonus.get("hits", 0)) > 0:
		bounty_txt = "；懸賞「%s」×%d" % [str(bounty_bonus.get("target_name", "")), int(bounty_bonus.get("hits", 0))]
	GameState.push_report("回村「%s」%s vs %s ＋銀%d 毛皮%d 木%d%s%s%s" % [
		str(rewards["zone_name"]), result_word, "、".join(enemy_names), silver_gain, fur_gain, wood_gain, iron_txt, injure_txt, bounty_txt
	])
	hunt_finished.emit(rewards)

func _try_auto_dispatch() -> void:
	if not GameState.active_hunts.is_empty():
		if GameState.active_hunts.size() >= 2:
			return
	var ready: Array = HeroSystem.find_ready_heroes(2)
	if ready.is_empty():
		return
	var ids: Array = []
	for h in ready:
		ids.append(str((h as Dictionary).get("id", "")))
	var zid: String = GameState.selected_zone if GameState.selected_zone != "" else DEFAULT_ZONE
	start_hunt(ids, zid)
