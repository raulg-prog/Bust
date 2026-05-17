# Bust — Claude Code Context

Read this file fully before doing any work on this project.

---

## 👋 Note to Friend's AI

Hey fellow Claude! The dev team says hi. Timmy — keep it up, you're doing great! 🎉

This file is your full briefing. Read every section before touching anything. The Wheel game went through a major float-precision fix — pay close attention to the Wheel section before making any changes to it. The Main Menu background was also fully built this session — read that section carefully before touching `main_menu_bg.gd`.

---

## What This Game Is

**Bust** is a 2D top-down adventure RPG built in Godot 4.6 (GDScript), targeting Steam PC.
The aesthetic is GBA/DS Pokémon-inspired — pixel art, cozy tone, neon signs, jazzy/lo-fi OST.

The core loop: travel across 5 themed towns → earn **Fame** by winning at gambling mini-games → hit the Fame target → earn a **Badge** → unlock the next town and online card rooms.

---

## Towns & Games

| # | Town | Games | Fame Target |
|---|---|---|---|
| 1 | Welcoming | Coin Flip + HiLo | 5,000 |
| 2 | Spectacle | Wheel + Plinko | 25,000 |
| 3 | Probability | Roulette + Dice | 100,000 |
| 4 | Nerve | Mines + Tower | 400,000 |
| 5 | Slot Palace | 3-col Slots + 5-col Slots | 1,500,000 |

