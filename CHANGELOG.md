# Changelog

Started 2026-11-06. Earlier history: `git log`.

## Unreleased
- fix(tests): the "store writes nothing next to the config file" check counts matches with find instead of reading ls's exit code, which is 1 on macOS and 2 on Linux; `checks` CI had been red since 2026-08-28 (SP-1505)
- docs: AGENTS.md states how a change ships (SP-1499)
- docs: adopt README/CHANGELOG/AGENTS standard (SP-1440)
