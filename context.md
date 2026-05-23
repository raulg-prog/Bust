# Bust — Full Project Context

Read this fully before touching any game code.

---

## What This Game Is

**Bust** is a 2D top-down adventure RPG built in Godot 4.6 (GDScript), targeting Steam PC.
The aesthetic is GBA/DS Pokémon-inspired — pixel art, cozy tone, neon signs, jazzy/lo-fi OST.

The core loop: travel across 5 themed towns → earn **Fame** by winning at gambling mini-games → hit the Fame target → earn a **Badge** → unlock the next town and online card rooms.

---

## Towns & Games

| # | Town | Games | Fame Target |
|---|---|---|---|
| 1 | Flipside | Coin Flip + HiLo | 5,000 |
| 2 | Cascade | Wheel + Plinko | 25,000 |
| 3 | The Odds | Roulette + Dice | 100,000 |
| 4 | Brink | Mines + Tower | 400,000 |
| 5 | Tilterton | Gems + 2nd slot TBD | 1,500,000 |
| 6 | Bluffwood | Texas Hold'em + Baccarat + Blackjack | — |

Town 6 (Bluffwood) is the dedicated multiplayer town — unlocks at 3 Badges (low stakes) and 5 Badges (high stakes). No Fame target; progression is through Badge count.

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
- `return_pos: Vector2` — spawn position override when returning from a game
- `return_active: bool` — consumed by town `_ready()`, then cleared

Key constants:
- `FAME_TARGETS: Array[float]` = [5000, 25000, 100000, 400000, 1500000]
- `WHEEL_BASE: Array[float]` = [200, 1000, 5000, 25000, 100000]
- `WHEEL_COOLDOWN` = 14400.0 seconds

Key functions:
- `add_fame(town_id, amount)` — adds Fame, auto-awards Badge if target hit, emits `badge_earned`
- `claim_wheel_spin()` — weighted random payout, enforces cooldown (safety-net free spin only)
- `ensure_minimum()` — floors bankroll at $100, returns true if triggered
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
│   ├── Buildings/
│   │   ├── HiLo.png                # 256×192 log cabin — Town 1 HiLo hall
│   │   └── CoinFlip.png            # 256×192 log cabin — Town 1 CoinFlip hall
│   ├── Wheel/
│   │   ├── Wheel2.png              # Active wheel image — 20 segments, centres at 12 o'clock multiples
│   │   └── SpinBtn.png             # Spin button image (green SPIN circle)
│   ├── Gems/                       # 7 gem sprites at 48×48px (Aquamarine→Diamond)
│   ├── Logo/
│   │   ├── UpperCase.png           # Active logo — used on main menu
│   │   └── LowerCase.png
│   ├── Lucky Lou/
│   │   └── download1.png           # Safe tile chip — green/gold friendly chip
│   ├── Tilt Tony/
│   │   └── Tilt Tony no background.png  # Mine tile chip — red/gold angry chip
│   ├── Floor TIles/                # Tileset assets (16×16 native)
│   │   └── 1x/                     # Custom 64×64 grass tiles (Artboard 1grass1-4.png)
│   └── vector-rpg-character-template/  # Player character sprites (64px frames)
│       └── Individual Animations/  # idle-1/2_64.png, walk-1/2_64.png + directional SVGs
├── autoloads/
│   └── game_state.gd               # Global singleton
├── scenes/
│   ├── main_menu/
│   │   ├── MainMenu.tscn           # Main menu — set as project main scene
│   │   ├── main_menu.gd            # UI logic (Play → Town1, Exit → quit)
│   │   └── main_menu_bg.gd         # SubViewport live Town1 camera pan
│   ├── player/
│   │   ├── Player.tscn             # Reusable player scene (CharacterBody2D)
│   │   └── player.gd               # 4-directional movement + directional animations
│   ├── Towns/
│   │   ├── Town1.tscn              # Flipside — 40×36 tile map, 2 game buildings
│   │   ├── town1.gd                # @tool: grass fill + door triggers
│   │   ├── Cascade.tscn            # Town2 — in progress
│   │   ├── cascade.gd              # HUD, doors, tree border tool
│   │   └── Objects/                # PineTree.tscn, Bush.tscn
│   └── games/
│       ├── hilo/           — HiLo.tscn, hilo.gd
│       ├── coinflip/       — CoinFlip.tscn, coinflip.gd
│       ├── wheel/          — Wheel.tscn, wheel.gd, wheel_overlay.gd
│       ├── plinko/         — Plinko.tscn, plinko.gd, plinko_board.gd
│       ├── dice/           — Dice.tscn, dice.gd, dice_slider.gd
│       ├── mines/          — Mines.tscn, mines.gd
│       ├── tower/          — Tower.tscn, tower.gd
│       ├── roulette/       — Roulette.tscn, roulette.gd, roulette_wheel.gd, chip_overlay.gd
│       └── gems/           — Gems.tscn, gems.gd, gems_rtp_sim.gd
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
- Multiplier compounds across correct guesses; cash out anytime after the first correct guess
- **Skip**: up to 10 skips per bet — redraws the current card without guessing
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
- `WheelContainer` (Control, 380×380) holds `WheelImage`, `SpinButton` (TextureButton), `PivotMarker`, `WheelOverlay`
- `WheelContainer` is locked (`metadata/_edit_lock_ = true`) — don't move it by accident
- `wheel_overlay.gd` draws gold pointer triangle, 12px above wheel top edge

