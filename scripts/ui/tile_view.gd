class_name TileView extends Control

## Single tile on the board. Owns its own value, palette lookup, and animations
## (`play_slide`, `play_merge`, `play_spawn`). Animations are awaitable so
## `BoardView` can orchestrate them in parallel and `await` the whole move.

const PALETTE_BG: Dictionary = {
	0: Color("#2a2a33"),
	2: Color("#3b3b47"),
	4: Color("#454e5a"),
	8: Color("#f2b179"),
	16: Color("#f59563"),
	32: Color("#f67c5f"),
	64: Color("#f65e3b"),
	128: Color("#edcf72"),
	256: Color("#edcc61"),
	512: Color("#edc850"),
	1024: Color("#edc53f"),
	2048: Color("#edc22e"),
}
const PALETTE_FG_LIGHT: Color = Color("#ffffff")
const PALETTE_FG_DARK: Color = Color("#222222")
const HIGH_VALUE_BG: Color = Color("#3c3a32")

const SLIDE_MS: int = 120
const MERGE_POP_MS: int = 120
const SPAWN_MS: int = 80

@onready var _bg: ColorRect = $Background
@onready var _label: Label = $Label

var _value: int = 0
var cell_pos: Vector2i = Vector2i.ZERO   ## Logical board cell this tile currently represents.

func _ready() -> void:
	pivot_offset = size * 0.5
	_apply()

func set_value(v: int) -> void:
	_value = v
	if is_inside_tree():
		_apply()

func get_value() -> int:
	return _value

func _apply() -> void:
	pivot_offset = size * 0.5
	if _value == 0:
		_bg.color = PALETTE_BG[0]
		_label.text = ""
		return
	_bg.color = PALETTE_BG.get(_value, HIGH_VALUE_BG)
	_label.text = str(_value)
	_label.add_theme_color_override("font_color", _text_color_for(_value))
	_label.add_theme_font_size_override("font_size", _font_size_for(_value))

static func _text_color_for(v: int) -> Color:
	return PALETTE_FG_DARK if v <= 4 else PALETTE_FG_LIGHT

static func _font_size_for(v: int) -> int:
	if v < 100:
		return 96
	elif v < 1000:
		return 80
	elif v < 10000:
		return 64
	return 48

# ---------------------------------------------------------------------------
# Animations
# ---------------------------------------------------------------------------

## Tween `position` to `to_pos` with ease-out-cubic. Awaitable.
func play_slide(to_pos: Vector2) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", to_pos, SLIDE_MS / 1000.0) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

## Brief scale pop to signal a merge completion. Awaitable.
func play_merge() -> void:
	pivot_offset = size * 0.5
	var half: float = MERGE_POP_MS / 2000.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), half) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2.ONE, half) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

## Fade + scale from 0 → 1, for new tiles spawned on a successful move. Awaitable.
func play_spawn() -> void:
	pivot_offset = size * 0.5
	scale = Vector2.ZERO
	modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, SPAWN_MS / 1000.0) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, SPAWN_MS / 1000.0)
	await tween.finished
