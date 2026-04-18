class_name StatsPanel extends Control

## Read-only view of lifetime stats maintained by `StatsTracker` / `SaveManager`.
## Refreshes on every `visibility_changed` so it stays accurate.

@onready var _games: Label = $Frame/List/Games/Value
@onready var _merges: Label = $Frame/List/Merges/Value
@onready var _highest: Label = $Frame/List/Highest/Value
@onready var _wins: Label = $Frame/List/Wins/Value
@onready var _play_time: Label = $Frame/List/PlayTime/Value
@onready var _best_time: Label = $Frame/List/BestTime/Value
@onready var _close_btn: Button = $Frame/List/Close

func _ready() -> void:
	_close_btn.pressed.connect(_on_close)
	visibility_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if not visible:
		return
	_games.text = str(SaveManager.get_stat("games_played"))
	_merges.text = str(SaveManager.get_stat("total_merges"))
	_highest.text = str(SaveManager.get_stat("highest_tile"))
	_wins.text = str(SaveManager.get_stat("wins_2048"))
	_play_time.text = _format_duration(SaveManager.get_stat("total_play_seconds"))
	var bt: int = SaveManager.get_stat("best_time_to_2048_seconds")
	_best_time.text = _format_duration(bt) if bt > 0 else "—"

func _on_close() -> void:
	visible = false

static func _format_duration(seconds: int) -> String:
	if seconds <= 0:
		return "0s"
	if seconds < 60:
		return "%ds" % seconds
	if seconds < 3600:
		return "%dm %ds" % [seconds / 60, seconds % 60]
	return "%dh %dm" % [seconds / 3600, (seconds % 3600) / 60]
