extends Node
## JSON 存檔 — user://save_slot_0.json（含版本欄）

const SAVE_PATH := "user://save_slot_0.json"
const BACKUP_PATH := "user://save_slot_0.bak.json"
const BACKUP_PATH_2 := "user://save_slot_0.bak2.json"
const SAVE_VERSION := 14

func save_game() -> bool:
	_rotate_backups()
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

func _rotate_backups() -> void:
	## 現行 → .bak；舊 .bak → .bak2（最多兩份自動備份）
	if not FileAccess.file_exists(SAVE_PATH):
		return
	if FileAccess.file_exists(BACKUP_PATH):
		_copy_user_file(BACKUP_PATH, BACKUP_PATH_2)
	_copy_user_file(SAVE_PATH, BACKUP_PATH)

func _copy_user_file(src: String, dst: String) -> bool:
	var fr: FileAccess = FileAccess.open(src, FileAccess.READ)
	if fr == null:
		return false
	var buf: PackedByteArray = fr.get_buffer(fr.get_length())
	fr = null
	var fw: FileAccess = FileAccess.open(dst, FileAccess.WRITE)
	if fw == null:
		return false
	fw.store_buffer(buf)
	fw.flush()
	fw = null
	return true

func has_backup() -> bool:
	return FileAccess.file_exists(BACKUP_PATH)

func restore_backup() -> bool:
	## 從最近自動備份還原主存檔（測試／救援）
	if not FileAccess.file_exists(BACKUP_PATH):
		return false
	if not _copy_user_file(BACKUP_PATH, SAVE_PATH):
		return false
	return load_game()

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
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)
	if FileAccess.file_exists(BACKUP_PATH_2):
		DirAccess.remove_absolute(BACKUP_PATH_2)
