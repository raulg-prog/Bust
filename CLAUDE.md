# Bust — Claude Code Context

Read this file fully before doing any work on this project.

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
│   └── Floor TIles/                # Tileset assets (not yet wired up)
├── autoloads/
│   └── game_state.gd               # Global singleton
├── scenes/
│   └── games/
│       ├── hilo/
│       │   ├── HiLo.tscn
│       │   └── hilo.gd
│       └── coinflip/
│           ├── CoinFlip.tscn
│           └── coinflip.gd
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

Multiplier wheel with three risk profiles. Player picks Low / Med / High risk, bets, and spins. The visual is a horizontal scrolling segment strip (not a rotating circle) that eases out to the winning tile under a fixed ▼ pointer.

Risk profiles — all EV = 1.0 (no house edge), 20 segments each:
- **Low** (60% win): 8×0x · 10×1.5x · 2×2.5x
- **Med** (40% win): 12×0x · 6×2x · 2×4x
- **High** (25% win): 15×0x · 4×2x · 1×12x

Segment strip is built dynamically in GDScript (shuffled per spin, REPS=6 repetitions for scroll distance). Animation uses `Tween.EASE_OUT / TRANS_CUBIC` over 2.5s. Winning segment is always chosen from the last repetition to ensure a full scroll every spin.

**Note:** The `claim_wheel_spin()` function in `game_state.gd` is the **safety-net free spin** (4-hour cooldown), completely separate from this betting game.

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
- Wheel of Fortune UI
- Save/load system
- OST and sound effects
- NPC sidequests