**Spin math (critical — do not change without testing):**
```gdscript
# Canonical angle — never read back from wheel_image.rotation
var wheel_exact_rot : float = 0.0

func _do_spin() -> void:
    var seg_angle := TAU / float(n)
    var land_r    := -float(win_idx) * seg_angle   # NO +0.5 — centres at exact multiples
    var start_r   := wheel_exact_rot
    var excess    := fposmod(start_r - land_r, TAU)
    var target_r  := start_r - excess - float(SPIN_REV) * TAU
    wheel_exact_rot = land_r
    wheel_image.rotation = start_r  # CRITICAL: force exact start before tween

func _on_spin_complete(win_idx: int, mult: float) -> void:
    wheel_image.rotation = wheel_exact_rot  # snap to exact centre
```

**Why `wheel_exact_rot` exists — do not remove it:**
- `wheel_image.rotation` accumulates as a large negative float over many spins → `fposmod()` loses precision
- `wheel_exact_rot` is always reset to a small value (`land_r`, within one rotation) after every spin
- Setting `wheel_image.rotation = start_r` before the tween keeps `target_r` within ~50 rad of 0
- **Do NOT** read `win_idx` back from `wheel_image.rotation` — use the pre-bound value
- **Do NOT add +0.5** to `land_r` — shifts landing onto segment boundaries

