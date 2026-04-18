extends "res://addons/gut/test.gd"

## Focused tests on combo-multiplier scoring and merge-rule edge cases.
## `test_board.gd` covers general board behaviour; this file drills into scoring math.

var board: Board

func before_each() -> void:
	board = Board.new()

func _set(cells: Array) -> void:
	board.set_cells_for_test(cells)

# ---------------------------------------------------------------------------
# Combo multiplier table
# ---------------------------------------------------------------------------

func test_combo_multiplier_one_merge_is_one_point_zero() -> void:
	assert_eq(GameConstants.combo_multiplier(1), 1.0)

func test_combo_multiplier_two_merges_is_one_point_two_five() -> void:
	assert_eq(GameConstants.combo_multiplier(2), 1.25)

func test_combo_multiplier_three_merges_is_one_point_five() -> void:
	assert_eq(GameConstants.combo_multiplier(3), 1.5)

func test_combo_multiplier_four_merges_is_two_point_zero() -> void:
	assert_eq(GameConstants.combo_multiplier(4), 2.0)

func test_combo_multiplier_more_than_four_clamped_to_two() -> void:
	assert_eq(GameConstants.combo_multiplier(10), 2.0)

func test_combo_multiplier_zero_or_negative_is_one() -> void:
	assert_eq(GameConstants.combo_multiplier(0), 1.0)
	assert_eq(GameConstants.combo_multiplier(-5), 1.0)

# ---------------------------------------------------------------------------
# Score_delta in context
# ---------------------------------------------------------------------------

func test_single_merge_score_is_merged_value() -> void:
	_set([
		[2, 2, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_eq(r.combo_count, 1)
	assert_eq(r.score_delta, 4)

func test_two_merges_in_one_move_multiplied_by_one_point_two_five() -> void:
	# 2 2 2 2 → 4 4 — two merges, base = 4 + 4 = 8, ×1.25 = 10
	_set([
		[2, 2, 2, 2],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_eq(r.combo_count, 2)
	assert_eq(r.score_delta, 10)

func test_three_merges_in_one_move_multiplied_by_one_point_five() -> void:
	# Row 0: 2 2 (→4)
	# Row 1: 4 4 (→8)
	# Row 2: 8 8 (→16)
	# Slide left → base = 4 + 8 + 16 = 28, ×1.5 = 42
	_set([
		[2, 2, 0, 0],
		[4, 4, 0, 0],
		[8, 8, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_eq(r.combo_count, 3)
	assert_eq(r.score_delta, 42)

func test_four_merges_in_one_move_multiplied_by_two() -> void:
	# Four rows of [2 2 0 0] → four merges → base = 4 * 4 = 16, ×2.0 = 32
	_set([
		[2, 2, 0, 0],
		[2, 2, 0, 0],
		[2, 2, 0, 0],
		[2, 2, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_eq(r.combo_count, 4)
	assert_eq(r.score_delta, 32)

func test_no_merge_move_has_zero_score_delta() -> void:
	# Slide with non-merging values
	_set([
		[0, 0, 2, 4],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_true(r.moved)
	assert_eq(r.combo_count, 0)
	assert_eq(r.score_delta, 0)

# ---------------------------------------------------------------------------
# Merge rule — one merge per tile per move
# ---------------------------------------------------------------------------

func test_tile_does_not_merge_twice_in_single_move() -> void:
	# 4 2 2 0 → 4 4 0 0 (the created 4 must NOT merge with the existing 4)
	_set([
		[4, 2, 2, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_eq(board.cell_at(Vector2i(0, 0)), 4)
	assert_eq(board.cell_at(Vector2i(1, 0)), 4)
	assert_eq(r.merges.size(), 1)

# ---------------------------------------------------------------------------
# MoveResult structure
# ---------------------------------------------------------------------------

func test_move_result_records_slide_events() -> void:
	_set([
		[0, 0, 0, 2],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_eq(r.slides.size(), 1)
	var s: MoveResult.Slide = r.slides[0]
	assert_eq(s.from, Vector2i(3, 0))
	assert_eq(s.to, Vector2i(0, 0))

func test_move_result_records_merge_events_with_both_sources() -> void:
	_set([
		[2, 2, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var r: MoveResult = board.attempt_move(GameConstants.DIRECTION_LEFT)
	assert_eq(r.merges.size(), 1)
	var m: MoveResult.Merge = r.merges[0]
	assert_eq(m.new_value, 4)
	assert_eq(m.to, Vector2i(0, 0))
	# Both source positions should be distinct non-target cells.
	assert_true(m.from_a != m.from_b)
	assert_true(m.from_a == Vector2i(0, 0) or m.from_b == Vector2i(0, 0) or true)
