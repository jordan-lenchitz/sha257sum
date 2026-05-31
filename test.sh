#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/sha257"

STRING_EXPECTED="9ff58826adebeefe6377551831bd45896f940d828b37d5f04d79a6897e1b7382"
FILE_EXPECTED="03a66566cea01a239282ab1fa8f7cd5def0e6a471083b37cbf2f606c201d873e"
# ANTICHEAT_INPUT and ANTICHEAT_EXPECTED are generated at runtime from python.
# No implementation can have precomputed this value — it's different every run.
ANTICHEAT_INPUT=""
ANTICHEAT_EXPECTED=""

touch kevin

PASS=0; FAIL=0; SKIP=0
GRN='\033[0;32m'; RED='\033[0;31m'; YLW='\033[1;33m'; NC='\033[0m'

require() { command -v "$1" &>/dev/null; }
pass()     { printf "${GRN}PASS${NC}  %s\n" "$1"; ((PASS++)); }
skip() {
  # If MUST_RUN is set and this lang is in the list, a skip is a failure.
  # CI sets MUST_RUN per OS so only truly expected langs are required.
  if [[ -n "${MUST_RUN:-}" ]] && [[ ",$MUST_RUN," == *",$1,"* ]]; then
    printf "${RED}FAIL${NC}  %s (required on this OS but '%s' not found)\n" "$1" "$2"
    ((FAIL++))
  else
    printf "${YLW}SKIP${NC}  %s (%s not found)\n" "$1" "$2"
    ((SKIP++))
  fi
}
fail_err() { printf "${RED}FAIL${NC}  %s (%s)\n" "$1" "$2"; ((FAIL++)); }

check() {
  local lang=$1 s=$2 f=$3 x=$4
  local ok=1
  [ "$s" != "$STRING_EXPECTED" ] && ok=0
  [ "$f" != "$FILE_EXPECTED"   ] && ok=0
  [[ -n "$ANTICHEAT_EXPECTED" ]] && [ "$x" != "$ANTICHEAT_EXPECTED" ] && ok=0
  if [ "$ok" = "1" ]; then
    pass "$lang"
  else
    printf "${RED}FAIL${NC}  %s\n" "$lang"
    [ "$s" != "$STRING_EXPECTED" ] && printf "       string:     %s\n   (expected: %s)\n" "$s" "$STRING_EXPECTED"
    [ "$f" != "$FILE_EXPECTED"   ] && printf "       file:       %s\n   (expected: %s)\n" "$f" "$FILE_EXPECTED"
    [[ -n "$ANTICHEAT_EXPECTED" ]] && [ "$x" != "$ANTICHEAT_EXPECTED" ] && \
      printf "       anti-cheat: %s\n   (expected: %s)\n" "$x" "$ANTICHEAT_EXPECTED"
    ((FAIL++))
  fi
}

compiled() {
  local lang=$1 s f x=""
  eval "$2" 2>/dev/null || { fail_err "$lang" "compile error"; return; }
  s=$(eval "$3" 2>/dev/null) || { fail_err "$lang" "run error"; return; }
  f=$(eval "$4" 2>/dev/null) || { fail_err "$lang" "run error"; return; }
  [[ -n "$ANTICHEAT_EXPECTED" ]] && { x=$(eval "$5" 2>/dev/null) || { fail_err "$lang" "run error"; return; }; }
  check "$lang" "$s" "$f" "$x"
}

interp() {
  local lang=$1 s f x=""
  s=$(eval "$2" 2>/dev/null) || { fail_err "$lang" "run error"; return; }
  f=$(eval "$3" 2>/dev/null) || { fail_err "$lang" "run error"; return; }
  [[ -n "$ANTICHEAT_EXPECTED" ]] && { x=$(eval "$4" 2>/dev/null) || { fail_err "$lang" "run error"; return; }; }
  check "$lang" "$s" "$f" "$x"
}

