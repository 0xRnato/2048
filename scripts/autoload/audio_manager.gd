extends Node

## Centralised SFX playback. One `AudioStreamPlayer` per bus ("sfx", "music") plus
## a key → stream map loaded from `res://assets/sfx/*.ogg`. Streams load lazily; if
## a file is missing the key silently no-ops and prints a debug warning (useful while
## audio assets are still being sourced — M3 wires the routing, actual audio files
## arrive incrementally).

const STREAM_PATHS: Dictionary = {
	"move": "res://assets/sfx/move.ogg",
	"merge": "res://assets/sfx/merge.ogg",
	"combo": "res://assets/sfx/combo.ogg",
	"win": "res://assets/sfx/win.ogg",
	"game_over": "res://assets/sfx/game_over.ogg",
	"achievement": "res://assets/sfx/achievement.ogg",
	"ui_click": "res://assets/sfx/ui_click.ogg",
}

var sfx_volume_linear: float = 0.8
var music_volume_linear: float = 0.6

var _sfx_player: AudioStreamPlayer
var _streams: Dictionary = {}   # key → AudioStream

func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)
	_preload_streams()
	_connect_events()

func _preload_streams() -> void:
	for key in STREAM_PATHS.keys():
		var path: String = STREAM_PATHS[key]
		if ResourceLoader.exists(path):
			_streams[key] = load(path)
		elif OS.is_debug_build():
			print("[AudioManager] stream missing: %s (no-op until asset arrives)" % path)

func _connect_events() -> void:
	EventBus.move_resolved.connect(_on_move_resolved)
	EventBus.tile_merged.connect(_on_tile_merged)
	EventBus.combo_scored.connect(_on_combo_scored)
	EventBus.game_won.connect(_on_game_won)
	EventBus.game_over_reached.connect(_on_game_over)
	EventBus.achievement_unlocked.connect(_on_achievement)

func play(key: String) -> void:
	var stream: AudioStream = _streams.get(key)
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = linear_to_db(sfx_volume_linear)
	_sfx_player.play()

func set_sfx_volume(v: float) -> void:
	sfx_volume_linear = clampf(v, 0.0, 1.0)

func set_music_volume(v: float) -> void:
	music_volume_linear = clampf(v, 0.0, 1.0)

# ---------------------------------------------------------------------------
# Event handlers
# ---------------------------------------------------------------------------

func _on_move_resolved(result: MoveResult) -> void:
	if result.moved:
		play("move")

func _on_tile_merged(_value: int) -> void:
	play("merge")

func _on_combo_scored(_count: int, _score: int) -> void:
	play("combo")

func _on_game_won() -> void:
	play("win")

func _on_game_over() -> void:
	play("game_over")

func _on_achievement(_id: String) -> void:
	play("achievement")
