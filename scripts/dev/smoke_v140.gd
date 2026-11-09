extends Node
## headless 煙測 v0.14.0：戰鬥手感 hurt／parry／入場／區分層底圖
## godot --headless --path . res://scenes/dev/smoke_v140.tscn

const SmokeUtil = preload("res://scripts/dev/SmokeUtil.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	var main_src := SmokeUtil.main_src()
	if not SmokeUtil.version_at_least(main_src, 0, 14, 0):
		ok = false
		errors.append("main.gd title should be >= v0.14.0")

	## SAVE 維持 14（本版無存檔結構變更）
	if int(GameState.SAVE_VERSION) < 14:
		ok = false
		errors.append("SAVE_VERSION should stay >= 14 got %d" % int(GameState.SAVE_VERSION))
	if int(SaveManager.SAVE_VERSION) < 14:
		ok = false
		errors.append("SaveManager SAVE_VERSION should be >= 14")

	## DamageFloater parry kind
	var df_src := FileAccess.get_file_as_string("res://scripts/ui/DamageFloater.gd")
	if not df_src.contains("\"parry\"") or not df_src.contains("招架"):
		ok = false
		errors.append("DamageFloater missing parry/招架")

	## auto_combat feel hooks
	var ac_src := FileAccess.get_file_as_string("res://scenes/combat/auto_combat.gd")
	for need in [
		"func _tween_entrance",
		"func _after_entrance",
		"func _fx_hurt",
		"func _fx_parry",
		"func _fx_micro_shake",
		"ArenaBg_",
		"zone_bg_layer",
		"\"parry\"",
	]:
		if not ac_src.contains(need):
			ok = false
			errors.append("auto_combat missing %s" % need)

	## 入場唔應拖慢主戰鬥循環過耐（淡入約 0.26s）
	if not ac_src.contains("0.26"):
		ok = false
		errors.append("entrance fade duration marker missing")

	## 微震幅度要細（1～2px 級）
	if not ac_src.contains("Vector2(1.5, -1.0)"):
		ok = false
		errors.append("micro shake amplitude missing")

	## scene loads
	var ac_res: Resource = load("res://scenes/combat/auto_combat.tscn")
	if ac_res == null:
		ok = false
		errors.append("auto_combat.tscn missing")
	else:
		var ac_node: Node = (ac_res as PackedScene).instantiate()
		if ac_node == null or not ac_node.has_method("play"):
			ok = false
			errors.append("auto_combat play() missing")
		else:
			## 掛到樹再 play 短場，確認入場／分層唔報錯
			add_child(ac_node)
			ac_node.call("play", {
				"title": "煙測交鋒",
				"heroes": ["hero_aqing", "orange_yangguo"],
				"enemies": [{"kind": "wolf", "name": "野狼"}],
				"success": true,
				"duration": 3.0,
				"show_summary": false,
				"battle_mode": "hunt",
				"zone_bg": "hills",
				"summary": {},
			})
			## 等入場＋逼近開頭
			await get_tree().create_timer(0.55).timeout
			if not bool(ac_node.call("is_busy")):
				ok = false
				errors.append("auto_combat should be busy during entrance/fight")
			## 確認分層已建
			var arena: Node = ac_node.get_node_or_null("%Arena")
			if arena == null:
				ok = false
				errors.append("Arena missing")
			else:
				var sky: Node = arena.get_node_or_null("ArenaBg_sky")
				var mid: Node = arena.get_node_or_null("ArenaBg_mid")
				var props: Node = arena.get_node_or_null("ArenaBg_props")
				if sky == null or mid == null or props == null:
					ok = false
					errors.append("zone bg layer nodes missing")
				elif not (sky as CanvasItem).visible:
					## hills 應有 sky 層
					var sky_path: String = ArtPaths.zone_bg_layer("hills", "sky")
					if ArtPaths.exists(sky_path):
						ok = false
						errors.append("hills sky layer should be visible when file exists")
			## 等到打完（duration 3 + entrance ~0.3 + approach 0.55 + outro）
			await get_tree().create_timer(4.2).timeout
			if bool(ac_node.call("is_busy")):
				## 再畀少少時間
				await get_tree().create_timer(1.5).timeout
			if bool(ac_node.call("is_busy")):
				ok = false
				errors.append("auto_combat still busy after expected end")
			ac_node.queue_free()

	## 區分層路徑齊
	for zk in ["hills", "mire", "crypt", "outpost"]:
		for layer in ["sky", "mid", "ground", "props"]:
			var p: String = ArtPaths.zone_bg_layer(zk, layer)
			if not ArtPaths.exists(p):
				ok = false
				errors.append("missing zone layer %s" % p)

	if ok:
		print("SMOKE_V140_OK")
	else:
		print("SMOKE_V140_FAIL")
		for e in errors:
			print("  - ", e)
	await get_tree().process_frame
	get_tree().quit(0 if ok else 1)
