# daylog — agent notes

Cross-repo rules live in `~/Dev/Projects/CLAUDE.md`; this file holds only what is specific here. CONTRIBUTING.md is the public, contributor-facing version of these notes.

## Layout

A near-pure-prompt Claude Code plugin, not the Python layout: `commands/*.md` (the four slash commands), `templates/day.md` (the daily file layout and its substitution tokens), `scripts/` (`hooks-hash.sh`, `check-plugin-metadata.sh`), `tests/` (POSIX sh), `examples/config.md`, `docs/`, plus the manifests `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

## Run and test

```bash
sh tests/run.sh
```

Dependency-free POSIX sh (`jq` for the manifest check). To try a command change, symlink the repo into `~/.claude/plugins/local/daylog` and run it in a Claude Code session against a scratch `storage_root`.

## Do not run

- `scripts/hooks-hash.sh` in record mode — writes the hook-list approval hash into the user's daylog state (SP-764); the tests exercise it against a temp root.

## Deploy

Ships by: push

Public repo and marketplace (`/plugin marketplace add weijchen/daylog`): a push to `main` is the release, so the manifest version moves with user-visible changes. Mac-only in Jimmy's terms (a push closes the ticket). Parked since 2026-08-30 (scanner-excluded at Jimmy's request); reviving it is removing that exclusion in cron-automation's `config/scanner_config.yaml`.

## Traps

- The two manifests must agree on name and author; `check-plugin-metadata.sh` and its test are what stop them drifting.
- Hooks are user config, never code: an example hook goes in `examples/config.md`.
- The plugin rides Claude Code's plugin/skill API, which still moves; the manifest cannot pin a minimum version yet, so a breakage on a new Claude Code release is the first thing to suspect.
- Never put an author-specific absolute path in a command or doc (the last commit before parking removed one).

## See also

README.md · CHANGELOG.md · CONTRIBUTING.md · docs/
