extends Node

## No-op backend for editor, web, and desktop builds. Calls print in debug so you can
## verify `AdService` wiring without a real device. Rewarded-revive auto-grants in debug
## builds so you can exercise the game-over → revive flow from the web preview.

var _config: GameConfig = null

func initialize(p_config: GameConfig) -> void:
	_config = p_config
	_log("stub backend active — no real ads will be shown")

func request_consent() -> void:
	_log("request_consent() — auto-granted in stub")

func show_banner() -> void:
	_log("show_banner()")

func hide_banner() -> void:
	_log("hide_banner()")

func show_interstitial() -> void:
	_log("show_interstitial()")

func show_rewarded_revive(on_reward: Callable) -> void:
	_log("show_rewarded_revive() — auto-granting reward in debug")
	if on_reward.is_valid():
		# Delay one frame so caller UI can close gracefully before revive logic fires.
		await get_tree().process_frame
		on_reward.call()

func _log(msg: String) -> void:
	if OS.is_debug_build():
		print("[AdService/stub] %s" % msg)
