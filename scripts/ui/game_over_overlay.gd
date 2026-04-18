class_name GameOverOverlay extends Control

## Shown on `GAME_OVER`. Displays final score + best, lists achievements unlocked
## during this game, and offers Retry / Change mode. Revive (rewarded ad) button
## is wired in M8 — hidden here.

@onready var _score_label: Label = $Frame/List/Score
@onready var _best_label: Label = $Frame/List/Best
@onready var _ach_list: VBoxContainer = $Frame/List/Achievements
@onready var _retry_btn: Button = $Frame/List/Retry
@onready var _menu_btn: Button = $Frame/List/Menu

var _unlocked_this_game: Array[String] = []

func _ready() -> void:
	visible = false
	EventBus.state_changed.connect(_on_state_changed)
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)
	_retry_btn.pressed.connect(_on_retry)
	_menu_btn.pressed.connect(_on_menu)

func _on_state_changed(_from: int, to_state: int) -> void:
	if to_state == GameManager.AppState.GAME_OVER:
		_show()
	elif to_state == GameManager.AppState.PLAYING or to_state == GameManager.AppState.MENU:
		visible = false
	if to_state == GameManager.AppState.PLAYING:
		_unlocked_this_game.clear()

func _on_achievement_unlocked(id: String) -> void:
	_unlocked_this_game.append(id)

func _show() -> void:
	_score_label.text = tr("GAME_OVER_SCORE") % GameManager.score
	var best: int = SaveManager.get_best(GameManager.MODE_SAVE_KEYS.get(GameManager.current_mode, "classic"))
	_best_label.text = tr("GAME_OVER_BEST") % best
	_populate_achievements()
	visible = true

func _populate_achievements() -> void:
	for child in _ach_list.get_children():
		child.queue_free()
	for id in _unlocked_this_game:
		var entry: Dictionary = _lookup(id)
		var label: Label = Label.new()
		label.text = "✓ " + tr(entry.get("title_key", id))
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", Color(0.93, 0.76, 0.18, 1))
		_ach_list.add_child(label)

func _lookup(id: String) -> Dictionary:
	for entry in AchievementsManager.list():
		if entry.get("id") == id:
			return entry
	return {}

func _on_retry() -> void:
	GameManager.new_game(GameManager.current_mode)
	visible = false

func _on_menu() -> void:
	GameManager.transition_to(GameManager.AppState.MENU)
	visible = false
