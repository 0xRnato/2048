extends Node

## Global signal hub — decouples emitters from subscribers so systems don't need
## direct node references. Autoloaded as `EventBus`.

# --- App / FSM ---
signal state_changed(from_state: int, to_state: int)

# --- Score / gameplay ---
signal score_changed(new_score: int)
signal best_score_changed(mode: int, new_best: int)
signal move_resolved(result: MoveResult)
signal tile_merged(value: int)
signal combo_scored(count: int, score: int)
signal game_won
signal game_over_reached

# --- Animation / rendering ---
signal animation_started
signal animation_finished

## Fires when the logical board has been overhauled without a normal move —
## undo, new_game, or resume-from-save. Consumers (BoardView) rebuild to match.
signal board_reset

# --- Settings / meta ---
signal theme_changed(theme_name: String)
signal grid_size_changed(new_size: int)
signal achievement_unlocked(id: String)
