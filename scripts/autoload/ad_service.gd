extends Node

## Platform-dispatching ad service. At boot it picks a backend:
## - Android + AdMob plugin installed → `AdServiceAdMob`
## - everything else (editor, web, desktop) → `AdServiceStub` (no-op with debug logs)
##
## Higher-level systems call `AdService.show_banner()` / `show_interstitial()` /
## `show_rewarded_revive(callback)` without knowing which backend is active.

signal revive_granted

const CONFIG_PATH: String = "res://resources/game_config.tres"

var config: GameConfig = null
var _backend: Node = null
var _consent_given: bool = false

func _ready() -> void:
	if ResourceLoader.exists(CONFIG_PATH):
		config = load(CONFIG_PATH)
	if config == null:
		config = GameConfig.new()
	_pick_backend()

func _pick_backend() -> void:
	var admob_available: bool = OS.get_name() == "Android" and ClassDB.class_exists("MobileAds")
	var script_path: String
	if admob_available:
		script_path = "res://scripts/services/ad_service_admob.gd"
	else:
		script_path = "res://scripts/services/ad_service_stub.gd"
	var backend_script: GDScript = load(script_path)
	_backend = backend_script.new()
	_backend.name = "AdBackend"
	add_child(_backend)
	_backend.call("initialize", config)

## Call once on first launch before any ad. Stub auto-grants. On Android, triggers UMP.
func request_consent() -> void:
	if _consent_given:
		return
	_backend.call("request_consent")
	_consent_given = true

func show_banner() -> void:
	_backend.call("show_banner")

func hide_banner() -> void:
	_backend.call("hide_banner")

## Respect frequency caps — caller decides WHEN to attempt. Backend decides IF to show.
func show_interstitial() -> void:
	_backend.call("show_interstitial")

## `on_reward` fires only when the user watches the ad to completion. Stub auto-fires.
## Wired so `GameOverOverlay` can subscribe once and let `AdService` relay.
func show_rewarded_revive(on_reward: Callable) -> void:
	_backend.call("show_rewarded_revive", on_reward)

func is_stub() -> bool:
	return _backend != null and _backend.name == "AdBackend" and not _backend.has_method("_admob_marker")
