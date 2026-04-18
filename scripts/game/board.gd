class_name Board extends Resource

## Pure-data 2048 board. Grid-agnostic (3×3 / 4×4 / 5×5).
##
## All state is held in `_cells` (row-major `Array[int]`). `attempt_move(dir)` mutates
## the board in place and returns a `MoveResult` describing what happened, for the renderer
## to animate. No scene-tree dependencies — fully unit-testable.

@export var size: int = 4

var _cells: Array[int] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _has_won: bool = false

func new_game(p_size: int, seed_value: int = 0) -> void:
	size = p_size
	_cells = []
	_cells.resize(size * size)
	for i in _cells.size():
		_cells[i] = 0
	_has_won = false
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	_spawn_tile()
	_spawn_tile()

## Position in `Vector2i(col, row)` convention. Returns 0 for empty.
func cell_at(pos: Vector2i) -> int:
	return _cells[pos.y * size + pos.x]

func set_cell_at(pos: Vector2i, value: int) -> void:
	_cells[pos.y * size + pos.x] = value

func get_cells() -> Array[int]:
	return _cells.duplicate()

func highest_tile() -> int:
	var max_val: int = 0
	for v in _cells:
		if v > max_val:
			max_val = v
	return max_val

func empty_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for r in size:
		for c in size:
			if _cells[r * size + c] == 0:
				result.append(Vector2i(c, r))
	return result

func is_full() -> bool:
	for v in _cells:
		if v == 0:
			return false
	return true

func has_won() -> bool:
	return _has_won

func is_game_over() -> bool:
	if not is_full():
		return false
	for r in size:
		for c in size:
			var v: int = _cells[r * size + c]
			if r + 1 < size and _cells[(r + 1) * size + c] == v:
				return false
			if c + 1 < size and _cells[r * size + (c + 1)] == v:
				return false
	return true

## Attempt a move in `dir` (one of `GameConstants.DIRECTION_*`). Mutates `_cells` when
## something changed and returns a populated `MoveResult`. A no-op move returns a result
## with `moved = false` and empty arrays.
func attempt_move(dir: Vector2i) -> MoveResult:
	var result: MoveResult = MoveResult.new()
	if not GameConstants.is_valid_direction(dir):
		return result

	var old_cells: Array[int] = _cells.duplicate()
	var total_base_score: int = 0
	var all_slides: Array = []
	var all_merges: Array = []

	var lines: Array = _lines_for_direction(dir)
	for line in lines:
		var line_out: Dictionary = _slide_line(line)
		total_base_score += line_out["score"]
		for s in line_out["slides"]:
			all_slides.append(s)
		for m in line_out["merges"]:
			all_merges.append(m)
		for pos in line_out["new_values"].keys():
			var p: Vector2i = pos
			set_cell_at(p, line_out["new_values"][p])

	result.slides = all_slides
	result.merges = all_merges
	result.combo_count = all_merges.size()
	var multiplier: float = GameConstants.combo_multiplier(all_merges.size())
	result.score_delta = int(round(float(total_base_score) * multiplier))
	result.moved = old_cells != _cells

	if result.moved:
		if not _has_won and highest_tile() >= GameConstants.WIN_TILE:
			_has_won = true
		var spawn: MoveResult.Spawn = _spawn_tile()
		result.spawned = spawn
	return result

## Serialize to a Dictionary (stored in save file).
func serialize() -> Dictionary:
	return {
		"size": size,
		"cells": _cells.duplicate(),
		"has_won": _has_won,
		"rng_state": _rng.state,
	}

func deserialize(data: Dictionary) -> void:
	size = int(data.get("size", 4))
	var raw_cells: Array = data.get("cells", [])
	var typed: Array[int] = []
	for v in raw_cells:
		typed.append(int(v))
	_cells = typed
	_has_won = bool(data.get("has_won", false))
	if "rng_state" in data:
		_rng.state = int(data["rng_state"])

## Test helper — set the board from a 2-D array `[[0,0,2,4],[2,2,0,0],...]`.
## The row count determines `size` (must be square).
func set_cells_for_test(cells_2d: Array) -> void:
	size = cells_2d.size()
	_cells = []
	_cells.resize(size * size)
	for r in size:
		for c in size:
			_cells[r * size + c] = int(cells_2d[r][c])

## Test helper — seed the RNG deterministically without rerunning `new_game`.
func set_rng_seed(s: int) -> void:
	_rng.seed = s
	_rng.state = s

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

func _lines_for_direction(dir: Vector2i) -> Array:
	var lines: Array = []
	if dir == GameConstants.DIRECTION_LEFT:
		for r in size:
			var line: Array[Vector2i] = []
			for c in size:
				line.append(Vector2i(c, r))
			lines.append(line)
	elif dir == GameConstants.DIRECTION_RIGHT:
		for r in size:
			var line: Array[Vector2i] = []
			for c in range(size - 1, -1, -1):
				line.append(Vector2i(c, r))
			lines.append(line)
	elif dir == GameConstants.DIRECTION_UP:
		for c in size:
			var line: Array[Vector2i] = []
			for r in size:
				line.append(Vector2i(c, r))
			lines.append(line)
	elif dir == GameConstants.DIRECTION_DOWN:
		for c in size:
			var line: Array[Vector2i] = []
			for r in range(size - 1, -1, -1):
				line.append(Vector2i(c, r))
			lines.append(line)
	return lines

func _slide_line(line_positions: Array) -> Dictionary:
	# Strip zeros, keep original positions.
	var values: Array = []
	var sources: Array = []
	for pos in line_positions:
		var p: Vector2i = pos
		var v: int = cell_at(p)
		if v != 0:
			values.append(v)
			sources.append(p)

	# Merge pass — adjacent equal neighbours combine once per move.
	var merged_values: Array = []
	var merged_sources: Array = []
	var score: int = 0
	var i: int = 0
	while i < values.size():
		if i + 1 < values.size() and values[i] == values[i + 1]:
			var new_val: int = values[i] * 2
			merged_values.append(new_val)
			merged_sources.append([sources[i], sources[i + 1]])
			score += new_val
			i += 2
		else:
			merged_values.append(values[i])
			merged_sources.append([sources[i]])
			i += 1

	# Emit events + compute new cell map.
	var slides_out: Array = []
	var merges_out: Array = []
	var new_values: Dictionary = {}
	for idx in merged_values.size():
		var target_pos: Vector2i = line_positions[idx]
		var value: int = merged_values[idx]
		var srcs: Array = merged_sources[idx]
		new_values[target_pos] = value
		if srcs.size() == 2:
			merges_out.append(MoveResult.Merge.new(srcs[0], srcs[1], target_pos, value))
		else:
			var src: Vector2i = srcs[0]
			if src != target_pos:
				slides_out.append(MoveResult.Slide.new(src, target_pos))
	for idx in range(merged_values.size(), line_positions.size()):
		new_values[line_positions[idx]] = 0

	return {
		"slides": slides_out,
		"merges": merges_out,
		"new_values": new_values,
		"score": score,
	}

func _spawn_tile() -> MoveResult.Spawn:
	var empties: Array[Vector2i] = empty_cells()
	if empties.is_empty():
		return null
	var pos: Vector2i = empties[_rng.randi_range(0, empties.size() - 1)]
	var value: int = GameConstants.SPAWN_VALUE_LOW
	if _rng.randf() < GameConstants.SPAWN_HIGH_PROBABILITY:
		value = GameConstants.SPAWN_VALUE_HIGH
	set_cell_at(pos, value)
	return MoveResult.Spawn.new(pos, value)
