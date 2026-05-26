#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/sha257"

STRING_EXPECTED="9ff58826adebeefe6377551831bd45896f940d828b37d5f04d79a6897e1b7382"
FILE_EXPECTED="03a66566cea01a239282ab1fa8f7cd5def0e6a471083b37cbf2f606c201d873e"

touch kevin

PASS=0; FAIL=0; SKIP=0
GRN='\033[0;32m'; RED='\033[0;31m'; YLW='\033[1;33m'; NC='\033[0m'

require() { command -v "$1" &>/dev/null; }
pass()     { printf "${GRN}PASS${NC}  %s\n" "$1"; ((PASS++)); }
skip()     { printf "${YLW}SKIP${NC}  %s (%s not found)\n" "$1" "$2"; ((SKIP++)); }
fail_err() { printf "${RED}FAIL${NC}  %s (%s)\n" "$1" "$2"; ((FAIL++)); }

check() {
  local lang=$1 s=$2 f=$3
  if [ "$s" = "$STRING_EXPECTED" ] && [ "$f" = "$FILE_EXPECTED" ]; then
    pass "$lang"
  else
    printf "${RED}FAIL${NC}  %s\n" "$lang"
    [ "$s" != "$STRING_EXPECTED" ] && printf "       string: %s\n   (expected: %s)\n" "$s" "$STRING_EXPECTED"
    [ "$f" != "$FILE_EXPECTED"   ] && printf "       file:   %s\n   (expected: %s)\n" "$f" "$FILE_EXPECTED"
    ((FAIL++))
  fi
}

compiled() {
  local lang=$1 s f
  eval "$2" 2>/dev/null || { fail_err "$lang" "compile error"; return; }
  s=$(eval "$3" 2>/dev/null) || { fail_err "$lang" "run error"; return; }
  f=$(eval "$4" 2>/dev/null) || { fail_err "$lang" "run error"; return; }
  check "$lang" "$s" "$f"
}

interp() {
  local lang=$1 s f
  s=$(eval "$2" 2>/dev/null) || { fail_err "$lang" "run error"; return; }
  f=$(eval "$3" 2>/dev/null) || { fail_err "$lang" "run error"; return; }
  check "$lang" "$s" "$f"
}

echo ""
printf "results: ${GRN}%d passed${NC}  ${RED}%d failed${NC}  ${YLW}%d skipped${NC}\n" $PASS $FAIL $SKIP
rm -f kevin
[ "$FAIL" -eq 0 ]
