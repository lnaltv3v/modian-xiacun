extends Node
## headless 煙測 v0.19.0：CJK 字體主題＋直向 viewport
## godot --headless --path . res://scenes/dev/smoke_v190.tscn

const SmokeUtil = preload("res://scripts/dev/SmokeUtil.gd")

func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	var main_src := SmokeUtil.main_src()
	if not SmokeUtil.version_at_least(main_src, 0, 19, 0):
		ok = false
		errors.append("main.gd title should be >= v0.19.0")

	var vp := get_viewport().get_visible_rect().size
	print("viewport=", vp)
	if int(vp.x) != 720 or int(vp.y) != 1280:
		ok = false
		errors.append("viewport want 720x1280 got %s" % str(vp))

	if not FileAccess.file_exists("res://assets/fonts/DroidSansFallback.ttf"):
		ok = false
		errors.append("font file missing")

	var theme: Theme = ThemeDB.get_project_theme()
	if theme == null:
		ok = false
		errors.append("project theme missing")
	else:
		var f: Font = theme.default_font
		if f == null:
			ok = false
			errors.append("theme default_font missing")
		else:
			var sample := "墨點俠村繁體簡体"
			var sz: Vector2 = f.get_string_size(sample, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
			print("font_string_size=", sz)
			if sz.x < 80.0:
				ok = false
				errors.append("CJK string too narrow — font likely missing glyphs: %s" % str(sz))
			for ch in sample:
				var adv: float = f.get_string_size(String(ch), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
				if ch.unicode_at(0) > 127 and adv <= 1.0:
					ok = false
					errors.append("glyph missing for %s adv=%s" % [ch, adv])

	var main_ps: PackedScene = load("res://scenes/main/main.tscn")
	if main_ps == null:
		ok = false
		errors.append("main.tscn load fail")
	else:
		var main: Node = main_ps.instantiate()
		add_child(main)
		await get_tree().process_frame
		var title := main.get_node_or_null("%Title") as Label
		if title == null:
			ok = false
			errors.append("title missing")
		else:
			print("title=", title.text)
			if "v0.19" not in title.text:
				ok = false
				errors.append("title missing v0.19: %s" % title.text)
		var vh := main.get_node_or_null("%VillageHost") as Control
		if vh == null:
			ok = false
			errors.append("VillageHost missing")
		else:
			print("village_host=", vh.position, vh.size)
			if vh.size.x < 500.0 or vh.position.y < 100.0:
				ok = false
				errors.append("village host not portrait-ish")
		main.queue_free()

	if ok:
		print("SMOKE_V190_OK")
	else:
		print("SMOKE_V190_FAIL")
		for e in errors:
			print("  - ", e)
	get_tree().quit(0 if ok else 1)
