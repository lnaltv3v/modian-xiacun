extends Node
const _LootText = preload("res://scripts/ui/LootText.gd")
## headless 煙測 v0.9.2：掉落文案／教學第④步／村景 brief
## godot --headless --path . res://scenes/dev/smoke_v092.tscn

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var errors: PackedStringArray = PackedStringArray()

	SaveManager.clear_save()
	GameState._load_starter_data()

	## --- LootText richness ---
	var sample := {
		"silver": 12,
		"fur": 3,
		"wood": 1,
		"iron": 2,
		"success": true,
		"flavor": "試刀得勝。",
		"enemies": [
			{"kind": "wolf", "name": "野狼"},
			{"kind": "bandit", "name": "山賊"},
		],
		"injured": [],
		"bounty_bonus": {"hits": 1, "target_name": "灰狼王", "silver": 5, "fur": 1, "iron": 0},
	}
	var txt: String = _LootText.format_summary(sample)
	if not txt.contains("戰利品"):
		ok = false
		errors.append("LootText missing 戰利品")
	if not txt.contains("拾獲筆記"):
		ok = false
		errors.append("LootText missing 拾獲筆記")
	if not txt.contains("懸賞"):
		ok = false
		errors.append("LootText missing 懸賞")
	if not txt.contains("全員無大礙"):
		ok = false
		errors.append("LootText missing 全員無大礙")
	var empty_loot: String = _LootText.format_loot_block({"silver": 0, "fur": 0, "wood": 0, "iron": 0})
	if not empty_loot.contains("兩手空空"):
		ok = false
		errors.append("empty loot flavor missing")

	## --- Tutorial step 4 persist ---
	GameState.tutorial_step = 4
	if not SaveManager.save_game():
		ok = false
		errors.append("save failed")
	GameState.tutorial_step = 99
	if not SaveManager.load_game():
		ok = false
		errors.append("load failed")
	if GameState.tutorial_step != 4:
		ok = false
		errors.append("tutorial_step 4 not persisted got %d" % GameState.tutorial_step)

	## --- BRIEF village v2 exists ---
	var brief := "res://tools/BRIEF_village_v2.md"
	if not FileAccess.file_exists(brief):
		## FileAccess on res:// tools may work; also check absolute
		var abs_path := ProjectSettings.globalize_path(brief)
		if not FileAccess.file_exists(abs_path) and not FileAccess.file_exists("res://tools/BRIEF_village_v2.md"):
			## fallback: DirAccess
			if not FileAccess.open("res://tools/BRIEF_village_v2.md", FileAccess.READ):
				ok = false
				errors.append("missing BRIEF_village_v2.md")

	var f := FileAccess.open("res://tools/BRIEF_village_v2.md", FileAccess.READ)
	if f == null:
		ok = false
		errors.append("cannot read BRIEF_village_v2.md")
	else:
		var body: String = f.get_as_text()
		if not body.contains("960×540") and not body.contains("960x540"):
			ok = false
			errors.append("BRIEF missing 960 size")
		if not body.contains("可建"):
			ok = false
			errors.append("BRIEF missing 可建")
		if not body.contains("陰影"):
			ok = false
			errors.append("BRIEF missing 陰影")


	## --- Zone battle backgrounds ---
	for zk in ["hills", "mire", "crypt", "outpost"]:
		var zp: String = ArtPaths.zone_bg(zk)
		if not ResourceLoader.exists(zp):
			ok = false
			errors.append("missing zone bg %s" % zp)
		for layer in ["sky", "mid", "ground", "props"]:
			var lp: String = ArtPaths.zone_bg_layer(zk, layer)
			if not ResourceLoader.exists(lp):
				ok = false
				errors.append("missing zone layer %s" % lp)
	if ArtPaths.zone_bg_key_for("luan_shan_po", "hunt") != "hills":
		ok = false
		errors.append("luan_shan_po bg key")
	if ArtPaths.zone_bg_key_for("du_zhao", "hunt") != "mire":
		ok = false
		errors.append("du_zhao bg key")
	if ArtPaths.zone_bg_key_for("", "dungeon") != "crypt":
		ok = false
		errors.append("dungeon bg key")
	if ArtPaths.zone_bg_key_for("", "outpost") != "outpost":
		ok = false
		errors.append("outpost bg key")

	## --- Village buildable rect ---
	var layout_txt := FileAccess.get_file_as_string("res://data/buildings/layout.json")
	if not layout_txt.contains("buildable_rect"):
		ok = false
		errors.append("layout missing buildable_rect")
	if not layout_txt.contains("village_v2"):
		ok = false
		errors.append("layout missing village_v2 art_revision")

	## --- Title / version sanity via main script string (file read) ---
	var main_src := FileAccess.get_file_as_string("res://scenes/main/main.gd")
	if not main_src.contains("v0.9.2"):
		ok = false
		errors.append("main.gd not bumped to v0.9.2")
	if not main_src.contains("tutorial_step == 4"):
		ok = false
		errors.append("main.gd missing tutorial step 4 hooks")

	if ok:
		print("SMOKE_V092_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_V092_FAIL")
		for e in errors:
			print(" - ", e)
		get_tree().quit(1)
