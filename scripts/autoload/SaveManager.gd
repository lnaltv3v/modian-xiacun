extends Node
## JSON 存檔 — user://save_slot_0.json（含版本欄）

const SAVE_PATH := "user://save_slot_0.json"
const SAVE_VERSION := 7

func save_game() -> bool:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"saved_unix": Time.get_unix_time_from_system(),
		"state": GameState.to_save_dict(),
	}
	var json: String = JSON.stringify(data, "\t")
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write %s" % SAVE_PATH)
		return false
	f.store_string(json)
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed as Dictionary
	var ver: int = int(d.get("version", 0))
	if ver < 1:
		push_warning("SaveManager: unknown save version %d" % ver)
	if d.has("state") and d["state"] is Dictionary:
		GameState.load_from_dict(d["state"] as Dictionary)
		return true
	return false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
