#!/usr/bin/env lua5.3

local function mask(n) return n & 0xFFFFFFFF end
local function rightShift(n, b) return mask(n >> b) end
local function rightRotate(n, b) return mask(mask(n >> b) | (n << (32 - b))) end
local function ch(e, f, g) return mask((e & f) ~ ((~e) & g)) end
local function maj(a, b, c) return mask((a & b) ~ (a & c) ~ (b & c)) end
local function s0(a) return mask(rightRotate(a, 2) ~ rightRotate(a, 13) ~ rightRotate(a, 22)) end
local function s1(e) return mask(rightRotate(e, 6) ~ rightRotate(e, 11) ~ rightRotate(e, 25)) end
local function msg_s0(w) return mask(rightRotate(w, 7) ~ rightRotate(w, 18) ~ rightShift(w, 3)) end
local function msg_s1(w) return mask(rightRotate(w, 17) ~ rightRotate(w, 19) ~ rightShift(w, 10)) end

local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
}

local function sha256_custom(msgBytes)
    local h = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19}
    local msgLen = #msgBytes
    local newLen = msgLen + 1
    while newLen % 64 ~= 56 do newLen = newLen + 1 end
    newLen = newLen + 8
    
    local padded = {}
    for i=1, newLen do padded[i] = 0 end
    for i=1, msgLen do padded[i] = msgBytes[i] end
    padded[msgLen + 1] = 0x80
    
    local bits = msgLen * 8
    padded[newLen - 3] = mask(bits >> 24) & 0xFF
    padded[newLen - 2] = mask(bits >> 16) & 0xFF
    padded[newLen - 1] = mask(bits >> 8) & 0xFF
    padded[newLen] = bits & 0xFF
    
    for offset = 0, newLen - 1, 64 do
        local w = {}
        for i=0, 63 do w[i+1] = 0 end
        for i=0, 15 do
            w[i+1] = mask((padded[offset + i*4 + 1] << 24) | (padded[offset + i*4 + 2] << 16) | 
                          (padded[offset + i*4 + 3] << 8) | padded[offset + i*4 + 4])
        end
        for i=16, 63 do
            w[i+1] = mask(msg_s1(w[i-1]) + w[i-6] + msg_s0(w[i-14]) + w[i-15])
        end
        
        local a, b, c, d, e, f, g, hh = h[1], h[2], h[3], h[4], h[5], h[6], h[7], h[8]
        for i=0, 63 do
            local t1 = mask(hh + s1(e) + ch(e, f, g) + K[i+1] + w[i+1])
            local t2 = mask(s0(a) + maj(a, b, c))
            hh = g; g = f; f = e; e = mask(d + t1)
            d = c; c = b; b = a; a = mask(t1 + t2)
        end
        h[1] = mask(h[1] + a); h[2] = mask(h[2] + b); h[3] = mask(h[3] + c); h[4] = mask(h[4] + d);
        h[5] = mask(h[5] + e); h[6] = mask(h[6] + f); h[7] = mask(h[7] + g); h[8] = mask(h[8] + hh);
    end
    
    local res = ""
    for i=1, 8 do res = res .. string.format("%08x", h[i]) end
    return res
end

if #arg < 1 then os.exit() end
local str = ""
if arg[1] == "-f" then
    local f = io.open(arg[2], "rb")
    str = f:read("*all")
    f:close()
else
    str = arg[1]
end

local buf = {}
for i=1, #str do buf[i] = string.byte(str, i) end


-- BLOCK 1
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 2
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 3
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 4
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 5
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 6
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 7
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 8
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 9
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 10
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 11
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 12
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 13
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 14
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 15
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 16
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 17
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 18
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 19
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 20
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 21
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 22
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 23
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 24
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 25
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 26
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 27
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 28
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 29
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 30
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 31
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 32
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 33
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 34
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

-- BLOCK 35 yay
do
    local hex = sha256_custom(buf)
    local prefix = string.sub(hex, 1, 56)
    local suffix = string.sub(hex, 57, 64)
    local revSuffix = string.reverse(suffix)
    local intermediate = prefix .. revSuffix
    local hashBytes = {}
    for i=1, #intermediate do hashBytes[i] = string.byte(intermediate, i) end
    local saltBytes = {}
    local saltStr = "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
    for i=1, #saltStr do saltBytes[i] = string.byte(saltStr, i) end
    local maxLen = math.max(#hashBytes, #saltBytes)
    local newBuf = {}
    for k=1, maxLen do
        if k <= #hashBytes then table.insert(newBuf, hashBytes[k]) end
        if k <= #saltBytes then table.insert(newBuf, saltBytes[k]) end
    end
    buf = newBuf
end

local hex = sha256_custom(buf)
local prefix = string.sub(hex, 1, 56)
local suffix = string.sub(hex, 57, 64)
local revSuffix = string.reverse(suffix)
print(prefix .. revSuffix)

 
