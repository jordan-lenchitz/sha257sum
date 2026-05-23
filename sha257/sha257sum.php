<?php

function rightShift($n, $b) { return ($n >> $b) & (0xFFFFFFFF >> $b); }
function rightRotate($n, $b) { return (rightShift($n, $b) | ($n << (32 - $b))) & 0xFFFFFFFF; }
function ch($e, $f, $g) { return (($e & $f) ^ (~$e & $g)) & 0xFFFFFFFF; }
function maj($a, $b, $c) { return (($a & $b) ^ ($a & $c) ^ ($b & $c)) & 0xFFFFFFFF; }
function s0($a) { return (rightRotate($a, 2) ^ rightRotate($a, 13) ^ rightRotate($a, 22)) & 0xFFFFFFFF; }
function s1($e) { return (rightRotate($e, 6) ^ rightRotate($e, 11) ^ rightRotate($e, 25)) & 0xFFFFFFFF; }
function msg_s0($w) { return (rightRotate($w, 7) ^ rightRotate($w, 18) ^ rightShift($w, 3)) & 0xFFFFFFFF; }
function msg_s1($w) { return (rightRotate($w, 17) ^ rightRotate($w, 19) ^ rightShift($w, 10)) & 0xFFFFFFFF; }

$K = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];

function sha256_custom($msgBytes) {
    global $K;
    $h = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
    $msgLen = count($msgBytes);
    $newLen = $msgLen + 1;
    while ($newLen % 64 !== 56) $newLen++;
    $newLen += 8;
    
    $padded = array_fill(0, $newLen, 0);
    for ($i = 0; $i < $msgLen; $i++) $padded[$i] = $msgBytes[$i];
    $padded[$msgLen] = 0x80;
    
    $bits = $msgLen * 8;
    $padded[$newLen - 4] = ($bits >> 24) & 0xFF;
    $padded[$newLen - 3] = ($bits >> 16) & 0xFF;
    $padded[$newLen - 2] = ($bits >> 8) & 0xFF;
    $padded[$newLen - 1] = $bits & 0xFF;
    
    for ($offset = 0; $offset < $newLen; $offset += 64) {
        $w = array_fill(0, 64, 0);
        for ($i = 0; $i < 16; $i++) {
            $w[$i] = (($padded[$offset + $i*4] << 24) | ($padded[$offset + $i*4 + 1] << 16) | 
                     ($padded[$offset + $i*4 + 2] << 8) | $padded[$offset + $i*4 + 3]) & 0xFFFFFFFF;
        }
        for ($i = 16; $i < 64; $i++) {
            $w[$i] = (msg_s1($w[$i-2]) + $w[$i-7] + msg_s0($w[$i-15]) + $w[$i-16]) & 0xFFFFFFFF;
        }
        
        list($a, $b, $c, $d, $e, $f, $g, $hh) = $h;
        for ($i = 0; $i < 64; $i++) {
            $t1 = ($hh + s1($e) + ch($e, $f, $g) + $K[$i] + $w[$i]) & 0xFFFFFFFF;
            $t2 = (s0($a) + maj($a, $b, $c)) & 0xFFFFFFFF;
            $hh = $g; $g = $f; $f = $e; $e = ($d + $t1) & 0xFFFFFFFF;
            $d = $c; $c = $b; $b = $a; $a = ($t1 + $t2) & 0xFFFFFFFF;
        }
        $h[0] = ($h[0] + $a) & 0xFFFFFFFF; $h[1] = ($h[1] + $b) & 0xFFFFFFFF;
        $h[2] = ($h[2] + $c) & 0xFFFFFFFF; $h[3] = ($h[3] + $d) & 0xFFFFFFFF;
        $h[4] = ($h[4] + $e) & 0xFFFFFFFF; $h[5] = ($h[5] + $f) & 0xFFFFFFFF;
        $h[6] = ($h[6] + $g) & 0xFFFFFFFF; $h[7] = ($h[7] + $hh) & 0xFFFFFFFF;
    }
    $res = "";
    for ($i = 0; $i < 8; $i++) $res .= sprintf("%08x", $h[$i]);
    return $res;
}

if ($argc < 2) exit(0);
if ($argv[1] === "-f") {
    $str = file_get_contents($argv[2]);
} else {
    $str = $argv[1];
}

$buf = array_values(unpack('C*', $str));


// BLOCK 1
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 2
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 3
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 4
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 5
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 6
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 7
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 8
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 9
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 10
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 11
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 12
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 13
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 14
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 15
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 16
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 17
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 18
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 19
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 20
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 21
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 22
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 23
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 24
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 25
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 26
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 27
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 28
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 29
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 30
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 31
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 32
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 33
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// BLOCK 34
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

// block 35
$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
$intermediate = $prefix . $revSuffix;
$hashBytes = array_values(unpack('C*', $intermediate));
$saltBytes = array_values(unpack('C*', "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"));
$maxLen = max(count($hashBytes), count($saltBytes));
$newBuf = [];
for ($k = 0; $k < $maxLen; $k++) {
    if ($k < count($hashBytes)) $newBuf[] = $hashBytes[$k];
    if ($k < count($saltBytes)) $newBuf[] = $saltBytes[$k];
}
$buf = $newBuf;

$hex = sha256_custom($buf);
$prefix = substr($hex, 0, 56);
$suffix = substr($hex, 56);
$revSuffix = strrev($suffix);
echo $prefix . $revSuffix . "\n";

