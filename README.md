# Bust

A GBA/DS Pokémon-inspired top-down adventure RPG with gambling-based progression, built in Godot 4.6.

Travel across 5 themed towns, earn Fame by winning at mini-games, and collect Badges to unlock new areas. A 4-hour Wheel of Fortune safety net keeps you in the game if you go broke.

---

## Tech Stack

- **Engine:** Godot 4.6 (GDScript)
- **Platform:** PC (Steam target)
- **Renderer:** Forward Plus / D3D12

---

## Mini-Games (Current)

| Game | Description |
|---|---|
| HiLo | Guess higher or lower on a card streak — cash out anytime |
| Coin Flip | Heads or tails streak with compounding 2× multiplier |

---

## Getting Started (Collaborators)

### Prerequisites

- [Godot 4.6](https://godotengine.org/download/) — use the **Standard** build (not .NET)
- Git

### Clone the repo

```bash
git clone https://github.com/raulg-prog/Bust.git
cd Bust
```

### Open the project

1. Launch Godot 4.6
2. Click **Import**
3. Navigate to the cloned `Bust` folder and select `project.godot`
4. Click **Import & Edit**

Godot will regenerate the `.godot/` cache on first open — this is normal and takes a moment.

### Pulling updates

```bash
git pull origin main
```

If Godot is open when you pull, it will detect changed files and reimport automatically.

---

## Project Structure

```
Bust/
├── Assets/
│   ├── Cards/          # Card spritesheets (full + mini)
│   └── Floor TIles/    # Tileset assets
├── autoloads/
│   └── game_state.gd   # Global singleton (bankroll, fame, badges)
├── scenes/
│   └── games/
│       ├── hilo/       # HiLo scene + script
│       └── coinflip/   # Coin Flip scene + script
└── project.godot
```

---

## Getting Claude Up to Speed

This repo includes a `CLAUDE.md` with full project context — design pillars, code conventions, implemented systems, and the visual style guide. After cloning or pulling, tell Claude:

> "Please read CLAUDE.md and use it as context for this project."

Claude Code will load it automatically, but explicitly asking ensures it's fully digested before you start working.

---

## Contributing

1. Pull latest before starting work: `git pull origin main`
2. Ask Claude to read `CLAUDE.md` so it's on the same page
3. Make your changes
4. Commit with a clear message describing what and why
5. Push: `git push origin main`

Avoid committing the `.godot/` folder — it's gitignored since it's generated locally.
