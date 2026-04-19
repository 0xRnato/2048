class_name SwipeDetector extends Node

## Converts touch drag events into `GameManager.attempt_move(dir)` calls. Registered
## as a sibling of `InputController` in `main.tscn`; disabled when the input system
## is busy (post-animation debounce).
##
## Swipe rule: from touch-down to touch-up, compute delta. If dominant-axis magnitude
## ≥ `THRESHOLD_PX` AND exceeds the other axis by `DOMINANT_RATIO`, fire a move in
## the dominant direction.

const THRESHOLD_PX: float = 40.0
const DOMINANT_RATIO: float = 1.5

var disabled: bool = false

var _start_pos: Vector2 = Vector2.ZERO
var _tracking: bool = false

func _ready() -> void:
	EventBus.animation_started.connect(_on_animation_started)
	EventBus.animation_finished.connect(_on_animation_finished)

func _on_animation_started() -> void:
	disabled = true
	_tracking = false

func _on_animation_finished() -> void:
	disabled = false

func _input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event
		if t.pressed:
			_start_pos = t.position
			_tracking = true
		else:
			if _tracking:
				_resolve(t.position - _start_pos)
				_tracking = false
	elif event is InputEventMouseButton:
		# Desktop fallback so swipe can be tested in the editor without a touch device.
		var m: InputEventMouseButton = event
		if m.button_index == MOUSE_BUTTON_LEFT:
			if m.pressed:
				_start_pos = m.position
				_tracking = true
			else:
				if _tracking:
					_resolve(m.position - _start_pos)
					_tracking = false

func _resolve(delta: Vector2) -> void:
	var ax: float = absf(delta.x)
	var ay: float = absf(delta.y)
	if max(ax, ay) < THRESHOLD_PX:
		return
	if ax >= ay * DOMINANT_RATIO:
		if delta.x > 0:
			GameManager.attempt_move(GameConstants.DIRECTION_RIGHT)
		else:
			GameManager.attempt_move(GameConstants.DIRECTION_LEFT)
	elif ay >= ax * DOMINANT_RATIO:
		if delta.y > 0:
			GameManager.attempt_move(GameConstants.DIRECTION_DOWN)
		else:
			GameManager.attempt_move(GameConstants.DIRECTION_UP)
