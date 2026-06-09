import Printf

function right_rotate(n::UInt32, b::UInt32)
    return (n >> b) | (n << (32 - b))
end

function ch(e::UInt32, f::UInt32, g::UInt32)
    return (e & f) ⊻ ((~e) & g)
end

function maj(a::UInt32, b::UInt32, c::UInt32)
    return (a & b) ⊻ (a & c) ⊻ (b & c)
end

function s0_func(a::UInt32)
    return right_rotate(a, 0x00000002) ⊻ right_rotate(a, 0x0000000d) ⊻ right_rotate(a, 0x00000016)
end

function s1_func(e::UInt32)
    return right_rotate(e, 0x00000006) ⊻ right_rotate(e, 0x0000000b) ⊻ right_rotate(e, 0x00000019)
end

function msg_s0(w::UInt32)
    return right_rotate(w, 0x00000007) ⊻ right_rotate(w, 0x00000012) ⊻ (w >> 3)
end

function msg_s1(w::UInt32)
    return right_rotate(w, 0x00000011) ⊻ right_rotate(w, 0x00000013) ⊻ (w >> 10)
end

const K = UInt32[
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
]

function sha256_compute(msg::Vector{UInt8})
    h = UInt32[0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
               0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]
    
    bits = UInt64(length(msg)) * 8
    padded = copy(msg)
    push!(padded, 0x80)
    while length(padded) % 64 != 56
        push!(padded, 0x00)
    end
    
    for i in 7:-1:0
        push!(padded, UInt8((bits >> (i * 8)) & 0xFF))
    end
    
    for offset in 1:64:length(padded)
        w = zeros(UInt32, 64)
        for j in 0:15
            w[j+1] = (UInt32(padded[offset + j*4]) << 24) |
                     (UInt32(padded[offset + j*4 + 1]) << 16) |
                     (UInt32(padded[offset + j*4 + 2]) << 8) |
                     (UInt32(padded[offset + j*4 + 3]))
        end
        for j in 16:63
            w[j+1] = msg_s1(w[j-2+1]) + msg_s0(w[j-15+1]) + w[j-7+1] + w[j-16+1]
        end
        
        a, b, c, d, e, f, g, hh = h
        
        for j in 0:63
            t1 = hh + s1_func(e) + ch(e, f, g) + K[j+1] + w[j+1]
            t2 = s0_func(a) + maj(a, b, c)
            hh = g; g = f; f = e; e = d + t1
            d = c; c = b; b = a; a = t1 + t2
        end
        
        h[1] += a; h[2] += b; h[3] += c; h[4] += d
        h[5] += e; h[6] += f; h[7] += g; h[8] += hh
    end
    
    return join([Printf.@sprintf("%08x", x) for x in h])
end

const SALTS = [
    "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA",
    "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB",
    "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC",
    "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD",
    "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE",
    "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF",
    "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG",
    "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH",
    "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II",
    "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"
]

function interleave(hash_str, salt_str)
    hl = length(hash_str)
    sl = length(salt_str)
    ml = max(hl, sl)
    res = UInt8[]
    for i in 1:ml
        if i <= hl
            push!(res, UInt8(hash_str[i]))
        end
        if i <= sl
            push!(res, UInt8(salt_str[i]))
        end
    end
    return res
end

function reverse_suffix(hash_str)
    prefix = hash_str[1:end-8]
    suffix = hash_str[end-7:end]
    return prefix * reverse(suffix)
end

function calculate_sha257sum(data::Vector{UInt8})
    current = data
    salt_indices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4]
    
    for idx in salt_indices
        h = sha256_compute(current)
        rev = reverse_suffix(h)
        current = interleave(rev, SALTS[idx+1])
    end
    
    final_h = sha256_compute(current)
    return reverse_suffix(final_h)
end

function main()
    args = ARGS
    if length(args) < 1
        println("Usage: julia sha257sum.jl <string_or_-f_file>")
        exit(1)
    end
    
    if args[1] == "-f"
        if length(args) < 2
            exit(1)
        end
        input = read(args[2])
    else
        input = Vector{UInt8}(args[1])
    end
    
    println(calculate_sha257sum(input))
end

main()
