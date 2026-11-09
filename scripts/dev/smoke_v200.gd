extends Node
## headless 煙測 v0.20.0：Noto TC 字體＋世界地圖拖移／遇敵
## godot --headless --path . res://scenes/dev/smoke_v200.tscn

const SmokeUtil = preload("res://scripts/dev/SmokeUtil.gd")

func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	var main_src := SmokeUtil.main_src()
	if not SmokeUtil.version_at_least(main_src, 0, 20, 0):
		ok = false
		errors.append("main.gd title should be >= v0.20.0")

	if not FileAccess.file_exists("res://assets/fonts/NotoSansTC-Regular.otf"):
		ok = false
		errors.append("NotoSansTC-Regular.otf missing")

	var theme: Theme = ThemeDB.get_project_theme()
	if theme == null or theme.default_font == null:
		ok = false
		errors.append("project theme/font missing")
	else:
		var f: Font = theme.default_font
		if f is FontFile:
			var ff := f as FontFile
			if ff.allow_system_fallback:
				ok = false
				errors.append("allow_system_fallback should be false for Web CJK")
		var sample := "墨點俠村繁體中文獵魔村物語出征"
		var sz: Vector2 = f.get_string_size(sample, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		print("font_string_size=", sz)
		if sz.x < 100.0:
			ok = false
			errors.append("CJK string too narrow: %s" % str(sz))
		for ch in sample:
			var adv: float = f.get_string_size(String(ch), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			if ch.unicode_at(0) > 127 and adv <= 1.0:
				ok = false
				errors.append("glyph missing for %s" % ch)

	var map_ps: PackedScene = load("res://scenes/world/world_map.tscn")
	if map_ps == null:
		ok = false
		errors.append("world_map.tscn load fail")
	else:
		var map: Control = map_ps.instantiate()
		add_child(map)
		map.size = Vector2(704, 540)
		await get_tree().process_frame
		await get_tree().process_frame
		if map.has_method("pan_to_zone"):
			map.call("pan_to_zone", "luan_shan_po")
			await get_tree().process_frame
		var world: Node2D = map.get_node_or_null("World") as Node2D
		if world == null:
			ok = false
			errors.append("World node missing")
		else:
			print("world_pos=", world.position, " scale=", world.scale)
			if world.get_child_count() < 3:
				ok = false
				errors.append("world children too few")
		## simulate pan
		if map.has_method("_gui_input"):
			var drag := InputEventMouseButton.new()
			drag.button_index = MOUSE_BUTTON_LEFT
			drag.pressed = true
			drag.position = Vector2(200, 200)
			map._gui_input(drag)
			var mov := InputEventMouseMotion.new()
			mov.position = Vector2(120, 160)
			mov.relative = Vector2(-80, -40)
			map._gui_input(mov)
			await get_tree().process_frame
			print("after_pan world_pos=", world.position if world else Vector2.ZERO)
		## building overlay path via signal exists
		if not map.has_signal("building_clicked"):
			ok = false
			errors.append("building_clicked signal missing")
		if not map.has_signal("encounter_requested"):
			ok = false
			errors.append("encounter_requested signal missing")
		map.queue_free()

	var main_ps: PackedScene = load("res://scenes/main/main.tscn")
	if main_ps == null:
		ok = false
		errors.append("main.tscn load fail")
	else:
		var main: Node = main_ps.instantiate()
		add_child(main)
		await get_tree().process_frame
		await get_tree().process_frame
		var title := main.get_node_or_null("%Title") as Label
		if title == null or "v0.20" not in title.text:
			ok = false
			errors.append("title missing v0.20: %s" % (title.text if title else "null"))
		else:
			print("title=", title.text)
		var vh := main.get_node_or_null("%VillageHost") as Control
		if vh == null or vh.size.y < 400.0:
			ok = false
			errors.append("VillageHost not enlarged for map")
		else:
			print("village_host=", vh.position, vh.size)
		## ensure world map mounted
		var mounted := false
		for c in vh.get_children():
			if str(c.name).begins_with("WorldMap") or c.get_script() != null:
				mounted = true
		if not mounted and vh.get_child_count() < 1:
			ok = false
			errors.append("map not mounted in VillageHost")
		main.queue_free()

	if ok:
		print("SMOKE_V200_OK")
	else:
		print("SMOKE_V200_FAIL")
		for e in errors:
			print("  - ", e)
	get_tree().quit(0 if ok else 1)
