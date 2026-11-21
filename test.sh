#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/sha257"

STRING_EXPECTED="9ff58826adebeefe6377551831bd45896f940d828b37d5f04d79a6897e1b7382"
FILE_EXPECTED="03a66566cea01a239282ab1fa8f7cd5def0e6a471083b37cbf2f606c201d873e"
# these next two values are generated at runtime so no implementation can cheat and precompute the two above values
ANTICHEAT_INPUT=""
ANTICHEAT_EXPECTED=""

touch kevin

PASS=0; FAIL=0; SKIP=0
GRN='\033[0;32m'; RED='\033[0;31m'; YLW='\033[1;33m'; NC='\033[0m'

require() { command -v "$1" &>/dev/null; }
pass()     { printf "${GRN}PASS${NC}  %s\n" "$1"; ((PASS++)); }
skip() {
  # if MUST_RUN is set and this lang is in the list skip failure
  # but do not fret since CI sets MUST_RUN per OS so only truly expected langs are required
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

# verify static vectors against python and then generate the random anti-cheat
if require python3; then
  py_s=$(python3 sha257sum.py kevin    2>/dev/null)
  py_f=$(python3 sha257sum.py -f kevin 2>/dev/null)
  if [ "$py_s" != "$STRING_EXPECTED" ] || [ "$py_f" != "$FILE_EXPECTED" ]; then
    printf "${RED}FATAL${NC}: hardcoded expected values don't match python reference (uh oh) test.sh may be corrupted\n"
    printf "  python string: %s\n" "$py_s"
    printf "  python file:   %s\n" "$py_f"
    rm -f kevin
    exit 2
  fi
  ANTICHEAT_INPUT=$(python3 -c "import random,string; print(''.join(random.choices(string.ascii_lowercase,k=16)))")
  ANTICHEAT_EXPECTED=$(python3 sha257sum.py "$ANTICHEAT_INPUT" 2>/dev/null)
  printf "anti-cheat input: %s  →  %s\n\n" "$ANTICHEAT_INPUT" "$ANTICHEAT_EXPECTED"
fi

# Optional ONLY_RUN filter (comma-separated list of language names, or "all")
should_run() {
  [[ -z "${ONLY_RUN:-}" || "${ONLY_RUN}" == "all" ]] && return 0
  [[ ",${ONLY_RUN}," == *",$1,"* ]]
}

# compiled
if should_run "c"; then
  if require gcc;      then compiled "c"       "gcc sha257sum.c -o _t"        "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t
                       else skip "c"       "gcc";       fi
fi
if should_run "c++"; then
  if require g++;      then compiled "c++"     "g++ sha257sum.cpp -o _t"      "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t
                       else skip "c++"     "g++";       fi
fi
if should_run "fortran"; then
  if require gfortran; then compiled "fortran" "gfortran sha257sum.f90 -o _t" "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t
                       else skip "fortran" "gfortran";  fi
fi
if should_run "rust"; then
  if require rustc;    then compiled "rust"    "rustc sha257sum.rs -o _t"     "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t
                       else skip "rust"    "rustc";     fi
fi
if should_run "swift"; then
  if require swiftc;   then compiled "swift"   "swiftc sha257sum.swift -o _t" "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t
                       else skip "swift"   "swiftc";    fi
fi
if should_run "haskell"; then
  if require ghc;      then compiled "haskell" "ghc sha257sum.hs -o _t -outputdir _ghc_$$" "./_t kevin" "./_t -f kevin" './_t "$ANTICHEAT_INPUT"'; rm -f _t; rm -rf "_ghc_$$"
                       else skip "haskell" "ghc";       fi
fi
if should_run "ada"; then
  if require gnatmake; then compiled "ada"     "gnatmake sha257sum.adb -o _t" "./_t kevin" "./_t -f kevin" './_t "$ANTICHEAT_INPUT"'; rm -f _t sha257sum.o sha257sum.ali
                       else skip "ada"     "gnatmake"; fi
fi
if should_run "cobol"; then
  if require cobc;     then compiled "cobol"   "cobc -x -F sha257sum.cob -o _t" "./_t kevin" "./_t -f kevin" './_t "$ANTICHEAT_INPUT"'; rm -f _t
                       else skip "cobol"   "cobc";      fi
fi
if should_run "d"; then
  if require gdc;      then compiled "d"       "gdc sha257sum.d -o _t"        "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t
                       else skip "d"       "gdc";       fi
fi
if should_run "zig"; then
  if require zig;      then compiled "zig"     "zig build-exe sha257sum.zig -femit-bin=_t -O ReleaseSafe" "./_t kevin" "./_t -f kevin" './_t "$ANTICHEAT_INPUT"'; rm -f _t
                       else skip "zig"     "zig";       fi
fi
if should_run "crystal"; then
  if require crystal;  then compiled "crystal" "crystal build sha257sum.cr -o _t" "./_t kevin" "./_t -f kevin" './_t "$ANTICHEAT_INPUT"'; rm -f _t
                       else skip "crystal" "crystal";   fi
fi
if should_run "nim"; then
  if require nim;      then compiled "nim"     "nim c -d:release --hints:off sha257sum.nim" "./sha257sum kevin" "./sha257sum -f kevin" './sha257sum "$ANTICHEAT_INPUT"'; rm -f sha257sum
                       else skip "nim"     "nim";       fi
fi
if should_run "pascal"; then
  if require fpc;      then compiled "pascal"  "fpc -O3 sha257sum.pas -o_t"   "./_t kevin"  "./_t -f kevin"  './_t "$ANTICHEAT_INPUT"'; rm -f _t sha257sum.o
                       else skip "pascal"  "fpc";       fi
fi
if should_run "x86 assembly"; then
  if [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]] && require nasm && require ld; then
    compiled "x86 assembly" "nasm -f elf64 sha257sum.asm -o _t.o && ld _t.o -o _t" "./_t kevin" "./_t -f kevin" './_t "$ANTICHEAT_INPUT"'
    rm -f _t _t.o
  else skip "x86 assembly" "nasm/ld (linux x86_64)"; fi
