class_name BoardView extends Control

## Renders the active `Board`. Empty cells are drawn as background rectangles in
## `_draw()`; value tiles are `TileView` instances tracked by current cell position.
## Consumes `EventBus.move_resolved` events to animate slides, merges, and spawns
## in parallel, then emits `animation_finished` so upstream systems (input, HUD) can
## re-enable interaction.

signal animation_finished

const TILE_SCENE: PackedScene = preload("res://scenes/game/tile_view.tscn")
const BG_COLOR: Color = Color("#1c1c22")
const EMPTY_CELL_COLOR: Color = Color("#2a2a33")
const GRID_PADDING: int = 20
const TILE_GAP: int = 14

var animating: bool = false

var _tiles_by_cell: Dictionary = {}   ## Vector2i → TileView
var _grid_size: int = 0
var _tile_size: float = 0.0
var _origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	EventBus.move_resolved.connect(_on_move_resolved)
	EventBus.grid_size_changed.connect(_on_grid_size_changed)
	resized.connect(_reflow)

func rebuild(size: int) -> void:
	_grid_size = size
	_clear_tiles()
	_reflow()
	if GameManager.board == null:
		return
	for r in size:
		for c in size:
			var v: int = GameManager.board.cell_at(Vector2i(c, r))
			if v != 0:
				var cell: Vector2i = Vector2i(c, r)
				var tile: TileView = _make_tile(cell, v)
				tile.modulate.a = 1.0
				tile.scale = Vector2.ONE

func _make_tile(cell: Vector2i, value: int) -> TileView:
	var tile: TileView = TILE_SCENE.instantiate()
	add_child(tile)
	tile.size = Vector2(_tile_size, _tile_size)
	tile.custom_minimum_size = Vector2(_tile_size, _tile_size)
	tile.position = _cell_to_pixel(cell)
	tile.pivot_offset = Vector2(_tile_size * 0.5, _tile_size * 0.5)
	tile.cell_pos = cell
	tile.set_value(value)
	_tiles_by_cell[cell] = tile
	return tile

func _clear_tiles() -> void:
	for tile in _tiles_by_cell.values():
		if is_instance_valid(tile):
			tile.queue_free()
	_tiles_by_cell.clear()

func _reflow() -> void:
	queue_redraw()
	if _grid_size <= 0:
		return
	var w: float = size.x - GRID_PADDING * 2.0
	var h: float = size.y - GRID_PADDING * 2.0
	var avail: float = min(w, h)
	_tile_size = (avail - TILE_GAP * (_grid_size - 1)) / float(_grid_size)
	_tile_size = maxf(_tile_size, 16.0)
	var grid_total: float = _tile_size * _grid_size + TILE_GAP * (_grid_size - 1)
	_origin = Vector2((size.x - grid_total) * 0.5, (size.y - grid_total) * 0.5)
	for cell in _tiles_by_cell.keys():
		var t: TileView = _tiles_by_cell[cell]
		if not is_instance_valid(t):
			continue
		t.size = Vector2(_tile_size, _tile_size)
		t.custom_minimum_size = Vector2(_tile_size, _tile_size)
		t.position = _cell_to_pixel(cell)
		t.pivot_offset = Vector2(_tile_size * 0.5, _tile_size * 0.5)

func _cell_to_pixel(cell: Vector2i) -> Vector2:
	return _origin + Vector2(
		cell.x * (_tile_size + TILE_GAP),
		cell.y * (_tile_size + TILE_GAP)
	)

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, BG_COLOR)
	if _grid_size <= 0:
		return
	for r in _grid_size:
		for c in _grid_size:
			var p: Vector2 = _cell_to_pixel(Vector2i(c, r))
			draw_rect(Rect2(p, Vector2(_tile_size, _tile_size)), EMPTY_CELL_COLOR)

# ---------------------------------------------------------------------------
# Animation orchestration
# ---------------------------------------------------------------------------

func _on_grid_size_changed(new_size: int) -> void:
	rebuild(new_size)

func _on_move_resolved(result: MoveResult) -> void:
	if not result.moved:
		return
	animating = true
	EventBus.animation_started.emit()
	_animate(result)

func _animate(result: MoveResult) -> void:
	var next_map: Dictionary = {}   # final cell → TileView (after slides + merges)

	# 1. Slides — tile moves, value unchanged.
	var slide_awaits: Array = []
	for s in result.slides:
		var slide: MoveResult.Slide = s
		var tile: TileView = _tiles_by_cell.get(slide.from)
		if tile == null:
			continue
		tile.cell_pos = slide.to
		next_map[slide.to] = tile
		slide_awaits.append(tile.play_slide(_cell_to_pixel(slide.to)))

	# 2. Merges — two sources converge, one is freed, survivor takes new value.
	var merge_awaits: Array = []
	var survivors: Array = []   # {tile: TileView, new_value: int}
	for m in result.merges:
		var merge: MoveResult.Merge = m
		var tile_a: TileView = _tiles_by_cell.get(merge.from_a)
		var tile_b: TileView = _tiles_by_cell.get(merge.from_b)
		if tile_a != null:
			merge_awaits.append(tile_a.play_slide(_cell_to_pixel(merge.to)))
		if tile_b != null:
			merge_awaits.append(tile_b.play_slide(_cell_to_pixel(merge.to)))
		survivors.append({"tile_a": tile_a, "tile_b": tile_b, "to": merge.to, "value": merge.new_value})

	# Await all slide + merge tweens to finish.
	for a in slide_awaits:
		await a
	for a in merge_awaits:
		await a

	# Resolve merges: keep one tile, free the other, set new value, play merge pop.
	var pop_awaits: Array = []
	for entry in survivors:
		var tile_a: TileView = entry["tile_a"]
		var tile_b: TileView = entry["tile_b"]
		var to: Vector2i = entry["to"]
		var value: int = entry["value"]
		if is_instance_valid(tile_b):
			tile_b.queue_free()
		if is_instance_valid(tile_a):
			tile_a.cell_pos = to
			tile_a.set_value(value)
			next_map[to] = tile_a
			pop_awaits.append(tile_a.play_merge())
		elif is_instance_valid(tile_b):
			tile_b.cell_pos = to
			tile_b.set_value(value)
			next_map[to] = tile_b
			pop_awaits.append(tile_b.play_merge())

	# Tiles that did not slide or merge stay where they are.
	for cell in _tiles_by_cell.keys():
		var t: TileView = _tiles_by_cell[cell]
		if not is_instance_valid(t):
			continue
		if not next_map.has(t.cell_pos) and t.cell_pos == cell:
			next_map[cell] = t

	_tiles_by_cell = next_map

	for a in pop_awaits:
		await a

	# 3. Spawn — new tile appears.
	if result.spawned != null:
		var sp: MoveResult.Spawn = result.spawned
		var new_tile: TileView = _make_tile(sp.at, sp.value)
		await new_tile.play_spawn()

	animating = false
	animation_finished.emit()
	EventBus.animation_finished.emit()
