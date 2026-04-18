class_name MainScene extends Control

## Root of `main.tscn`. On boot: resume any in-progress game or start a fresh
## Classic run, rebuild the board, wire HUD button events to overlay visibility.

@onready var _board_view: BoardView = $BoardView
@onready var _hud: Hud = $Hud
@onready var _settings_panel: SettingsPanel = $Overlays/SettingsPanel
@onready var _stats_panel: StatsPanel = $Overlays/StatsPanel
@onready var _achievements_panel: AchievementsPanel = $Overlays/AchievementsPanel
@onready var _mode_selector: ModeSelector = $Overlays/ModeSelector
@onready var _won_overlay: WonOverlay = $Overlays/WonOverlay
@onready var _game_over_overlay: GameOverOverlay = $Overlays/GameOverOverlay

func _ready() -> void:
	_hud.settings_requested.connect(func() -> void: _toggle(_settings_panel))
	_hud.stats_requested.connect(func() -> void: _toggle(_stats_panel))
	_hud.achievements_requested.connect(func() -> void: _toggle(_achievements_panel))
	_hud.mode_requested.connect(func() -> void: _toggle(_mode_selector))
	if not GameManager.try_resume_from_save():
		GameManager.new_game(GameConstants.GameMode.CLASSIC)
	_board_view.rebuild(GameManager.board.size)

func _toggle(overlay: Control) -> void:
	overlay.visible = not overlay.visible
