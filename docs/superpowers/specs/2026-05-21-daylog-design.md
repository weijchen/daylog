# daylog — Design

- **Date:** 2026-05-21
- **Status:** Draft (awaiting user review)
- **Author:** brainstormed with Claude

## Summary

`daylog` is an open-source Claude Code plugin that provides a deliberate **daily plan → check → reflect loop** for developers. Each day produces a single Markdown file that you create in the morning (plan), append to during the day (progress), and complete at night (summary + reflection). It is vault-less and dependency-free: it works in any directory against plain files, with **git as a built-in context source**.

It is a rewrite of the author's personal, Obsidian-coupled "LifeOS" command set, reduced to its portable journaling-and-planning core and decoupled from any personal vault, schema, or external service.

### Positioning

`daylog` is a **human-facing journaling and planning tool**, not an agent-memory mechanism. The daily file persists across days and a future session *can* read it on demand, but this is a deliberate, human-triggered action — there is no automatic context injection, no background capture, and no compression. This intentionally distinguishes `daylog` from the official **Remember** plugin and tools like `claude-mem`, `claude-engram`, and `memory-toolkit`, all of which are automatic, agent-authored memory layers. `daylog`'s value is the opposite: *you* decide, in your own words, what each day means and what carries forward.

## Goals

- A tight daily loop: `start` (morning plan), `check` (mid-day progress), `end` (wrap-up with summary + reflection).
- One human-readable Markdown file per day; the morning's summary of "yesterday" closes the loop.
- Zero install friction: no runtime, no external dependencies, no API keys. Pure prompt + a config file.
- Portable: works in any project/directory; storage location and language are configurable.
- Git as a first-class, built-in context signal; other integrations are optional and opt-in.
- A genuine open-source product: real README, marketplace-installable, licensed, with an example and lightweight contribution docs.

## Non-Goals

- **No Obsidian / vault / PKM.** Research, knowledge distillation, spaced-repetition review, archiving, and finance commands stay in the author's personal LifeOS and are out of scope.
- **No multi-day or persistent plans.** Planning is daily only; there is no rolling backlog, sprint, or project artifact.
- **No agent-memory behavior.** No auto-injection hooks, no background session capture, no AI compression of history.
- **No data migration** from the existing vault.
- **No cross-agent adapters** in v1 — Claude Code plugin only.

## Name

`daylog`. Chosen because it is self-explanatory and has no collision within the Claude Code plugin ecosystem. (A same-name journaling CLI exists in the npm world; this is a different ecosystem and not a blocker. `almanac` and `throughline` were the runner-up candidates, both fully collision-free, retained as fallbacks if rebranding is ever needed.)

## Architecture

**Approach: pure-prompt Claude Code plugin. No executable code.**

The plugin ships as a set of Markdown slash-command definitions plus a Markdown daily-file template. Each command is a prompt that instructs Claude to: read the config, gather context (git via Bash, plus any configured hooks), read/write the day's file, ask the user the right questions, and write the result. Deterministic operations (running `git log`, computing today's date, locating/creating the day file, merging sections) are performed by Claude using its built-in tools (Bash, Read, Write, Edit).

Rationale: the operations here are simple and Claude performs them reliably from clear prompts, so a helper-script layer would add install friction (the very thing that kills adoption for a lightweight journaling tool) for little robustness gain. Helper scripts can be introduced later *if* a specific operation proves flaky in practice.

## Commands

Four slash commands (command prefix `daylog-`):

### `/daylog-init`
One-time setup wizard. Interactively:
- Asks for the **journal storage root** (default: a global `~/daylog/`).
- Asks for the **output language** (default: `en`).
- Optionally registers **context hooks** (see Config).
- Writes the config file and creates the storage directory.
- Idempotent: if a config already exists, offers to show/update it rather than overwrite blindly.

