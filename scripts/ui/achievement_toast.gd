class_name AchievementToast extends Control

## Transient notifier for `EventBus.achievement_unlocked`. Slides in from the top,
## holds for ~3 seconds, slides out. Placed in the global `Overlays` CanvasLayer.

const SLIDE_IN_MS: int = 250
const HOLD_MS: int = 3000
const SLIDE_OUT_MS: int = 300
const OFFSCREEN_Y: float = -240.0

@onready var _title_label: Label = $Panel/Title
@onready var _name_label: Label = $Panel/AchievementName

var _base_y: float = 0.0
var _queue: Array = []
var _busy: bool = false

func _ready() -> void:
	_title_label.text = tr("TOAST_ACHIEVEMENT")
	_base_y = position.y
	position.y = OFFSCREEN_Y
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(id: String) -> void:
	_queue.append(id)
	if not _busy:
		_play_next()

func _play_next() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	var id: String = _queue.pop_front()
	var entry: Dictionary = _lookup(id)
	_name_label.text = tr(entry.get("title_key", id))
	_title_label.text = tr("TOAST_ACHIEVEMENT")
	_animate()

func _animate() -> void:
	position.y = OFFSCREEN_Y
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:y", _base_y, SLIDE_IN_MS / 1000.0) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(HOLD_MS / 1000.0)
	tween.tween_property(self, "position:y", OFFSCREEN_Y, SLIDE_OUT_MS / 1000.0) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.finished.connect(_play_next)

func _lookup(id: String) -> Dictionary:
	for entry in AchievementsManager.list():
		if entry.get("id") == id:
			return entry
	return {}
