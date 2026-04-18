class_name GameConstants extends Object

## Central constants and static helpers for 2048 game logic.
##
## Imported directly (no instance) — `GameConstants.WIN_TILE`,
## `GameConstants.combo_multiplier(3)`, etc.

enum GameMode {
	CLASSIC,
	SIZE_3,
	SIZE_5,
}

const DIRECTION_UP: Vector2i = Vector2i(0, -1)
const DIRECTION_DOWN: Vector2i = Vector2i(0, 1)
const DIRECTION_LEFT: Vector2i = Vector2i(-1, 0)
const DIRECTION_RIGHT: Vector2i = Vector2i(1, 0)

const DIRECTIONS: Array[Vector2i] = [
	DIRECTION_UP,
	DIRECTION_DOWN,
	DIRECTION_LEFT,
	DIRECTION_RIGHT,
]

const WIN_TILE: int = 2048
const SPAWN_VALUE_LOW: int = 2
const SPAWN_VALUE_HIGH: int = 4
const SPAWN_HIGH_PROBABILITY: float = 0.1

## Combo factor indexed by (merges - 1). 1 merge → ×1.0, 2 → ×1.25, 3 → ×1.5, 4+ → ×2.0.
const COMBO_MULTIPLIERS: Array[float] = [1.0, 1.25, 1.5, 2.0]

const UNDO_STACK_MAX: int = 16

static func combo_multiplier(merge_count: int) -> float:
	if merge_count <= 0:
		return 1.0
	var idx: int = clampi(merge_count - 1, 0, COMBO_MULTIPLIERS.size() - 1)
	return COMBO_MULTIPLIERS[idx]

static func size_for_mode(mode: int) -> int:
	match mode:
		GameMode.SIZE_3:
			return 3
		GameMode.SIZE_5:
			return 5
		_:
			return 4

static func is_valid_direction(dir: Vector2i) -> bool:
	return dir in DIRECTIONS
