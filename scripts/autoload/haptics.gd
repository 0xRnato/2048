extends Node

## Thin wrapper over `Input.vibrate_handheld(ms)`. Fires on Android only; no-ops on
## every other platform. Respects the user's `prefs/haptics_enabled` setting, which
## `SaveManager` exposes in M4. Until then, `enabled` defaults to true.

const TAP_MS: int = 20
const MERGE_MS: int = 35
const WIN_MS: int = 120

var enabled: bool = true

func _ready() -> void:
	EventBus.tile_merged.connect(_on_tile_merged)
	EventBus.game_won.connect(_on_game_won)

func tap() -> void:
	_buzz(TAP_MS)

func merge() -> void:
	_buzz(MERGE_MS)

func win() -> void:
	_buzz(WIN_MS)

func _on_tile_merged(_value: int) -> void:
	merge()

func _on_game_won() -> void:
	win()

func _buzz(ms: int) -> void:
	if not enabled:
		return
	if OS.get_name() != "Android":
		return
	Input.vibrate_handheld(ms)
