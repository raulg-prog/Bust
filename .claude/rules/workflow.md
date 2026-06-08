# Session & Team Workflow — Bust

Cross-team collaboration protocol. This repo is shared by two teams (see the IDENTITY
table in `CLAUDE.md`). Identify your team on load and act accordingly.

| Team | Human | AI |
|---|---|---|
| 🔱 Raul + Gupta | Raul | Gupta |
| 🎰 Timmy + Carl | Timmy | Carl |

---

## Start of every session

1. **`git pull`** — and "git pull" means *both*: pull from GitHub **and** read the
   Messages section of `CLAUDE.md` for anything new from the other team.
2. Read `CLAUDE.md` (identity, status, inboxes).
3. Read `context.md` and `.claude/rules/` for game/code details as needed.
4. If you just pulled, sanity-check that the other team's merge didn't break your work.

---

## `HANDOFF.md` — what it is

- `HANDOFF.md` is **Carl's (Team Timmy + Carl) session-bootstrap file** — their onboarding
  doc describing their identity, rules, what they own, and their next-up list.
- It is **not addressed to us.** Read it to understand what the other team is doing and who
  owns what, but do **not** treat it as instructions for our team.
- The equivalent identity/rules for our team live in `CLAUDE.md`.

---

## Git discipline

- **Only commit or push when the human explicitly asks.** Don't touch git otherwise.
- **Pull before starting work** to avoid conflicts — two teams share `main`.
- Keep commits scoped to what was asked. Stage deliberately.
- When committing, exclude unrelated local files; `.claude/` session files are gitignored
  (only `.claude/skills/` and `.claude/rules/` are tracked).

---

## "push" protocol

When the human says **"push"**:
1. Update `CLAUDE.md` with session notes (status block + anything relevant).
2. Commit.
3. `git push`.

**Never edit `CLAUDE.md` unless the human says "push"** (or explicitly asks you to edit it).

---

## Messages — inbox conventions

The Messages section of `CLAUDE.md` is the **cross-team channel**. It has one **Inbox per
team** (inbox only — no sent/outbox sections).

- **Reading:** read your own team's inbox first, then the other team's. Word for word — no
  skipping, no summarising.
- **Sending:** to message the other team, append your note to **their** inbox section.
- Sign messages with your team emoji (🔱 for Gupta, 🎰 for Carl) and your name.

---

## Relay rule (intra-team vs cross-team)

- `CLAUDE.md` is for **cross-team** messages only. Conversations between a human and their
  own AI (e.g. Raul ↔ Gupta) do **not** go in `CLAUDE.md`.
- The AIs address each other, not the other human directly: **Carl writes to Gupta**, and
  **Gupta relays to Raul** (and vice-versa). Don't address the other team's human directly.
