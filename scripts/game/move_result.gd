class_name MoveResult extends RefCounted

## Value object describing the outcome of a single `Board.attempt_move(dir)`.
##
## The board mutates in place; `MoveResult` is the event record consumed by the
## renderer to drive tweens and by the `GameManager` to update score.

## Per-tile slide (no value change).
class Slide:
	var from: Vector2i
	var to: Vector2i

	func _init(p_from: Vector2i, p_to: Vector2i) -> void:
		from = p_from
		to = p_to

## Two tiles converging into one cell, doubling the value.
class Merge:
	var from_a: Vector2i
	var from_b: Vector2i
	var to: Vector2i
	var new_value: int

	func _init(p_from_a: Vector2i, p_from_b: Vector2i, p_to: Vector2i, p_new_value: int) -> void:
		from_a = p_from_a
		from_b = p_from_b
		to = p_to
		new_value = p_new_value

## New tile placed by the board after a successful move.
class Spawn:
	var at: Vector2i
	var value: int

	func _init(p_at: Vector2i, p_value: int) -> void:
		at = p_at
		value = p_value

var moved: bool = false
var score_delta: int = 0
var combo_count: int = 0
var slides: Array = []      ## Array[Slide]
var merges: Array = []      ## Array[Merge]
var spawned: Spawn = null   ## null when the move did not trigger a spawn
