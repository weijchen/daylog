# SP-801 — hash computation must fail CLOSED.
# compute() piped through `shasum | cut`; POSIX sh has no pipefail, so a missing
# or failing shasum made cut emit an empty string with exit 0. store then wrote
# an empty hash, verify compared empty==empty, and the review gate — a security
# control — passed forever without ever hashing anything.

HH="$REPO_ROOT/scripts/hooks-hash.sh"

fc_tmp=$(mktemp -d)
# note: run.sh sources every test file into one shell; don't clobber other
# files' traps — clean up inline at the end instead.

fc_write_config() {
  {
    printf '# daylog config\n\n'
    printf -- '- storage_root: ~/daylog\n'
    printf -- '- hooks:\n'
    printf -- '  - linear: linear issue list --state backlog\n'
  } > "$1"
}

fc_write_config "$fc_tmp/cfg.md"

# Restricted PATH with every tool the script needs EXCEPT shasum/sha256sum.
mkdir -p "$fc_tmp/bin-none"
for t in awk cut cat mkdir sed basename; do
  ln -s "$(command -v $t)" "$fc_tmp/bin-none/$t"
done

# Same, plus a shasum that is found by the probe but fails at runtime.
mkdir -p "$fc_tmp/bin-broken"
for t in awk cut cat mkdir sed basename; do
  ln -s "$(command -v $t)" "$fc_tmp/bin-broken/$t"
done
printf '#!/bin/sh\nexit 127\n' > "$fc_tmp/bin-broken/shasum"
chmod +x "$fc_tmp/bin-broken/shasum"

# Linux-shaped PATH: no shasum, but sha256sum exists (wrapper over the real tool).
mkdir -p "$fc_tmp/bin-linux"
for t in awk cut cat mkdir sed basename; do
  ln -s "$(command -v $t)" "$fc_tmp/bin-linux/$t"
done
printf '#!/bin/sh\nexec /usr/bin/shasum -a 256 "$@"\n' > "$fc_tmp/bin-linux/sha256sum"
chmod +x "$fc_tmp/bin-linux/sha256sum"

# --- fail-closed -------------------------------------------------------------

assert_exit 2 "compute exits 2 when no sha256 tool exists (was: empty hash, exit 0)" \
  env PATH="$fc_tmp/bin-none" "$HH" compute "$fc_tmp/cfg.md"

assert_exit 2 "compute exits 2 when shasum exists but fails (empty pipe output)" \
  env PATH="$fc_tmp/bin-broken" "$HH" compute "$fc_tmp/cfg.md"

assert_exit 2 "verify fails closed (exit 2, not 0) when hashing is impossible" \
  env PATH="$fc_tmp/bin-none" DAYLOG_STATE_DIR="$fc_tmp/state" "$HH" verify "$fc_tmp/cfg.md"

assert_exit 2 "store refuses to record an approval it cannot hash" \
  env PATH="$fc_tmp/bin-none" DAYLOG_STATE_DIR="$fc_tmp/state" "$HH" store "$fc_tmp/cfg.md"

# A failed store must not leave a hash file behind — an empty approved-hash
# would poison every later verify.
if [ -e "$fc_tmp/state/hooks.sha256" ]; then
  assert_eq "absent" "present" "failed store leaves no hooks.sha256 behind"
else
  assert_eq "absent" "absent" "failed store leaves no hooks.sha256 behind"
fi

# --- portability -------------------------------------------------------------

fc_linux_hash=$(env PATH="$fc_tmp/bin-linux" "$HH" compute "$fc_tmp/cfg.md")
assert_eq 64 "$(printf '%s' "$fc_linux_hash" | wc -c | tr -d ' ')" \
  "compute falls back to sha256sum when shasum is absent (Linux)"

fc_mac_hash=$("$HH" compute "$fc_tmp/cfg.md")
assert_eq "$fc_mac_hash" "$fc_linux_hash" \
  "shasum and sha256sum produce the same recorded hash"

rm -rf "$fc_tmp"
