# Godot / GDScript Rules — Bust

Conventions and gotchas for writing code in this project. Follow these exactly.

---

## Engine & Language

- **Godot 4.6**, GDScript only.
- Always use **typed** declarations. GDScript's inference (`:=`) fails on `Variant`-returning
  calls and must be replaced with explicit types in these cases:
  - `var rx : float = clamp(...)` — `clamp()` returns Variant, can't infer
  - `var x : StyleBoxFlat = a if cond else b` — ternaries need explicit type, not `:=`
  - `var btn : Button = tile_rows[row][col]` — indexing an untyped Array yields Variant
  - `var clicked : bool = event is InputEventMouseButton and event.pressed` — compound
    `is` expressions can't be inferred
- Typed loops over untyped arrays: `for x : Type in array`.
- Watch for **name clashes** between a variable and a function — GDScript errors. (e.g. use
  `_sb_popup` for the StyleBoxFlat var and `_style_popup()` for the function.)
- No comments unless the WHY is non-obvious.

---

## Naming

- **Scenes (`.tscn`)**: PascalCase — `MainMenu.tscn`, `Town1.tscn`, `HiLo.tscn`.
- **Scripts (`.gd`)**: snake_case matching the scene — `main_menu.gd`, `town1.gd`, `hilo.gd`.
- **Nodes**: PascalCase — `PlayButton`, `WheelContainer`, `ConfirmGroup`.
- **`class_name`**: PascalCase — `PlinkoBoard`, `DiceSlider`.
- **Constants**: UPPER_SNAKE — `MIN_BET`, `TOWN_ID`, `FAME_TARGETS`.
- **Private vars/funcs**: leading underscore — `_fade`, `_wire_hover()`.
- **Signals**: snake_case, noun/past-tense — `badge_earned`, `threshold_changed`.
- **Signal handlers**: `_on_<node>_<signal>` — `_on_play`, `_on_town1_exit_entered`.

---

## Node references

- Reference script-driven nodes with **`%NodeName`** (unique name) — never long
  `$Path/To/Node` chains.
- Any node referenced from script must have **`unique_name_in_owner = true`** in the `.tscn`.

---

## Editing `.tscn` files

Hand-editing `.tscn` is allowed for simple node/property changes, but:

- **The Godot editor reformats `.tscn` on save** — it adds `unique_id=...` to nodes and
  reorders properties. Expect this churn; don't fight it.
- **Never hand-edit `PackedByteArray` tile data** (TileMapLayer `tile_map_data`) or other
  large binary blobs — they're editor-generated.
- **Preserve `uid="..."` lines** on the scene header and `ext_resource` entries. Removing
  them breaks references.
- **Respect `metadata/_edit_lock_ = true`** — those nodes are locked intentionally; don't
  reposition them.
- After Read-ing a `.tscn` you intend to Edit, match its exact current formatting.

---

## Common Godot 4 API gotchas

- `to_local()` is **Node2D only** — not on Control. Use `gr.position - global_position`.
- Theme overrides: `add_theme_stylebox_override()` (not `add_theme_style_override`).
- `mouse_filter`: `STOP=0`, `PASS=1`, `IGNORE=2`. `PASS` propagates to **parents only**,
  not siblings.
- `SIZE_EXPAND_FILL = 3`.
- `VideoStreamPlayer` only plays **`.ogv` (Theora)** natively — not `.mp4`.
- For input that must fire regardless of GUI focus/blocking, prefer `_input()` over
  `_unhandled_input()`.

---

## `@tool` scripts

- `town1.gd`, `cascade.gd`, and `gems_rtp_sim.gd` are `@tool` (run in the editor).
- Guard runtime-only logic with `if Engine.is_editor_hint(): return`.
- `gems_rtp_sim.gd` is `@tool extends EditorScript` — run via **File → Run** in the script
  editor, not at game runtime.

---

## Visual / color

- **All RGB values are GBA 15-bit snapped**: each channel = `(n * 8) / 255`, integer
  n ∈ [0, 31]. Formula: `gba_val = round(target * 31)`, `godot_float = gba_val * 8 / 255`.
- **Max white = `0.973`** (248/255) — never use `1.0` for white.
- UI panels: `StyleBoxFlat` with `corner_radius = 0` and a 2–3px border.

---

## Per-game code conventions

- `_fmt(val: float) -> String` helper for comma-separated numbers — **copy it into each game
  script**, don't import.
- State machines use `enum State { IDLE, ACTIVE }`.
- `const MIN_BET = 10.0` — enforce in all games.
- `const TOWN_ID` in each game script, matching its town index (0–4).
- **No house edge — ever.** All games pay true mathematical odds.
