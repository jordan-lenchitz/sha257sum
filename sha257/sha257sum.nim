import os, strutils, algorithm

proc rightRotate(n: uint32, b: uint32): uint32 =
  (n shr b) or (n shl (32 - b))

proc ch(e, f, g: uint32): uint32 =
  (e and f) xor ((not e) and g)

proc maj(a, b, c: uint32): uint32 =
  (a and b) xor (a and c) xor (b and c)

proc s0_func(a: uint32): uint32 =
  rightRotate(a, 2) xor rightRotate(a, 13) xor rightRotate(a, 22)

proc s1_func(e: uint32): uint32 =
  rightRotate(e, 6) xor rightRotate(e, 11) xor rightRotate(e, 25)

proc msg_s0(w: uint32): uint32 =
  rightRotate(w, 7) xor rightRotate(w, 18) xor (w shr 3)

proc msg_s1(w: uint32): uint32 =
  rightRotate(w, 17) xor rightRotate(w, 19) xor (w shr 10)

const K: array[64, uint32] = [
  0x428a2f98'u32, 0x71374491'u32, 0xb5c0fbcf'u32, 0xe9b5dba5'u32, 0x3956c25b'u32, 0x59f111f1'u32, 0x923f82a4'u32, 0xab1c5ed5'u32,
  0xd807aa98'u32, 0x12835b01'u32, 0x243185be'u32, 0x550c7dc3'u32, 0x72be5d74'u32, 0x80deb1fe'u32, 0x9bdc06a7'u32, 0xc19bf174'u32,
  0xe49b69c1'u32, 0xefbe4786'u32, 0x0fc19dc6'u32, 0x240ca1cc'u32, 0x2de92c6f'u32, 0x4a7484aa'u32, 0x5cb0a9dc'u32, 0x76f988da'u32,
  0x983e5152'u32, 0xa831c66d'u32, 0xb00327c8'u32, 0xbf597fc7'u32, 0xc6e00bf3'u32, 0xd5a79147'u32, 0x06ca6351'u32, 0x14292967'u32,
  0x27b70a85'u32, 0x2e1b2138'u32, 0x4d2c6dfc'u32, 0x53380d13'u32, 0x650a7354'u32, 0x766a0abb'u32, 0x81c2c92e'u32, 0x92722c85'u32,
  0xa2bfe8a1'u32, 0xa81a664b'u32, 0xc24b8b70'u32, 0xc76c51a3'u32, 0xd192e819'u32, 0xd6990624'u32, 0xf40e3585'u32, 0x106aa070'u32,
  0x19a4c116'u32, 0x1e376c08'u32, 0x2748774c'u32, 0x34b0bcb5'u32, 0x391c0cb3'u32, 0x4ed8aa4a'u32, 0x5b9cca4f'u32, 0x682e6ff3'u32,
  0x748f82ee'u32, 0x78a5636f'u32, 0x84c87814'u32, 0x8cc70208'u32, 0x90befffa'u32, 0xa4506ceb'u32, 0xbef9a3f7'u32, 0xc67178f2'u32
]

proc sha256_compute(msg: seq[byte]): string =
  var h: array[8, uint32] = [0x6a09e667'u32, 0xbb67ae85'u32, 0x3c6ef372'u32, 0xa54ff53a'u32,
                             0x510e527f'u32, 0x9b05688c'u32, 0x1f83d9ab'u32, 0x5be0cd19'u32]
  
  let bits = uint64(msg.len) * 8
  var padded = msg
  padded.add(0x80'u8)
  while padded.len mod 64 != 56: padded.add(0'u8)
  
  for i in countdown(7, 0):
    padded.add(byte((bits shr (i * 8)) and 0xFF))
    
  for offset in countup(0, padded.len - 1, 64):
    var w: array[64, uint32]
    for j in 0..15:
      w[j] = (uint32(padded[offset + j*4]) shl 24) or
             (uint32(padded[offset + j*4 + 1]) shl 16) or
             (uint32(padded[offset + j*4 + 2]) shl 8) or
             (uint32(padded[offset + j*4 + 3]))
    for j in 16..63:
      w[j] = msg_s1(w[j-2]) + w[j-7] + msg_s0(w[j-15]) + w[j-16]
      
    var a = h[0]
    var b = h[1]
    var c = h[2]
    var d = h[3]
    var e = h[4]
    var f = h[5]
    var g = h[6]
    var hh = h[7]
    
    for j in 0..63:
      let t1 = hh + s1_func(e) + ch(e, f, g) + K[j] + w[j]
      let t2 = s0_func(a) + maj(a, b, c)
      hh = g; g = f; f = e; e = d + t1
      d = c; c = b; b = a; a = t1 + t2
      
    h[0] += a; h[1] += b; h[2] += c; h[3] += d
    h[4] += e; h[5] += f; h[6] += g; h[7] += hh
    
  result = ""
  for val in h:
    result.add(toHex(int64(val), 8).toLowerAscii())

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

proc interleave(hash, salt: string): seq[byte] =
  result = @[]
  let hl = hash.len
  let sl = salt.len
  let ml = max(hl, sl)
  for i in 0..<ml:
    if i < hl: result.add(byte(hash[i]))
    if i < sl: result.add(byte(salt[i]))

proc reverseSuffix(hash: string): string =
  let prefix = hash[0..^9]
  var suffix = hash[^8..^1]
  suffix.reverse()
  result = prefix & suffix

proc calculate_sha257sum(data: seq[byte]): string =
  var current = data
  let salt_indices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4]
  
  for idx in salt_indices:
    let h = sha256_compute(current)
    let rev = reverseSuffix(h)
    current = interleave(rev, SALTS[idx])
    
  let final_h = sha256_compute(current)
  result = reverseSuffix(final_h)

proc main() =
  let args = commandLineParams()
  if args.len < 1:
    echo "Usage: ./sha257sum <string_or_-f_file>"
    quit(1)
    
  var input: seq[byte]
  if args[0] == "-f":
    if args.len < 2: quit(1)
    let content = readFile(args[1])
    input = newSeq[byte](content.len)
    for i in 0..<content.len: input[i] = byte(content[i])
  else:
    let s = args[0]
    input = newSeq[byte](s.len)
    for i in 0..<s.len: input[i] = byte(s[i])
    
  echo calculate_sha257sum(input)

main()
