class_name BoardView extends Control

## Renders the active `Board`. Empty cells are drawn as background rectangles in
## `_draw()`; value tiles are `TileView` instances tracked by current cell position.
## Consumes `EventBus.move_resolved` events to animate slides, merges, and spawns
## in parallel, then emits `animation_finished` so upstream systems (input, HUD) can
## re-enable interaction.

signal animation_finished

const TILE_SCENE: PackedScene = preload("res://scenes/game/tile_view.tscn")
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
	EventBus.theme_changed.connect(_on_theme_changed)
	resized.connect(_reflow)

func _on_theme_changed(_id: String) -> void:
	queue_redraw()

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

## Safe accessor — returns null if the dict entry is missing or the referenced
## tile has already been queue-freed. Avoids typed-assignment errors.
func _safe_tile(cell: Vector2i) -> TileView:
	var raw = _tiles_by_cell.get(cell)
	if raw == null or not is_instance_valid(raw):
		return null
	return raw

func _cell_to_pixel(cell: Vector2i) -> Vector2:
	return _origin + Vector2(
		cell.x * (_tile_size + TILE_GAP),
		cell.y * (_tile_size + TILE_GAP)
	)

func _draw() -> void:
	var theme_res: BoardTheme = ThemeService.current_theme
	var bg: Color = theme_res.grid_background if theme_res != null else Color("#1c1c22")
	var empty_col: Color = theme_res.empty_cell if theme_res != null else Color("#2a2a33")
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, bg)
	if _grid_size <= 0:
		return
	for r in _grid_size:
		for c in _grid_size:
			var p: Vector2 = _cell_to_pixel(Vector2i(c, r))
			draw_rect(Rect2(p, Vector2(_tile_size, _tile_size)), empty_col)

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
	var next_map: Dictionary = {}   # final cell → TileView after slides + merges.

	# 1. Slides — tile moves, value unchanged. Fire-and-forget tween.
	for s in result.slides:
		var slide: MoveResult.Slide = s
		var tile: TileView = _safe_tile(slide.from)
		if tile == null:
			continue
		tile.cell_pos = slide.to
		next_map[slide.to] = tile
		tile.play_slide(_cell_to_pixel(slide.to))

	# 2. Merges — both source tiles tween to target cell; one is freed, survivor
	# takes the doubled value after the slide phase completes.
	var survivors: Array = []
	for m in result.merges:
		var merge: MoveResult.Merge = m
		var tile_a: TileView = _safe_tile(merge.from_a)
		var tile_b: TileView = _safe_tile(merge.from_b)
		if tile_a != null:
			tile_a.play_slide(_cell_to_pixel(merge.to))
		if tile_b != null:
			tile_b.play_slide(_cell_to_pixel(merge.to))
		survivors.append({"tile_a": tile_a, "tile_b": tile_b, "to": merge.to, "value": merge.new_value})

	# Wait for the slide phase to finish (all slides share SLIDE_MS duration).
	if not result.slides.is_empty() or not result.merges.is_empty():
		await get_tree().create_timer(TileView.SLIDE_MS / 1000.0).timeout

	# Resolve merges: free one source, set new value on survivor, play merge pop.
	# Intermediate raws are untyped so invalid instances skip cleanly.
	for entry in survivors:
		var raw_a = entry["tile_a"]
		var raw_b = entry["tile_b"]
		var to: Vector2i = entry["to"]
		var value: int = entry["value"]
		var tile_a: TileView = raw_a if is_instance_valid(raw_a) else null
		var tile_b: TileView = raw_b if is_instance_valid(raw_b) else null
		if tile_b != null:
			tile_b.queue_free()
		if tile_a != null:
			tile_a.cell_pos = to
			tile_a.set_value(value)
			next_map[to] = tile_a
			tile_a.play_merge()
		elif tile_b != null:
			tile_b.cell_pos = to
			tile_b.set_value(value)
			next_map[to] = tile_b
			tile_b.play_merge()

	# Tiles that did not slide or merge stay where they are. Iterate without typing
	# the intermediate so a queue_freed instance doesn't crash the assignment —
	# `is_instance_valid` runs before any typed cast.
	for cell in _tiles_by_cell.keys():
		var raw = _tiles_by_cell[cell]
		if not is_instance_valid(raw):
			continue
		var t: TileView = raw
		if not next_map.has(t.cell_pos) and t.cell_pos == cell:
			next_map[cell] = t

	_tiles_by_cell = next_map

	# Wait for the merge pop to play out.
	if not result.merges.is_empty():
		await get_tree().create_timer(TileView.MERGE_POP_MS / 1000.0).timeout

	# 3. Spawn — new tile appears.
	if result.spawned != null:
		var sp: MoveResult.Spawn = result.spawned
		var new_tile: TileView = _make_tile(sp.at, sp.value)
		new_tile.play_spawn()
		await get_tree().create_timer(TileView.SPAWN_MS / 1000.0).timeout

	animating = false
	animation_finished.emit()
	EventBus.animation_finished.emit()
