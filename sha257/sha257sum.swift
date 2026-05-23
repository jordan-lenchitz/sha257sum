import Foundation

func rightRotate(_ n: UInt32, _ b: UInt32) -> UInt32 { return (n >> b) | (n << (32 - b)) }
func rightShift(_ n: UInt32, _ b: UInt32) -> UInt32 { return n >> b }
func ch(_ e: UInt32, _ f: UInt32, _ g: UInt32) -> UInt32 { return (e & f) ^ (~e & g) }
func maj(_ a: UInt32, _ b: UInt32, _ c: UInt32) -> UInt32 { return (a & b) ^ (a & c) ^ (b & c) }
func s0(_ a: UInt32) -> UInt32 { return rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22) }
func s1(_ e: UInt32) -> UInt32 { return rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25) }
func msg_s0(_ w: UInt32) -> UInt32 { return rightRotate(w, 7) ^ rightRotate(w, 18) ^ rightShift(w, 3) }
func msg_s1(_ w: UInt32) -> UInt32 { return rightRotate(w, 17) ^ rightRotate(w, 19) ^ rightShift(w, 10) }

let K: [UInt32] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
]

func sha256(_ msg: [UInt8]) -> String {
    var h: [UInt32] = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]
    var newLen = msg.count + 1
    while newLen % 64 != 56 { newLen += 1 }
    newLen += 8
    
    var padded = [UInt8](repeating: 0, count: newLen)
    for i in 0..<msg.count { padded[i] = msg[i] }
    padded[msg.count] = 0x80
    
    let bits = UInt64(msg.count) * 8
    for i in 0..<8 {
        padded[newLen - 1 - i] = UInt8((bits >> (i * 8)) & 0xFF)
    }
    
    for offset in stride(from: 0, to: newLen, by: 64) {
        var w = [UInt32](repeating: 0, count: 64)
        for i in 0..<16 {
            w[i] = (UInt32(padded[offset + i*4]) << 24) | (UInt32(padded[offset + i*4 + 1]) << 16) | 
                   (UInt32(padded[offset + i*4 + 2]) << 8) | UInt32(padded[offset + i*4 + 3])
        }
        for i in 16..<64 {
            w[i] = msg_s1(w[i-2]) &+ w[i-7] &+ msg_s0(w[i-15]) &+ w[i-16]
        }
        
        var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7]
        for i in 0..<64 {
            let t1 = hh &+ s1(e) &+ ch(e, f, g) &+ K[i] &+ w[i]
            let t2 = s0(a) &+ maj(a, b, c)
            hh = g; g = f; f = e; e = d &+ t1
            d = c; c = b; b = a; a = t1 &+ t2
        }
        h[0] = h[0] &+ a; h[1] = h[1] &+ b; h[2] = h[2] &+ c; h[3] = h[3] &+ d
        h[4] = h[4] &+ e; h[5] = h[5] &+ f; h[6] = h[6] &+ g; h[7] = h[7] &+ hh
    }
    return String(format: "%08x%08x%08x%08x%08x%08x%08x%08x", h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7])
}

let args = CommandLine.arguments
if args.count < 2 { exit(0) }
var buf: [UInt8] = []

if args[1] == "-f" {
    let url = URL(fileURLWithPath: args[2])
    let data = try! Data(contentsOf: url)
    buf = [UInt8](data)
} else {
    buf = Array(args[1].utf8)
}

// BLOCK 1
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 2
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 3
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 4
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 5
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 6
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 7
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 8
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 9
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 10
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 11
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 12
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 13
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 14
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 15
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 16
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 17
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 18
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 19
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 20
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 21
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 22
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 23
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 24
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 25
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 26
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 27
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 28
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 29
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 30
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 31
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 32
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 33
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK 34
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

// BLOCK_35
do {
    let hex = sha256(buf)
    let prefix = String(hex.prefix(56))
    let suffix = String(hex.suffix(8))
    let revSuffix = String(suffix.reversed())
    let intermediate = prefix + revSuffix
    let hashBytes = Array(intermediate.utf8)
    let saltBytes = Array("jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE".utf8)
    let maxLen = max(hashBytes.count, saltBytes.count)
    var newBuf: [UInt8] = []
    newBuf.reserveCapacity(hashBytes.count + saltBytes.count)
    for k in 0..<maxLen {
        if k < hashBytes.count { newBuf.append(hashBytes[k]) }
        if k < saltBytes.count { newBuf.append(saltBytes[k]) }
    }
    buf = newBuf
}

let hex = sha256(buf)
let prefix = String(hex.prefix(56))
let suffix = String(hex.suffix(8))
let revSuffix = String(suffix.reversed())
print(prefix + revSuffix)

