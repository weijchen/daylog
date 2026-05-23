---
description: Mid-day checkpoint — load today's context and log progress
argument-hint: ""
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# /daylog-check — Mid-day Checkpoint

## Constants
- **Config path**: `~/.config/daylog/config.md`
- **Today**: current system date, format `YYYY-MM-DD`

## Process

### 1. Read config and today's file
Read `~/.config/daylog/config.md` for `storage_root`, `language`, and `repos`.
Read `{storage_root}/{today}.md`. This is the deliberate "load my context for this session" moment — summarize the day's `Focus`, `Carryover`, and any existing `Progress` back to the user so the session has context.
If today's file does not exist, tell the user to run `/daylog-start` first and stop.

### 2. Gather fresh git activity
Using the same `repos` resolution as `/daylog-start`, collect commits since the morning and current uncommitted changes, to inform the checkpoint. Attempt this always, but skip gracefully (don't error out) if a repo can't be read.

### 3. Append a timestamped checkpoint
Under the `## Progress` section, append:

```
### {HH:MM}
- {what's done}
- {in flight}
- {blockers, if any}
```

Derive the content from git activity and a brief AskUserQuestion ("Where are things right now?") if the user hasn't said. Do not overwrite existing Progress entries — append only. Write in the configured `language`.

### 4. Show the appended entry
Display the new checkpoint for confirmation.
