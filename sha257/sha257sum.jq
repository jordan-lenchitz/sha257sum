def pow2:
  [1, 2, 4, 8, 16, 32, 64, 128,
   256, 512, 1024, 2048, 4096, 8192, 16384, 32768,
   65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608,
   16777216, 33554432, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648,
   4294967296];

def and4:
  [[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
   [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1],
   [0,0,2,2,0,0,2,2,0,0,2,2,0,0,2,2],
   [0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3],
   [0,0,0,0,4,4,4,4,0,0,0,0,4,4,4,4],
   [0,1,0,1,4,5,4,5,0,1,0,1,4,5,4,5],
   [0,0,2,2,4,4,6,6,0,0,2,2,4,4,6,6],
   [0,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7],
   [0,0,0,0,0,0,0,0,8,8,8,8,8,8,8,8],
   [0,1,0,1,0,1,0,1,8,9,8,9,8,9,8,9],
   [0,0,2,2,0,0,2,2,8,8,10,10,8,8,10,10],
   [0,1,2,3,0,1,2,3,8,9,10,11,8,9,10,11],
   [0,0,0,0,4,4,4,4,8,8,8,8,12,12,12,12],
   [0,1,0,1,4,5,4,5,8,9,8,9,12,13,12,13],
   [0,0,2,2,4,4,6,6,8,8,10,10,12,12,14,14],
   [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]];

def xor4:
  [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],
   [1,0,3,2,5,4,7,6,9,8,11,10,13,12,15,14],
   [2,3,0,1,6,7,4,5,10,11,8,9,14,15,12,13],
   [3,2,1,0,7,6,5,4,11,10,9,8,15,14,13,12],
   [4,5,6,7,0,1,2,3,12,13,14,15,8,9,10,11],
   [5,4,7,6,1,0,3,2,13,12,15,14,9,8,11,10],
   [6,7,4,5,2,3,0,1,14,15,12,13,10,11,8,9],
   [7,6,5,4,3,2,1,0,15,14,13,12,11,10,9,8],
   [8,9,10,11,12,13,14,15,0,1,2,3,4,5,6,7],
   [9,8,11,10,13,12,15,14,1,0,3,2,5,4,7,6],
   [10,11,8,9,14,15,12,13,2,3,0,1,6,7,4,5],
   [11,10,9,8,15,14,13,12,3,2,1,0,7,6,5,4],
   [12,13,14,15,8,9,10,11,4,5,6,7,0,1,2,3],
   [13,12,15,14,9,8,11,10,5,4,7,6,1,0,3,2],
   [14,15,12,13,10,11,8,9,6,7,4,5,2,3,0,1],
   [15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0]];

def k_table:
  [1116352408, 1899447441, 3049323471, 3921009573,
   961987163,  1508970993, 2453635748, 2870763221,
   3624381080, 310598401,  607225278,  1426881987,
   1925078388, 2162078206, 2614888103, 3248222580,
   3835390401, 4022224774, 264347078,  604807628,
   770255983,  1249150122, 1555081692, 1996064986,
   2554220882, 2821834349, 2952996808, 3210313671,
   3336571891, 3584528711, 113926993,  338241895,
   666307205,  773529912,  1294757372, 1396182291,
   1695183700, 1986661051, 2177026350, 2456956037,
   2730485921, 2820302411, 3259730800, 3345764771,
   3516065817, 3600352804, 4094571909, 275423344,
   430227734,  506948616,  659060556,  883997877,
   958139571,  1322822218, 1537002063, 1747873779,
   1955562222, 2024104815, 2227730452, 2361852424,
   2428436474, 2756734187, 3204031479, 3329325298];

def salts:
  ["jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA",
   "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB",
   "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC",
   "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD",
   "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE",
   "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF",
   "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG",
   "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH",
   "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II",
   "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"];

def hex_digits: "0123456789abcdef" | split("");

def band($t; $a; $b):
  $t[$a % 16][$b % 16]
  + 16 * $t[($a / 16 | floor) % 16][($b / 16 | floor) % 16]
  + 256 * $t[($a / 256 | floor) % 16][($b / 256 | floor) % 16]
  + 4096 * $t[($a / 4096 | floor) % 16][($b / 4096 | floor) % 16]
  + 65536 * $t[($a / 65536 | floor) % 16][($b / 65536 | floor) % 16]
  + 1048576 * $t[($a / 1048576 | floor) % 16][($b / 1048576 | floor) % 16]
  + 16777216 * $t[($a / 16777216 | floor) % 16][($b / 16777216 | floor) % 16]
  + 268435456 * $t[($a / 268435456 | floor) % 16][($b / 268435456 | floor) % 16];

def bxor($t; $a; $b):
  $t[$a % 16][$b % 16]
  + 16 * $t[($a / 16 | floor) % 16][($b / 16 | floor) % 16]
  + 256 * $t[($a / 256 | floor) % 16][($b / 256 | floor) % 16]
  + 4096 * $t[($a / 4096 | floor) % 16][($b / 4096 | floor) % 16]
  + 65536 * $t[($a / 65536 | floor) % 16][($b / 65536 | floor) % 16]
  + 1048576 * $t[($a / 1048576 | floor) % 16][($b / 1048576 | floor) % 16]
  + 16777216 * $t[($a / 16777216 | floor) % 16][($b / 16777216 | floor) % 16]
  + 268435456 * $t[($a / 268435456 | floor) % 16][($b / 268435456 | floor) % 16];