### `/daylog-start`
Morning planning. Steps:
1. Read config.
2. Gather context: read **yesterday's day file** (specifically its `Summary` section) for carryover; collect **git state** (current branch, any uncommitted/recent work) across configured repos; run any configured hooks.
3. Present a concise context summary.
4. Ask the user their **focus for today** (and what to defer/drop). The focus question is always **multi-select**, offering candidate priorities derived from the gathered context (carryover, active repos, today's commits) plus a free-form option.
5. Create today's day file from the template, populating the plan sections.
6. Show the file for approval; edit on request.

### `/daylog-check`
Mid-day resume / progress checkpoint. Steps:
1. Read config and **today's day file** (the deliberate "load my context" moment).
2. Optionally gather fresh git activity since the morning.
3. Append a **timestamped checkpoint** under `Progress` (what's done, what's in flight, any blockers).
4. Show the appended entry.

### `/daylog-end`
End-of-day wrap-up. Steps:
1. Read config, **today's day file**, and gather the day's signals: git commits since midnight across configured repos, the morning `Focus`, and the `Progress` checkpoints.
2. **Summarize step (auto-draft):** synthesize those signals into a draft `Summary` of the day and present it to the user.
3. Ask the user to confirm/adjust the summary and add any **learnings** (optional).
4. Write the final `Summary`, `Done / Carryover`, and `Learnings` sections into the day file.
5. Show the completed file for approval.

The `Summary` produced here is exactly what the next morning's `/daylog-start` reads as "yesterday," closing the loop.

## Daily File

One file per day, named `YYYY-MM-DD.md`, in the configured storage root. Sections fill in across the loop:

```markdown
---
date: YYYY-MM-DD
---

## Focus            <!-- start: today's priorities -->
## Carryover        <!-- start: unfinished from yesterday -->
## Context          <!-- start: relevant git/branch state, hook output -->

## Progress         <!-- check: timestamped checkpoints -->

## Summary          <!-- end: synthesized recap (read by next start) -->
## Done / Carryover <!-- end: completed + what rolls to tomorrow -->
## Learnings        <!-- end: optional -->
```

The template is a user-editable file shipped with the plugin. Customizing structure — or **localizing section headings** to another language — is done by editing the template; no code change required. (Output *text* language is set in config; *structure/headings* are template-driven.)

## Config

Written by `/daylog-init`, read by every command. The config is a **single human-readable Markdown file at a fixed path** — `~/.config/daylog/config.md` — with settings expressed as a simple labeled list that Claude parses from the prompt. (Fixed path rather than inside the storage root, since commands must locate the config *before* they know `storage_root`.) Fields:

- `storage_root` — directory for day files. Default: `~/daylog/`.
- `language` — output language for generated text. Default: `en`.
- `repos` — repository paths to scan for git context. **Default: `scan ~/Dev`**, which auto-discovers git repos under `~/Dev` up to ~3 levels deep (`find ~/Dev -maxdepth 3 -type d -name .git -prune`), catching nested layouts like `~/Dev/Projects/<repo>`. Only repos with same-day activity are surfaced. User can override with an explicit list at init.
- `exclude` (optional) — a list of directories to skip during `scan` discovery (e.g., `~/Dev/Archive` of retired repos that have perpetual stale uncommitted changes). Discovered repos under any excluded path are dropped.
- `hooks` (optional) — a list of named shell commands whose stdout is fed into planning/summary as additional context (e.g., a Linear or GitHub CLI). Dependency-free core; entirely opt-in.

## Context Gathering

- **Git (built-in):** commits since local midnight across configured repos, current branch, and modified/uncommitted files. The universal dev signal; no configuration required beyond which repos to scan.
- **Hooks (optional):** each hook is a shell command declared in config; its stdout is included as context. This is how external services (Linear, GitHub issues, calendars, etc.) plug in without the core depending on any of them.

## Open-Source Packaging

- **README:** what it is, the daily loop, install via `/plugin`, full config reference, hook examples, and the positioning vs. memory plugins.
- **Marketplace layout:** `.claude-plugin/marketplace.json` + `plugin.json` so users install cleanly via `/plugin`.
- **LICENSE:** MIT (unless the author prefers otherwise).
- **Example:** a sample config and one filled-in example day file, so prospective users see the output before adopting.
- **CONTRIBUTING + issue templates:** lightweight, to invite contributions without heavy process.

## Key Decisions (from brainstorming)

1. **Scope = journaling + daily planning only** (LifeOS "family A"); all Obsidian/PKM commands dropped. → coherent, portable product.
2. **Vault-less.** No Obsidian dependency; plain files anywhere.
3. **Daily loop only.** No persistent multi-day plans. → keeps the loop tight.
4. **One file per day** that evolves through start → check → end. → simple to navigate.
5. **Storage configurable, default global.** User decides at init.
6. **Git built-in; other integrations optional via hooks.** → universal core, dependency-free.
7. **Pure-prompt architecture, no code.** → zero install friction; reconsider scripts only if needed.
8. **`end` includes an auto-summarize step** before reflection. → produces the recap that feeds the next morning.
9. **Human-facing journal; memory is a deliberate, human-triggered bonus.** No auto-injection. → distinct from Remember/claude-mem and avoids context bloat.
10. **Name: `daylog`** (CC-ecosystem clear).

## Open Questions

- **Marketplace distribution** — publish in the author's own marketplace repo, or submit to a community marketplace. Decide before launch, not before build.
- **Does the author dogfood `daylog` for their own dev journal**, replacing the `~/Dev/journal/` portion of LifeOS? Out of scope for v1 build, but informs whether the existing journal format should be matched.
