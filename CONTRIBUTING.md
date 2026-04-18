# Contributing

## Language

- **English** in code, commits, comments, file names, technical docs.
- **Portuguese (BR)** allowed only in UI strings routed through i18n (`tr("KEY")`) — the
  source string itself is still in English; translations live in `translations/pt_BR.po`.

## Commit conventions

[Conventional Commits](https://www.conventionalcommits.org/) with these rules:

- **Type** — one of `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`,
  `ci`, `build`, `revert`.
- **Scope** — optional, kebab-case, one or two words: `feat(board):`, `fix(ads):`,
  `ci(export-web):`. Leave off for wide changes.
- **Subject** — lowercase, no trailing period, < 72 characters. Imperative mood
  ("add undo button" not "added undo button").
- **Body** — only when the *why* is non-obvious. The diff explains the *what*.
- **No AI co-authors.** No `Co-Authored-By: Claude` lines, no "Generated with" markers.
  Author is `Renato Neto <rnato.netoo@gmail.com>`.

### Examples

```
feat(board): add combo multiplier to move_result score calculation
fix(input): swipe threshold too low on high-dpi screens
docs: add ads integration walkthrough
ci(export-android): cache godot export templates by version
```

## Branching

- **Trunk-based.** Push directly to `main` for small, self-contained changes.
- **Short-lived feature branches** for larger milestones (M6+). Branch name: `feat/<scope>`
  or `fix/<scope>`. Squash-merge PRs to keep `main` linear.
- No long-lived `develop` / `release` branches.

## Code style

GDScript, strictly typed:

```gdscript
class_name Board extends Resource

@export var size: int = 4

var _cells: Array[int]

func attempt_move(dir: Vector2i) -> MoveResult:
    ...
```

- `snake_case.gd` file names; `PascalCase` for `class_name`.
- `SCREAMING_SNAKE_CASE` for `const` and enum values.
- `_` prefix for private members.
- Every variable, function parameter, and return type annotated.
- `@export` tunables so values live in the editor, not hard-coded.
- Signals in past tense for events (`tile_merged`, `state_changed`), present for commands
  (`move_requested`).
- Prefer composition: small scenes composed in bigger ones, not deep inheritance.

## Pre-commit

Install once per clone:

```bash
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg
```

Hooks configured in `.pre-commit-config.yaml`:

- `gdformat --check` — format
- `gdlint` — lint
- `trailing-whitespace`, `end-of-file-fixer`, `check-yaml`, `check-json` — hygiene
- `conventional-pre-commit` — commit-msg validation

CI duplicates these checks, so pre-commit is a local-dev convenience, not a gate.

## Tests

GUT is committed under `addons/gut/`. Run from project root:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit -gexit
```

- Unit tests for pure logic (`board.gd`, `move_result.gd`, `save_manager.gd`) in
  `tests/unit/`. Target: **≥ 90 %** line coverage on game logic.
- Integration tests for FSM + save flow in `tests/integration/`.
- Tests must run without a scene tree (no `get_tree()` in unit tests).

## PR checklist

- [ ] Commit follows Conventional Commits.
- [ ] `gdformat` and `gdlint` pass locally.
- [ ] Tests updated or added for any logic change.
- [ ] `godot --headless --import` passes with zero errors.
- [ ] If the change affects gameplay feel, tested against the web build (not only the editor).
- [ ] If the change adds a user-facing string, added to `translations/translations.csv`.

## Release process

See [`docs/release-process.md`](./docs/release-process.md). TL;DR: update `CHANGELOG.md`,
tag `vMAJOR.MINOR.PATCH`, push tag; the release workflow does the rest.

## Reporting bugs

Use the **Bug report** issue template. Include Godot version, platform, reproducer steps,
and expected vs. actual behavior. Crashes: attach the log from `user://logs/`.

## Reporting security issues

See [`SECURITY.md`](./SECURITY.md). Do not open a public issue for security reports.
