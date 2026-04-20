# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Placeholder — changes land here before their tagged release.

## [1.0.0] — 2026-04-19

First feature-complete release. Web demo live on GitHub Pages, Android debug APK
built by CI on every push to `main`.

### Added
- **Core engine** — `Board` resource with classic 2048 move resolution, merge rule
  (one merge per tile per move), win/lose detection, deterministic seeded RNG.
  42 GUT tests covering move resolution, combo scoring, FSM transitions.
- **Combo multiplier** — scoring bonus for multi-merge moves: ×1.0 / ×1.25 / ×1.5 / ×2.0.
  Floating "×N COMBO" toast on multi-merges.
- **Game modes** — Classic 4×4, Mini 3×3, Big 5×5. Separate best-score slots per mode.
- **Win → endless** — reaching 2048 prompts keep-playing / new-game; endless mode
  chases higher tiles (4096, 8192) without re-triggering the win dialog.
- **Undo** — in-memory stack capped at 16 entries. Keyboard shortcut `Ctrl+Z`.
- **Rendering** — dynamic `TileView` instances per occupied cell. Slide / merge-pop /
  spawn tweens orchestrated by `BoardView` with timer-synced phases.
- **Input** — keyboard (arrows, WASD, `Ctrl+Z`, `Esc`) and touch (swipe detector with
  40-px threshold + 1.5 dominant-axis ratio).
- **Themes** — Forest (monochrome green, default), Light (classic 2048 palette),
  Colorblind-safe (Deuteranopia-friendly). Theme propagates to board, background,
  and HUD text.
- **Persistence** — `SaveManager` autoload with `ConfigFile` at `user://save.cfg`,
  atomic writes via temp + rename. Resumes in-progress game on launch.
- **Stats** — games played, total merges, highest tile, wins, play time, best time
  to 2048. Dedicated Stats panel.
- **Achievements** — 14-entry catalog: first merge, reach 256–8192, 4-way combo,
  win 3×3 / 5×5, 10-minute speedrun, undo master, theme explorer, polyglot.
  Unlock toasts slide in from the top.
- **Localization** — English + Portuguese (BR). All UI text routed through `tr()`.
  Auto-detects OS locale on first boot.
- **Audio** — 7 SFX slots (move / merge / combo / win / game-over / achievement /
  ui-click) sourced from Kenney CC0 packs.
- **Haptics** — Android-only merge + win vibration via `Input.vibrate_handheld()`.
- **Tutorial** — 5-step first-run walkthrough with per-locale text. Replay-able
  from Settings.
- **AdMob scaffold (test mode)** — `AdService` autoload with platform dispatch
  (Android+plugin → real, else stub). Revive button on Game Over (ring buffer,
  one use per game). Banner auto-toggle by app state. Interstitial cap (every
  3rd game-over, ≥ 60 s interval). UMP consent stub on first boot. Real plugin
  install documented in `docs/ads-integration.md`.

### Infrastructure
- **Web export** — single-threaded WASM, deploy on push to `main` via GitHub
  Actions + `actions/deploy-pages@v4`. Live at
  <https://0xrnato.github.io/2048/>.
- **Android export** — gradle build, arm64-v8a + armeabi-v7a, package
  `io.rnato.twenty48`, min SDK 24 / target 35. Auto-installs build template +
  writes `.build_version` marker on CI. Debug-signed APK uploaded as artifact on
  every push.
- **CI** — four workflows: `ci` (lint + GUT tests), `export-web`,
  `export-android`, `release`. Godot 4.6.2 and templates downloaded per run.
- **Custom branding** — forest-green splash screen on boot, green tile-progression
  app icon, themed main-scene background.

## [0.0.1] — 2026-04-18

### Added
- Project scaffold: `project.godot`, empty `main.tscn`, placeholder icon.
- Repository hygiene: `.gitignore`, `.gitattributes`, `.editorconfig`, MIT `LICENSE`.
- Public documentation: `README.md`, `DESIGN.md`, `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md`, `SECURITY.md`.
- GitHub scaffolding: CI / export / release workflow skeletons, issue and PR templates,
  CODEOWNERS, Dependabot config.
- Pre-commit configuration (`gdformat`, `gdlint`, hygiene hooks, conventional-commit check).

[Unreleased]: https://github.com/0xRnato/2048/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/0xRnato/2048/releases/tag/v1.0.0
[0.0.1]: https://github.com/0xRnato/2048/releases/tag/v0.0.1
