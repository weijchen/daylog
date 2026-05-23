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
1. "Where should day files be stored?" — default `~/daylog`
2. "Output language for generated entries?" — default `en`
3. "Which repos should daylog scan for git context?" — default: `scan ~/Dev` (auto-discovers git repos under it, including nested ones like `~/Dev/Projects/<repo>`); or the user provides explicit paths.
4. "Add any context hooks now? (optional — a hook is a named shell command whose output is added as context, e.g. `linear: linear issue list --assignee me --state backlog`. Press skip to add later.)" — collect zero or more `name: command` pairs.

### 3. Write the config
Create `~/.config/daylog/config.md` (run `mkdir -p ~/.config/daylog` first):

```
# daylog config

- storage_root: {storage_root}
- language: {language}
- repos: {repos}
- hooks:
  # optional — each hook is a named shell command whose stdout is added as context:
  # - linear: linear issue list --assignee me --state backlog
```

If the user supplied hooks in step 2.4, write them as `  - {name}: {command}` lines under `hooks:` (replacing the comment examples). If they skipped, leave the commented examples as-is.

Then create the storage directory: `mkdir -p {storage_root}`.

### 4. Confirm
Show the written config and confirm the storage directory exists. Tell the user to run `/daylog-start` to plan their day.
