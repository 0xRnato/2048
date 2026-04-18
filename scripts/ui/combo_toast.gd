class_name ComboToast extends Control

## Floating "×N COMBO" text that appears on multi-merge moves. Subscribes to
## `EventBus.combo_scored`; auto-fades after ~800 ms. Cross-board, placed in a
## CanvasLayer so it floats above `BoardView`.

const FADE_IN_MS: int = 120
const HOLD_MS: int = 500
const FADE_OUT_MS: int = 240
const RISE_PX: float = 80.0

@onready var _label: Label = $Label

var _base_y: float = 0.0

func _ready() -> void:
	_label.modulate.a = 0.0
	_base_y = position.y
	EventBus.combo_scored.connect(_on_combo_scored)

func _on_combo_scored(count: int, _score: int) -> void:
	_label.text = "×%d COMBO" % count
	_label.add_theme_font_size_override("font_size", 96 + count * 4)
	position.y = _base_y
	_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(_label, "modulate:a", 1.0, FADE_IN_MS / 1000.0)
	tween.parallel().tween_property(self, "position:y", _base_y - RISE_PX, (FADE_IN_MS + HOLD_MS) / 1000.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD_MS / 1000.0)
	tween.tween_property(_label, "modulate:a", 0.0, FADE_OUT_MS / 1000.0)
