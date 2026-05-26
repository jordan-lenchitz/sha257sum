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

# --- compiled ---
if require gcc;      then compiled "c"       "gcc sha257sum.c -o _t"       "./_t kevin"  "./_t -f kevin"; rm -f _t
                     else skip "c"       "gcc";       fi
if require g++;      then compiled "c++"     "g++ sha257sum.cpp -o _t"     "./_t kevin"  "./_t -f kevin"; rm -f _t
                     else skip "c++"     "g++";       fi
if require gfortran; then compiled "fortran" "gfortran sha257sum.f90 -o _t" "./_t kevin" "./_t -f kevin"; rm -f _t
                     else skip "fortran" "gfortran";  fi
if require rustc;    then compiled "rust"    "rustc sha257sum.rs -o _t"    "./_t kevin"  "./_t -f kevin"; rm -f _t
                     else skip "rust"    "rustc";     fi
if require swiftc;   then compiled "swift"   "swiftc sha257sum.swift -o _t" "./_t kevin" "./_t -f kevin"; rm -f _t
                     else skip "swift"   "swiftc";    fi
if require ghc;      then compiled "haskell" "ghc sha257sum.hs -o _t -outputdir /tmp/ghc_$$" "./_t kevin" "./_t -f kevin"; rm -f _t; rm -rf "/tmp/ghc_$$"
                     else skip "haskell" "ghc";       fi

# --- jvm ---
if javac -version &>/dev/null; then
  compiled "java"   "javac sha257sum.java"                                      "java sha257sum kevin"    "java sha257sum -f kevin"
else skip "java" "javac"; fi

if require kotlinc; then
  compiled "kotlin" "kotlinc sha257sum.kt -include-runtime -d _t.jar"          "java -jar _t.jar kevin"  "java -jar _t.jar -f kevin"
  rm -f _t.jar
else skip "kotlin" "kotlinc"; fi

# anchor: verify hardcoded expected values against python before trusting any result
# if someone tampers with STRING_EXPECTED or FILE_EXPECTED, python catches it here
if require python3; then
  py_s=$(python3 sha257sum.py kevin   2>/dev/null)
  py_f=$(python3 sha257sum.py -f kevin 2>/dev/null)
  if [ "$py_s" != "$STRING_EXPECTED" ] || [ "$py_f" != "$FILE_EXPECTED" ]; then
    printf "${RED}FATAL${NC}: hardcoded expected values don't match python reference\n"
    printf "  python string: %s\n" "$py_s"
    printf "  python file:   %s\n" "$py_f"
    rm -f kevin
    exit 2
  fi
fi

echo ""
printf "results: ${GRN}%d passed${NC}  ${RED}%d failed${NC}  ${YLW}%d skipped${NC}\n" $PASS $FAIL $SKIP
rm -f kevin
[ "$FAIL" -eq 0 ]