fi
if should_run "verilog"; then
  if require iverilog && require vvp; then
    compiled "verilog" "iverilog -o _t.vvp sha257sum.v" "vvp _t.vvp +INPUT=kevin" "vvp _t.vvp +FILE=kevin" 'vvp _t.vvp "+INPUT=$ANTICHEAT_INPUT"'
    rm -f _t.vvp
  else skip "verilog" "iverilog/vvp"; fi
fi

# jvm
if should_run "java"; then
  if javac -version &>/dev/null; then
    compiled "java"   "javac sha257sum.java"                              "java sha257sum kevin"   "java sha257sum -f kevin"   'java sha257sum "$ANTICHEAT_INPUT"'
  else skip "java" "javac"; fi
fi

if should_run "kotlin"; then
  if require kotlinc; then
    compiled "kotlin" "kotlinc sha257sum.kt -include-runtime -d _t.jar"  "java -jar _t.jar kevin" "java -jar _t.jar -f kevin" 'java -jar _t.jar "$ANTICHEAT_INPUT"'
    rm -f _t.jar
  else skip "kotlin" "kotlinc"; fi
fi

# interpreted
if should_run "go"; then
  if require go;     then interp "go"         "go run sha257sum.go kevin"               "go run sha257sum.go -f kevin"               'go run sha257sum.go "$ANTICHEAT_INPUT"'
                     else skip "go"         "go";      fi
fi
if should_run "node.js"; then
  if require node;   then interp "node.js"    "node sha257sum.js kevin"                 "node sha257sum.js -f kevin"                 'node sha257sum.js "$ANTICHEAT_INPUT"'
                     else skip "node.js"    "node";    fi
fi
if should_run "typescript"; then
  if require ts-node; then interp "typescript" "ts-node sha257sum.ts kevin"              "ts-node sha257sum.ts -f kevin"              'ts-node sha257sum.ts "$ANTICHEAT_INPUT"'
  elif require npx;   then interp "typescript" "npx --yes -p ts-node -p typescript@^5 ts-node sha257sum.ts kevin" "npx --yes -p ts-node -p typescript@^5 ts-node sha257sum.ts -f kevin" 'npx --yes -p ts-node -p typescript@^5 ts-node sha257sum.ts "$ANTICHEAT_INPUT"'
                      else skip "typescript" "ts-node or npx";  fi
