extends Node

## Local achievements — evaluated on every relevant `EventBus` signal. Unlock
## state persists in `SaveManager` keyed by string id. Catalog is code-defined
## (predicates as lambdas); a `.tres` catalog would work too but the `Callable`
## field doesn't serialize cleanly.
##
## New achievements are append-only. Removing an id is a breaking save change.

const CATALOG: Array = [
	{"id": "first_merge", "title_key": "ACH_FIRST_MERGE", "desc_key": "ACH_FIRST_MERGE_DESC"},
	{"id": "reach_256", "title_key": "ACH_REACH_256", "desc_key": ""},
	{"id": "reach_512", "title_key": "ACH_REACH_512", "desc_key": ""},
	{"id": "reach_1024", "title_key": "ACH_REACH_1024", "desc_key": ""},
	{"id": "reach_2048", "title_key": "ACH_REACH_2048", "desc_key": ""},
	{"id": "reach_4096", "title_key": "ACH_REACH_4096", "desc_key": ""},
	{"id": "reach_8192", "title_key": "ACH_REACH_8192", "desc_key": ""},
	{"id": "combo_4", "title_key": "ACH_COMBO_4", "desc_key": "ACH_COMBO_4_DESC"},
	{"id": "win_3x3", "title_key": "ACH_WIN_3X3", "desc_key": ""},
	{"id": "win_5x5", "title_key": "ACH_WIN_5X5", "desc_key": ""},
	{"id": "speedrun_10min", "title_key": "ACH_SPEEDRUN_10MIN", "desc_key": "ACH_SPEEDRUN_10MIN_DESC"},
	{"id": "undo_master", "title_key": "ACH_UNDO_MASTER", "desc_key": "ACH_UNDO_MASTER_DESC"},
	{"id": "theme_explorer", "title_key": "ACH_THEME_EXPLORER", "desc_key": "ACH_THEME_EXPLORER_DESC"},
	{"id": "polyglot", "title_key": "ACH_POLYGLOT", "desc_key": "ACH_POLYGLOT_DESC"},
]

var _themes_tried: Dictionary = {}
var _langs_tried: Dictionary = {}
var _undo_count: int = 0

func _ready() -> void:
	EventBus.tile_merged.connect(_on_tile_merged)
	EventBus.combo_scored.connect(_on_combo_scored)
	EventBus.game_won.connect(_on_game_won)
	EventBus.theme_changed.connect(_on_theme_changed)

func list() -> Array:
	return CATALOG

func is_unlocked(id: String) -> bool:
	return SaveManager.is_achievement_unlocked(id)

func unlocked_ids() -> Array[String]:
	var out: Array[String] = []
	for entry in CATALOG:
		if is_unlocked(entry["id"]):
			out.append(entry["id"])
	return out

func on_undo_used() -> void:
	_undo_count += 1
	if _undo_count >= 100:
		_try_unlock("undo_master")

func on_language_changed(lang: String) -> void:
	_langs_tried[lang] = true
	if _langs_tried.size() >= 2:
		_try_unlock("polyglot")

# ---------------------------------------------------------------------------
# Internal evaluation
# ---------------------------------------------------------------------------

func _on_tile_merged(value: int) -> void:
	_try_unlock("first_merge")
	if value >= 256: _try_unlock("reach_256")
	if value >= 512: _try_unlock("reach_512")
	if value >= 1024: _try_unlock("reach_1024")
	if value >= 2048: _try_unlock("reach_2048")
	if value >= 4096: _try_unlock("reach_4096")
	if value >= 8192: _try_unlock("reach_8192")

func _on_combo_scored(count: int, _score: int) -> void:
	if count >= 4:
		_try_unlock("combo_4")

func _on_game_won() -> void:
	if GameManager.board == null:
		return
	var size: int = GameManager.board.size
	if size == 3:
		_try_unlock("win_3x3")
	elif size == 5:
		_try_unlock("win_5x5")
	# speedrun_10min — time tracked by StatsTracker; check there
	var elapsed: int = SaveManager.get_stat("best_time_to_2048_seconds")
	if elapsed > 0 and elapsed <= 600:
		_try_unlock("speedrun_10min")

func _on_theme_changed(id: String) -> void:
	_themes_tried[id] = true
	if _themes_tried.size() >= 3:
		_try_unlock("theme_explorer")

func _try_unlock(id: String) -> void:
	if SaveManager.unlock_achievement(id):
		EventBus.achievement_unlocked.emit(id)
