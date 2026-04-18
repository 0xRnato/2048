class_name InputController extends Node

## Single input source of truth. Reads the `move_up/down/left/right`, `undo`, and `pause`
## input actions and dispatches to `GameManager`. Touch swipe support comes in M4 via
## `SwipeDetector`. Input is silently dropped when not in a playable state, so this
## layer has no knowledge of the FSM beyond calling `GameManager.attempt_move`.

var disabled: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if disabled:
		return
	if event.is_action_pressed("move_up"):
		GameManager.attempt_move(GameConstants.DIRECTION_UP)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		GameManager.attempt_move(GameConstants.DIRECTION_DOWN)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left"):
		GameManager.attempt_move(GameConstants.DIRECTION_LEFT)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		GameManager.attempt_move(GameConstants.DIRECTION_RIGHT)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("undo"):
		GameManager.undo()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	if GameManager.current_state == GameManager.AppState.PLAYING or GameManager.current_state == GameManager.AppState.ENDLESS:
		GameManager.transition_to(GameManager.AppState.PAUSED)
	elif GameManager.current_state == GameManager.AppState.PAUSED:
		GameManager.transition_to(GameManager.AppState.PLAYING)
