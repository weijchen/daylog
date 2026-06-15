# daylog

A deliberate daily **plan → check → reflect** loop for developers — as a Claude Code plugin. Vault-less, dependency-free, plain Markdown.

> **Status: prototype / reference implementation.** daylog runs end-to-end, but it's a minimal, portable take on a daily-workflow pattern — not a battle-tested daily driver. The author personally uses a richer, vault-integrated workflow; daylog distills the *loop* into something anyone can adopt. Treat it as a starting point to fork and shape. Issues and PRs welcome.

`daylog` is a *human-facing* journal and planner. It is **not** an automatic agent-memory tool: nothing is captured in the background and nothing is injected into your sessions unless you ask. You decide, in your own words, what each day means and what carries forward. (If you want automatic session memory, see the official Remember plugin instead — daylog is the deliberate, human-authored counterpart.)

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

## Configuration

Your live config is at `~/.config/daylog/config.md` (written by `/daylog-init`; `templates/config.md` in this repo shows the format). Fields:

- `storage_root` — where day files live (default `~/daylog`)
- `language` — output language (default `en`)
- `repos` — `scan ~/Dev` (auto-discovers git repos under it, including nested ones like `~/Dev/Projects/<repo>`), or explicit paths
- `exclude` — optional list of directories to skip during scan (e.g. `~/Dev/Archive` of retired repos)
- `hooks` — optional shell commands whose output is added as context (e.g. a Linear/GitHub CLI). They run with your full shell privileges on every `/daylog-start`, so only add commands you trust.

## Context sources

- **Git (built-in):** today's commits, current branch, uncommitted changes across your configured repos.
- **Hooks (optional, opt-in):** any shell command — that's how external services plug in without daylog depending on them. `/daylog-init` shows the hook list and asks you to confirm before storing it, and `/daylog-start` displays each command before running it — so a hook from a synced/shared config can't run unseen.

## Customizing & localizing

Day-file structure and section headings live in `templates/day.md`. It uses substitution tokens that `/daylog-start` fills in:

- `{{DATE}}` → the day's date
- `{{FOCUS}}` → your stated focus
- `{{CARRYOVER}}` → unfinished items pulled from the previous day
- `{{CONTEXT}}` → git state and hook output

Edit `templates/day.md` to change the layout or translate the section headings. Output text language is set by `language` in config.

## License

MIT.
