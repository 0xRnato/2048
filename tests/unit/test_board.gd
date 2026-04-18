extends "res://addons/gut/test.gd"

## Board resource unit tests. Covers move resolution, merges, win/lose detection,
## spawn semantics, and serialization round-trip.

var board: Board

func before_each() -> void:
	board = Board.new()

func _set(cells: Array) -> void:
	board.set_cells_for_test(cells)

func _dump() -> Array:
	var out: Array = []
	for r in board.size:
		var row: Array = []
		for c in board.size:
			row.append(board.cell_at(Vector2i(c, r)))
		out.append(row)
	return out

# ---------------------------------------------------------------------------
# new_game
# ---------------------------------------------------------------------------

func test_new_game_spawns_exactly_two_tiles() -> void:
	board.new_game(4, 42)
	var non_empty: int = 0
	for r in 4:
		for c in 4:
			if board.cell_at(Vector2i(c, r)) != 0:
				non_empty += 1
	assert_eq(non_empty, 2, "Expected exactly 2 tiles after new_game")

func test_new_game_resets_win_flag() -> void:
	board.new_game(4, 1)
	assert_false(board.has_won(), "has_won should be false on fresh board")

# ---------------------------------------------------------------------------
# Slides — basic
# ---------------------------------------------------------------------------

func test_slide_left_basic() -> void:
	_set([
		[0, 0, 0, 2],
		[0, 2, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_true(r.moved)
	assert_eq(board.cell_at(Vector2i(0, 0)), 2)
	assert_eq(board.cell_at(Vector2i(0, 1)), 2)

func test_slide_right_basic() -> void:
	_set([
		[2, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_RIGHT)
	assert_true(r.moved)
	assert_eq(board.cell_at(Vector2i(3, 0)), 2)

func test_slide_up_basic() -> void:
	_set([
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[2, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_UP)
	assert_true(r.moved)
	assert_eq(board.cell_at(Vector2i(0, 0)), 2)

func test_slide_down_basic() -> void:
	_set([
		[2, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_DOWN)
	assert_true(r.moved)
	assert_eq(board.cell_at(Vector2i(0, 3)), 2)

# ---------------------------------------------------------------------------
# Merges
# ---------------------------------------------------------------------------

func test_merge_two_adjacent_equal_tiles_left() -> void:
	_set([
		[2, 2, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_true(r.moved)
	assert_eq(board.cell_at(Vector2i(0, 0)), 4)
	assert_eq(r.merges.size(), 1)
	assert_eq(r.score_delta, 4)

func test_merge_line_2_2_2_2_produces_two_4s_not_one_8() -> void:
	# Classic 2048 rule: each tile merges at most once per move.
	_set([
		[2, 2, 2, 2],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_eq(board.cell_at(Vector2i(0, 0)), 4)
	assert_eq(board.cell_at(Vector2i(1, 0)), 4)
	assert_eq(board.cell_at(Vector2i(2, 0)), 0)
	assert_eq(r.merges.size(), 2)

func test_merge_line_4_4_2_2_produces_8_and_4() -> void:
	_set([
		[4, 4, 2, 2],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_eq(board.cell_at(Vector2i(0, 0)), 8)
	assert_eq(board.cell_at(Vector2i(1, 0)), 4)
	assert_eq(r.merges.size(), 2)

func test_merge_resolves_from_far_side_on_right() -> void:
	# 2 2 2 0 moved right → 0 0 2 4 (rightmost pair merges first)
	_set([
		[2, 2, 2, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var _r: MoveResult = board.attempt_move(GameConstants.DIRECTION_RIGHT)
	assert_eq(board.cell_at(Vector2i(3, 0)), 4)
	assert_eq(board.cell_at(Vector2i(2, 0)), 2)

# ---------------------------------------------------------------------------
# No-op moves
# ---------------------------------------------------------------------------

func test_move_that_changes_nothing_does_not_spawn() -> void:
	_set([
		[2, 4, 8, 16],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_false(r.moved)
	assert_null(r.spawned)
	assert_eq(r.score_delta, 0)

func test_invalid_direction_returns_empty_result() -> void:
	_set([
		[2, 2, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(Vector2i(1, 1))
	assert_false(r.moved)

# ---------------------------------------------------------------------------
# Spawn
# ---------------------------------------------------------------------------

func test_successful_move_spawns_new_tile() -> void:
	_set([
		[2, 2, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	board.set_rng_seed(1)
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_not_null(r.spawned, "Expected a spawn event after a moving turn")
	var at: Vector2i = r.spawned.at
	assert_eq(board.cell_at(at), r.spawned.value)

# ---------------------------------------------------------------------------
# Win + game over
# ---------------------------------------------------------------------------

func test_has_won_flips_when_2048_tile_appears() -> void:
	_set([
		[1024, 1024, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	assert_false(board.has_won())
	var _r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_true(board.has_won())

func test_is_game_over_false_when_board_has_empty_cell() -> void:
	_set([
		[2, 4, 2, 4],
		[4, 2, 4, 2],
		[2, 4, 2, 4],
		[4, 2, 4, 0],
	])
	assert_false(board.is_game_over())

func test_is_game_over_false_when_full_but_merges_available() -> void:
	_set([
		[2, 4, 2, 4],
		[4, 2, 4, 2],
		[2, 4, 2, 4],
		[4, 2, 4, 4],
	])
	assert_false(board.is_game_over())

func test_is_game_over_true_when_full_and_no_merges() -> void:
	_set([
		[2, 4, 2, 4],
		[4, 2, 4, 2],
		[2, 4, 2, 4],
		[4, 2, 4, 2],
	])
	assert_true(board.is_game_over())

# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

func test_serialize_deserialize_roundtrip() -> void:
	_set([
		[2, 4, 8, 16],
		[0, 2, 0, 4],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var data: Dictionary = board.serialize()
	var other: Board = Board.new()
	other.deserialize(data)
	assert_eq(other.size, board.size)
	for r in board.size:
		for c in board.size:
			assert_eq(other.cell_at(Vector2i(c, r)), board.cell_at(Vector2i(c, r)))
	assert_eq(other.has_won(), board.has_won())

# ---------------------------------------------------------------------------
# Deterministic seeding
# ---------------------------------------------------------------------------

func test_same_seed_produces_same_initial_board() -> void:
	var a: Board = Board.new()
	var b: Board = Board.new()
	a.new_game(4, 20260418)
	b.new_game(4, 20260418)
	for r in 4:
		for c in 4:
			assert_eq(a.cell_at(Vector2i(c, r)), b.cell_at(Vector2i(c, r)),
				"Cell (%d,%d) diverges under the same seed" % [c, r])

# ---------------------------------------------------------------------------
# Grid size variants
# ---------------------------------------------------------------------------

func test_new_game_3x3_has_3x3_cells() -> void:
	board.new_game(3, 7)
	assert_eq(board.size, 3)
	assert_eq(board.get_cells().size(), 9)

func test_new_game_5x5_has_5x5_cells() -> void:
	board.new_game(5, 7)
	assert_eq(board.size, 5)
	assert_eq(board.get_cells().size(), 25)

# ---------------------------------------------------------------------------
# Highest tile
# ---------------------------------------------------------------------------

func test_highest_tile_returns_max_value_on_board() -> void:
	_set([
		[2, 4, 0, 0],
		[0, 128, 0, 0],
		[0, 0, 32, 0],
		[0, 0, 0, 0],
	])
	assert_eq(board.highest_tile(), 128)
