class_name TutorialOverlay extends Control

## 5-step first-run walkthrough. Gated by `SaveManager.get_pref("tutorial_seen")`.
## Re-triggerable from Settings (toggle `tutorial_seen=false` and reopen).

const STEPS: Array[Dictionary] = [
	{"title_key": "TUT_STEP_1_TITLE", "body_key": "TUT_STEP_1_BODY"},
	{"title_key": "TUT_STEP_2_TITLE", "body_key": "TUT_STEP_2_BODY"},
	{"title_key": "TUT_STEP_3_TITLE", "body_key": "TUT_STEP_3_BODY"},
	{"title_key": "TUT_STEP_4_TITLE", "body_key": "TUT_STEP_4_BODY"},
	{"title_key": "TUT_STEP_5_TITLE", "body_key": "TUT_STEP_5_BODY"},
]

signal finished

@onready var _title: Label = $Frame/Title
@onready var _body: Label = $Frame/Body
@onready var _counter: Label = $Frame/Counter
@onready var _skip_btn: Button = $Frame/Buttons/Skip
@onready var _next_btn: Button = $Frame/Buttons/Next

var _step: int = 0

func _ready() -> void:
	_skip_btn.pressed.connect(_on_finish)
	_next_btn.pressed.connect(_on_next)
	visible = false

func show_from_start() -> void:
	_step = 0
	_render()
	visible = true

func _render() -> void:
	var entry: Dictionary = STEPS[_step]
	_title.text = tr(entry["title_key"])
	_body.text = tr(entry["body_key"])
	_counter.text = "%d / %d" % [_step + 1, STEPS.size()]
	_next_btn.text = tr("TUT_DONE") if _step == STEPS.size() - 1 else tr("TUT_NEXT")

func _on_next() -> void:
	if _step >= STEPS.size() - 1:
		_on_finish()
		return
	_step += 1
	_render()

func _on_finish() -> void:
	SaveManager.set_pref("tutorial_seen", true)
	visible = false
	finished.emit()