def rotr($p2; $x; $n):
  (($x / $p2[$n]) | floor) + (($x % $p2[$n]) * $p2[32 - $n]);

def to_utf8:
  [explode[] |
    if . < 128 then .
    elif . < 2048 then (192 + (. / 64 | floor)), (128 + (. % 64))
    elif . < 65536 then (224 + (. / 4096 | floor)), (128 + ((. / 64 | floor) % 64)), (128 + (. % 64))
    else (240 + (. / 262144 | floor)), (128 + ((. / 4096 | floor) % 64)), (128 + ((. / 64 | floor) % 64)), (128 + (. % 64))
    end];

def word_hex($hd):
  . as $w |
  $hd[($w / 268435456 | floor) % 16] +
  $hd[($w / 16777216 | floor) % 16] +
  $hd[($w / 1048576 | floor) % 16] +
  $hd[($w / 65536 | floor) % 16] +
  $hd[($w / 4096 | floor) % 16] +
  $hd[($w / 256 | floor) % 16] +
  $hd[($w / 16 | floor) % 16] +
  $hd[$w % 16];

def sha256($p2; $a4; $x4; $kt; $hd):
  . as $bytes |
  ($bytes | length) as $len |
  (($len + 9) % 64) as $rem |
  (if $rem == 0 then 0 else 64 - $rem end) as $zeros |
  ($len * 8) as $bits |
  ($bytes + [128] + [range($zeros) | 0] + [
    ($bits / 72057594037927936 | floor) % 256,
    ($bits / 281474976710656 | floor) % 256,
    ($bits / 1099511627776 | floor) % 256,
    ($bits / 4294967296 | floor) % 256,
    ($bits / 16777216 | floor) % 256,
    ($bits / 65536 | floor) % 256,
    ($bits / 256 | floor) % 256,
    $bits % 256
  ]) as $padded |
  (($padded | length) / 64) as $nblk |
  (reduce range($nblk) as $blk (
    [1779033703, 3144134277, 1013904242, 2773480762,
     1359893119, 2600822924, 528734635,  1541459225];
    ($blk * 64) as $off |
    ([range(16) as $i |
      $padded[$off + $i * 4] * 16777216
      + $padded[$off + $i * 4 + 1] * 65536
      + $padded[$off + $i * 4 + 2] * 256
      + $padded[$off + $i * 4 + 3]
    ]) as $w0 |
    (reduce range(16; 64) as $i ($w0;
      .[$i - 15] as $v15 |
      .[$i - 2] as $v2 |
      bxor($x4; bxor($x4; rotr($p2; $v15; 7); rotr($p2; $v15; 18)); ($v15 / 8 | floor)) as $s0 |
      bxor($x4; bxor($x4; rotr($p2; $v2; 17); rotr($p2; $v2; 19)); ($v2 / 1024 | floor)) as $s1 |
      . + [(.[$i - 16] + $s0 + .[$i - 7] + $s1) % 4294967296]
    )) as $w |
    . as $h |
    (reduce range(64) as $i ($h;
      .[0] as $a | .[1] as $b | .[2] as $c | .[3] as $d |
      .[4] as $e | .[5] as $f | .[6] as $g | .[7] as $hh |
      bxor($x4; bxor($x4; rotr($p2; $e; 6); rotr($p2; $e; 11)); rotr($p2; $e; 25)) as $S1 |
      (band($a4; $e; $f) + band($a4; 4294967295 - $e; $g)) as $ch |
      (($hh + $S1 + $ch + $kt[$i] + $w[$i]) % 4294967296) as $t1 |
      bxor($x4; bxor($x4; rotr($p2; $a; 2); rotr($p2; $a; 13)); rotr($p2; $a; 22)) as $S0 |
      (band($a4; $a; $b) + band($a4; bxor($x4; $a; $b); $c)) as $maj |
      (($S0 + $maj) % 4294967296) as $t2 |
      [($t1 + $t2) % 4294967296, $a, $b, $c, ($d + $t1) % 4294967296, $e, $f, $g]
    )) as $st |
    [range(8) as $j | ($h[$j] + $st[$j]) % 4294967296]
  )) |
  map(word_hex($hd)) | add;

def reverse_suffix:
  .[0:56] + (.[56:64] | split("") | reverse | add);

def interleave_bytes($a; $b):
  ($a | length) as $la |
  ($b | length) as $lb |
  (if $la > $lb then $la else $lb end) as $m |
  [range($m) as $i |
    (if $i < $la then $a[$i] else empty end),
    (if $i < $lb then $b[$i] else empty end)];

pow2 as $p2 |
and4 as $a4 |
xor4 as $x4 |
k_table as $kt |
hex_digits as $hd |
(salts | map(explode)) as $salt_bytes |
($input | to_utf8) |
(reduce range(35) as $r (.;
  (sha256($p2; $a4; $x4; $kt; $hd) | reverse_suffix | explode) as $rev |
  interleave_bytes($rev; $salt_bytes[$r % 10])
)) |
sha256($p2; $a4; $x4; $kt; $hd) |
reverse_suffix