**SEGMENTS array (indices 0–19, clockwise from 12 o'clock) — matches Wheel2.png:**
```
0: Spin Again (1.0)   1: 0.5x   2: 1x    3: 0.5x   4: 0x (Bust)
5: 0.5x               6: 2x     7: 0.5x  8: 1x     9: 0x (Bust)
10: Spin Again (1.0)  11: 0.5x  12: 10x  13: 0.5x  14: 0x (Bust)
15: 0.5x              16: 2x    17: 0.5x 18: 1x    19: 0x (Bust)
```
EV = 1.15. `SPIN_AGAIN_IDX: Array[int] = [0, 10]` — check by index, NOT by `mult == 1.0`.

**Note:** `claim_wheel_spin()` in `game_state.gd` is the **safety-net free spin** (4-hour cooldown) — completely separate from this betting game.

### Plinko (`scenes/games/plinko/`)

Single-bet Galton board. Ball falls through pegs and lands in one of 13 buckets. Multiple balls can be in flight simultaneously.

**Architecture:** `plinko_board.gd` (class_name PlinkoBoard — pure renderer + geometry API) + `plinko.gd` (logic, RNG, animation).

**Board geometry:**
- `ROWS = 12`, `BUCKETS = 13`, peg spacing `_ps() = size.x / 13`
- `TOP_Y = 40`, `ROW_H = 30`, `BUCKET_TOP = 400`, `BUCKET_H = 50`
- Draw loop: `range(2, ROWS)` — top 2 rows invisible. Collider loop: `range(ROWS)` — all 12 have colliders.

**Distribution — discrete binomial random walk (NOT physics):**
- `_weighted_bucket()` uses `C(12,k)` weights: `[1, 12, 66, 220, 495, 792, 924, 792, 495, 220, 66, 12, 1]`
- `_build_path(bucket)`: shuffles right/left steps — physics can never give true binomial odds

**Animation:** `BALL_SCALE = 0.22`, `STEP_TIME = 0.11s`, total drop ≈ 1.6s. Waypoints are midpoints between peg positions — ball arcs through gaps.

**Multipliers:**
```
Bucket:   0     1     2    3    4    5    6    7    4    3    2     1     0
Mult:   170x  24x  8.1x  2x  0.7x 0.2x 0.2x 0.2x 0.7x 2x  8.1x 24x  170x
```

### Dice (`scenes/games/dice/`)

Slider-based dice game. Player picks threshold (2–98), bets Roll Over or Roll Under. True odds — no house edge.

**Math:**
- Roll Over T: win if result >= T → multiplier = `100/(100-T)`
- Roll Under T: win if result < T → multiplier = `100/T`
- Result: `float(randi_range(0, 9999)) / 100.0` → 10,000 discrete values

**Architecture:** `dice_slider.gd` (class_name DiceSlider — draw + drag, emits `threshold_changed`) + `dice.gd` (logic).

**Key implementation notes:**
- `var rx : float` — explicit annotation required (GDScript can't infer `clamp()` return type)
- Result circle (R=30) stays visible between rolls — cleared only at next roll start
- `ModeToggleBtn` disabled during animation, re-enabled 0.3s after landing
- Layout: 860×520 centred, 33/66 HBox split

### Mines (`scenes/games/mines/`)

Minefield game. Bets, picks grid size and mine count, reveals tiles. Cash out anytime after first safe reveal. True odds, no house edge.

**Grid sizes:** 25/36/49/64 tiles. Tile px sizes: 76/68/60/52.

**Multiplier — true hypergeometric odds:**
```gdscript
func _multiplier(k: int) -> float:
    var s := float(grid_size - mine_count)
    var result := 1.0
    for i in k:
        result *= float(grid_size - i) / (s - float(i))
    return result
```

**State machine:** IDLE → PLAYING → GAME_OVER → IDLE

**Tile visuals:** Lucky Lou (safe), Tilt Tony (mine) — `btn.icon` + `btn.expand_icon = true`. All styles built via `add_theme_stylebox_override()` at runtime.

**Layout:** 880×580, 33/66 HBox. `< Back` anchored top-left of root (`offset` 10/10/105/46), `z_index = 10`.

**Color theme:** Town 4 amber/brown — bg `Color(0.157, 0.094, 0.031, 1)`.

### Tower (`scenes/games/tower/`)

Climbing risk game. Pick one safe tile per row across 9 rows. Cash out anytime. True odds, no house edge.

**Difficulty table:**
| Difficulty | Columns | Traps | Safe | Mult/row |
|---|---|---|---|---|
| Easy   | 4 | 1 | 3 | 1.33× |
| Medium | 3 | 1 | 2 | 1.5×  |
| Hard   | 2 | 1 | 1 | 2×    |
| Expert | 3 | 2 | 1 | 3×    |
| Master | 4 | 3 | 1 | 4×    |

**Multiplier:** `pow(cols / safe, rows_cleared)` — true odds compounded per row.

**Key notes:**
- `_sb_popup` (StyleBoxFlat) and `_style_popup()` (function) — different names to avoid GDScript clash
- `var btn : Button = tile_rows[row][col]` — explicit type required (untyped Array inference fix)
- Row reveal: safe pick greys other tiles in that row; bomb/cashout reveals full board

**Color theme:** Town 4 amber/brown — same as Mines.

### Roulette (`scenes/games/roulette/`)

American roulette. Chip placement → spin → result. True odds — no house edge.

**Three-script design:**
- `roulette_wheel.gd` — pure `_draw()` renderer (38 pockets, ball, gold pointer)
- `roulette.gd` — chip selection, bet placement, spin math, payout, history
- `chip_overlay.gd` — transparent Control over number grid; intercepts mouse for straight/split/corner bets

**Wheel order (clockwise from 12 o'clock, 37 = "00"):**
```gdscript
[0, 28, 9, 26, 30, 11, 7, 20, 32, 17, 5, 22, 34, 15, 3,
 24, 36, 13, 1, 37, 27, 10, 25, 29, 12, 8, 19, 31, 18,
 6, 21, 33, 16, 4, 23, 35, 14, 2]
```

**Bet payouts (true odds, 38 pockets):**
| Bet | Payout |
|---|---|
| Straight | 37:1 |
| Split | 18:1 |
| Corner | 8.5:1 |
| Column / Dozen | ≈2.167:1 |
| Even-money (Red/Black/etc.) | ≈1.111:1 |

**Chip overlay — critical architecture:**
- `mouse_filter = MOUSE_FILTER_PASS` — propagates to parents, NOT siblings
- Sized to `_num_vbox` only — outside bet rows receive input directly
- Number buttons: `mouse_filter = MOUSE_FILTER_IGNORE` — overlay owns their input
- `THRESH = 9.0` px from cell edge for split/corner detection
- `_reg_plain()` for 2:1 column buttons — no adjacency participation

**Spin math:** same `wheel_exact_rot` approach as Wheel game. `+0.5 * seg_angle` so pocket CENTER lands under pointer.

**Win label:** shows profit from winning bets only (not net). `BoardView` fades to 0.25 opacity during spin.

**GDScript type fixes:** `for x : Type in array`, `var x : StyleBoxFlat = a if cond else b`, `_num_vbox` typed as `Control`.

### Gems (`scenes/games/gems/`)

8×8 cluster-pays slot. Min cluster 5 connected same-symbol. Tumble cascade on wins. Gold Fever meter.

**Key constants:**
```gdscript
const COLS := 8; const ROWS := 8; const NSYMS := 7; const CELL_SIZE := 64
const MIN_CLUSTER := 5; const MIN_BET := 10.0; const TOWN_ID := 4; const METER_MAX := 114
```

**Gem tiers (0 lowest → 6 highest):** Aquamarine, Amethyst, Topaz, Sapphire, Emerald, Ruby, Diamond.
Sprites: `res://Assets/Gems/Artboard 1<Name>.png`, 48×48px displayed in 64×64 cells.

**Paytable (9 size buckets: 5,6,7,8,9-11,12-14,15-19,20-24,25+):**
```gdscript
const PAYTABLE : Array = [
    [0.38,  0.57,  0.76,  1.31,  3.76,  7.52,  14.09,  37.6,  188.0],  # Aquamarine
    [0.57,  0.76,  1.12,  1.88,  5.64,  9.40,  18.80,  56.4,  281.8],  # Amethyst
    [0.76,  0.93,  1.50,  2.26,  7.52, 14.09,  28.18,  75.2,  375.7],  # Topaz
    [0.93,  1.12,  1.50,  2.81,  9.40, 18.80,  37.58,  94.0,  563.8],  # Sapphire
    [1.12,  1.88,  2.81,  4.69, 14.09, 28.18,  56.38, 188.0, 1127.6],  # Emerald
    [1.88,  2.81,  4.69,  9.40, 28.18, 46.97,  93.96, 375.7, 1879.7],  # Ruby
    [3.76,  5.64,  9.40, 18.80, 46.97, 93.96, 188.00, 751.4, 3758.1],  # Diamond
]
```

Diamond 25+ cluster pays **3758×** bet. RTP calibrated to **98%** (500k Monte Carlo sim). Slots target 98% not 100% — true 100% EV is impossible on cluster-pays cascades.

**Architecture:** `_slots` (fixed Panel backgrounds) + `_gem_sprites` (free TextureRect nodes for animation). `_grid_node` has `clip_contents = true` to hide gems animating above the visible area.

**Animation timings:** spin drop-in 0.55s (EASE_IN quad, per-column stagger 0.05s), tumble slide 0.32s, new gems drop 0.42s (0.03s column stagger), inter-chain pause 0.18s.

**Gold Fever:** accumulates winning symbol count across tumble chain. When `_meter >= 114`, applies 2× multiplier to all wins that spin.

`gems_rtp_sim.gd` — `@tool extends EditorScript`, run via File → Run in script editor.

---

## Code Conventions

- **Scene node references**: use `%NodeName` syntax — never long `$Path/To/Node` chains
- **Mark nodes** referenced in script with `unique_name_in_owner = true` in the `.tscn`
- **Formatting**: `_fmt(val: float) -> String` helper in every game script — copy it in, don't import
- **State machines**: `enum State { IDLE, ACTIVE }` pattern
- **Minimum bet**: `MIN_BET = 10.0` — enforce in all games
- **TOWN_ID**: each game script has a `const TOWN_ID` matching its town index (0–4)
- No comments unless the WHY is non-obvious
- No house edge — ever

---

## Visual Style

- GBA pixel art aesthetic — flat colors, hard edges, limited palette
- UI panels: `StyleBoxFlat` with `corner_radius = 0`, 2–3px border
- **All RGB values are GBA 15-bit snapped** — each channel = `(n * 8) / 255` for integer n ∈ [0, 31]
  - Formula: `gba_val = round(target * 31)`, `godot_float = gba_val * 8 / 255`
  - Max white = `248/255 ≈ 0.973` — never use 1.0

**Semantic colors (GBA-snapped):**
- Balance / win: `Color(0.376, 0.973, 0.502, 1)` — bright green
- Fame: `Color(0.502, 0.753, 0.973, 1)` — bright blue
- Gold / title: `Color(0.973, 0.847, 0.188, 1)`
- Result yellow: `Color(0.973, 0.973, 0.439, 1)`
- Loss red: `Color(0.973, 0.376, 0.376, 1)`
- Dim labels: `Color(0.627, 0.627, 0.753, 1)`

**Per-game room themes:**
- **Town 1 — Blue** (HiLo, CoinFlip): bg `Color(0.031, 0.063, 0.188, 1)` · accent `Color(0.220, 0.345, 0.659, 1)`
- **Town 2 — Red** (Wheel, Plinko): bg `Color(0.157, 0.031, 0.031, 1)` · accent `Color(0.659, 0.220, 0.220, 1)`
- **Town 3 — Green** (Dice, Roulette): bg `Color(0.031, 0.157, 0.063, 1)` · accent `Color(0.220, 0.659, 0.345, 1)`
- **Town 4 — Amber** (Mines, Tower): bg `Color(0.157, 0.094, 0.031, 1)` · panel `Color(0.188, 0.125, 0.063, 1)` · accent `Color(0.659, 0.408, 0.125, 1)`

---

## Main Menu (`scenes/main_menu/`)

### `main_menu_bg.gd` — Background renderer

Live SubViewport pan over `Town1.tscn`. Instances Town1, disables the Player (`process_mode = DISABLED`, `visible = false`, `player_cam.enabled = false`), adds its own `Camera2D` at zoom=2 and calls `make_current()`. Camera bounces diagonally at `Vector2(40, 15)` px/s within world bounds `(320,180)–(960,972)`. `handle_input_locally = false` on the SubViewport so no input leaks.

### `main_menu.gd`

Play → `Town1.tscn`. Exit → `get_tree().quit()`. `_wire_hover(btn)` connects `mouse_entered`/`mouse_exited` — tweens `scale` to 1.12 on enter, back to 1.0 on exit (TRANS_BACK, 0.15s). `pivot_offset` set to `btn.size / 2` on each enter so scale expands from center.

### `MainMenu.tscn` node tree

```
MainMenu (Control, main_menu.gd)
  Background (Control, main_menu_bg.gd, mouse_filter=IGNORE)
  DarkOverlay (ColorRect, Color(0,0,0,0.28), mouse_filter=IGNORE)
  Logo (TextureRect, UpperCase.png, anchor center, 500×180, STRETCH_KEEP_ASPECT_CENTERED)
  ButtonsVBox (VBoxContainer, anchor left-center, x=80–320, y=center±65)
    PlayButton  (unique_name) — 44px, StyleBoxEmpty, dim grey → white on hover
    ExitButton  (unique_name) — 44px, StyleBoxEmpty, dim grey → white on hover
```

---

## What's Not Built Yet

- Town2 (Cascade) scene — ~50% done, no interior decoration yet
- Towns 3–5 scenes
- Wire Gems into Town5 scene
- BackButtons for Dice, Roulette, Mines, Tower — all currently point to MainMenu (temporary)
- Multiplayer card rooms (Bluffwood)
- Wheel of Fortune UI (safety-net free spin — separate from the Wheel betting game)
- Save/load system
- OST and sound effects
- NPC sidequests
- Town1 decoration (paths, fences between buildings)
- Fame/Badge UI overlay in overworld

---

## Session Notes

### Wheel — float-precision fix + segment overhaul

- `wheel_exact_rot` canonical variable prevents float drift across many spins
- Switched texture to `Wheel2.png`; `SPIN_AGAIN_IDX = [0, 10]`
- `_on_spin_complete` checks index, not `mult == 1.0`

### Plinko — overhaul to discrete binomial

- Replaced physics with `C(12,k)` weighted bucket selection
- `_build_path()` shuffles coin-flip steps for correct visual path
- MULTS: `[170, 24, 8.1, 2, 0.7, 0.2, 0.2, 0.2, 0.7, 2, 8.1, 24, 170]`

### Town1 + Player

- `Player.tscn` — CharacterBody2D, AnimatedSprite2D (4-dir), Camera2D zoom=2
- `town1.gd` — `@tool`: fixed-seed fill in editor, randomized at runtime
- Buildings: 256×192px log cabin PNGs; door triggers use `call_deferred`
- Pond: `StaticBody2D` + `CollisionPolygon2D` (blocks player)
- Player `z_index = 2` — recheck after any editor save (Godot resets it)

### Exit spawn position system

- `GameState.return_pos` / `return_active` — door sets it, town `_ready()` consumes and clears it
- Offset `Vector2(0, 35)` so player spawns just below the door, avoids re-trigger

### Town1 ↔ Town2 bidirectional travel

- `town1.gd` wires `CascadeReturn` Area2D → Town2
- `cascade.gd` wires `Town1Exit` Area2D → Town1

### GBA 15-bit color palette

- All RGB values in all `.tscn` and `.gd` files snapped to GBA 15-bit (n×8/255, n ∈ 0–31)
- Per-game room themes applied throughout

### Gems — foundation built

- 8×8 cluster slot, BFS flood-fill, tumble cascade, Gold Fever meter
- RTP calibrated to 98% via 3 iterations of 500k Monte Carlo sim (cumulative scale ≈ 3.758×)
- Hit rate 34.7%, avg tumbles 0.416, max observed 10 cascades

### Main Menu — reworked 2026-05-22

- Removed panel/title/buttons; added `UpperCase.png` logo centered on screen
- Play + Exit as bare text buttons (StyleBoxEmpty), left side, vertically centered
- Hover: `font_hover_color` (dim→bright) + scale tween 1.0→1.12 via `_wire_hover()`

### Navigation

- All games return to their town (not MainMenu) via BackButton
- `main_menu.gd` New Game → `Town1.tscn` directly

---

## Next Up

- Build Town3 scene (The Odds — Roulette + Dice); wire their BackButtons to it
- Build Town4 scene (Brink — Mines + Tower); wire their BackButtons to it
- Wire Gems into Town5 scene when Town5 is built
- NPC placement in Town1
- Fame/Badge UI overlay in overworld
