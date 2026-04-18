extends Node

## High-level application state machine + gameplay orchestrator. Owns the active
## `Board`, score, session stats, and current `GameMode`. Input layer calls
## `attempt_move(dir)`; UI listens to signals on `EventBus`.

enum AppState { BOOT, MENU, PLAYING, PAUSED, WON_DIALOG, ENDLESS, GAME_OVER }

const _VALID_TRANSITIONS: Dictionary = {
	AppState.BOOT: [AppState.MENU],
	AppState.MENU: [AppState.PLAYING],
	AppState.PLAYING: [AppState.PAUSED, AppState.WON_DIALOG, AppState.GAME_OVER, AppState.MENU],
	AppState.PAUSED: [AppState.PLAYING, AppState.MENU],
	AppState.WON_DIALOG: [AppState.ENDLESS, AppState.PLAYING, AppState.MENU],
	AppState.ENDLESS: [AppState.PAUSED, AppState.GAME_OVER, AppState.MENU],
	AppState.GAME_OVER: [AppState.PLAYING, AppState.MENU],
}

var current_state: int = AppState.BOOT
var current_mode: int = GameConstants.GameMode.CLASSIC
var board: Board = null
var score: int = 0

var _undo_stack: Array = []

func _ready() -> void:
	transition_to(AppState.MENU)

# ---------------------------------------------------------------------------
# FSM
# ---------------------------------------------------------------------------

## Attempt to transition to `next`. Returns true if the transition was valid and applied.
## Invalid transitions are logged and rejected — state stays unchanged.
func transition_to(next: int) -> bool:
	var allowed: Array = _VALID_TRANSITIONS.get(current_state, [])
	if next not in allowed:
		push_warning(
			"GameManager: invalid transition %s -> %s"
			% [state_name(current_state), state_name(next)]
		)
		return false
	var previous: int = current_state
	current_state = next
	EventBus.state_changed.emit(previous, next)
	return true

static func state_name(state: int) -> String:
	match state:
		AppState.BOOT: return "BOOT"
		AppState.MENU: return "MENU"
		AppState.PLAYING: return "PLAYING"
		AppState.PAUSED: return "PAUSED"
		AppState.WON_DIALOG: return "WON_DIALOG"
		AppState.ENDLESS: return "ENDLESS"
		AppState.GAME_OVER: return "GAME_OVER"
		_: return "?"

# ---------------------------------------------------------------------------
# Gameplay
# ---------------------------------------------------------------------------

## Begin a new game in the given mode. Resets board, score, and undo stack.
func new_game(mode: int) -> void:
	current_mode = mode
	board = Board.new()
	score = 0
	_undo_stack.clear()
	board.new_game(GameConstants.size_for_mode(mode), _seed_for_mode(mode))
	EventBus.score_changed.emit(score)
	EventBus.grid_size_changed.emit(board.size)
	if current_state == AppState.MENU or current_state == AppState.GAME_OVER or current_state == AppState.WON_DIALOG:
		transition_to(AppState.PLAYING)

## Dispatch a move. Returns the `MoveResult` (empty when not in a playable state).
func attempt_move(dir: Vector2i) -> MoveResult:
	if not (current_state == AppState.PLAYING or current_state == AppState.ENDLESS):
		return MoveResult.new()
	if board == null:
		return MoveResult.new()

	_push_undo_snapshot()
	var result: MoveResult = board.attempt_move(dir)
	if not result.moved:
		# Roll back the snapshot we speculatively pushed.
		_undo_stack.pop_back()
		return result

	score += result.score_delta
	EventBus.score_changed.emit(score)
	if result.combo_count >= 2:
		EventBus.combo_scored.emit(result.combo_count, result.score_delta)
	for m in result.merges:
		EventBus.tile_merged.emit(m.new_value)
	EventBus.move_resolved.emit(result)

	# Win triggers the one-shot dialog only from PLAYING; ENDLESS re-entries don't re-fire.
	if board.has_won() and current_state == AppState.PLAYING:
		EventBus.game_won.emit()
		transition_to(AppState.WON_DIALOG)
	elif board.is_game_over():
		EventBus.game_over_reached.emit()
		transition_to(AppState.GAME_OVER)
	return result

## Pop the last snapshot. Returns true on success, false when the stack is empty.
func undo() -> bool:
	if _undo_stack.is_empty():
		return false
	var snap: Dictionary = _undo_stack.pop_back()
	board.deserialize(snap["board"])
	score = int(snap["score"])
	EventBus.score_changed.emit(score)
	return true

## Continue playing past the 2048 win tile — only valid from `WON_DIALOG`.
func keep_playing() -> bool:
	return transition_to(AppState.ENDLESS)

## Start a fresh game in the current mode.
func restart() -> void:
	new_game(current_mode)

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

func _push_undo_snapshot() -> void:
	_undo_stack.append({"board": board.serialize(), "score": score})
	if _undo_stack.size() > GameConstants.UNDO_STACK_MAX:
		_undo_stack.pop_front()

func _seed_for_mode(mode: int) -> int:
	if mode == GameConstants.GameMode.DAILY:
		var d: Dictionary = Time.get_date_dict_from_system(true)
		return int("%04d%02d%02d" % [d["year"], d["month"], d["day"]])
	return int(Time.get_ticks_usec()) ^ hash(OS.get_unique_id())