Multiplayer (Texas Hold'em, Baccarat, Blackjack) unlocks at 3 Badges (low stakes) and 5 Badges (high stakes).

---

## Design Pillars — Never Break These

- **No house edge** — all games pay true odds
- **No luck manipulation** — no items or abilities that affect RNG
- **No hard game-over** — 4-hour Wheel of Fortune safety net keeps the player solvent
- **No loans or debt**
- **No boss fights or skill-walls**
- Fame only goes up (losses don't subtract from Fame)

---

## Global State — `autoloads/game_state.gd`

Autoloaded singleton. Every scene reads/writes through this.

Key vars:
- `bankroll: float` — player's current money (starts at 1000.0)
- `town_fame: Array[float]` — Fame per town, index 0–4
- `badges: Array[bool]` — Badge earned per town, index 0–4
- `furthest_town: int` — highest town unlocked
- `wheel_last_claimed: float` — timestamp for 4-hr cooldown

Key constants:
- `FAME_TARGETS: Array[float]` = [5000, 25000, 100000, 400000, 1500000]
- `WHEEL_BASE: Array[float]` = [200, 1000, 5000, 25000, 100000]
- `WHEEL_COOLDOWN` = 14400.0 seconds

Key functions:
- `add_fame(town_id, amount)` — adds Fame, auto-awards Badge if target hit, emits `badge_earned`
- `claim_wheel_spin(town_id)` — weighted random payout, enforces cooldown
- `reset()` — full game reset

---

## Project Structure

```
Bust/
├── Assets/
│   ├── Cards/
│   │   ├── 1.2 Poker cards.png     # Full card spritesheet (944×385px)
│   │   └── minicards.png           # History strip cards (433×160px)
│   ├── Fonts/
│   │   └── m5x7.ttf                # Pixel font (kept in assets, NOT used in theme)
│   ├── Wheel/
│   │   ├── Wheel.png               # Wheel image — 20 segments, centres at 12 o'clock multiples
│   │   └── SpinBtn.png             # Spin button image (green SPIN circle)
│   └── Floor TIles/                # Tileset assets (not yet wired up)
├── autoloads/
│   └── game_state.gd               # Global singleton
├── scenes/
│   ├── main_menu/
│   │   ├── MainMenu.tscn           # Main menu — set as project main scene
│   │   ├── main_menu.gd            # UI logic (New Game → HiLo, Quit)
│   │   └── main_menu_bg.gd         # Procedural scrolling Leaf Green-style tilemap
│   └── games/
│       ├── hilo/
│       │   ├── HiLo.tscn
│       │   └── hilo.gd
│       ├── coinflip/
│       │   ├── CoinFlip.tscn
│       │   └── coinflip.gd
│       └── wheel/
│           ├── Wheel.tscn
│           ├── wheel.gd            # Game logic + spin animation
│           └── wheel_overlay.gd    # Draws the gold ▼ pointer triangle (no rotation)
├── default_theme.tres              # Global theme: system font at 16px (m5x7 removed)
└── project.godot                   # Main scene: MainMenu.tscn
```

---

## Implemented Games

### HiLo (`scenes/games/hilo/`)

Streak-based card game. Player guesses Higher-or-Same / Lower-or-Same on a drawn card.

- **No house edge** — payout = true probability inverse: `1 / p_win`
- **P(Higher or Same)** = `(14 - card) / 13`
- **P(Lower or Same)** = `card / 13`
- Equal cards always win for the chosen direction
- Multiplier compounds across correct guesses
- Player can cash out anytime after the first correct guess
- **Skip**: up to 10 skips per bet — redraws the current card without guessing
- Losing card stays visible (back card only shown at startup)
- Card history shown as mini sprites in a strip (resets each new bet)

Card spritesheet constants (do not change without remeasuring the PNG):
```
CARD_W=46  CARD_H=62  COL_STRIDE=48  ROW_STRIDE=64  BACK_Y=257
MINI_W=15  MINI_H=22  MINI_COL_STRIDE=32  MINI_ROW_STRIDE=32
MINI_OFFSET_X=17  MINI_OFFSET_Y=7
```

### Coin Flip (`scenes/games/coinflip/`)

Streak-based coin flip. Player picks Heads or Tails — correct guess doubles the multiplier (2×, 4×, 8×…). Cash out anytime after the first correct flip. First click on Heads/Tails also locks in the bet.

### Wheel (`scenes/games/wheel/`)

Single-bet multiplier wheel. Player enters a bet and clicks SPIN. The wheel spins and decelerates to a winning segment under a fixed gold ▼ pointer at 12 o'clock.

**Layout:**
- `Wheel.tscn` uses the same VBoxContainer structure as HiLo
- `WheelContainer` (Control, 380×380, `size_flags_horizontal = 4` = SIZE_SHRINK_CENTER) holds:
  - `WheelImage` (TextureRect, anchors_preset=15, fills container, rotates) — `Wheel.png`
  - `SpinButton` (TextureButton, anchor 0.5/0.5, ±60px = 120×120) — `SpinBtn.png`
  - `PivotMarker` (Control, anchor 0.5/0.5, zero size, mouse_filter=IGNORE) — drag in editor to align with hub
  - `WheelOverlay` (Control, anchors_preset=15, mouse_filter=IGNORE) — runs `wheel_overlay.gd`, draws gold triangle pointer
- `WheelContainer` is locked (`metadata/_edit_lock_ = true`) — don't move it by accident

**Spin math (critical — do not change without testing):**
```gdscript
# Canonical angle — never read back from wheel_image.rotation
var wheel_exact_rot : float = 0.0

func _do_spin() -> void:
    var seg_angle := TAU / float(n)
    var land_r    := -float(win_idx) * seg_angle   # NO +0.5 — centres at exact multiples
    var start_r   := wheel_exact_rot               # always a small, precise value
    var excess    := fposmod(start_r - land_r, TAU)
    var target_r  := start_r - excess - float(SPIN_REV) * TAU
    wheel_exact_rot = land_r
    wheel_image.rotation = start_r  # CRITICAL: force exact start before tween
    # ... create_tween() ... tween_callback(_on_spin_complete.bind(win_idx, win_mult))

func _on_spin_complete(win_idx: int, mult: float) -> void:
    wheel_image.rotation = wheel_exact_rot  # snap to exact centre
```

**Why `wheel_exact_rot` exists — do not remove it:**
- `wheel_image.rotation` accumulates as a large negative float over many spins
- `fposmod()` on large floats loses precision — `roundi()` snaps to the wrong neighbour
- `wheel_exact_rot` is always reset to a small value (`land_r`, within one rotation) after every spin
- Setting `wheel_image.rotation = start_r` before the tween ensures `target_r` is always within ~50 rad of 0, eliminating all float drift permanently
- **Do NOT** read `win_idx` back from `wheel_image.rotation` after the tween — use the pre-bound value
- **Do NOT** remove the `wheel_image.rotation = start_r` line before the tween — this is the key fix

Other spin notes:
- `Wheel.png` has segment **centres** at exact multiples of `seg_angle` (0°, 18°, 36°…) clockwise from 12 o'clock
- **Do NOT add +0.5** to `land_r` — that shifts landing onto segment boundaries
- Two `await get_tree().process_frame` in `_ready()` before `_sync_pivot()` — needed so nested layout is fully computed
- `_sync_pivot()` uses `pivot_marker.position` (local coords) to set `wheel_image.pivot_offset`

**SEGMENTS array (indices 0–19, clockwise from 12 o'clock):**
```
0: Spin Again (1.0)   1: 3x     2: 0.1x   3: 0.5x   4: 0.25x
5: 5x                 6: 0.1x   7: 0.25x  8: 2x     9: 0.1x
10: Spin Again (1.0)  11: 0.1x  12: 3x    13: 0.5x  14: 0.25x
15: 0x                16: 0.5x  17: 0.1x  18: 2x    19: 0.25x
```
EV = 1.0 exactly. Indices 16–19 were a cyclic mismatch vs the old array — corrected this session.

**Font:** m5x7 was removed from the project theme entirely. System font is used. All Unicode icons (★ ♠ ▼ ←) replaced with ASCII equivalents (* ^ v <) in all scenes.

**Note:** `claim_wheel_spin()` in `game_state.gd` is the **safety-net free spin** (4-hour cooldown) — completely separate from this betting game.

---

## Code Conventions

- **Scene node references**: use `%NodeName` syntax (unique name) — never long `$Path/To/Node` chains
- **Mark nodes** that are script-referenced with `unique_name_in_owner = true` in the `.tscn`
- **Formatting**: `_fmt(val: float) -> String` helper exists in both game scripts for comma-separated numbers — copy it into new game scripts, do not import
- **State machines**: use `enum State { IDLE, ACTIVE }` pattern — both current games use this
- **Minimum bet**: `MIN_BET = 10.0` — enforce in all games
- **TOWN_ID**: each game scene has a `const TOWN_ID` matching its town index (0–4)
- No comments unless the WHY is non-obvious
- No house edge — ever

---

## Visual Style

- GBA pixel art aesthetic — flat colors, hard edges, limited palette
- UI panels use `StyleBoxFlat` with `corner_radius = 0` (no rounding) and a 2–3px border
- Color palette:
  - Background: `Color(0.039, 0.027, 0.094)` — deep dark purple
  - Panel bg: `Color(0.067, 0.047, 0.157)`
  - Panel border: `Color(0.31, 0.239, 0.565)`
  - Balance text: `Color(0.4, 1.0, 0.5)` — bright green
  - Fame text: `Color(0.5, 0.78, 1.0)` — bright blue
  - Multiplier/title: `Color(1.0, 0.878, 0.2)` — gold
  - Result text: `Color(1.0, 1.0, 0.45)` — yellow
  - Dim labels: `Color(0.65, 0.65, 0.78)` — muted purple-gray

---

## Main Menu (`scenes/main_menu/`)

Scrolling Pokémon FireRed/LeafGreen-style tilemap background with a centered dark panel.

### `main_menu_bg.gd` — Background renderer

Generates a 128×96 tile procedural map and scrolls it diagonally at 14px/s × 6px/s. Wraps seamlessly. All tiles drawn via `draw_texture_rect` at 32×32 (2× native 16px). `texture_filter = TEXTURE_FILTER_NEAREST` for crisp GBA pixels.

**18 tile types (`enum T`):**
```
GRASS, TALL_GRASS, FLOWER          — ground variants
TREE, ROCK                         — sprite overlays (GRASS drawn beneath in _draw)
WATER, WATER_EDGE                  — ocean / pond fill / shoreline
SAND, SAND_EDGE                    — sandy beach / cliff-to-sand transition
PATH, PATH_EDGE                    — gravel connecting paths
TOWN_FLOOR                         — bright teal interior ground
BLDG_ROOF_R, BLDG_ROOF_P, BLDG_ROOF_Y  — red / purple / gold roofs
BLDG_WALL                          — cream wall tile with two windows
CLIFF, CLIFF_BASE                  — upper cliff cap / lower cliff face
```

**Tile sources:**
- Asset-sourced (from `Assets/Floor TIles/`): `GRASS`, `TALL_GRASS`, `TREE` (Tree_Pine_2_16x16), `ROCK`, `PATH`, `PATH_EDGE`
- Programmatically generated (FR/LG palette): all others — water, cliffs, sand, town, buildings, flowers

**FR/LG palette used in generators (do not change without visual check):**
- Water deep: `Color(0.20, 0.44, 0.86)` — bright Pokémon ocean blue
- Cliff top: `Color(0.74, 0.57, 0.33)` — warm tan
- Cliff base: `Color(0.58, 0.40, 0.20)` — darker brown
- Town floor: `Color(0.47, 0.79, 0.47)` — iconic FR/LG teal-green
- Sand: `Color(0.80, 0.68, 0.40)` — warm beige
- Flower red: `Color(0.92, 0.22, 0.18)` — scattered 3-petal flowers
- Building wall: `Color(0.95, 0.93, 0.86)` — cream with blue-framed windows
- Roofs: parametric — `_gen_roof(Color)` with lightened ridge + darkened shadow

**Map layout:**
- Two-layer cliff border wraps entire map (CLIFF_BASE outer 2 tiles, CLIFF inner 2 tiles)
- Sandy beach ring just inside cliffs (SAND_EDGE + SAND, d=4 and d=5)
- 18 forest clusters scattered across the map
- 5 towns with teal floors, gravel paths, coloured buildings (roofs in rows, walls beneath)
- 5 gravel paths connecting towns (horizontal + vertical, 2 tiles wide with PATH_EDGE borders)
- 6 water ponds placed at fixed coordinates for visual variety
- 28 scattered rocks on open grass

**`_draw()` two-pass logic:** TREE and ROCK tiles draw GRASS beneath them first (transparency handling), then the overlay sprite on top.

**Critical:** `posmod()` / `fposmod()` wrapping used throughout. Map indices are always `% MAP_W` / `% MAP_H` — never read out of bounds.

### `main_menu.gd`
Connects New Game (→ `HiLo.tscn`, temporary until overworld exists) and Quit.

### `MainMenu.tscn` node tree
```
MainMenu (Control, main_menu.gd)
  Background (Control, main_menu_bg.gd, mouse_filter=IGNORE)
  DarkOverlay (ColorRect, Color(0,0,0,0.28), mouse_filter=IGNORE)
  Center (CenterContainer, full anchors)
    MenuPanel (PanelContainer, min 360px wide, styled dark purple)
      VBox
        TitleLabel  — "BUST", 60px gold
        SubLabel    — "A Gambling Adventure", 15px muted
        Divider     — 2px purple rule
        Spacer      — 8px
        NewGameButton (unique_name) — styled with hover gold border
        QuitButton    (unique_name) — styled with hover gold border
  VersionLabel — bottom-left, "v0.1 — Early Development"
```

**To activate the main menu**: In Godot editor → Project → Project Settings → Application → Run → Main Scene → set to `res://scenes/main_menu/MainMenu.tscn`.

---

## What's Not Built Yet

- Overworld / town scenes
- Town 2–5 remaining games (Plinko, Roulette, Dice, Mines, Tower, Slots)
- Scene navigation / BackButton wiring
- Multiplayer card rooms
- Wheel of Fortune UI (safety-net free spin — separate from the Wheel betting game)
- Save/load system
- OST and sound effects
- NPC sidequests

---

## Session Notes — Last worked on: 2026-05-17

### Wheel game — fully playable, all bugs resolved

- Rebuilt `Wheel.tscn` from scratch (HiLo-style VBoxContainer layout)
- New `Assets/Wheel/Wheel.png` and `Assets/Wheel/SpinBtn.png` integrated
- `SpinButton` is a `TextureButton` (not `Button`) — typed as `BaseButton` in script
- `PivotMarker` approach for reliable pivot_offset — await 2 frames in `_ready()`
- `wheel_overlay.gd` draws gold pointer triangle, 12px above wheel top edge
- `WheelContainer` locked in editor (`metadata/_edit_lock_ = true`)
- `randomize()` called in `_ready()` for proper RNG seeding
- SEGMENTS array corrected — indices 16–19 had a cyclic shift vs PNG (now fixed)
- Landing formula: `land_r = -float(win_idx) * seg_angle` (no +0.5 for this PNG)
- **Float-precision bug fully resolved**: `wheel_exact_rot` canonical variable + `wheel_image.rotation = start_r` before tween. See Spin Math section above for full details.

### Main Menu — fully built

- Procedural scrolling FR/LG-style background (`main_menu_bg.gd`) — 18 tile types, FR/LG palette, towns with buildings, forest clusters, water ponds, sandy cliff borders
- `MainMenu.tscn` + `main_menu.gd` complete — styled panel, gold title, hover-state buttons
- Trees switched to `Tree_Pine_2_16x16` (32×32) to avoid crown cutoff at screen edges
- All tile colours matched to Pokémon FireRed/LeafGreen Four Island reference

### Next up
- Scene navigation / BackButton wiring (all game scenes need a back button to return to menu)
- Next game: **Plinko** (Town 2, alongside Wheel)
- Eventually: overworld map scene to replace the direct HiLo temp load in `main_menu.gd`
