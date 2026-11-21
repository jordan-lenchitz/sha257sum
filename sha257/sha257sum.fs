#! /usr/bin/env gforth

$ffffffff constant mask32

: u32   ( u -- u32 )      mask32 and ;
: u32+  ( a b -- c )      + u32 ;
: rotr32 ( x n -- y )     2dup rshift >r 32 swap - lshift u32 r> or ;

: big-s0 ( a -- u )       dup 2 rotr32 over 13 rotr32 xor swap 22 rotr32 xor ;
: big-s1 ( e -- u )       dup 6 rotr32 over 11 rotr32 xor swap 25 rotr32 xor ;
: msg-s0 ( w -- u )       dup 7 rotr32 over 18 rotr32 xor swap 3 rshift xor ;
: msg-s1 ( w -- u )       dup 17 rotr32 over 19 rotr32 xor swap 10 rshift xor ;

: sha-ch  ( e f g -- u )  >r over and swap invert u32 r> and xor ;
: sha-maj ( a b c -- u )  >r 2dup and >r or r> swap r> and or ;

create sha-h0
  $6a09e667 , $bb67ae85 , $3c6ef372 , $a54ff53a ,
  $510e527f , $9b05688c , $1f83d9ab , $5be0cd19 ,

create sha-k
  $428a2f98 , $71374491 , $b5c0fbcf , $e9b5dba5 ,
  $3956c25b , $59f111f1 , $923f82a4 , $ab1c5ed5 ,
  $d807aa98 , $12835b01 , $243185be , $550c7dc3 ,
  $72be5d74 , $80deb1fe , $9bdc06a7 , $c19bf174 ,
  $e49b69c1 , $efbe4786 , $0fc19dc6 , $240ca1cc ,
  $2de92c6f , $4a7484aa , $5cb0a9dc , $76f988da ,
  $983e5152 , $a831c66d , $b00327c8 , $bf597fc7 ,
  $c6e00bf3 , $d5a79147 , $06ca6351 , $14292967 ,
  $27b70a85 , $2e1b2138 , $4d2c6dfc , $53380d13 ,
  $650a7354 , $766a0abb , $81c2c92e , $92722c85 ,
  $a2bfe8a1 , $a81a664b , $c24b8b70 , $c76c51a3 ,
  $d192e819 , $d6990624 , $f40e3585 , $106aa070 ,
  $19a4c116 , $1e376c08 , $2748774c , $34b0bcb5 ,
  $391c0cb3 , $4ed8aa4a , $5b9cca4f , $682e6ff3 ,
  $748f82ee , $78a5636f , $84c87814 , $8cc70208 ,
  $90befffa , $a4506ceb , $bef9a3f7 , $c67178f2 ,

create sha-h    8 cells allot
create sha-w    64 cells allot
create sha-blk  64 allot

variable sha-blen
variable sha-total
variable sha-bits

variable va  variable vb  variable vc  variable vd
variable ve  variable vf  variable vg  variable vh
variable vt1 variable vt2

: sha-h@ ( i -- u )  cells sha-h + @ ;
: sha-h! ( u i -- )  cells sha-h + ! ;
: sha-w@ ( i -- u )  cells sha-w + @ ;
: sha-w! ( u i -- )  cells sha-w + ! ;
: sha-k@ ( i -- u )  cells sha-k + @ ;

: blk-be32@ ( i -- u )
  4 * sha-blk +
  dup c@ 24 lshift
  over 1 + c@ 16 lshift or
  over 2 + c@ 8 lshift or
  swap 3 + c@ or ;

: sha256-compress ( -- )
  16 0 do
    i blk-be32@ i sha-w!
  loop
  64 16 do
    i 2 - sha-w@ msg-s1
    i 7 - sha-w@ u32+
    i 15 - sha-w@ msg-s0 u32+
    i 16 - sha-w@ u32+
    i sha-w!
  loop

  0 sha-h@ va !  1 sha-h@ vb !  2 sha-h@ vc !  3 sha-h@ vd !
  4 sha-h@ ve !  5 sha-h@ vf !  6 sha-h@ vg !  7 sha-h@ vh !

  64 0 do
    vh @
    ve @ big-s1 u32+
    ve @ vf @ vg @ sha-ch u32+
    i sha-k@ u32+
    i sha-w@ u32+
    vt1 !

    va @ big-s0
    va @ vb @ vc @ sha-maj u32+
    vt2 !

    vg @ vh !
    vf @ vg !
    ve @ vf !
    vd @ vt1 @ u32+ ve !
    vc @ vd !
    vb @ vc !
    va @ vb !
    vt1 @ vt2 @ u32+ va !
  loop

  0 sha-h@ va @ u32+ 0 sha-h!
  1 sha-h@ vb @ u32+ 1 sha-h!
  2 sha-h@ vc @ u32+ 2 sha-h!
  3 sha-h@ vd @ u32+ 3 sha-h!
  4 sha-h@ ve @ u32+ 4 sha-h!
  5 sha-h@ vf @ u32+ 5 sha-h!
  6 sha-h@ vg @ u32+ 6 sha-h!
  7 sha-h@ vh @ u32+ 7 sha-h! ;

