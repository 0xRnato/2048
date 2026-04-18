class_name MainScene extends Control

## Root of `main.tscn`. Boots the game: wires the BoardView to the current `Board`
## and kicks off a Classic game directly (no menu scene yet — added in M5). A proper
## menu with a mode selector replaces this auto-start in M5.

@onready var _board_view: BoardView = $BoardView
@onready var _hud: Hud = $Hud

func _ready() -> void:
	GameManager.new_game(GameConstants.GameMode.CLASSIC)
	_board_view.rebuild(GameManager.board.size)
