# Bust — Claude Code Context

Read this file fully before doing any work on this project.

---

## 👋 Note to Friend's AI

Hey fellow Claude! The dev team says hi. Timmy — keep it up, you're doing great! 🎉

This file is your full briefing. Read every section before touching anything. The Wheel game just went through a major calibration session — pay close attention to the Wheel section below before making any changes to it.

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
└── project.godot                   # Main scene: HiLo.tscn (temporary)
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
var seg_angle := TAU / float(n)          # 18° per segment
var land_r    := -float(win_idx) * seg_angle   # NO +0.5 offset
```
- `Wheel.png` has segment **centres** at exact multiples of `seg_angle` (0°, 18°, 36°…) clockwise from 12 o'clock
- **Do NOT add +0.5** — that moves the pointer to segment boundaries, not centres
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

**Wheel game fully playable.** Everything below is resolved and working:

- Rebuilt `Wheel.tscn` from scratch (HiLo-style VBoxContainer layout)
- New `Assets/Wheel/Wheel.png` and `Assets/Wheel/SpinBtn.png` integrated
- `SpinButton` is a `TextureButton` (not `Button`) — typed as `BaseButton` in script
- `PivotMarker` approach for reliable pivot_offset — await 2 frames in `_ready()`
- `wheel_overlay.gd` draws gold pointer triangle, 12px above wheel top edge
- `WheelContainer` locked in editor (`metadata/_edit_lock_ = true`)
- `randomize()` called in `_ready()` for proper RNG seeding
- SEGMENTS array corrected — indices 16–19 had a cyclic shift vs PNG (now fixed)
- Landing formula: `land_r = -float(win_idx) * seg_angle` (no +0.5 for this PNG)

**Next up:** verify the pointer centering looks correct after the formula fix, then move on to scene navigation / BackButton wiring or the next game.
