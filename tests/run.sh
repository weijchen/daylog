#!/bin/sh
# daylog test runner — dependency-free POSIX sh.
# Usage: tests/run.sh [test-file ...]   (default: every tests/test_*.sh)

set -u

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
export REPO_ROOT

PASS=0
FAIL=0

# assert_ok "<description>" <command...>
assert_ok() {
  desc=$1
  shift
  output=$("$@" 2>&1)
  got=$?
  if [ "$got" -eq 0 ]; then
    PASS=$((PASS + 1))
    printf '  ok   %s\n' "$desc"
  else
    FAIL=$((FAIL + 1))
    printf '  FAIL %s\n       expected exit 0, got %s\n' "$desc" "$got"
    printf '       output: %s\n' "$output"
  fi
}

# assert_exit <expected-code> "<description>" <command...>
assert_exit() {
  want=$1
  desc=$2
  shift 2
  output=$("$@" 2>&1)
  got=$?
  if [ "$got" -eq "$want" ]; then
    PASS=$((PASS + 1))
    printf '  ok   %s\n' "$desc"
  else
    FAIL=$((FAIL + 1))
    printf '  FAIL %s\n       expected exit %s, got %s\n' "$desc" "$want" "$got"
    printf '       output: %s\n' "$output"
  fi
}

# assert_eq "<expected>" "<actual>" "<description>"
assert_eq() {
  if [ "$1" = "$2" ]; then
    PASS=$((PASS + 1))
    printf '  ok   %s\n' "$3"
  else
    FAIL=$((FAIL + 1))
    printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$3" "$1" "$2"
  fi
}

# assert_ne "<a>" "<b>" "<description>"
assert_ne() {
  if [ "$1" != "$2" ]; then
    PASS=$((PASS + 1))
    printf '  ok   %s\n' "$3"
  else
    FAIL=$((FAIL + 1))
    printf '  FAIL %s\n       expected the two values to differ, both were: %s\n' "$3" "$1"
  fi
}

if [ $# -gt 0 ]; then
  FILES=$*
else
  FILES=$(find "$REPO_ROOT/tests" -name 'test_*.sh' | sort)
fi

for f in $FILES; do
  printf '%s\n' "$(basename "$f")"
  # shellcheck disable=SC1090
  . "$f"
done

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
