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
- **Yesterday's summary (carryover)**: list `{storage_root}/*.md`, take the files dated before today newest-first, and walk back through them (up to **7**) to find the most recent with a non-empty `## Summary` or `## Done / Carryover`; read both sections (the latter holds explicit carryover items). Handle the gaps explicitly — never error or invent items:
  - **No prior file at all** (first run, or empty `{storage_root}`): there is no carryover. Note *"first daylog entry — no prior day to carry over"* in the context summary and treat carryover as empty.
  - **Most recent prior file has empty `## Summary` and `## Done / Carryover`** (previous day never wrapped up with `/daylog-end`): keep walking back to the most recent file that *does* have content. If found, use it and note the gap (e.g. *"latest summary is from {date}"*). If none within the last 7 files, proceed with empty carryover and say so.
  - Files may be non-consecutive — match by most recent prior **date**, not strictly yesterday.
- **Git state**: resolve `repos`:
  - If `repos` is a `scan {DIR}` directive: discover git repos under `{DIR}` with `find {DIR} -maxdepth 3 -type d -name .git -prune 2>/dev/null | sed 's|/.git$||'` (this finds repos nested a couple levels down, e.g. `{DIR}/Projects/<repo>`).
  - Otherwise treat `repos` as an explicit list of repo paths (comma/space/newline-separated).
  - Then drop any discovered repo whose path is under a directory listed in the config's `exclude` field (e.g. an `~/Dev/Archive` of retired repos).
  For each repo, collect current branch (`git -C {repo} rev-parse --abbrev-ref HEAD`), today's commits (`git -C {repo} log --oneline --since="$(date +%F)T00:00:00"`), and uncommitted changes (`git -C {repo} status -s`). **Only surface repos that have today's commits or uncommitted changes — skip dormant ones** so the context stays relevant.
- **Hooks**: for each hook in config, run its command and capture stdout.

### 3. Present a concise context summary
Show: carryover from the latest prior summary, current git state, and any hook output. Keep it brief.

### 4. Ask the user (AskUserQuestion)
1. "What's your focus today?" — **always a multi-select question** (`multiSelect: true`). Derive 3–4 candidate focus items from the gathered context (carryover items, active repos / WIP, today's commits) as the options so the user can pick several at once; they can always add their own via "Other". The day's priorities are the selected items.
2. "Anything to defer or drop?" — free text (optional)

### 5. Create today's day file
Read the plugin's `templates/day.md` (use Read to load the actual file — do not reconstruct it from memory) and fill tokens:
- `{{DATE}}` → today
- `{{FOCUS}}` → the user's focus
- `{{CARRYOVER}}` → unfinished items from the prior summary found in step 2 (`## Summary` + `## Done / Carryover`) plus the user's defer/drop notes. **If step 2 found no prior summary (first run / gap), set this to a short explicit note** (e.g. *"— (none — first daylog entry)"* or the gap note), not an empty string.
- `{{CONTEXT}}` → the git state and hook output gathered in step 2

Write to `{storage_root}/{today}.md`. If the file already exists, ask whether to overwrite or open the existing one.

Generate all text in the configured `language`.

### 6. Validate & show
Read the file back, confirm the frontmatter `date` matches today and that **Focus and Context** are non-empty. **Carryover is non-empty only when step 2 found a prior summary** — on a first run or a gap with no prior summary it is legitimately empty (expected, not an error). (Progress, Summary, Done / Carryover, and Learnings stay empty — filled later by `/daylog-check` and `/daylog-end`.) Display for approval; edit on request.
