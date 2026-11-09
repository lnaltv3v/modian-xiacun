extends RefCounted
## Shared helpers for headless smoke scripts (version pins, etc.)

static func main_src() -> String:
	return FileAccess.get_file_as_string("res://scenes/main/main.gd")


static func version_at_least(src: String, min_major: int, min_minor: int, min_patch: int) -> bool:
	## Accept current HEAD title when it is this smoke's version or newer.
	var re := RegEx.new()
	var err: int = re.compile("v(\\d+)\\.(\\d+)\\.(\\d+)")
	if err != OK:
		return false
	var m: RegExMatch = re.search(src)
	if m == null:
		return false
	var a: int = int(m.get_string(1))
	var b: int = int(m.get_string(2))
	var c: int = int(m.get_string(3))
	if a != min_major:
		return a > min_major
	if b != min_minor:
		return b > min_minor
	return c >= min_patch


static func main_at_least(min_major: int, min_minor: int, min_patch: int) -> bool:
	return version_at_least(main_src(), min_major, min_minor, min_patch)
