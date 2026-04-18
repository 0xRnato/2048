class_name BoardTheme extends Resource

## Palette for one visual theme. Saved as a `.tres` under `resources/themes/`.
## `ThemeService` loads all three at boot and swaps them live via
## `EventBus.theme_changed`.

@export var id: String = ""
@export var display_name: String = ""
@export var background: Color = Color("#111114")
@export var grid_background: Color = Color("#1c1c22")
@export var empty_cell: Color = Color("#2a2a33")
@export var high_value_bg: Color = Color("#3c3a32")
@export var text_color_light: Color = Color("#ffffff")
@export var text_color_dark: Color = Color("#222222")
## HUD / menu text colors (decoupled from tile-text so themes can tune them independently).
@export var ui_text_primary: Color = Color("#ffffff")
@export var ui_text_secondary: Color = Color("#b0b0b8")
@export var tile_palette: Dictionary = {}   ## int (tile value) → Color

func color_for(value: int) -> Color:
	if value == 0:
		return empty_cell
	var key: String = str(value)
	if tile_palette.has(key):
		return tile_palette[key]
	if tile_palette.has(value):
		return tile_palette[value]
	return high_value_bg

func text_color_for(value: int) -> Color:
	return text_color_dark if value <= 4 else text_color_light
