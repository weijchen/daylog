#!/bin/sh
# daylog — hook-list review state (SP-764)
#
# Hooks run as shell commands with your full privileges on every /daylog-start.
# /daylog-init asks you to confirm them once, but a config synced from another
# machine (dotfiles, iCloud, a shared repo) can introduce new or altered hooks
# that would otherwise run un-reviewed on the very next /daylog-start.
#
# This records a hash of the hook list at the moment you approved it, so
# /daylog-start can tell three states apart:
#
#   0  reviewed and unchanged (or no hooks at all — nothing to run)
#   3  hooks present but never reviewed on this machine
#   4  the hook list changed since you approved it
#
# The hash is stored MACHINE-LOCALLY, on purpose. Storing it in config.md would
# make it travel with the very file it guards, and storage_root is somewhere we
# actively suggest putting on a synced drive (see README "Storage & backup").
#
# Usage:
#   hooks-hash.sh compute <config>     print the hash of the config's hook list
#   hooks-hash.sh store   <config>     record that hook list as approved
#   hooks-hash.sh verify  <config>     compare against the approved list
#   hooks-hash.sh state-dir [--literal]  print the state directory

set -u

usage() {
  printf 'usage: %s {compute|store|verify} <config-path>\n' "$(basename "$0")" >&2
  printf '       %s state-dir [--literal]\n' "$(basename "$0")" >&2
  exit 64
}

state_dir() {
  if [ -n "${DAYLOG_STATE_DIR:-}" ]; then
    printf '%s' "$DAYLOG_STATE_DIR"
  else
    printf '%s/daylog' "${XDG_STATE_HOME:-$HOME/.local/state}"
  fi
}

# The executable content of the hooks block: `- name: command` lines only.
# Comments and blank lines are excluded — they never run, so changing one must
# not demand a re-review. The block ends at the next unindented `- key:` field.
extract_hooks() {
  awk '
    /^[[:space:]]*-[[:space:]]*hooks:[[:space:]]*$/ { in_block = 1; next }
    in_block {
      if ($0 ~ /^[^[:space:]]/) { in_block = 0; next }
      line = $0
      sub(/^[[:space:]]+/, "", line)
      if (line == "" || line ~ /^#/) next
      if (line ~ /^-[[:space:]]*/) {
        sub(/^-[[:space:]]*/, "", line)
        sub(/[[:space:]]+$/, "", line)
        if (line != "") print line
      }
    }
  ' "$1"
}

# SP-801: hashing must fail CLOSED. POSIX sh has no pipefail, so a missing or
# failing shasum used to make `shasum | cut` print an empty string with exit 0
# — store recorded an empty hash, verify compared empty==empty, and this
# review gate passed forever without ever hashing anything.
sha256_tool() {
  if command -v shasum >/dev/null 2>&1; then
    printf 'shasum'
  elif command -v sha256sum >/dev/null 2>&1; then
    printf 'sha256sum'
  else
    return 1
  fi
}

run_sha256() {
  if [ "$1" = shasum ]; then shasum -a 256; else sha256sum; fi
}

compute() {
  [ -f "$1" ] || { printf 'daylog: config not found: %s\n' "$1" >&2; exit 2; }
  if ! tool=$(sha256_tool); then
    printf 'daylog: neither shasum nor sha256sum found; refusing to skip hook review\n' >&2
    exit 2
  fi
  hash=$(extract_hooks "$1" | run_sha256 "$tool" | cut -d' ' -f1)
  if [ -z "$hash" ]; then
    printf 'daylog: hash computation produced no output; refusing to skip hook review\n' >&2
    exit 2
  fi
  printf '%s\n' "$hash"
}

has_hooks() {
  [ -n "$(extract_hooks "$1")" ]
}

cmd=${1:-}
[ -n "$cmd" ] || usage

case "$cmd" in
  state-dir)
    if [ "${2:-}" = "--literal" ] && [ -z "${DAYLOG_STATE_DIR:-}" ]; then
      # Show the unexpanded form, so docs and tests can assert *where* it lives
      # rather than what it happened to expand to on one machine.
      printf '${XDG_STATE_HOME:-$HOME/.local/state}/daylog\n'
    else
      printf '%s\n' "$(state_dir)"
    fi
    ;;

  compute)
    [ $# -ge 2 ] || usage
    compute "$2"
    ;;

  store)
    [ $# -ge 2 ] || usage
    dir=$(state_dir)
    mkdir -p "$dir" || exit 2
    # Compute before touching the file: `compute > file` truncates first, so a
    # failed compute would leave an empty approved-hash poisoning every verify.
    approved=$(compute "$2") || exit 2
    printf '%s\n' "$approved" > "$dir/hooks.sha256" || exit 2
    printf 'daylog: hook list approved (%s)\n' "$dir/hooks.sha256"
    ;;

  verify)
    [ $# -ge 2 ] || usage
    config=$2
    [ -f "$config" ] || { printf 'daylog: config not found: %s\n' "$config" >&2; exit 2; }

    if ! has_hooks "$config"; then
      # Nothing executable to guard.
      exit 0
    fi

    stored_file="$(state_dir)/hooks.sha256"
    current=$(compute "$config") || exit 2

    if [ ! -f "$stored_file" ]; then
      printf 'daylog: this config defines hooks that have never been reviewed on this machine.\n' >&2
      printf 'Review them, then approve with: %s store %s\n' "$0" "$config" >&2
      exit 3
    fi

    stored=$(cat "$stored_file")
    if [ "$current" = "$stored" ]; then
      exit 0
    fi

    printf 'daylog: the hook list has CHANGED since you approved it.\n' >&2
    printf 'Current hooks:\n' >&2
    extract_hooks "$config" | sed 's/^/  - /' >&2
    printf 'Review the list above, then re-approve with: %s store %s\n' "$0" "$config" >&2
    exit 4
    ;;

  *)
    usage
    ;;
esac
