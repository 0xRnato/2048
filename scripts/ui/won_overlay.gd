class_name WonOverlay extends Control

## Shown when the player first produces a 2048 tile. Two buttons: keep playing
## (→ ENDLESS) or new game (→ fresh board in the same mode). Driven by
## `EventBus.state_changed` on WON_DIALOG.

@onready var _keep_btn: Button = $Frame/List/KeepPlaying
@onready var _new_game_btn: Button = $Frame/List/NewGame

func _ready() -> void:
	visible = false
	EventBus.state_changed.connect(_on_state_changed)
	_keep_btn.pressed.connect(_on_keep)
	_new_game_btn.pressed.connect(_on_new_game)

func _on_state_changed(_from: int, to_state: int) -> void:
	visible = to_state == GameManager.AppState.WON_DIALOG

func _on_keep() -> void:
	GameManager.keep_playing()
	visible = false

func _on_new_game() -> void:
	GameManager.new_game(GameManager.current_mode)
	visible = false
