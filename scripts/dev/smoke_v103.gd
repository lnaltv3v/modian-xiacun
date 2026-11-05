extends Node
## headless 煙測 v0.10.3：Pivot R6 UI drop-in paths／尺寸
## godot --headless --path . res://scenes/dev/smoke_v103.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	var expect := {
		"hud_panel.png": Vector2i(320, 64),
		"btn_dispatch.png": Vector2i(128, 40),
		"btn_build.png": Vector2i(128, 40),
		"icon_silver.png": Vector2i(32, 32),
		"icon_wood.png": Vector2i(32, 32),
		"icon_hide.png": Vector2i(32, 32),
		"icon_iron.png": Vector2i(32, 32),
		"icon_herb.png": Vector2i(32, 32),
	}
	for fn in expect.keys():
		var path: String = ArtPaths.UI_DIR + fn
		if not ArtPaths.exists(path):
			ok = false
			errors.append("missing %s" % path)
			continue
		var tex: Texture2D = ArtPaths.load_tex(path)
		var want: Vector2i = expect[fn]
		if tex == null or tex.get_width() != want.x or tex.get_height() != want.y:
			ok = false
			errors.append("%s size want %s" % [fn, want])

	if ArtPaths.HUD_PANEL != ArtPaths.UI_DIR + "hud_panel.png":
		ok = false
		errors.append("HUD_PANEL path")
	if ArtPaths.BTN_DISPATCH != ArtPaths.UI_DIR + "btn_dispatch.png":
		ok = false
		errors.append("BTN_DISPATCH path")
	if ArtPaths.BTN_BUILD != ArtPaths.UI_DIR + "btn_build.png":
		ok = false
		errors.append("BTN_BUILD path")
	if ArtPaths.ICON_FUR != ArtPaths.UI_DIR + "icon_hide.png":
		ok = false
		errors.append("ICON_FUR should map icon_hide")

	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not ("v0.10.3" in main_src):
		ok = false
		errors.append("main.gd not bumped to v0.10.3")
	if not ("_setup_ui_art" in main_src):
		ok = false
		errors.append("main.gd missing _setup_ui_art")
	if not ("ArtPaths.HUD_PANEL" in main_src and "ArtPaths.BTN_DISPATCH" in main_src and "ArtPaths.BTN_BUILD" in main_src):
		ok = false
		errors.append("main.gd not wiring HUD/BTN constants")

	if ok:
		print("SMOKE_V103_OK")
	else:
		print("SMOKE_V103_FAIL")
		for e in errors:
			print("  - ", e)
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if ok else 1)
