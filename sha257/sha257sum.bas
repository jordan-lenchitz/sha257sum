#!/usr/bin/env yabasic

dim K(63)
K(0)  = 0x428a2f98 : K(1)  = 0x71374491 : K(2)  = 0xb5c0fbcf : K(3)  = 0xe9b5dba5
K(4)  = 0x3956c25b : K(5)  = 0x59f111f1 : K(6)  = 0x923f82a4 : K(7)  = 0xab1c5ed5
K(8)  = 0xd807aa98 : K(9)  = 0x12835b01 : K(10) = 0x243185be : K(11) = 0x550c7dc3
K(12) = 0x72be5d74 : K(13) = 0x80deb1fe : K(14) = 0x9bdc06a7 : K(15) = 0xc19bf174
K(16) = 0xe49b69c1 : K(17) = 0xefbe4786 : K(18) = 0x0fc19dc6 : K(19) = 0x240ca1cc
K(20) = 0x2de92c6f : K(21) = 0x4a7484aa : K(22) = 0x5cb0a9dc : K(23) = 0x76f988da
K(24) = 0x983e5152 : K(25) = 0xa831c66d : K(26) = 0xb00327c8 : K(27) = 0xbf597fc7
K(28) = 0xc6e00bf3 : K(29) = 0xd5a79147 : K(30) = 0x06ca6351 : K(31) = 0x14292967
K(32) = 0x27b70a85 : K(33) = 0x2e1b2138 : K(34) = 0x4d2c6dfc : K(35) = 0x53380d13
K(36) = 0x650a7354 : K(37) = 0x766a0abb : K(38) = 0x81c2c92e : K(39) = 0x92722c85
K(40) = 0xa2bfe8a1 : K(41) = 0xa81a664b : K(42) = 0xc24b8b70 : K(43) = 0xc76c51a3
K(44) = 0xd192e819 : K(45) = 0xd6990624 : K(46) = 0xf40e3585 : K(47) = 0x106aa070
K(48) = 0x19a4c116 : K(49) = 0x1e376c08 : K(50) = 0x2748774c : K(51) = 0x34b0bcb5
K(52) = 0x391c0cb3 : K(53) = 0x4ed8aa4a : K(54) = 0x5b9cca4f : K(55) = 0x682e6ff3
K(56) = 0x748f82ee : K(57) = 0x78a5636f : K(58) = 0x84c87814 : K(59) = 0x8cc70208
K(60) = 0x90befffa : K(61) = 0xa4506ceb : K(62) = 0xbef9a3f7 : K(63) = 0xc67178f2

dim SALTS$(9)
SALTS$(0) = "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
SALTS$(1) = "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
SALTS$(2) = "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
SALTS$(3) = "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
SALTS$(4) = "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
SALTS$(5) = "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
SALTS$(6) = "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
SALTS$(7) = "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
SALTS$(8) = "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
SALTS$(9) = "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"

dim POW2(32)
POW2(0) = 1
for i = 1 to 32
    POW2(i) = POW2(i - 1) * 2
next i

sub rotr(n, b)
    return int(n / POW2(b)) + mod(n, POW2(b)) * POW2(32 - b)
end sub

sub hex8$(v)
    return right$("00000000" + lower$(hex$(v)), 8)
end sub

sub reverseLast8$(h$)
    local p$, s$, r$, i
    p$ = left$(h$, 56)
    s$ = right$(h$, 8)
    r$ = ""
    for i = 8 to 1 step -1
        r$ = r$ + mid$(s$, i, 1)
    next i
    return p$ + r$
end sub

