# daylog config

# storage_root points at an iCloud-synced directory rather than the ~/daylog default,
# so the history survives the machine.
- storage_root: ~/Library/Mobile Documents/com~apple~CloudDocs/daylog
- language: en
- repos: scan ~/Dev
- exclude:
  - ~/Dev/Archive
  - ~/Dev/Learning
- hook_timeout: 10
- hooks:
  - linear: linear issue list --assignee me --state backlog
