class_name BoardView extends Control

## Renders the active `Board`. In M2 this is a static rebuild after every move —
## no animations yet. `EventBus.move_resolved` triggers a full re-render; input is
## only blocked during animations in M3.

const TILE_SCENE: PackedScene = preload("res://scenes/game/tile_view.tscn")
const BG_COLOR: Color = Color("#1c1c22")
const GRID_PADDING: int = 16
const TILE_GAP: int = 14

var _tiles: Array = []   ## Array[TileView], row-major
var _grid_size: int = 0
var _tile_size: float = 0.0

func _ready() -> void:
	EventBus.move_resolved.connect(_on_move_resolved)
	EventBus.grid_size_changed.connect(_on_grid_size_changed)
	resized.connect(_reflow)

func rebuild(size: int) -> void:
	_grid_size = size
	_clear_tiles()
	_tiles.resize(size * size)
	for r in size:
		for c in size:
			var tile: TileView = TILE_SCENE.instantiate()
			add_child(tile)
			_tiles[r * size + c] = tile
	_reflow()
	_refresh_from_board()

func _clear_tiles() -> void:
	for t in _tiles:
		if t != null and is_instance_valid(t):
			t.queue_free()
	_tiles = []

func _reflow() -> void:
	if _grid_size <= 0:
		return
	var w: float = size.x - GRID_PADDING * 2
	var h: float = size.y - GRID_PADDING * 2
	var avail: float = min(w, h)
	_tile_size = (avail - TILE_GAP * (_grid_size - 1)) / float(_grid_size)
	if _tile_size < 16.0:
		_tile_size = 16.0
	var origin: Vector2 = Vector2(
		(size.x - (_tile_size * _grid_size + TILE_GAP * (_grid_size - 1))) * 0.5,
		(size.y - (_tile_size * _grid_size + TILE_GAP * (_grid_size - 1))) * 0.5
	)
	for r in _grid_size:
		for c in _grid_size:
			var t: TileView = _tiles[r * _grid_size + c]
			t.position = origin + Vector2(c * (_tile_size + TILE_GAP), r * (_tile_size + TILE_GAP))
			t.custom_minimum_size = Vector2(_tile_size, _tile_size)
			t.size = Vector2(_tile_size, _tile_size)

func _refresh_from_board() -> void:
	if GameManager.board == null:
		return
	for r in _grid_size:
		for c in _grid_size:
			var tile: TileView = _tiles[r * _grid_size + c]
			tile.set_value(GameManager.board.cell_at(Vector2i(c, r)))

func _on_move_resolved(_result: MoveResult) -> void:
	_refresh_from_board()

func _on_grid_size_changed(new_size: int) -> void:
	rebuild(new_size)

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, BG_COLOR)
