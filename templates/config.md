# daylog config

- storage_root: ~/daylog
  # ⚠️ this default is a plain local directory with NO backup — a disk failure or a
  # stray `rm -rf` takes every entry with it. Point it at somewhere already synced or
  # backed up (iCloud Drive, Dropbox, a git-tracked dotfiles dir) to avoid silent loss.
- language: en
- repos: scan ~/Dev
  # "scan {DIR}" auto-discovers git repos under {DIR} (up to ~3 levels deep, e.g. {DIR}/Projects/<repo>);
  # or replace with an explicit list of repo paths
- exclude:
  # optional — directories to skip during scan (e.g. retired/archived repos):
  # - ~/Dev/Archive
- hook_timeout: 10
  # seconds any single hook may run before /daylog-start gives up and moves on.
  # A hook that blocks on network or an auth prompt would otherwise stall planning
  # indefinitely with no diagnostic.
- hooks:
  # optional — each hook is a named shell command whose stdout is added as context.
  # ⚠️ hooks run as shell commands with your full privileges on every /daylog-start —
  # only add commands you trust; review any that arrive via a synced/shared config.
  # /daylog-start re-asks for approval whenever this list changes.
  # - linear: linear issue list --assignee me --state backlog
