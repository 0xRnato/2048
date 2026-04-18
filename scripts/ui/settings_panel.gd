class_name SettingsPanel extends Control

## Overlay for user-facing preferences. Values persist via `SaveManager`; audio
## values propagate to `AudioManager`, language to `Locale`.

@onready var _theme_options: OptionButton = $Frame/Scroll/List/ThemeRow/Options
@onready var _language_options: OptionButton = $Frame/Scroll/List/LanguageRow/Options
@onready var _sound_slider: HSlider = $Frame/Scroll/List/SoundRow/Slider
@onready var _music_slider: HSlider = $Frame/Scroll/List/MusicRow/Slider
@onready var _haptics_check: CheckButton = $Frame/Scroll/List/HapticsRow/Toggle
@onready var _replay_tutorial_btn: Button = $Frame/Scroll/List/ReplayTutorial
@onready var _reset_save_btn: Button = $Frame/Scroll/List/ResetSave
@onready var _close_btn: Button = $Frame/Scroll/List/Close

func _ready() -> void:
	_populate_themes()
	_populate_languages()
	_resize_dropdowns()
	_load_current()
	_wire()
	visible = false

func _resize_dropdowns() -> void:
	# OptionButton's popup menu has its own theme — needs a separate font size override.
	_theme_options.get_popup().add_theme_font_size_override("font_size", 36)
	_language_options.get_popup().add_theme_font_size_override("font_size", 36)

func _populate_themes() -> void:
	_theme_options.clear()
	_theme_options.add_item(tr("SETTINGS_THEME_DARK"))
	_theme_options.set_item_metadata(0, "dark")
	_theme_options.add_item(tr("SETTINGS_THEME_LIGHT"))
	_theme_options.set_item_metadata(1, "light")
	_theme_options.add_item(tr("SETTINGS_THEME_COLORBLIND"))
	_theme_options.set_item_metadata(2, "colorblind")

func _populate_languages() -> void:
	_language_options.clear()
	_language_options.add_item(tr("SETTINGS_LANGUAGE_EN"))
	_language_options.set_item_metadata(0, "en")
	_language_options.add_item(tr("SETTINGS_LANGUAGE_PT_BR"))
	_language_options.set_item_metadata(1, "pt_BR")

func _load_current() -> void:
	var theme_pref: String = str(SaveManager.get_pref("theme"))
	for i in _theme_options.item_count:
		if _theme_options.get_item_metadata(i) == theme_pref:
			_theme_options.select(i)
			break
	var lang_pref: String = str(SaveManager.get_pref("lang"))
	if lang_pref == "":
		lang_pref = TranslationServer.get_locale()
	for i in _language_options.item_count:
		if _language_options.get_item_metadata(i) == lang_pref:
			_language_options.select(i)
			break
	_sound_slider.value = float(SaveManager.get_pref("sound_volume"))
	_music_slider.value = float(SaveManager.get_pref("music_volume"))
	_haptics_check.button_pressed = bool(SaveManager.get_pref("haptics_enabled"))

func _wire() -> void:
	_theme_options.item_selected.connect(_on_theme_selected)
	_language_options.item_selected.connect(_on_language_selected)
	_sound_slider.value_changed.connect(_on_sound_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_haptics_check.toggled.connect(_on_haptics_toggled)
	_replay_tutorial_btn.pressed.connect(_on_replay_tutorial_pressed)
	_reset_save_btn.pressed.connect(_on_reset_save_pressed)
	_close_btn.pressed.connect(_on_close_pressed)

func _on_theme_selected(idx: int) -> void:
	var key: String = str(_theme_options.get_item_metadata(idx))
	SaveManager.set_pref("theme", key)
	ThemeService.apply(key)

func _on_language_selected(idx: int) -> void:
	var key: String = str(_language_options.get_item_metadata(idx))
	SaveManager.set_pref("lang", key)
	Locale.set_locale(key)
	AchievementsManager.on_language_changed(key)

func _on_sound_changed(v: float) -> void:
	SaveManager.set_pref("sound_volume", v)
	AudioManager.set_sfx_volume(v)

func _on_music_changed(v: float) -> void:
	SaveManager.set_pref("music_volume", v)
	AudioManager.set_music_volume(v)

func _on_haptics_toggled(on: bool) -> void:
	SaveManager.set_pref("haptics_enabled", on)
	Haptics.enabled = on

func _on_replay_tutorial_pressed() -> void:
	SaveManager.set_pref("tutorial_seen", false)
	visible = false

func _on_reset_save_pressed() -> void:
	SaveManager.reset_all()
	_load_current()

func _on_close_pressed() -> void:
	visible = false
