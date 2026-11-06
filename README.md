# daylog

A deliberate daily **plan → check → reflect** loop for developers — as a Claude Code plugin. Vault-less, dependency-free, plain Markdown.

> **Status: prototype / reference implementation.** daylog runs end-to-end, but it's a minimal, portable take on a daily-workflow pattern — not a battle-tested daily driver. The author personally uses a richer, vault-integrated workflow; daylog distills the *loop* into something anyone can adopt. Treat it as a starting point to fork and shape. Issues and PRs welcome.

`daylog` is a *human-facing* journal and planner. It is **not** an automatic agent-memory tool: nothing is captured in the background and nothing is injected into your sessions unless you ask. You decide, in your own words, what each day means and what carries forward. (If you want automatic session memory, see the official Remember plugin instead — daylog is the deliberate, human-authored counterpart.)

## What it does

Four slash commands keep one Markdown file per day: the morning command writes a plan from yesterday's summary and today's git state, the midday command logs a timestamped checkpoint, the evening command drafts the summary from git and the checkpoints, and the first-run command creates the config. Optional hooks pull extra context from CLIs you name.

## Why it exists

The author's own daily loop lives in a vault-integrated, personal workflow; daylog distils just the loop into a portable plugin anyone can install and fork, with nothing captured in the background.

## Where it runs

Inside Claude Code on your own machine, as an installed plugin; storage is a directory of Markdown files you choose. Development is parked since 2026-08-30: the plugin works as published, and issues and PRs are still read.

## The daily loop

| Command | When | What it does |
|---|---|---|
| `/daylog-init`  | once    | Creates your config (`~/.config/daylog/config.md`) and storage directory. |
| `/daylog-start` | morning | Pulls yesterday's summary + today's git state, asks your focus, writes today's plan. |
| `/daylog-check` | midday  | Loads today's context into the session and logs a timestamped progress note. |
| `/daylog-end`   | evening | Auto-drafts a summary from git + your checkpoints, you refine it, then records the day. |

Each day is one file: `YYYY-MM-DD.md`. The evening summary is what next morning reads as "yesterday" — that's the loop.

## Install

```
/plugin marketplace add weijchen/daylog
/plugin install daylog@daylog
```
Then run `/daylog-init`.

## Requirements

- **Claude Code** with plugin support — daylog is built and tested against Claude Code **2.1.x** (developed on 2.1.177).
- No other dependencies: the core is plain Markdown commands plus `git`. Optional [hooks](#context-sources) use whatever CLIs you point them at.

daylog relies on Claude Code's evolving plugin/skill API (slash commands, `templates/day.md` substitution tokens, config hooks). On much older Claude Code versions these may not resolve and entries can come out incomplete — keep Claude Code current. The manifest can't yet enforce a minimum version; a hard pin will follow once the plugin API stabilises.

## Configuration

Your live config is at `~/.config/daylog/config.md` (written by `/daylog-init`; `templates/config.md` in this repo shows the format). Fields:

- `storage_root` — where day files live (default `~/daylog`; see [Storage & backup](#storage--backup))
- `language` — output language (default `en`)
- `repos` — `scan ~/Dev` (auto-discovers git repos under it, including nested ones like `~/Dev/Projects/<repo>`), or explicit paths
- `exclude` — optional list of directories to skip during scan (e.g. `~/Dev/Archive` of retired repos)
- `hook_timeout` — seconds any single hook may run before `/daylog-start` gives up on it (default `10`)
- `hooks` — optional shell commands whose output is added as context (e.g. a Linear/GitHub CLI). They run with your full shell privileges on every `/daylog-start`, so only add commands you trust.

## Storage & backup

`storage_root` defaults to `~/daylog` — a plain local directory. daylog is vault-less by design, but **vault-less does not have to mean backup-less**: nothing syncs, versions, or backs that directory up, so a disk failure or a stray `rm -rf` takes every entry with it. Months of daily history is exactly the kind of thing you only discover is gone once it matters.

Point `storage_root` at somewhere already protected:

- **iCloud Drive** — `~/Library/Mobile Documents/com~apple~CloudDocs/daylog`
- **Dropbox / Drive / OneDrive** — any synced folder
- **A git repo** — e.g. inside your dotfiles, giving you version history as well as a copy

Day files are plain Markdown with no index or database, so moving `storage_root` is just moving the directory and updating the config. `/daylog-init` suggests this when it asks where to store day files.

## Context sources

- **Git (built-in):** today's commits, current branch, uncommitted changes across your configured repos.
- **Hooks (optional, opt-in):** any shell command — that's how external services plug in without daylog depending on them. `/daylog-init` shows the hook list and asks you to confirm before storing it.

### How hooks are guarded

Hooks run with your full shell privileges every morning, so two things guard them:

- **Approval survives a re-sync.** When you approve a hook list, daylog records a hash of it in machine-local state (`${XDG_STATE_HOME:-~/.local/state}/daylog/hooks.sha256`). `/daylog-start` re-checks that hash every run and **asks again whenever the list has changed** — so a hook that arrives later, via dotfiles or an iCloud-synced `config.md`, cannot run just because it was already on disk. The hash lives outside `config.md` on purpose: stored inside, it would sync along with the file it is meant to guard. A list that has never been approved on this machine is treated the same as a changed one, and a check that fails to run is reported as unverified rather than clean.
- **A hook cannot hang your morning.** Each one runs under `hook_timeout` (default 10s). A hook that blocks on a network call or an auth prompt is abandoned and reported as timed out — distinctly from one that failed and one that simply returned nothing — and planning continues without it.

## Customizing & localizing

Day-file structure and section headings live in `templates/day.md`. It uses substitution tokens that `/daylog-start` fills in:

- `{{DATE}}` → the day's date
- `{{FOCUS}}` → your stated focus
- `{{CARRYOVER}}` → unfinished items pulled from the previous day
- `{{CONTEXT}}` → git state and hook output

Edit `templates/day.md` to change the layout or translate the section headings. Output text language is set by `language` in config.

## License

MIT.