: sha256-init ( -- )
  8 0 do
    sha-h0 i cells + @ i sha-h!
  loop
  0 sha-blen !
  0 sha-total ! ;

: sha256-byte ( c -- )
  sha-blk sha-blen @ + c!
  1 sha-blen +!
  1 sha-total +!
  sha-blen @ 64 = if
    sha256-compress
    0 sha-blen !
  then ;

: sha256-update ( addr len -- )
  bounds ?do
    i c@ sha256-byte
  loop ;

create hex-buf 64 allot

: nibble>hex ( n -- c )
  dup 10 < if [char] 0 + else 10 - [char] a + then ;

: sha256-final ( -- )
  sha-total @ 3 lshift sha-bits !
  $80 sha-blk sha-blen @ + c!
  1 sha-blen +!

  sha-blen @ 56 > if
    sha-blk sha-blen @ + 64 sha-blen @ - erase
    sha256-compress
    0 sha-blen !
  then

  sha-blk sha-blen @ + 56 sha-blen @ - erase

  8 0 do
    sha-bits @ 7 i - 8 * rshift $ff and
    sha-blk 56 + i + c!
  loop

  sha256-compress

  8 0 do
    i sha-h@
    8 0 do
      dup 7 i - 4 * rshift $f and nibble>hex
      hex-buf j 8 * i + + c!
    loop
    drop
  loop ;

: get-salt ( idx -- addr len )
  case
    0 of s" jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA" endof
    1 of s" jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB" endof
    2 of s" jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC" endof
    3 of s" jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD" endof
    4 of s" jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE" endof
    5 of s" jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF" endof
    6 of s" jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG" endof
    7 of s" jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH" endof
    8 of s" jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II" endof
    9 of s" jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ" endof
  endcase ;

: reverse-suffix ( -- )
  4 0 do
    hex-buf 56 + i + c@
    hex-buf 63 + i - c@
    hex-buf 56 + i + c!
    hex-buf 63 + i - c!
  loop ;

create inter-buf 256 allot
variable inter-len
variable cur-saddr
variable cur-slen

: inter-emit ( c -- )
  inter-buf inter-len @ + c!
  1 inter-len +! ;

: interleave-salt ( addr len -- )
  cur-slen !
  cur-saddr !
  0 inter-len !
  64 cur-slen @ max 0 do
    i 64 < if
      hex-buf i + c@ inter-emit
    then
    i cur-slen @ < if
      cur-saddr @ i + c@ inter-emit
    then
  loop ;

: run-sha257-rounds ( -- )
  35 0 do
    reverse-suffix
    i 10 mod get-salt interleave-salt
    sha256-init
    inter-buf inter-len @ sha256-update
    sha256-final
  loop
  reverse-suffix ;

create io-buf 4096 allot
variable cur-fd

: hash-file ( addr len -- )
  r/o bin open-file if
    drop s" Error: could not open file" stderr write-line drop
    1 (bye)
  then
  cur-fd !
  sha256-init
  begin
    io-buf 4096 cur-fd @ read-file throw
    dup 0>
  while
    io-buf swap sha256-update
  repeat
  drop
  cur-fd @ close-file throw
  sha256-final ;

: usage-exit ( -- )
  s" Usage: gforth sha257sum.fs <string> | -f <file>" stderr write-line drop
  1 (bye) ;

: main ( -- )
  argc @ 2 < if usage-exit then
  1 arg s" -f" compare 0= if
    argc @ 3 < if usage-exit then
    2 arg hash-file
  else
    sha256-init
    1 arg sha256-update
    sha256-final
  then
  run-sha257-rounds
  hex-buf 64 type cr
  bye ;

main