fi
if should_run "coffeescript"; then
  if require coffee;  then interp "coffeescript" "coffee sha257sum.coffee kevin"         "coffee sha257sum.coffee -f kevin"           'coffee sha257sum.coffee "$ANTICHEAT_INPUT"'
                      else skip "coffeescript" "coffee"; fi
fi
if should_run "python"; then
  if require python3;then interp "python"     "python3 sha257sum.py kevin"              "python3 sha257sum.py -f kevin"              'python3 sha257sum.py "$ANTICHEAT_INPUT"'
                     else skip "python"     "python3"; fi
fi
if should_run "ruby"; then
  if require ruby;   then interp "ruby"       "ruby sha257sum.rb kevin"                 "ruby sha257sum.rb -f kevin"                 'ruby sha257sum.rb "$ANTICHEAT_INPUT"'
                     else skip "ruby"       "ruby";    fi
fi
if should_run "perl"; then
  if require perl;   then interp "perl"       "perl sha257sum.pl kevin"                 "perl sha257sum.pl -f kevin"                 'perl sha257sum.pl "$ANTICHEAT_INPUT"'
                     else skip "perl"       "perl";    fi
fi
if should_run "prolog"; then
  if require swipl;  then interp "prolog"     "swipl -q sha257sum.pro -- kevin"         "swipl -q sha257sum.pro -- -f kevin"         'swipl -q sha257sum.pro -- "$ANTICHEAT_INPUT"'
                     else skip "prolog"     "swipl";   fi
fi
if should_run "php"; then
  if require php;    then interp "php"        "php sha257sum.php kevin"                 "php sha257sum.php -f kevin"                 'php sha257sum.php "$ANTICHEAT_INPUT"'
                     else skip "php"        "php";     fi
fi
if should_run "lua"; then
  if require lua;      then interp "lua"      "lua sha257sum.lua kevin"                 "lua sha257sum.lua -f kevin"                 'lua sha257sum.lua "$ANTICHEAT_INPUT"'
  elif require lua5.4; then interp "lua"      "lua5.4 sha257sum.lua kevin"              "lua5.4 sha257sum.lua -f kevin"              'lua5.4 sha257sum.lua "$ANTICHEAT_INPUT"'
  elif require lua54;  then interp "lua"      "lua54 sha257sum.lua kevin"               "lua54 sha257sum.lua -f kevin"               'lua54 sha257sum.lua "$ANTICHEAT_INPUT"'
  elif require lua5.3; then interp "lua"      "lua5.3 sha257sum.lua kevin"              "lua5.3 sha257sum.lua -f kevin"              'lua5.3 sha257sum.lua "$ANTICHEAT_INPUT"'
  elif require lua53;  then interp "lua"      "lua53 sha257sum.lua kevin"               "lua53 sha257sum.lua -f kevin"               'lua53 sha257sum.lua "$ANTICHEAT_INPUT"'
                       else skip "lua"        "lua";     fi
fi
if should_run "julia"; then
  if require julia;  then interp "julia"      "julia sha257sum.jl kevin"                "julia sha257sum.jl -f kevin"                'julia sha257sum.jl "$ANTICHEAT_INPUT"'
                     else skip "julia"      "julia";   fi
fi
if should_run "common lisp"; then
  if require sbcl;   then interp "common lisp" "sbcl --script sha257sum.cl kevin"        "sbcl --script sha257sum.cl -f kevin"        'sbcl --script sha257sum.cl "$ANTICHEAT_INPUT"'
                     else skip "common lisp" "sbcl";    fi
fi
if should_run "elixir"; then
  if require elixir; then interp "elixir"     "elixir sha257sum.exs kevin"              "elixir sha257sum.exs -f kevin"              'elixir sha257sum.exs "$ANTICHEAT_INPUT"'
                     else skip "elixir"     "elixir";  fi
