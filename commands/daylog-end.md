---
description: End of day — auto-summarize the day, then reflect and record
argument-hint: ""
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# /daylog-end — Wrap-up

## Constants
- **Config path**: `~/.config/daylog/config.md`
- **Today**: current system date, format `YYYY-MM-DD`

## Process

### 1. Read config, today's file, and the day's signals
Read `~/.config/daylog/config.md` for `storage_root`, `language`, `repos`.
Read `{storage_root}/{today}.md` for the morning `Focus` and the `Progress` checkpoints.
Gather **today's git commits** across the resolved `repos` (`git -C {repo} log --oneline --since="$(date +%F)T00:00:00"`).
If today's file does not exist, warn the user and offer to create a minimal one or stop.

### 2. Summarize step (auto-draft)
Synthesize the morning `Focus`, the `Progress` checkpoints, and today's git commits into a draft 2–4 sentence `## Summary` of the day. Present this draft to the user.

### 3. Confirm and reflect (AskUserQuestion, one at a time)
1. "Here's the draft summary — adjust anything?" — user edits/approves the summary.
2. "What did you learn today? (optional)" — learnings.

### 4. Write the record
Fill the day file's previously-empty sections (do not touch `Focus`/`Carryover`/`Context`/`Progress`). If `## Summary` already has content (e.g. `/daylog-end` was run earlier today), show it and ask whether to replace or keep it before writing:
- `## Summary` → the confirmed summary. (This is what tomorrow's `/daylog-start` reads as "yesterday".)
- `## Done / Carryover` → completed items (cross-referenced with the morning Focus) and what rolls to tomorrow.
- `## Learnings` → the user's learnings, if any.

Write in the configured `language`.

### 5. Validate & show
Read back; confirm `Summary` is non-empty. Display the completed file for approval; edit on request.
