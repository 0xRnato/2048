class_name Hud extends Control

## Top HUD — current score, best score, and a "New game" button. Undo button is
## added in M5 alongside the undo stack UX.

@onready var _score_label: Label = $Top/Score/Value
@onready var _best_label: Label = $Top/Best/Value
@onready var _new_game_btn: Button = $Top/NewGame

func _ready() -> void:
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.best_score_changed.connect(_on_best_score_changed)
	_new_game_btn.pressed.connect(_on_new_game_pressed)

func _on_score_changed(new_score: int) -> void:
	_score_label.text = str(new_score)

func _on_best_score_changed(_mode: int, new_best: int) -> void:
	_best_label.text = str(new_best)

func set_best(value: int) -> void:
	_best_label.text = str(value)

func _on_new_game_pressed() -> void:
	GameManager.new_game(GameManager.current_mode)