fi
if should_run "clojure"; then
  if require clojure;then interp "clojure"    "java -cp /usr/share/java/clojure.jar clojure.main sha257sum.clj kevin" "java -cp /usr/share/java/clojure.jar clojure.main sha257sum.clj -f kevin" 'java -cp /usr/share/java/clojure.jar clojure.main sha257sum.clj "$ANTICHEAT_INPUT"'
                     else skip "clojure"    "clojure"; fi
fi
if should_run "c#"; then
  if require dotnet; then
    echo '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net8.0</TargetFramework></PropertyGroup></Project>' > sha257sum.csproj
    interp "c#" "dotnet run -v q -- kevin" "dotnet run -v q -- -f kevin" 'dotnet run -v q -- "$ANTICHEAT_INPUT"'
    rm -f sha257sum.csproj
    rm -rf bin obj
  else skip "c#" "dotnet"; fi
fi
if should_run "f#"; then
  if require dotnet; then interp "f#" "DOTNET_NOLOGO=true dotnet fsi --exec sha257sum.fsx -- kevin" "DOTNET_NOLOGO=true dotnet fsi --exec sha257sum.fsx -- -f kevin" 'DOTNET_NOLOGO=true dotnet fsi --exec sha257sum.fsx -- "$ANTICHEAT_INPUT"'
                     else skip "f#" "dotnet"; fi
fi
if should_run "tcl"; then
  if require tclsh;     then interp "tcl" "tclsh sha257sum.tcl kevin"    "tclsh sha257sum.tcl -f kevin"    'tclsh sha257sum.tcl "$ANTICHEAT_INPUT"'
  elif require tclsh8.6; then interp "tcl" "tclsh8.6 sha257sum.tcl kevin" "tclsh8.6 sha257sum.tcl -f kevin" 'tclsh8.6 sha257sum.tcl "$ANTICHEAT_INPUT"'
                        else skip "tcl" "tclsh"; fi
fi
if should_run "basic"; then
  if require yabasic;   then interp "basic" "yabasic sha257sum.bas -- kevin" "yabasic sha257sum.bas -- -f kevin" 'yabasic sha257sum.bas -- "$ANTICHEAT_INPUT"'
                        else skip "basic" "yabasic"; fi
fi
if should_run "forth"; then
  if require gforth;    then interp "forth" "gforth sha257sum.fs kevin" "gforth sha257sum.fs -f kevin" 'gforth sha257sum.fs "$ANTICHEAT_INPUT"'
                        else skip "forth" "gforth"; fi
fi

# shell
if should_run "bash/awk"; then
  if require bash && require awk; then
    interp "bash/awk" "bash sha257sum.sh kevin" "bash sha257sum.sh -f kevin" 'bash sha257sum.sh "$ANTICHEAT_INPUT"'
  else skip "bash/awk" "bash or awk"; fi
fi

if should_run "sed"; then
  if require sed;  then interp "sed"        "./sha257sum.sed kevin"                       "./sha257sum.sed -f kevin"                      './sha257sum.sed "$ANTICHEAT_INPUT"'
                   else skip "sed"        "sed";     fi
fi

if should_run "ksh"; then
  if require ksh;  then interp "ksh"        "ksh sha257sum.ksh kevin"                     "ksh sha257sum.ksh -f kevin"                    'ksh sha257sum.ksh "$ANTICHEAT_INPUT"'
                   else skip "ksh"        "ksh";     fi
fi
if should_run "powershell"; then
  if require pwsh; then interp "powershell" "pwsh -File sha257sum.ps1 -InputString kevin"  "pwsh -File sha257sum.ps1 -InputString kevin -IsFile" 'pwsh -File sha257sum.ps1 -InputString "$ANTICHEAT_INPUT"'
                   else skip "powershell" "pwsh";    fi
fi

# exotic
if should_run "mumps"; then
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
fi

if should_run "matlab" || should_run "octave"; then
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
fi

echo ""
printf "results: ${GRN}%d passed${NC}  ${RED}%d failed${NC}  ${YLW}%d skipped${NC}\n" $PASS $FAIL $SKIP
rm -f kevin
[ "$FAIL" -eq 0 ]
