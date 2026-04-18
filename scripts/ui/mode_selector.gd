class_name ModeSelector extends Control

## Overlay with four buttons, one per `GameMode`. Tapping a button starts a
## new game in that mode and closes the overlay.

@onready var _classic: Button = $Frame/List/Classic
@onready var _daily: Button = $Frame/List/Daily
@onready var _size_3: Button = $Frame/List/Size3
@onready var _size_5: Button = $Frame/List/Size5
@onready var _close_btn: Button = $Frame/List/Close

func _ready() -> void:
	_classic.pressed.connect(_start.bind(GameConstants.GameMode.CLASSIC))
	_daily.pressed.connect(_start.bind(GameConstants.GameMode.DAILY))
	_size_3.pressed.connect(_start.bind(GameConstants.GameMode.SIZE_3))
	_size_5.pressed.connect(_start.bind(GameConstants.GameMode.SIZE_5))
	_close_btn.pressed.connect(_on_close)

func _start(mode: int) -> void:
	GameManager.new_game(mode)
	visible = false

func _on_close() -> void:
	visible = false
