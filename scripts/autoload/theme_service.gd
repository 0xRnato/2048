extends Node

## Loads the 3 `BoardTheme` resources at boot and applies the one stored in
## `prefs/theme`. Exposes `current_theme` and emits `EventBus.theme_changed(id)`
## on every swap. Consumers (`TileView`, `BoardView`, `Hud`) listen and repaint.

const THEME_PATHS: Dictionary = {
	"dark": "res://resources/themes/dark.tres",
	"light": "res://resources/themes/light.tres",
	"colorblind": "res://resources/themes/colorblind.tres",
}

var _themes: Dictionary = {}   ## id → BoardTheme
var current_theme: BoardTheme = null

func _ready() -> void:
	_load_all()
	var saved: String = str(SaveManager.get_pref("theme"))
	apply(saved if _themes.has(saved) else "dark")

func _load_all() -> void:
	for id in THEME_PATHS.keys():
		var path: String = THEME_PATHS[id]
		if ResourceLoader.exists(path):
			_themes[id] = load(path)
		elif OS.is_debug_build():
			print("[ThemeService] theme resource missing: %s" % path)

func apply(id: String) -> void:
	if not _themes.has(id):
		return
	current_theme = _themes[id]
	EventBus.theme_changed.emit(id)

func get_theme(id: String) -> BoardTheme:
	return _themes.get(id)

func available_ids() -> Array:
	return _themes.keys()
