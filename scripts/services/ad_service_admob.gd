extends Node

## Android backend. Scaffolded for integration with `poing-studios/godot-admob-plugin`.
## Until the plugin is installed under `addons/admob/` and enabled, the methods log
## warnings and fall through.
##
## Install steps (one-time on Android device testing):
##   1. Editor → AssetLib → search "AdMob Plugin" (poing-studios) → install
##   2. Project → Project Settings → Plugins → enable "AdMob"
##   3. Rebuild the Android build template (Project → Install Android Build Template)
##   4. Reopen project; the `MobileAds` class becomes available on Android exports
##
## Everywhere else this file is inert — the boot-time dispatcher in `AdService`
## routes to `AdServiceStub` when the plugin is absent.

var _config: GameConfig = null
var _banner = null
var _interstitial = null
var _rewarded = null

## Marker method used by `AdService.is_stub()` to distinguish this backend.
func _admob_marker() -> void:
	pass

func initialize(p_config: GameConfig) -> void:
	_config = p_config
	if not ClassDB.class_exists("MobileAds"):
		push_warning("[AdService/admob] plugin classes missing — running inert")
		return
	# Plugin wiring happens here once installed. Pseudocode:
	# MobileAds.initialize()
	# MobileAds.set_ad_request(AdRequest.new())
	# _banner = AdView.new()
	# _banner.ad_unit_id = _config.ad_banner_id
	# _interstitial = InterstitialAd.new()
	# _rewarded = RewardedAd.new()
	# Connect loaded / closed / user_earned_reward signals.
	print("[AdService/admob] initialize — plugin detected, backend ready")

func request_consent() -> void:
	# Trigger UMP consent form (EEA legal requirement).
	# UserMessagingPlatform.request_consent_info_update()
	# if UserMessagingPlatform.is_consent_form_available():
	#     UserMessagingPlatform.show_consent_form()
	print("[AdService/admob] request_consent — UMP not yet wired")

func show_banner() -> void:
	if _banner == null:
		return
	# _banner.load_ad(AdRequest.new())
	# _banner.show()
	pass

func hide_banner() -> void:
	if _banner == null:
		return
	# _banner.hide()
	pass

func show_interstitial() -> void:
	if _interstitial == null:
		return
	# _interstitial.load_ad(_config.ad_interstitial_id)
	# _interstitial.show()
	pass

func show_rewarded_revive(on_reward: Callable) -> void:
	if _rewarded == null:
		# Plugin not loaded — pretend the user canceled so the caller can move on.
		return
	# Listen once for `user_earned_reward`; call `on_reward` on emit.
	# _rewarded.load_ad(_config.ad_rewarded_id)
	# _rewarded.show()
	pass
