# daylog config

- storage_root: ~/daylog
- language: en
- repos: scan ~/Dev
  # "scan {DIR}" auto-discovers git repos under {DIR} (up to ~3 levels deep, e.g. {DIR}/Projects/<repo>);
  # or replace with an explicit list of repo paths
- exclude:
  # optional — directories to skip during scan (e.g. retired/archived repos):
  # - ~/Dev/Archive
- hooks:
  # optional — each hook is a named shell command whose stdout is added as context.
  # ⚠️ hooks run as shell commands with your full privileges on every /daylog-start —
  # only add commands you trust; review any that arrive via a synced/shared config.
  # - linear: linear issue list --assignee me --state backlog
