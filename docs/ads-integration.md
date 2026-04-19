# Ads integration

Android build integrates Google AdMob **in test mode only** as a learning exercise
for the full production flow (UMP consent → banner → interstitial → rewarded).
Test IDs are the Google-published ones, safe to ship; real IDs are swapped in via
GitHub secrets when (and if) the game is published to the Play Store.

## Architecture

```
GameOverOverlay / GameManager / …
              │
              ▼
  AdService  (autoload, scripts/autoload/ad_service.gd)
              │
    ┌─────────┴───────────┐
    ▼                     ▼
AdServiceStub      AdServiceAdMob
  (web, editor,     (Android with poing-studios
  desktop builds)    plugin installed)
```

`AdService._pick_backend()` runs at boot:

| Condition                                             | Backend          |
|------------------------------------------------------|------------------|
| `OS.get_name() == "Android"` AND `ClassDB.class_exists("MobileAds")` | AdMob real ads   |
| any other combination                                | Stub (no-op + debug logs) |

Higher systems never call the backends directly — they call the autoload
(`AdService.show_banner()` etc).

## Game config

`resources/game_config.tres` holds ad unit IDs + frequency caps. Defaults are
Google's test IDs:

| Unit          | Test ID                                       |
|---------------|-----------------------------------------------|
| App ID        | `ca-app-pub-3940256099942544~3347511713`     |
| Banner        | `ca-app-pub-3940256099942544/6300978111`     |
| Interstitial  | `ca-app-pub-3940256099942544/1033173712`     |
| Rewarded      | `ca-app-pub-3940256099942544/5224354917`     |

Frequency caps:

- Interstitial: every 3 game-overs AND at least 60 seconds since the last one.
- Rewarded revive: one per game.

## UX rules

- **Banner** — visible only in `PLAYING` and `ENDLESS` states. Hidden in menu,
  pause, win dialog, game-over overlay, settings, etc.
- **Interstitial** — fires on `GAME_OVER` transition, gated by the caps above.
  Never fires during the rest of the flow.
- **Rewarded revive** — opt-in button on the game-over overlay that restores
  the last 3 pre-game-over moves (via a ring buffer separate from the undo
  stack). Limited to one revive per game. Button is hidden if the revive
  buffer is empty or the revive was already used.
- **Web, editor, desktop** — no real ads, no network calls. Stub logs to
  console in debug builds so you can verify wiring.

## UMP consent

Google's User Messaging Platform SDK is a legal requirement in the EEA/UK,
even for test-mode ads. The consent form is requested once on first boot via
`AdService.request_consent()`. Until the real plugin is installed the stub
auto-grants.

When the real plugin is installed, wire these signals in
`scripts/services/ad_service_admob.gd`:

- `UserMessagingPlatform.request_consent_info_update`
- `UserMessagingPlatform.show_consent_form` (if `consent_form_available`)

Gate every ad call on the consent outcome. If the user denies, fall back to
stub behaviour (no ads served).

## Installing the real AdMob plugin on Android

The Godot 4 AdMob integration we target is
[`poing-studios/godot-admob-plugin`](https://github.com/poing-studios/godot-admob-plugin).

1. In the Godot editor, open `AssetLib` and search for **AdMob Plugin** (author
   `poing-studios`). Install to the project — it lands under `addons/admob/`.
2. `Project` → `Project Settings` → `Plugins` → enable **AdMob**.
3. Reinstall the Android build template (`Project` → `Install Android Build
   Template`) so the plugin-modified AndroidManifest is picked up.
4. Reopen the project. `MobileAds`, `AdView`, `InterstitialAd`, and
   `RewardedAd` classes should now be available. `AdService` auto-routes to
   `AdServiceAdMob` on the next Android launch.
5. Fill in the TODO comments inside
   `scripts/services/ad_service_admob.gd` — instantiate the plugin objects,
   wire `user_earned_reward` / `ad_loaded` / `ad_failed_to_load` signals.

## Going to production (Play Store)

Switch from test IDs to real ones without committing the real IDs to the repo:

1. Register the app in the AdMob console, note the real App ID + Unit IDs.
2. Add GitHub secrets:
   - `ADMOB_APP_ID`
   - `ADMOB_BANNER_ID`
   - `ADMOB_INTERSTITIAL_ID`
   - `ADMOB_REWARDED_ID`
3. In `.github/workflows/export-android.yml`, before export:
   ```bash
   sed -i "s|ca-app-pub-3940256099942544~3347511713|$ADMOB_APP_ID|" resources/game_config.tres
   sed -i "s|ca-app-pub-3940256099942544/6300978111|$ADMOB_BANNER_ID|" resources/game_config.tres
   # … same for interstitial + rewarded
   ```
4. Production Android exports now use real IDs; debug builds + web still ship
   with test IDs (which is fine — Google allows test IDs indefinitely).

Keep the repository copy of `game_config.tres` on test IDs forever. The
production swap only happens in CI.
