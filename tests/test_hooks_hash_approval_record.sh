# SP-852 / SP-853 — the approval record, and what verify says about it.
#
# SP-852: store wrote the canonical file with a plain redirect, which truncates
# before it writes. A kill in between leaves hooks.sha256 empty, and verify then
# reported exit 4 — "the hook list has CHANGED since you approved it" — which is
# a false statement: the hooks did not change, the approval record was lost.
# Two states collapsed into one observation, and the misleading one trains
# reflexive re-approval of a security gate.
#
# The file already reasoned about this exact failure one step short: the SP-801
# comment directly above the write explains that `compute > file` truncates
# first, so a failed compute would poison every later verify. Same concern, same
# line, the kill case left open.
#
# Both halves are needed and they catch different things. The atomic write stops
# a *partial* hash ever landing — a truncated hash is a valid-looking string that
# is genuinely indistinguishable from a different hash, so no reader can detect
# it. The reader guard catches an *empty* record whatever produced it, including
# a file already corrupt on disk before this fix.
#
# SP-853: exit 3 asked the user to approve a hook list without printing it. The
# exit 4 path already printed it. That gap is load-bearing here — once an empty
# record reports 3 instead of 4, the branch that must show the hooks is the one
# that did not.

HH="$REPO_ROOT/scripts/hooks-hash.sh"

ar_tmp=$(mktemp -d)

ar_write_config() {
  {
    printf '# daylog config\n\n'
    printf -- '- storage_root: ~/daylog\n'
    printf -- '- hooks:\n'
    printf -- '  - linear: linear issue list --state backlog\n'
    printf -- '  - weather: curl -s wttr.in/Taipei\n'
  } > "$1"
}

ar_write_config "$ar_tmp/cfg.md"

# --- SP-853: exit 3 must show what it is asking about ------------------------

ar_state_new="$ar_tmp/state-new"
ar_out=$(env DAYLOG_STATE_DIR="$ar_state_new" "$HH" verify "$ar_tmp/cfg.md" 2>&1)
ar_code=$?

assert_eq 3 "$ar_code" "an unreviewed hook list still exits 3"

case "$ar_out" in
  *"linear issue list --state backlog"*)
    assert_eq yes yes "exit 3 prints the hook commands it wants approved" ;;
  *)
    assert_eq "the hook commands" "$ar_out" \
      "exit 3 prints the hook commands it wants approved" ;;
esac

case "$ar_out" in
  *"curl -s wttr.in/Taipei"*)
    assert_eq yes yes "exit 3 prints every hook, not just the first" ;;
  *)
    assert_eq "every hook command" "$ar_out" \
      "exit 3 prints every hook, not just the first" ;;
esac

# --- SP-852: store replaces the record atomically ----------------------------

ar_state="$ar_tmp/state"
env DAYLOG_STATE_DIR="$ar_state" "$HH" store "$ar_tmp/cfg.md" >/dev/null 2>&1

assert_eq "$(env DAYLOG_STATE_DIR="$ar_state" "$HH" compute "$ar_tmp/cfg.md")" \
  "$(cat "$ar_state/hooks.sha256")" \
  "store records the computed hash"

# The staging file must not survive — a fix that litters the state dir with
# hooks.sha256.XXXXXX is its own bug.
ar_litter=$(find "$ar_state" -name 'hooks.sha256.*' | wc -l | tr -d ' ')
assert_eq 0 "$ar_litter" "store leaves no staging file behind"

# Storing twice must still leave exactly one record.
env DAYLOG_STATE_DIR="$ar_state" "$HH" store "$ar_tmp/cfg.md" >/dev/null 2>&1
ar_count=$(find "$ar_state" -name 'hooks.sha256*' | wc -l | tr -d ' ')
assert_eq 1 "$ar_count" "a second store replaces the record rather than adding one"

