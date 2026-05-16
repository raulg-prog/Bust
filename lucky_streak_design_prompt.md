# Lucky Streak — Game Design Prompt

**Engine/Platform:** Godot 4, targeting Steam (PC primary; Steam Deck verified as stretch goal).

**Genre:** 2D top-down adventure RPG with gambling-based progression and online multiplayer card rooms.

## Premise

The player is an aspiring gambler setting out to become the best in the land. They travel an island nation of five themed gambling towns, building Fame at each one. Earning each town's Fame target awards a Badge — a public mark of skill and reputation. Badges unlock tiered online multiplayer card rooms. The arc is one of mastery, travel, and reputation. NPC sidequests across the towns address gambling's real costs honestly, grounding the cozy world with emotional range.

## Town Progression

Each town features two thematically paired games. Both treated equally — no signature game, no multipliers. Players choose whichever they prefer.

| # | Town Theme | Games | Fame Target |
|---|---|---|---|
| 1 | The Welcoming Town | Coin Flip + HiLo | 5,000 |
| 2 | The Spectacle Town | Wheel + Plinko | 25,000 |
| 3 | The Probability Town | Roulette + Dice | 100,000 |
| 4 | The Nerve Town | Mines + Tower | 400,000 |
| 5 | The Slot Palace | 3-column Slots + 5-column Slots | 1,500,000 |

Difficulty curve runs from lowest house edge / lowest volatility (Town 1) to higher volatility, more dramatic swings (Town 5). House edges and RTPs are publicly displayed in every venue — players should know the math.

## Fame System (Badges)

Fame is **net earnings from games only**, calculated at a 1:1 ratio: every dollar of profit from a winning game spin equals one Fame point in that town's counter. Losses don't subtract. Fame is per-town, not global — players must engage with each town rather than grinding one.

**Wheel of Fortune payouts do not count toward Fame** — the wheel is a pure bankroll safety net. Fame is exclusively earned through actual gameplay at the tables.

Hitting a town's Fame target awards its Badge and unlocks travel to the next town.

## Multiplayer Card Rooms

- **Low stakes online:** 3 Badges
- **High stakes online:** 5 Badges

Games: Texas Hold'em, Baccarat (social-table format — shared dealer, chat, side bets), Blackjack (social-table format). Random seating, anti-collusion monitoring, small rake.

## Bankroll Safety Net: 4-Hour Wheel of Fortune

Every 4 hours of real time, the player can spin the Wheel of Fortune for a cash payout. This is the only safety net for broke players — no loans, no debt, no bust-recovery story beats. If a player runs out of money, they wait for the next spin or play small stakes at any town they've unlocked.

**Wheel payout distribution:**

| Multiplier | Probability |
|---|---|
| 0.5× | 40% |
| 1× | 35% |
| 2× | 17.4% |
| 5× | 5% |
| 10× | 2.5% |
| **50× JACKPOT** | **0.1%** |

Expected value: ~1.45× base per spin. No bust segments — every spin pays something. Jackpot is roughly 1 in 1,000 spins; even a dedicated player claiming 4 spins per day would expect a jackpot only every ~250 days. Legendary, not routine.

**Base value scales with the player's furthest unlocked town** (so revisiting earlier towns doesn't reduce spin payouts):

| Furthest Town | Base | Typical (1×) | 10× hit | Jackpot (50×) |
|---|---|---|---|---|
| 1 | $200 | $200 | $2,000 | $10,000 |
| 2 | $1,000 | $1,000 | $10,000 | $50,000 |
| 3 | $5,000 | $5,000 | $50,000 | $250,000 |
| 4 | $25,000 | $25,000 | $250,000 | $1,250,000 |
| 5 | $100,000 | $100,000 | $1,000,000 | $5,000,000 |

Wheel is interactive on first claim (drag and release); auto-spin available for subsequent claims.

## Core Design Principles

- **No luck manipulation.** Base RNG is untouched. No charms, buffs, multipliers.
- **No boss fights.** Progression is purely Fame-based, respecting gambling's luck-based nature.
- **No skill-walls.** Every player can complete the world; unlucky streaks slow progress but don't softlock.
- **No loans, no debt.** The 4-hour wheel is the only safety net.
- **No hard game-over.** Going broke means waiting for the next spin or playing small stakes.
- **Player agency** comes from bet sizing, bankroll management, game selection, and in-game cash-out timing (Mines, Tower).

## Quality-of-Life Systems

- 4-hour Wheel of Fortune as the bankroll safety net.
- Tilt prompts: loss streaks trigger an optional "take a break" nudge — wellness-focused, no mechanical penalty.
- Replayability: every town stays open forever as a reliable income source.

## Tone and Art

Cozy pixel art, neon signs, jazzy/lo-fi soundtrack. Aspirational player arc grounded by honest NPC stories about gambling's real costs — characters who have lost too much, who chase losses, who can't stop. The world acknowledges the full picture without being preachy.

## Open Design Questions

- House edge tuning per game (match real-world numbers or soften early towns for friendliness?)
- Town aesthetics, NPC casts, and venue designs within each town
- Overarching narrative hooks: Fame ladder, mentor figure whose path the player retraces, annual championship event, or no overarching story (just vibes)?
- Post-game content after multiplayer unlocks
- Multiplayer matchmaking strategy at low player counts (especially at launch)
- Specific bet-size minimums per town tier
