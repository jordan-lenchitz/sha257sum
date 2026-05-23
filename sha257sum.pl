#!/usr/bin/env perl
use strict;
use warnings;
use integer; # Enforce integer math where possible

# Use standard 32-bit masking
sub mask { $_[0] & 0xFFFFFFFF }

sub right_rotate {
    my ($n, $b) = @_;
    return mask(mask($n >> $b) | ($n << (32 - $b)));
}

sub right_shift {
    my ($n, $b) = @_;
    return mask($n >> $b);
}

sub ch {
    my ($e, $f, $g) = @_;
    return mask(($e & $f) ^ (~$e & $g));
}

sub maj {
    my ($a, $b, $c) = @_;
    return mask(($a & $b) ^ ($a & $c) ^ ($b & $c));
}

sub s0 {
    my $a = shift;
    return mask(right_rotate($a, 2) ^ right_rotate($a, 13) ^ right_rotate($a, 22));
}

sub s1 {
    my $e = shift;
    return mask(right_rotate($e, 6) ^ right_rotate($e, 11) ^ right_rotate($e, 25));
}

sub msg_s0 {
    my $w = shift;
    return mask(right_rotate($w, 7) ^ right_rotate($w, 18) ^ right_shift($w, 3));
}

sub msg_s1 {
    my $w = shift;
    return mask(right_rotate($w, 17) ^ right_rotate($w, 19) ^ right_shift($w, 10));
}

my @K = (
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
);

sub sha256 {
    my $msg = shift;
    my @h = (0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19);
    
    my @msg_bytes = unpack("C*", $msg);
    my $msg_len = scalar(@msg_bytes);
    my $new_len = $msg_len + 1;
    while ($new_len % 64 != 56) { $new_len++; }
    $new_len += 8;
    
    my @padded = @msg_bytes;
    push @padded, 0x80;
    while (scalar(@padded) < $new_len - 8) { push @padded, 0; }
    
    my $bits = $msg_len * 8;
    my $bits_high = 0; # Simple string lengths won't overflow 32-bit bits here
    push @padded, (($bits_high >> 24) & 0xFF), (($bits_high >> 16) & 0xFF), (($bits_high >> 8) & 0xFF), ($bits_high & 0xFF);
    push @padded, (($bits >> 24) & 0xFF), (($bits >> 16) & 0xFF), (($bits >> 8) & 0xFF), ($bits & 0xFF);
    
    for (my $offset = 0; $offset < $new_len; $offset += 64) {
        my @w;
        for (my $i = 0; $i < 16; $i++) {
            $w[$i] = ($padded[$offset + $i*4] << 24) | ($padded[$offset + $i*4 + 1] << 16) | ($padded[$offset + $i*4 + 2] << 8) | $padded[$offset + $i*4 + 3];
            $w[$i] = mask($w[$i]);
        }
        for (my $i = 16; $i < 64; $i++) {
            $w[$i] = mask(msg_s1($w[$i-2]) + $w[$i-7] + msg_s0($w[$i-15]) + $w[$i-16]);
        }
        
        my ($a, $b, $c, $d, $e, $f, $g, $hh) = @h;
        for (my $i = 0; $i < 64; $i++) {
            my $t1 = mask($hh + s1($e) + ch($e, $f, $g) + $K[$i] + $w[$i]);
            my $t2 = mask(s0($a) + maj($a, $b, $c));
            $hh = $g; $g = $f; $f = $e; $e = mask($d + $t1);
            $d = $c; $c = $b; $b = $a; $a = mask($t1 + $t2);
        }
        $h[0] = mask($h[0] + $a); $h[1] = mask($h[1] + $b); $h[2] = mask($h[2] + $c); $h[3] = mask($h[3] + $d);
        $h[4] = mask($h[4] + $e); $h[5] = mask($h[5] + $f); $h[6] = mask($h[6] + $g); $h[7] = mask($h[7] + $hh);
    }
    return sprintf("%08x%08x%08x%08x%08x%08x%08x%08x", @h);
}

my $buf;
if (!defined $ARGV[0]) {
    exit;
}
if ($ARGV[0] eq "-f") {
    open my $fh, '<:raw', $ARGV[1] or die "Cannot open file: $!";
    local $/ = undef;
    $buf = <$fh>;
    close $fh;
} else {
    $buf = $ARGV[0];
}

# START OF SUPER STUPID PROCESSING BLOCK 1
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 2
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 3
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 4
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 5
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 6
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 7
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 8
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 9
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 10
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 11
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 12
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 13
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 14
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 15
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 16
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 17
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 18
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 19
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 20
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 21
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 22
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 23
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 24
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 25
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 26
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 27
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 28
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 29
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 30
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 31
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 32
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 33
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 34
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

# START OF SUPER STUPID PROCESSING BLOCK 35
{
    my $hex = sha256($buf);
    my $prefix = substr($hex, 0, 56);
    my $suffix = substr($hex, 56);
    my $rev_suffix = reverse($suffix);
    my $intermediate = $prefix . $rev_suffix;
    my @hash_bytes = unpack("C*", $intermediate);
    my @salt_bytes = unpack("C*", "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE");
    my $max_len = scalar(@hash_bytes) > scalar(@salt_bytes) ? scalar(@hash_bytes) : scalar(@salt_bytes);
    my @new_buf;
    for (my $k = 0; $k < $max_len; $k++) {
        push @new_buf, $hash_bytes[$k] if $k < scalar(@hash_bytes);
        push @new_buf, $salt_bytes[$k] if $k < scalar(@salt_bytes);
    }
    $buf = pack("C*", @new_buf);
}

my $hex = sha256($buf);
my $prefix = substr($hex, 0, 56);
my $suffix = substr($hex, 56);
my $rev_suffix = reverse($suffix);
print $prefix . $rev_suffix . "\n";