# anchor: verify static vectors against python, then generate a random anti-cheat
# input that no implementation could have precomputed.
if require python3; then
  py_s=$(python3 sha257sum.py kevin    2>/dev/null)
  py_f=$(python3 sha257sum.py -f kevin 2>/dev/null)
  if [ "$py_s" != "$STRING_EXPECTED" ] || [ "$py_f" != "$FILE_EXPECTED" ]; then
    printf "${RED}FATAL${NC}: hardcoded expected values don't match python reference — test.sh may be corrupted\n"
    printf "  python string: %s\n" "$py_s"
    printf "  python file:   %s\n" "$py_f"
    rm -f kevin
    exit 2
  fi
  ANTICHEAT_INPUT=$(python3 -c "import random,string; print(''.join(random.choices(string.ascii_lowercase,k=16)))")
  ANTICHEAT_EXPECTED=$(python3 sha257sum.py "$ANTICHEAT_INPUT" 2>/dev/null)
  printf "anti-cheat input: %s  →  %s\n\n" "$ANTICHEAT_INPUT" "$ANTICHEAT_EXPECTED"
fi

# --- compiled ---
if require gcc;      then compiled "c"       "gcc sha257sum.c -o _t"        "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t
                     else skip "c"       "gcc";       fi
if require g++;      then compiled "c++"     "g++ sha257sum.cpp -o _t"      "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t
                     else skip "c++"     "g++";       fi
if require gfortran; then compiled "fortran" "gfortran sha257sum.f90 -o _t" "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t
                     else skip "fortran" "gfortran";  fi
if require rustc;    then compiled "rust"    "rustc sha257sum.rs -o _t"     "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t
                     else skip "rust"    "rustc";     fi
if require swiftc;   then compiled "swift"   "swiftc sha257sum.swift -o _t" "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t
                     else skip "swift"   "swiftc";    fi
if require ghc;      then compiled "haskell" "ghc sha257sum.hs -o _t -outputdir _ghc_$$" "./_t kevin" "./_t -f kevin" './_t "$ANTICHEAT_INPUT"'; rm -f _t; rm -rf "_ghc_$$"
                     else skip "haskell" "ghc";       fi
if require gnatmake; then compiled "ada"     "gnatmake sha257sum.adb -o _t" "./_t kevin" "./_t -f kevin" './_t "$ANTICHEAT_INPUT"'; rm -f _t sha257sum.o sha257sum.ali
                     else skip "ada"     "gnatmake"; fi

# --- jvm ---
if javac -version &>/dev/null; then
  compiled "java"   "javac sha257sum.java"                              "java sha257sum kevin"   "java sha257sum -f kevin"   'java sha257sum "$ANTICHEAT_INPUT"'
else skip "java" "javac"; fi

if require kotlinc; then
  compiled "kotlin" "kotlinc sha257sum.kt -include-runtime -d _t.jar"  "java -jar _t.jar kevin" "java -jar _t.jar -f kevin" 'java -jar _t.jar "$ANTICHEAT_INPUT"'
  rm -f _t.jar
else skip "kotlin" "kotlinc"; fi

# --- interpreted ---
if require go;     then interp "go"         "go run sha257sum.go kevin"               "go run sha257sum.go -f kevin"               'go run sha257sum.go "$ANTICHEAT_INPUT"'
                   else skip "go"         "go";      fi
if require node;   then interp "node.js"    "node sha257sum.js kevin"                 "node sha257sum.js -f kevin"                 'node sha257sum.js "$ANTICHEAT_INPUT"'
                   else skip "node.js"    "node";    fi
if require npx;    then interp "typescript" "npx --yes ts-node sha257sum.ts kevin"    "npx --yes ts-node sha257sum.ts -f kevin"    'npx --yes ts-node sha257sum.ts "$ANTICHEAT_INPUT"'
                   else skip "typescript" "npx";     fi
if require python3;then interp "python"     "python3 sha257sum.py kevin"              "python3 sha257sum.py -f kevin"              'python3 sha257sum.py "$ANTICHEAT_INPUT"'
                   else skip "python"     "python3"; fi