assert_exit 0 "a stored, unchanged hook list verifies clean" \
  env DAYLOG_STATE_DIR="$ar_state" "$HH" verify "$ar_tmp/cfg.md"

# --- SP-852: an empty record is 'no approval', not 'the list changed' --------

ar_state_empty="$ar_tmp/state-empty"
mkdir -p "$ar_state_empty"
: > "$ar_state_empty/hooks.sha256"

ar_out_empty=$(env DAYLOG_STATE_DIR="$ar_state_empty" "$HH" verify "$ar_tmp/cfg.md" 2>&1)
ar_code_empty=$?

assert_eq 3 "$ar_code_empty" \
  "an empty approval record reports 'never reviewed' (3), not 'changed' (4)"

case "$ar_out_empty" in
  *CHANGED*)
    assert_eq "no CHANGED claim" "$ar_out_empty" \
      "an empty record must not claim the hook list changed" ;;
  *)
    assert_eq yes yes "an empty record must not claim the hook list changed" ;;
esac

# Blank-but-not-empty is the same situation.
printf '\n' > "$ar_state_empty/hooks.sha256"
assert_exit 3 "a whitespace-only approval record also reports 3" \
  env DAYLOG_STATE_DIR="$ar_state_empty" "$HH" verify "$ar_tmp/cfg.md"

# --- SP-852: a store that cannot finish must not destroy the old approval -----
#
# The atomicity itself cannot be tested by killing the shell mid-write — the
# race is not deterministic. What *is* deterministic is the property that makes
# atomicity worth having: an interrupted store leaves the previous approval
# intact. Injecting the failure at the rename shows it. With the old plain
# redirect the canonical file is truncated and rewritten before anything can
# fail, so the record is already replaced; with stage-then-rename a failed
# rename leaves the original untouched.

ar_state_keep="$ar_tmp/state-keep"
env DAYLOG_STATE_DIR="$ar_state_keep" "$HH" store "$ar_tmp/cfg.md" >/dev/null 2>&1
ar_first_hash=$(cat "$ar_state_keep/hooks.sha256")

# A PATH carrying everything the script needs, but where `mv` always fails.
mkdir -p "$ar_tmp/bin-nomv"
for t in awk cut cat mkdir sed basename shasum mktemp rm find tr; do
  _p=$(command -v "$t" 2>/dev/null) && ln -sf "$_p" "$ar_tmp/bin-nomv/$t"
done
printf '#!/bin/sh\nexit 1\n' > "$ar_tmp/bin-nomv/mv"
chmod +x "$ar_tmp/bin-nomv/mv"

# Change the hooks so a successful store would visibly move the recorded hash.
{
  printf '# daylog config\n\n'
  printf -- '- storage_root: ~/daylog\n'
  printf -- '- hooks:\n'
  printf -- '  - linear: linear issue list --state started\n'
} > "$ar_tmp/cfg2.md"

env PATH="$ar_tmp/bin-nomv" DAYLOG_STATE_DIR="$ar_state_keep" \
  "$HH" store "$ar_tmp/cfg2.md" >/dev/null 2>&1

assert_eq "$ar_first_hash" "$(cat "$ar_state_keep/hooks.sha256")" \
  "a store that fails to finish leaves the previous approval intact"

ar_keep_litter=$(find "$ar_state_keep" -name 'hooks.sha256.*' | wc -l | tr -d ' ')
assert_eq 0 "$ar_keep_litter" "a failed store cleans up its staging file"

# --- characterisation: real drift is still drift -----------------------------

ar_state_drift="$ar_tmp/state-drift"
mkdir -p "$ar_state_drift"
printf '%s\n' "0000000000000000000000000000000000000000000000000000000000000000" \
  > "$ar_state_drift/hooks.sha256"

assert_exit 4 "a different stored hash is still reported as drift (4)" \
  env DAYLOG_STATE_DIR="$ar_state_drift" "$HH" verify "$ar_tmp/cfg.md"

rm -rf "$ar_tmp"
