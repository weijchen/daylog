# Contributing to daylog

daylog is a near-pure-prompt Claude Code plugin — the commands are Markdown files in `commands/`, the daily layout is `templates/day.md`. No build step, no dependencies beyond a POSIX shell (`scripts/` also uses `jq` for the manifest check).

## To change behavior
Edit the relevant `commands/*.md` file. Test by symlinking the repo into `~/.claude/plugins/local/daylog` and running the command in a Claude Code session against a scratch `storage_root`.

## Tests

The few pieces that are shell rather than prose have tests:

```
sh tests/run.sh
```

Dependency-free POSIX sh; runs in a couple of seconds and is what CI runs.

- `scripts/hooks-hash.sh` — records/verifies approval of the hook list
- `scripts/check-plugin-metadata.sh` — asserts `plugin.json` and `marketplace.json` still agree on name and author

**Run `sh tests/run.sh` before opening a PR.** If you change either manifest, the metadata check is what stops the two from drifting.

## Adding a context hook
Hooks are user config, not code — see the README. If you want to ship an example hook, add it to `examples/config.md`.

## Pull requests
- Keep each command focused on its one job.
- Update the README if you change a command's behavior or config.
- Describe how you tested the change.
