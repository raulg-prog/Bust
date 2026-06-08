---
name: standup
description: Generate a daily standup update from recent git activity
allowed-tools: Bash(git *)
---

## Activity

Current author: !`git config user.name`

My commits, last 3 days (dated):
!`git log --author="$(git config user.name)" --since="3 days ago" --pretty=format:'%ad  %s' --date=short`

Files in my recent commits:
!`git log --author="$(git config user.name)" --since="3 days ago" --name-only --pretty=format: | sort -u | sed '/^$/d'`

All recent commits, any author (context only — NOT my work):
!`git log --since="3 days ago" --pretty=format:'%ad  %an  %s' --date=short`

## Instructions

Write a standup update. Rules:
- **Only count commits by the current author as my work.** Commits by other authors are
  the other team's — list them under context/awareness at most, never as my own.
- **Use the real commit dates shown above.** Compare them to today's actual date — do not
  label everything "today" or "yesterday" by default. If something was committed days ago,
  say so.
- Uncommitted working-tree changes (if any) are today's in-progress work.

Format:
- **Recently (dated)**: what I worked on, with the actual dates
- **Today / Next**: what I plan to work on
- **Blockers**: any issues (say "None" if none)
