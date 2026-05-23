# daylog config

- storage_root: ~/daylog
- language: en
- repos: scan ~/Dev
  # "scan {DIR}" auto-discovers git repos under {DIR} (up to ~3 levels deep, e.g. {DIR}/Projects/<repo>);
  # or replace with an explicit list of repo paths
- hooks:
  # optional — each hook is a named shell command whose stdout is added as context:
  # - linear: linear issue list --assignee me --state backlog