sub sha256$(buf(), bufLen)
    local h0, h1, h2, h3, h4, h5, h6, h7
    local newLen, i, offset, base, bits, bitHi, bitLo
    local a, b, c, d, e, f, g, hh
    local s0, s1, ch, maj, t1, t2, ms0, ms1, w2, w7, w15, w16
    local padded(1), w(63)

    h0 = 0x6a09e667 : h1 = 0xbb67ae85 : h2 = 0x3c6ef372 : h3 = 0xa54ff53a
    h4 = 0x510e527f : h5 = 0x9b05688c : h6 = 0x1f83d9ab : h7 = 0x5be0cd19

    newLen = bufLen + 1
    while(mod(newLen, 64) <> 56)
        newLen = newLen + 1
    wend
    newLen = newLen + 8

    dim padded(newLen - 1)
    for i = 0 to bufLen - 1
        padded(i) = buf(i)
    next i
    padded(bufLen) = 0x80
    for i = bufLen + 1 to newLen - 9
        padded(i) = 0
    next i

    bits = bufLen * 8
    bitHi = int(bits / 4294967296)
    bitLo = mod(bits, 4294967296)
    for i = 0 to 3
        padded(newLen - 1 - i) = mod(int(bitLo / POW2(i * 8)), 256)
        padded(newLen - 5 - i) = mod(int(bitHi / POW2(i * 8)), 256)
    next i

    for offset = 0 to newLen - 1 step 64
        for i = 0 to 15
            base = offset + i * 4
            w(i) = padded(base) * 16777216 + padded(base + 1) * 65536 + padded(base + 2) * 256 + padded(base + 3)
        next i
        for i = 16 to 63
            w2  = w(i - 2)
            w7  = w(i - 7)
            w15 = w(i - 15)
            w16 = w(i - 16)
            ms0 = eor(eor(rotr(w15, 7), rotr(w15, 18)), int(w15 / 8))
            ms1 = eor(eor(rotr(w2, 17), rotr(w2, 19)), int(w2 / 1024))
            w(i) = mod(ms1 + w7 + ms0 + w16, 4294967296)
        next i

        a = h0 : b = h1 : c = h2 : d = h3
        e = h4 : f = h5 : g = h6 : hh = h7

        for i = 0 to 63
            s1  = eor(eor(rotr(e, 6), rotr(e, 11)), rotr(e, 25))
            ch  = eor(and(e, f), and(4294967295 - e, g))
            t1  = mod(hh + s1 + ch + K(i) + w(i), 4294967296)
            s0  = eor(eor(rotr(a, 2), rotr(a, 13)), rotr(a, 22))
            maj = eor(eor(and(a, b), and(a, c)), and(b, c))
            t2  = mod(s0 + maj, 4294967296)

            hh = g
            g  = f
            f  = e
            e  = mod(d + t1, 4294967296)
            d  = c
            c  = b
            b  = a
            a  = mod(t1 + t2, 4294967296)
        next i

        h0 = mod(h0 + a,  4294967296)
        h1 = mod(h1 + b,  4294967296)
        h2 = mod(h2 + c,  4294967296)
        h3 = mod(h3 + d,  4294967296)
        h4 = mod(h4 + e,  4294967296)
        h5 = mod(h5 + f,  4294967296)
        h6 = mod(h6 + g,  4294967296)
        h7 = mod(h7 + hh, 4294967296)
    next offset

    return hex8$(h0) + hex8$(h1) + hex8$(h2) + hex8$(h3) + hex8$(h4) + hex8$(h5) + hex8$(h6) + hex8$(h7)
end sub

sub sha257sum$(buf(), bufLen)
    local r, inter$, salt$, lenA, lenB, maxLen, ptr, i
    local cur(1), nextBuf(1), curLen

    curLen = bufLen
    if curLen > 0 then
        dim cur(curLen - 1)
        for i = 0 to curLen - 1
            cur(i) = buf(i)
        next i
    endif

    for r = 0 to 34
        inter$ = reverseLast8$(sha256$(cur(), curLen))
        salt$  = SALTS$(mod(r, 10))
        lenA   = len(inter$)
        lenB   = len(salt$)
        maxLen = lenA
        if lenB > maxLen maxLen = lenB

        dim nextBuf(lenA + lenB - 1)
        ptr = 0
        for i = 1 to maxLen
            if i <= lenA then
                nextBuf(ptr) = asc(mid$(inter$, i, 1))
                ptr = ptr + 1
            endif
            if i <= lenB then
                nextBuf(ptr) = asc(mid$(salt$, i, 1))
                ptr = ptr + 1
            endif
        next i

        curLen = ptr
        dim cur(curLen - 1)
        for i = 0 to curLen - 1
            cur(i) = nextBuf(i)
        next i
    next r

    return reverseLast8$(sha256$(cur(), curLen))
end sub

argc = peek("arguments")
if argc < 1 then
    print "Usage: yabasic sha257sum.bas -- [-f <file> | <string>]"
    exit 1
endif

arg1$ = peek$("argument")
dim inputBuf(1)
inputLen = 0

if arg1$ = "-f" then
    if argc < 2 then
        print "Missing file path"
        exit 1
    endif
    filePath$ = peek$("argument")
    if not open(#1, filePath$, "rb") then
        print "Cannot open file: ", filePath$
        exit 1
    endif
    cap = 1024
    dim inputBuf(cap - 1)
    while(not eof(#1))
        b = peek(#1)
        if b >= 0 then
            if inputLen >= cap then
                cap = cap * 2
                dim inputBuf(cap - 1)
            endif
            inputBuf(inputLen) = b
            inputLen = inputLen + 1
        endif
    wend
    close #1
else
    inputLen = len(arg1$)
    if inputLen > 0 then
        dim inputBuf(inputLen - 1)
        for i = 1 to inputLen
            inputBuf(i - 1) = asc(mid$(arg1$, i, 1))
        next i
    endif
endif

print sha257sum$(inputBuf(), inputLen)
