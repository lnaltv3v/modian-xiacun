extends Node
## JSON 存檔骨架 — user://save_slot_0.json

const SAVE_PATH := "user://save_slot_0.json"

func save_game() -> bool:
	var data: Dictionary = {
		"version": 1,
		"saved_at": Time.get_datetime_string_from_system(),
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
	if d.has("state") and d["state"] is Dictionary:
		GameState.load_from_dict(d["state"] as Dictionary)
		return true
	return false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
