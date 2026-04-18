class_name MainScene extends Control

## Root of `main.tscn`. On boot:
## 1. Ask `GameManager` to resume any in-progress game; if none exists, start a new
##    Classic game.
## 2. Instruct the `BoardView` to build itself against the active board.
## 3. Wire the settings button to toggle the SettingsPanel overlay.

@onready var _board_view: BoardView = $BoardView
@onready var _hud: Hud = $Hud
@onready var _settings_panel: SettingsPanel = $Overlays/SettingsPanel
@onready var _settings_btn: Button = $Hud/Top/Settings

func _ready() -> void:
	_settings_btn.pressed.connect(_on_settings_pressed)
	if not GameManager.try_resume_from_save():
		GameManager.new_game(GameConstants.GameMode.CLASSIC)
	_board_view.rebuild(GameManager.board.size)

func _on_settings_pressed() -> void:
	_settings_panel.visible = not _settings_panel.visible
