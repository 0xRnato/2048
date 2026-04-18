extends Node

## Lifetime statistics aggregator. Listens to `EventBus` for gameplay signals,
## increments counters, persists to `SaveManager.set_stat`. Debounced write
## (1 s) so rapid merges don't thrash the save file.

const WRITE_DEBOUNCE_MS: int = 1000

const KEYS: Array[String] = [
	"games_played",
	"total_merges",
	"total_score",
	"highest_tile",
	"wins_2048",
	"total_play_seconds",
	"best_time_to_2048_seconds",
	"max_combo",
]

var _dirty: bool = false
var _write_timer: Timer

var _game_start_ticks: int = 0

func _ready() -> void:
	_write_timer = Timer.new()
	_write_timer.one_shot = true
	_write_timer.wait_time = WRITE_DEBOUNCE_MS / 1000.0
	_write_timer.timeout.connect(_flush)
	add_child(_write_timer)

	EventBus.tile_merged.connect(_on_tile_merged)
	EventBus.combo_scored.connect(_on_combo_scored)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.game_won.connect(_on_game_won)
	EventBus.game_over_reached.connect(_on_game_over)
	EventBus.state_changed.connect(_on_state_changed)

# ---------------------------------------------------------------------------
# Typed accessors
# ---------------------------------------------------------------------------

func get_stat(key: String) -> int:
	return SaveManager.get_stat(key)

func _add(key: String, delta: int) -> void:
	var current: int = SaveManager.get_stat(key)
	SaveManager.set_stat(key, current + delta)
	_mark_dirty()

func _set_max(key: String, value: int) -> void:
	var current: int = SaveManager.get_stat(key)
	if value > current:
		SaveManager.set_stat(key, value)
		_mark_dirty()

func _mark_dirty() -> void:
	_dirty = true
	if _write_timer.is_stopped():
		_write_timer.start()

func _flush() -> void:
	if _dirty:
		# SaveManager already persists on set_stat; nothing else to do. This hook
		# reserved for future aggregated writes.
		_dirty = false

# ---------------------------------------------------------------------------
# Event handlers
# ---------------------------------------------------------------------------

func _on_tile_merged(value: int) -> void:
	_add("total_merges", 1)
	_set_max("highest_tile", value)

func _on_combo_scored(count: int, _score: int) -> void:
	_set_max("max_combo", count)

func _on_score_changed(score: int) -> void:
	# total_score counts the running sum across all games; increment by delta,
	# but we don't have the delta here. Track via `score` snapshots on game end.
	# This is updated on GAME_OVER / GAME_WON instead.
	pass

func _on_game_won() -> void:
	_add("wins_2048", 1)
	var now: int = Time.get_ticks_msec()
	var elapsed: int = (now - _game_start_ticks) / 1000
	if _game_start_ticks > 0:
		var best: int = SaveManager.get_stat("best_time_to_2048_seconds")
		if best == 0 or elapsed < best:
			SaveManager.set_stat("best_time_to_2048_seconds", elapsed)
			_mark_dirty()

func _on_game_over() -> void:
	_add("games_played", 1)
	var final_score: int = GameManager.score
	_add("total_score", final_score)
	if _game_start_ticks > 0:
		var elapsed: int = (Time.get_ticks_msec() - _game_start_ticks) / 1000
		_add("total_play_seconds", elapsed)

func _on_state_changed(from_state: int, to_state: int) -> void:
	# Start the game timer when entering PLAYING from a non-playing state.
	if to_state == GameManager.AppState.PLAYING and from_state != GameManager.AppState.PAUSED:
		_game_start_ticks = Time.get_ticks_msec()
