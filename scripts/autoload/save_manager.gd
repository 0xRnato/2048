extends Node

## Versioned, crash-safe save file at `user://save.cfg`. Atomic writes via
## `save.cfg.tmp` + `rename`. Exposes typed getters/setters for every known key
## in the schema defined in `DESIGN.md` (`prefs/*`, `best/*`, `stats/*`,
## `achievements/<id>`, `daily/<YYYYMMDD>`, `in_progress/*`).
##
## Migration: `meta/version` is bumped on schema changes; `_migrate(from, to)` runs
## before reads so older save files are silently upgraded.

const SAVE_PATH: String = "user://save.cfg"
const TMP_PATH: String = "user://save.cfg.tmp"
const SCHEMA_VERSION: int = 1

const DEFAULT_PREFS: Dictionary = {
	"theme": "dark",
	"mode": "classic",
	"lang": "",            # empty = use OS locale
	"sound_volume": 0.8,
	"music_volume": 0.6,
	"haptics_enabled": true,
	"tutorial_seen": false,
}

var _cfg: ConfigFile = ConfigFile.new()

func _ready() -> void:
	load_from_disk()

# ---------------------------------------------------------------------------
# Disk
# ---------------------------------------------------------------------------

func load_from_disk() -> void:
	_cfg = ConfigFile.new()
	if not FileAccess.file_exists(SAVE_PATH):
		_cfg.set_value("meta", "version", SCHEMA_VERSION)
		flush()
		return
	var err: int = _cfg.load(SAVE_PATH)
	if err != OK:
		push_warning("SaveManager: failed to load %s (err=%d); starting fresh" % [SAVE_PATH, err])
		_cfg = ConfigFile.new()
		_cfg.set_value("meta", "version", SCHEMA_VERSION)
		return
	var stored: int = int(_cfg.get_value("meta", "version", 0))
	if stored < SCHEMA_VERSION:
		_migrate(stored, SCHEMA_VERSION)

func flush() -> void:
	var err: int = _cfg.save(TMP_PATH)
	if err != OK:
		push_warning("SaveManager: temp write failed (%d)" % err)
		return
	var src: String = ProjectSettings.globalize_path(TMP_PATH)
	var dst: String = ProjectSettings.globalize_path(SAVE_PATH)
	var da: DirAccess = DirAccess.open(src.get_base_dir())
	if da != null:
		if FileAccess.file_exists(SAVE_PATH):
			da.remove(SAVE_PATH)
		da.rename(TMP_PATH, SAVE_PATH)
	else:
		# Fallback: overwrite directly.
		_cfg.save(SAVE_PATH)
		if FileAccess.file_exists(TMP_PATH):
			DirAccess.remove_absolute(src)

# ---------------------------------------------------------------------------
# Typed accessors
# ---------------------------------------------------------------------------

func get_pref(key: String) -> Variant:
	return _cfg.get_value("prefs", key, DEFAULT_PREFS.get(key))

func set_pref(key: String, value: Variant) -> void:
	_cfg.set_value("prefs", key, value)
	flush()

func get_best(mode_key: String) -> int:
	return int(_cfg.get_value("best", mode_key, 0))

func set_best(mode_key: String, score: int) -> void:
	_cfg.set_value("best", mode_key, score)
	flush()

func get_stat(key: String) -> int:
	return int(_cfg.get_value("stats", key, 0))

func set_stat(key: String, value: int) -> void:
	_cfg.set_value("stats", key, value)
	flush()

func is_achievement_unlocked(id: String) -> bool:
	return _cfg.has_section_key("achievements", id)

func unlock_achievement(id: String) -> bool:
	if is_achievement_unlocked(id):
		return false
	_cfg.set_value("achievements", id, Time.get_unix_time_from_system())
	flush()
	return true

func get_daily(yyyymmdd: String, field: String, default: Variant = 0) -> Variant:
	return _cfg.get_value("daily", "%s_%s" % [yyyymmdd, field], default)

func set_daily(yyyymmdd: String, field: String, value: Variant) -> void:
	_cfg.set_value("daily", "%s_%s" % [yyyymmdd, field], value)
	flush()

# --- In-progress game ---

func has_in_progress() -> bool:
	return _cfg.has_section("in_progress")

func save_in_progress(mode: int, board_data: Dictionary, score: int, elapsed_seconds: int) -> void:
	_cfg.set_value("in_progress", "mode", mode)
	_cfg.set_value("in_progress", "board", board_data)
	_cfg.set_value("in_progress", "score", score)
	_cfg.set_value("in_progress", "elapsed_seconds", elapsed_seconds)
	flush()

func load_in_progress() -> Dictionary:
	if not has_in_progress():
		return {}
	return {
		"mode": int(_cfg.get_value("in_progress", "mode", 0)),
		"board": _cfg.get_value("in_progress", "board", {}),
		"score": int(_cfg.get_value("in_progress", "score", 0)),
		"elapsed_seconds": int(_cfg.get_value("in_progress", "elapsed_seconds", 0)),
	}

func clear_in_progress() -> void:
	if _cfg.has_section("in_progress"):
		_cfg.erase_section("in_progress")
		flush()

func reset_all() -> void:
	_cfg = ConfigFile.new()
	_cfg.set_value("meta", "version", SCHEMA_VERSION)
	flush()

# ---------------------------------------------------------------------------
# Migration
# ---------------------------------------------------------------------------

func _migrate(from_version: int, to_version: int) -> void:
	# Placeholder — no migrations needed yet. Future schema bumps land here.
	print("[SaveManager] migrating save %d → %d" % [from_version, to_version])
	_cfg.set_value("meta", "version", to_version)
	flush()
