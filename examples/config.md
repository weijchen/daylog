# daylog config

- storage_root: ~/daylog
- language: en
- repos: scan ~/Dev
- exclude:
  - ~/Dev/Archive
  - ~/Dev/Learning
- hooks:
  - linear: linear issue list --assignee me --state backlog
