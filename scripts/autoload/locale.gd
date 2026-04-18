extends Node

## Applies locale at boot based on `prefs/lang` (set in Settings) or OS default.
## Updates `TranslationServer.set_locale()`. `.csv` translation file is configured
## in `project.godot` under `internationalization/locale/translations_pot_files`.

const SUPPORTED_LOCALES: Array[String] = ["en", "pt_BR"]
const FALLBACK_LOCALE: String = "en"

func _ready() -> void:
	apply_from_prefs()

func apply_from_prefs() -> void:
	var pref: String = str(SaveManager.get_pref("lang"))
	var target: String = pref if pref != "" else _detect_os_locale()
	set_locale(target)

func set_locale(locale: String) -> void:
	if locale not in SUPPORTED_LOCALES:
		locale = FALLBACK_LOCALE
	TranslationServer.set_locale(locale)

func _detect_os_locale() -> String:
	var os_loc: String = OS.get_locale()
	for supported in SUPPORTED_LOCALES:
		if os_loc.begins_with(supported):
			return supported
		# Godot uses underscore form like "pt_BR"; OS may return "pt_BR" or "pt-BR".
		if os_loc.replace("-", "_").begins_with(supported):
			return supported
	return FALLBACK_LOCALE
