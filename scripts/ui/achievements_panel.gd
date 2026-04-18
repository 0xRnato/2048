class_name AchievementsPanel extends Control

## Scrollable list of every achievement in the catalog, with locked / unlocked
## state. Repopulates on `visibility_changed`.

@onready var _list: VBoxContainer = $Frame/Scroll/List
@onready var _close_btn: Button = $Frame/Close

func _ready() -> void:
	_close_btn.pressed.connect(_on_close)
	visibility_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if not visible:
		return
	for child in _list.get_children():
		child.queue_free()
	for entry in AchievementsManager.list():
		_list.add_child(_make_row(entry))

func _make_row(entry: Dictionary) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 80)
	row.add_theme_constant_override("separation", 20)

	var status: Label = Label.new()
	var unlocked: bool = AchievementsManager.is_unlocked(entry["id"])
	status.text = "✓" if unlocked else "✕"
	status.add_theme_font_size_override("font_size", 48)
	status.add_theme_color_override("font_color",
		Color("#f0b429") if unlocked else Color("#5a5a68"))
	status.custom_minimum_size = Vector2(60, 0)
	row.add_child(status)

	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_col)

	var name_label: Label = Label.new()
	name_label.text = tr(entry.get("title_key", entry["id"]))
	name_label.add_theme_font_size_override("font_size", 38)
	text_col.add_child(name_label)

	var desc_key: String = entry.get("desc_key", "")
	if desc_key != "":
		var desc_label: Label = Label.new()
		desc_label.text = tr(desc_key)
		desc_label.add_theme_font_size_override("font_size", 28)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1))
		text_col.add_child(desc_label)

	return row

func _on_close() -> void:
	visible = false
