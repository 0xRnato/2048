class_name Hud extends Control

## Top HUD — score, best, undo, new game, plus secondary buttons that toggle the
## Mode / Stats / Achievements / Settings panels. Panel references are wired from
## `MainScene` via `bind_panels()` to keep this scene independent of overlay paths.

signal mode_requested
signal stats_requested
signal achievements_requested
signal settings_requested

@onready var _score_title: Label = $Container/Top/Score/Title
@onready var _score_label: Label = $Container/Top/Score/Value
@onready var _best_title: Label = $Container/Top/Best/Title
@onready var _best_label: Label = $Container/Top/Best/Value
@onready var _new_game_btn: Button = $Container/Top/NewGame
@onready var _undo_btn: Button = $Container/Top/Undo
@onready var _mode_btn: Button = $Container/Sub/Mode
@onready var _stats_btn: Button = $Container/Sub/Stats
@onready var _achievements_btn: Button = $Container/Sub/Achievements
@onready var _settings_btn: Button = $Container/Sub/Settings

func _ready() -> void:
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.best_score_changed.connect(_on_best_score_changed)
	EventBus.theme_changed.connect(_on_theme_changed)
	_new_game_btn.pressed.connect(_on_new_game_pressed)
	_undo_btn.pressed.connect(_on_undo_pressed)
	_mode_btn.pressed.connect(func() -> void: mode_requested.emit())
	_stats_btn.pressed.connect(func() -> void: stats_requested.emit())
	_achievements_btn.pressed.connect(func() -> void: achievements_requested.emit())
	_settings_btn.pressed.connect(func() -> void: settings_requested.emit())
	_apply_theme()

func _on_theme_changed(_id: String) -> void:
	_apply_theme()

func _apply_theme() -> void:
	var theme_res: BoardTheme = ThemeService.current_theme
	if theme_res == null:
		return
	_score_title.add_theme_color_override("font_color", theme_res.ui_text_secondary)
	_best_title.add_theme_color_override("font_color", theme_res.ui_text_secondary)
	_score_label.add_theme_color_override("font_color", theme_res.ui_text_primary)
	_best_label.add_theme_color_override("font_color", theme_res.ui_text_primary)

func _on_score_changed(new_score: int) -> void:
	_score_label.text = str(new_score)

func _on_best_score_changed(_mode: int, new_best: int) -> void:
	_best_label.text = str(new_best)

func _on_new_game_pressed() -> void:
	GameManager.new_game(GameManager.current_mode)

func _on_undo_pressed() -> void:
	if GameManager.undo():
		AchievementsManager.on_undo_used()
