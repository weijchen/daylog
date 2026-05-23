# Contributing to daylog

daylog is a pure-prompt Claude Code plugin — the commands are Markdown files in `commands/`, the daily layout is `templates/day.md`. No build step, no dependencies.

## To change behavior
Edit the relevant `commands/*.md` file. Test by symlinking the repo into `~/.claude/plugins/local/daylog` and running the command in a Claude Code session against a scratch `storage_root`.

## Adding a context hook
Hooks are user config, not code — see the README. If you want to ship an example hook, add it to `examples/config.md`.

## Pull requests
- Keep each command focused on its one job.
- Update the README if you change a command's behavior or config.
- Describe how you tested the change.
