class_name GameConfig extends Resource

## Tunable project-level configuration — ad IDs, frequency caps, combo table overrides.
## Instance lives at `res://resources/game_config.tres`.
##
## Ad IDs default to Google's public test IDs. Replace only when publishing to Play Store
## (wire via GitHub secrets in `export-android.yml`, not committed).

# --- AdMob test IDs (safe, Google-published). ---
@export var admob_app_id: String = "ca-app-pub-3940256099942544~3347511713"
@export var ad_banner_id: String = "ca-app-pub-3940256099942544/6300978111"
@export var ad_interstitial_id: String = "ca-app-pub-3940256099942544/1033173712"
@export var ad_rewarded_id: String = "ca-app-pub-3940256099942544/5224354917"

# --- Frequency caps ---
@export var interstitial_every_n_game_overs: int = 3
@export var interstitial_min_interval_seconds: int = 60

# --- Revive ---
@export var revive_moves_restored: int = 3
@export var revive_max_per_game: int = 1
