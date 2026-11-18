#!/usr/bin/env tclsh

set K [list \
    0x428a2f98 0x71374491 0xb5c0fbcf 0xe9b5dba5 0x3956c25b 0x59f111f1 0x923f82a4 0xab1c5ed5 \
    0xd807aa98 0x12835b01 0x243185be 0x550c7dc3 0x72be5d74 0x80deb1fe 0x9bdc06a7 0xc19bf174 \
    0xe49b69c1 0xefbe4786 0x0fc19dc6 0x240ca1cc 0x2de92c6f 0x4a7484aa 0x5cb0a9dc 0x76f988da \
    0x983e5152 0xa831c66d 0xb00327c8 0xbf597fc7 0xc6e00bf3 0xd5a79147 0x06ca6351 0x14292967 \
    0x27b70a85 0x2e1b2138 0x4d2c6dfc 0x53380d13 0x650a7354 0x766a0abb 0x81c2c92e 0x92722c85 \
    0xa2bfe8a1 0xa81a664b 0xc24b8b70 0xc76c51a3 0xd192e819 0xd6990624 0xf40e3585 0x106aa070 \
    0x19a4c116 0x1e376c08 0x2748774c 0x34b0bcb5 0x391c0cb3 0x4ed8aa4a 0x5b9cca4f 0x682e6ff3 \
    0x748f82ee 0x78a5636f 0x84c87814 0x8cc70208 0x90befffa 0xa4506ceb 0xbef9a3f7 0xc67178f2]

set SALTS [list \
    "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA" \
    "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB" \
    "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC" \
    "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD" \
    "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE" \
    "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF" \
    "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG" \
    "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH" \
    "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II" \
    "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"]

proc rotr {n b} {
    expr {(($n >> $b) | ($n << (32 - $b))) & 0xffffffff}
}

proc sha256 {byteList} {
    global K
    set h0 0x6a09e667
    set h1 0xbb67ae85
    set h2 0x3c6ef372
    set h3 0xa54ff53a
    set h4 0x510e527f
    set h5 0x9b05688c
    set h6 0x1f83d9ab
    set h7 0x5be0cd19

    set origLen [llength $byteList]
    set padded $byteList
    lappend padded 0x80
    while {([llength $padded] % 64) != 56} {
        lappend padded 0
    }
    set bitLen [expr {$origLen * 8}]
    for {set shift 56} {$shift >= 0} {incr shift -8} {
        lappend padded [expr {($bitLen >> $shift) & 0xff}]
    }

    set totalLen [llength $padded]
    for {set offset 0} {$offset < $totalLen} {incr offset 64} {
        set w [list]
        for {set i 0} {$i < 16} {incr i} {
            set base [expr {$offset + $i * 4}]
            set b0 [lindex $padded $base]
            set b1 [lindex $padded [expr {$base + 1}]]
            set b2 [lindex $padded [expr {$base + 2}]]
            set b3 [lindex $padded [expr {$base + 3}]]
            lappend w [expr {(($b0 << 24) | ($b1 << 16) | ($b2 << 8) | $b3) & 0xffffffff}]
        }
        for {set i 16} {$i < 64} {incr i} {
            set w2  [lindex $w [expr {$i - 2}]]
            set w7  [lindex $w [expr {$i - 7}]]
            set w15 [lindex $w [expr {$i - 15}]]
            set w16 [lindex $w [expr {$i - 16}]]
            set s0 [expr {[rotr $w15 7] ^ [rotr $w15 18] ^ ($w15 >> 3)}]
            set s1 [expr {[rotr $w2 17] ^ [rotr $w2 19] ^ ($w2 >> 10)}]
            lappend w [expr {($s1 + $w7 + $s0 + $w16) & 0xffffffff}]
        }

        set a $h0; set b $h1; set c $h2; set d $h3
        set e $h4; set f $h5; set g $h6; set hh $h7

        for {set i 0} {$i < 64} {incr i} {
            set S1 [expr {[rotr $e 6] ^ [rotr $e 11] ^ [rotr $e 25]}]
            set ch [expr {($e & $f) ^ ((~$e & 0xffffffff) & $g)}]
            set t1 [expr {($hh + $S1 + $ch + [lindex $K $i] + [lindex $w $i]) & 0xffffffff}]
            set S0 [expr {[rotr $a 2] ^ [rotr $a 13] ^ [rotr $a 22]}]
            set maj [expr {($a & $b) ^ ($a & $c) ^ ($b & $c)}]
            set t2 [expr {($S0 + $maj) & 0xffffffff}]

            set hh $g
            set g $f
            set f $e
            set e [expr {($d + $t1) & 0xffffffff}]
            set d $c
            set c $b
            set b $a
            set a [expr {($t1 + $t2) & 0xffffffff}]
        }

        set h0 [expr {($h0 + $a) & 0xffffffff}]
        set h1 [expr {($h1 + $b) & 0xffffffff}]
        set h2 [expr {($h2 + $c) & 0xffffffff}]
        set h3 [expr {($h3 + $d) & 0xffffffff}]
        set h4 [expr {($h4 + $e) & 0xffffffff}]
        set h5 [expr {($h5 + $f) & 0xffffffff}]
        set h6 [expr {($h6 + $g) & 0xffffffff}]
        set h7 [expr {($h7 + $hh) & 0xffffffff}]
    }

    format "%08x%08x%08x%08x%08x%08x%08x%08x" $h0 $h1 $h2 $h3 $h4 $h5 $h6 $h7
}

proc strToBytes {s} {
    set raw [encoding convertto utf-8 $s]
    set res [list]
    if {[string length $raw] > 0} {
        binary scan $raw cu* res
    }
    return $res
}

proc reverseLast8 {hex} {
    set prefix [string range $hex 0 55]
    set suffix [string reverse [string range $hex 56 63]]
    return "${prefix}${suffix}"
}

proc interleave {a b} {
    set lenA [llength $a]
    set lenB [llength $b]
    set maxLen [expr {$lenA > $lenB ? $lenA : $lenB}]
    set out [list]
    for {set i 0} {$i < $maxLen} {incr i} {
        if {$i < $lenA} { lappend out [lindex $a $i] }
        if {$i < $lenB} { lappend out [lindex $b $i] }
    }
    return $out
}

proc sha257sum {byteList} {
    global SALTS
    set buf $byteList
    for {set i 0} {$i < 35} {incr i} {
        set inter [reverseLast8 [sha256 $buf]]
        set hashBytes [strToBytes $inter]
        set saltBytes [strToBytes [lindex $SALTS [expr {$i % 10}]]]
        set buf [interleave $hashBytes $saltBytes]
    }
    return [reverseLast8 [sha256 $buf]]
}

if {$argc < 1} {
    puts stderr "Usage: tclsh sha257sum.tcl \[-f <file> | <string>\]"
    exit 1
}

if {[lindex $argv 0] eq "-f"} {
    if {$argc < 2} {
        puts stderr "Missing file path"
        exit 1
    }
    set fh [open [lindex $argv 1] r]
    fconfigure $fh -translation binary
    set raw [read $fh]
    close $fh
    set inputBytes [list]
    if {[string length $raw] > 0} {
        binary scan $raw cu* inputBytes
    }
} else {
    set inputBytes [strToBytes [lindex $argv 0]]
}

puts [sha257sum $inputBytes]
