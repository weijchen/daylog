---
description: Set up daylog — create config and journal storage
argument-hint: ""
allowed-tools: [Read, Write, Edit, Bash, AskUserQuestion]
---

# /daylog-init — Setup

## Constants
- **Config path (fixed)**: `~/.config/daylog/config.md`
- **Default storage root**: `~/daylog`
- **Default language**: `en`

## Process

### 1. Check for existing config
Run: `cat ~/.config/daylog/config.md 2>/dev/null`
- If it exists, show its contents and ask (AskUserQuestion): keep it as-is, or reconfigure?
- If "keep", stop here.

### 2. Ask setup questions (AskUserQuestion, one at a time)
1. "Where should day files be stored?" — default `~/daylog`. **When offering the default, note that `~/daylog` is a plain local directory with no backup**: months of entries are lost with the disk or a stray `rm -rf`. Suggest pointing `storage_root` at somewhere already backed up or synced — iCloud Drive, Dropbox, or a git-tracked dotfiles directory — and let the user keep the local default if they prefer.
2. "Output language for generated entries?" — default `en`
3. "Which repos should daylog scan for git context?" — default: `scan ~/Dev` (auto-discovers git repos under it, including nested ones like `~/Dev/Projects/<repo>`); or the user provides explicit paths.
4. "Add any context hooks now? (optional — a hook is a named shell command whose output is added as context, e.g. `linear: linear issue list --assignee me --state backlog`. Press skip to add later.)" — collect zero or more `name: command` pairs.

### 3. Write the config
Create `~/.config/daylog/config.md` (run `mkdir -p ~/.config/daylog` first):

```
# daylog config

- storage_root: {storage_root}
  # ⚠️ a plain local path (the ~/daylog default) has no backup — point this at an
  # iCloud/Dropbox/git-tracked directory if you want your history to survive the disk.
- language: {language}
- repos: {repos}
- exclude:
  # optional — directories to skip during scan (e.g. retired repos): add `  - <path>` lines
- hook_timeout: 10
  # seconds any single hook may run before /daylog-start gives up on it and moves on
- hooks:
  # optional — each hook is a named shell command whose stdout is added as context.
  # ⚠️ hooks run as shell commands with your full privileges on every /daylog-start —
  # only add commands you trust; review any that arrive via a synced/shared config.
  # - linear: linear issue list --assignee me --state backlog
```

If the user supplied hooks in step 2.4, **first display the full resolved list of `name: command` pairs and warn that each runs as a shell command with full user privileges on every `/daylog-start`; ask for explicit confirmation (AskUserQuestion) before storing them.** Only on confirmation, write them as `  - {name}: {command}` lines under `hooks:` (replacing the comment examples). If the user declines, write no hooks and tell them they can add hooks later by editing the config. If they skipped in 2.4, leave the commented examples as-is.

**After writing hooks, record the approval:** run `${CLAUDE_PLUGIN_ROOT}/scripts/hooks-hash.sh store ~/.config/daylog/config.md`. This stores a hash of the approved hook list in machine-local state (`${XDG_STATE_HOME:-~/.local/state}/daylog/`), so `/daylog-start` can detect a hook list that later changes — for example when the config is re-synced from another machine — and re-ask instead of running it unseen. The hash is deliberately **not** written into `config.md` itself: it would then travel with the file it is meant to guard.

Then create the storage directory: `mkdir -p {storage_root}`.

### 4. Confirm
Show the written config and confirm the storage directory exists. Tell the user to run `/daylog-start` to plan their day.
