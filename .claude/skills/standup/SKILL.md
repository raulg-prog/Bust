---
name: standup
description: Generate a daily standup update from recent git activity
allowed-tools: Bash(git *)
---

## Today's Activity

Recent commits: !`git log --oneline --since="24 hours ago"`
Changed files: !`git diff --name-only HEAD~5 HEAD`

Based on the above git activity, write a brief standup update in this format:
- **Yesterday**: What I worked on
- **Today**: What I plan to work on
- **Blockers**: Any issues (say "None" if no blockers)
