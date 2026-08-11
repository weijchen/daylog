#!/bin/sh
# daylog — plugin manifest consistency check (SP-763)
#
# .claude-plugin/plugin.json and .claude-plugin/marketplace.json each carry the
# plugin's identity independently. Nothing propagates an edit from one to the
# other, so a rename or an author change can ship half-applied.
#
# This asserts the fields that MUST agree:
#   - plugin.json .name  ==  marketplace.json .name  ==  .plugins[].name
#   - plugin.json .author.name  ==  marketplace.json .owner.name
#
# Descriptions are deliberately NOT compared: marketplace.json carries a short
# listing blurb while plugin.json carries the long form. That difference is by
# design, not drift.
#
# Exit codes:
#   0  checked, consistent
#   1  checked, inconsistent
#   2  could not check (missing or unparseable manifest) — never reported as clean
#
# Usage: check-plugin-metadata.sh [repo-root]

set -u

ROOT=${1:-$(cd "$(dirname "$0")/.." && pwd)}
PLUGIN="$ROOT/.claude-plugin/plugin.json"
MARKET="$ROOT/.claude-plugin/marketplace.json"

command -v jq >/dev/null 2>&1 || {
  printf 'daylog: jq is required for this check but was not found\n' >&2
  exit 2
}

for f in "$PLUGIN" "$MARKET"; do
  [ -f "$f" ] || { printf 'daylog: manifest not found: %s\n' "$f" >&2; exit 2; }
  jq empty "$f" >/dev/null 2>&1 || {
    printf 'daylog: manifest is not valid JSON: %s\n' "$f" >&2
    exit 2
  }
done

plugin_name=$(jq -r '.name // empty' "$PLUGIN")
plugin_author=$(jq -r '.author.name // empty' "$PLUGIN")
market_name=$(jq -r '.name // empty' "$MARKET")
market_owner=$(jq -r '.owner.name // empty' "$MARKET")

for v in plugin_name plugin_author market_name market_owner; do
  eval "val=\$$v"
  [ -n "$val" ] || {
    printf 'daylog: required field missing (%s)\n' "$v" >&2
    exit 2
  }
done

status=0

fail() {
  printf 'daylog: %s\n' "$1" >&2
  status=1
}

[ "$plugin_name" = "$market_name" ] || \
  fail "name mismatch: plugin.json '$plugin_name' vs marketplace.json '$market_name'"

[ "$plugin_author" = "$market_owner" ] || \
  fail "author mismatch: plugin.json author.name '$plugin_author' vs marketplace.json owner.name '$market_owner'"

# Every marketplace entry must name a plugin that plugin.json agrees exists.
entries=$(jq -r '.plugins // [] | length' "$MARKET")
[ "$entries" -gt 0 ] || {
  printf 'daylog: marketplace.json lists no plugins\n' >&2
  exit 2
}

i=0
while [ "$i" -lt "$entries" ]; do
  entry_name=$(jq -r --argjson i "$i" '.plugins[$i].name // empty' "$MARKET")
  [ -n "$entry_name" ] || {
    printf 'daylog: marketplace.json plugins[%s] has no name\n' "$i" >&2
    exit 2
  }
  [ "$entry_name" = "$plugin_name" ] || \
    fail "marketplace.json plugins[$i].name '$entry_name' does not match plugin.json '$plugin_name'"
  i=$((i + 1))
done

if [ "$status" -eq 0 ]; then
  printf 'daylog: plugin metadata consistent (name=%s, author=%s)\n' "$plugin_name" "$plugin_author"
fi

exit "$status"
