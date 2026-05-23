---
description: Morning planning — create today's day file with your focus
argument-hint: ""
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# /daylog-start — Morning Plan

## Constants
- **Config path**: `~/.config/daylog/config.md`
- **Today**: current system date, format `YYYY-MM-DD`

## Process

### 1. Read config
Read `~/.config/daylog/config.md`. Extract `storage_root`, `language`, `repos`, and `exclude`. If the config is missing, tell the user to run `/daylog-init` first and stop.

### 2. Gather context (in parallel)
- **Yesterday's summary**: list `{storage_root}/*.md`, pick the most recent file whose date is before today, and read both its `## Summary` and `## Done / Carryover` sections (the latter holds the explicit carryover items). (There may be gaps — use the latest prior file, not strictly yesterday.)
- **Git state**: resolve `repos`:
  - If `repos` is a `scan {DIR}` directive: discover git repos under `{DIR}` with `find {DIR} -maxdepth 3 -type d -name .git -prune 2>/dev/null | sed 's|/.git$||'` (this finds repos nested a couple levels down, e.g. `{DIR}/Projects/<repo>`).
  - Otherwise treat `repos` as an explicit list of repo paths (comma/space/newline-separated).
  - Then drop any discovered repo whose path is under a directory listed in the config's `exclude` field (e.g. an `~/Dev/Archive` of retired repos).
  For each repo, collect current branch (`git -C {repo} rev-parse --abbrev-ref HEAD`), today's commits (`git -C {repo} log --oneline --since="$(date +%F)T00:00:00"`), and uncommitted changes (`git -C {repo} status -s`). **Only surface repos that have today's commits or uncommitted changes — skip dormant ones** so the context stays relevant.
- **Hooks**: for each hook in config, run its command and capture stdout.

### 3. Present a concise context summary
Show: carryover from the latest prior summary, current git state, and any hook output. Keep it brief.

### 4. Ask the user (AskUserQuestion)
1. "What's your focus today?" — free text (the day's priorities)
2. "Anything to defer or drop?" — free text (optional)

### 5. Create today's day file
Read the plugin's `templates/day.md` (use Read to load the actual file — do not reconstruct it from memory) and fill tokens:
- `{{DATE}}` → today
- `{{FOCUS}}` → the user's focus
- `{{CARRYOVER}}` → unfinished items from the latest prior file's `## Summary` and `## Done / Carryover` + the user's defer/drop notes
- `{{CONTEXT}}` → the git state and hook output gathered in step 2

Write to `{storage_root}/{today}.md`. If the file already exists, ask whether to overwrite or open the existing one.

Generate all text in the configured `language`.

### 6. Validate & show
Read the file back, confirm the frontmatter `date` matches today and that Focus, Carryover, and Context are non-empty (Progress, Summary, Done / Carryover, and Learnings should remain empty — they are filled later by `/daylog-check` and `/daylog-end`). Display for approval; edit on request.
