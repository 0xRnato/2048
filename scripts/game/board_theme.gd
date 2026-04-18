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
@export var tile_palette: Dictionary = {}   ## int (tile value) → Color

func color_for(value: int) -> Color:
	if value == 0:
		return empty_cell
	if tile_palette.has(value):
		return tile_palette[value]
	return high_value_bg

func text_color_for(value: int) -> Color:
	return text_color_dark if value <= 4 else text_color_light
