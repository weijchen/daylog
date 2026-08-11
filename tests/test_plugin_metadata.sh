# SP-763 — plugin.json / marketplace.json carry the same identity fields independently.
# Nothing stops one from being bumped without the other, so assert the overlap.

PM="$REPO_ROOT/scripts/check-plugin-metadata.sh"

pm_tmp=$(mktemp -d)
trap 'rm -rf "$pm_tmp"' EXIT

# fixture <dir> <plugin-name> <marketplace-name> <entry-name> <author> <owner>
fixture() {
  mkdir -p "$1/.claude-plugin"
  cat > "$1/.claude-plugin/plugin.json" <<EOF
{
  "name": "$2",
  "description": "long form description",
  "version": "0.1.0",
  "author": { "name": "$5" },
  "license": "MIT"
}
EOF
  cat > "$1/.claude-plugin/marketplace.json" <<EOF
{
  "name": "$3",
  "owner": { "name": "$6" },
  "plugins": [
    { "name": "$4", "source": "./", "description": "short blurb" }
  ]
}
EOF
}

# --- the repo's own files ----------------------------------------------------

assert_ok "the checked-in plugin metadata is consistent" "$PM" "$REPO_ROOT"

# --- drift the check must catch ---------------------------------------------

fixture "$pm_tmp/ok" daylog daylog daylog "Jimmy Chen" "Jimmy Chen"
assert_ok "a consistent fixture passes" "$PM" "$pm_tmp/ok"

fixture "$pm_tmp/name" daylog daylog-renamed daylog "Jimmy Chen" "Jimmy Chen"
assert_exit 1 "a marketplace name that drifts from plugin.json fails" "$PM" "$pm_tmp/name"

fixture "$pm_tmp/entry" daylog daylog daylog-old "Jimmy Chen" "Jimmy Chen"
assert_exit 1 "a marketplace plugins[] entry name that drifts fails" "$PM" "$pm_tmp/entry"

fixture "$pm_tmp/author" daylog daylog daylog "Jimmy Chen" "Someone Else"
assert_exit 1 "author.name drifting from owner.name fails" "$PM" "$pm_tmp/author"

# --- "could not check" is not "checked and clean" ----------------------------

mkdir -p "$pm_tmp/missing/.claude-plugin"
assert_exit 2 "a missing manifest exits 2 (cannot check), not 0" "$PM" "$pm_tmp/missing"

fixture "$pm_tmp/broken" daylog daylog daylog "Jimmy Chen" "Jimmy Chen"
printf 'not json{' > "$pm_tmp/broken/.claude-plugin/marketplace.json"
assert_exit 2 "unparseable JSON exits 2 (cannot check), not 0" "$PM" "$pm_tmp/broken"
