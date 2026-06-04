# Carl Handoff — Bust Project

You are **Carl**, the AI for **Team Timmy + Carl** 🎰. Your human is **Timmy** (tjtejedor@gmail.com). Never call him Raul.

The other team is **Raul + Gupta** 🔱. They share the same GitHub repo.

---

## Your First Move Every Session

1. Run `git pull` on `C:\Users\ID140\OneDrive\Desktop\Code\Bust`
2. Read `CLAUDE.md` — check the Messages section for anything new from Gupta/Raul
3. Read `context.md` for full game/code details if you need them
4. When Timmy says **"push"** → update CLAUDE.md with session notes, commit, push to GitHub

---

## Key Rules

- **Never edit CLAUDE.md unless Timmy says "push"**
- **No permission prompts** — `.claude/settings.json` has blanket allow rules
- **No house edge** — all games pay true mathematical odds
- Repo: `https://github.com/raulg-prog/Bust.git` (Raul owns it, Timmy is collaborator)
- Engine: **Godot 4.6 / GDScript**
- "git pull" = pull from GitHub AND read CLAUDE.md messages
- "push" = update CLAUDE.md + commit + git push

---

## What Timmy + Carl Own

- **Roulette** (`scenes/games/roulette/`) — fully built, 3-script design
  - `roulette.gd` — game logic, chip placement, spin, payouts
  - `roulette_wheel.gd` — procedural `_draw()` wheel
  - `chip_overlay.gd` — handles mouse input + draws chips on number grid
  - True odds: 37:1 straight, 18:1 split, 8.5:1 corner, ≈2.167:1 columns/dozens, ≈1.111:1 even-money
  - Chips: $1 / $10 / $25 / $50 / $100 / $500
  - Buttons: Spin Wheel, Clear, ↺ Rebet, ×2 Double
- **Dice** (`scenes/games/dice/`) — fully built
- **Mines** (`scenes/games/mines/`) — fully built
- **Tower** (`scenes/games/tower/`) — fully built
- **Main Menu music** — `Assets/Sounds/Main Menu Music.ogg`, fade in/out/loop logic in `main_menu.gd`

## What Raul + Gupta Own

- Town1 (Flipside) — complete overworld
- Town2 (Cascade) — ~50% done, bidirectional travel wired
- HiLo, CoinFlip, Wheel, Plinko — all built
- Gems — cluster slot game (Town5), foundation complete, 98% RTP
- Intro video + Main Menu UI structure

---

## Critical Code Notes

### Roulette chip_overlay.gd
- `mouse_filter = MOUSE_FILTER_PASS` — propagates to PARENTS only, not siblings
- Overlay sized to `_num_vbox` (number rows only) — outside bets are below it and unblocked
- `_reg_plain()` registers col_1/2/3 in `_crects` only (no grid entry) for 2:1 button routing
- `NOTIFICATION_MOUSE_EXIT` clears hover highlight when mouse leaves
- `_to_local_rect()` snaps rects to whole pixels for perfect highlight alignment
- Number buttons: `mouse_filter = MOUSE_FILTER_IGNORE`
- `to_local()` does NOT exist on Control — use `gr.position - global_position`

### Roulette _build_board()
- `zero_vbox` (VBoxContainer) holds 0/00 with `SIZE_EXPAND_FILL` vertical — spans all 3 rows
- `num_outer` (HBoxContainer) is `_num_vbox` typed as `Control`
- Split key: `"sp|n_X|n_Y"` (sorted). Corner key: `"co|n_A|n_B|n_C|n_D"` (sorted)

### General Godot 4 gotchas
- `to_local()` is Node2D only — not available on Control
- `SIZE_EXPAND_FILL = 3`
- MOUSE_FILTER_STOP=0, MOUSE_FILTER_PASS=1, MOUSE_FILTER_IGNORE=2
- GBA color palette: each channel = `(n * 8) / 255`, max white = 0.973 not 1.0
- All game scripts have `_fmt(val: float) -> String` for comma-separated numbers

---

## Towns & Games Overview

| # | Town | Games | Fame Target |
|---|---|---|---|
| 1 | Flipside | Coin Flip + HiLo | 5,000 |
| 2 | Cascade | Wheel + Plinko | 25,000 |
| 3 | The Odds | Roulette + Dice | 100,000 |
| 4 | Brink | Mines + Tower | 400,000 |
| 5 | Tilterton | Slots (Gems + 1 more) | 1,500,000 |
| 6 | Bluffwood | Multiplayer card games | — |

---

## Next Up (Team Timmy + Carl)

- Build Town3 scene (The Odds — Roulette + Dice); wire BackButtons to it
- Build Town4 scene (Brink — Mines + Tower); wire BackButtons to it
- Add music to individual game scenes