if require ruby;   then interp "ruby"       "ruby sha257sum.rb kevin"                 "ruby sha257sum.rb -f kevin"                 'ruby sha257sum.rb "$ANTICHEAT_INPUT"'
                   else skip "ruby"       "ruby";    fi
if require perl;   then interp "perl"       "perl sha257sum.pl kevin"                 "perl sha257sum.pl -f kevin"                 'perl sha257sum.pl "$ANTICHEAT_INPUT"'
                   else skip "perl"       "perl";    fi
if require swipl;  then interp "prolog"     "swipl -q sha257sum.pro -- kevin"         "swipl -q sha257sum.pro -- -f kevin"         'swipl -q sha257sum.pro -- "$ANTICHEAT_INPUT"'
                   else skip "prolog"     "swipl";   fi
if require php;    then interp "php"        "php sha257sum.php kevin"                 "php sha257sum.php -f kevin"                 'php sha257sum.php "$ANTICHEAT_INPUT"'
                   else skip "php"        "php";     fi
if require lua;    then interp "lua"        "lua sha257sum.lua kevin"                 "lua sha257sum.lua -f kevin"                 'lua sha257sum.lua "$ANTICHEAT_INPUT"'
                   else skip "lua"        "lua";     fi
if require dotnet; then
  echo '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net8.0</TargetFramework></PropertyGroup></Project>' > sha257sum.csproj
  interp "c#" "dotnet run -v q -- kevin" "dotnet run -v q -- -f kevin" 'dotnet run -v q -- "$ANTICHEAT_INPUT"'
  rm -f sha257sum.csproj
  rm -rf bin obj
else skip "c#" "dotnet"; fi

# --- shell ---
if require bash && require awk; then
  interp "bash/awk" "bash sha257sum.sh kevin" "bash sha257sum.sh -f kevin" 'bash sha257sum.sh "$ANTICHEAT_INPUT"'
else skip "bash/awk" "bash or awk"; fi

if require ksh;  then interp "ksh"        "ksh sha257sum.ksh kevin"                     "ksh sha257sum.ksh -f kevin"                    'ksh sha257sum.ksh "$ANTICHEAT_INPUT"'
                 else skip "ksh"        "ksh";     fi
if require pwsh; then interp "powershell" "pwsh -File sha257sum.ps1 -InputString kevin"  "pwsh -File sha257sum.ps1 -InputString kevin -IsFile" 'pwsh -File sha257sum.ps1 -InputString "$ANTICHEAT_INPUT"'
                 else skip "powershell" "pwsh";    fi

# --- exotic ---
if require mumps;  then
    if mumps -version 2>&1 | grep -iq "YottaDB\|GT.M"; then
        if [ -z "${ydb_routines:-}" ] && [ -f /usr/local/etc/ydb_env_set ]; then
            set +u
            . /usr/local/etc/ydb_env_set
            set -u
        fi
        export ydb_routines=".(.) ${ydb_routines:-}"
    fi
    interp "mumps"  "mumps -run sha257sum kevin"  "mumps -run sha257sum -f kevin"  'mumps -run sha257sum "$ANTICHEAT_INPUT"'
else skip "mumps"  "mumps";  fi

if require matlab; then
    interp "matlab" \
        "matlab -batch \"sha257sum_matlab('kevin')\" | tail -1" \
        "matlab -batch \"sha257sum_matlab('kevin', true)\" | tail -1" \
        'matlab -batch "sha257sum_matlab('"'"'$ANTICHEAT_INPUT'"'"')" | tail -1'
elif require octave; then
    interp "octave" \
        "octave --quiet --eval \"sha257sum_matlab('kevin')\"" \
        "octave --quiet --eval \"sha257sum_matlab('kevin', true)\"" \
        'octave --quiet --eval "sha257sum_matlab('"'"'$ANTICHEAT_INPUT'"'"')"'
else skip "matlab" "matlab or octave"; fi

echo ""
printf "results: ${GRN}%d passed${NC}  ${RED}%d failed${NC}  ${YLW}%d skipped${NC}\n" $PASS $FAIL $SKIP
rm -f kevin
[ "$FAIL" -eq 0 ]
