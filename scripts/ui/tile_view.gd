class_name TileView extends Control

## Single tile on the board. In M2 purely static — the value determines background
## colour and label text. M3 will add `play_slide`, `play_merge`, `play_spawn` tweens.

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

@onready var _bg: ColorRect = $Background
@onready var _label: Label = $Label

var _value: int = 0

func _ready() -> void:
	_apply()

func set_value(v: int) -> void:
	_value = v
	if is_inside_tree():
		_apply()

func get_value() -> int:
	return _value

func _apply() -> void:
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
