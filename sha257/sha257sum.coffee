fs = require 'fs'

K = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
]

SALTS = [
  "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
  "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
  "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
  "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
  "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
  "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
  "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
  "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
  "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
  "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"
]

rightRotate = (n, b) -> ((n >>> b) | (n << (32 - b))) >>> 0
rightShift = (n, b) -> n >>> b
ch = (e, f, g) -> ((e & f) ^ ((~e >>> 0) & g)) >>> 0
maj = (a, b, c) -> ((a & b) ^ (a & c) ^ (b & c)) >>> 0
s0 = (a) -> (rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22)) >>> 0
s1 = (e) -> (rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25)) >>> 0
msgS0 = (w) -> (rightRotate(w, 7) ^ rightRotate(w, 18) ^ rightShift(w, 3)) >>> 0
msgS1 = (w) -> (rightRotate(w, 17) ^ rightRotate(w, 19) ^ rightShift(w, 10)) >>> 0

sha256 = (msg) ->
  h = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
  ]

  newLen = msg.length + 1
  newLen++ while newLen % 64 isnt 56
  newLen += 8

  padded = new Uint8Array newLen
  padded.set msg
  padded[msg.length] = 0x80

  bits = msg.length * 8
  bitsHigh = Math.floor(bits / 4294967296)
  for i in [0...4]
    padded[newLen - 1 - i] = (bits >>> (i * 8)) & 0xff
    padded[newLen - 5 - i] = (bitsHigh >>> (i * 8)) & 0xff

  offset = 0
  while offset < newLen
    w = new Uint32Array 64
    for i in [0...16]
      w[i] = ((padded[offset + i * 4] << 24) |
              (padded[offset + i * 4 + 1] << 16) |
              (padded[offset + i * 4 + 2] << 8) |
              padded[offset + i * 4 + 3]) >>> 0
    for i in [16...64]
      w[i] = (msgS1(w[i - 2]) + w[i - 7] + msgS0(w[i - 15]) + w[i - 16]) >>> 0

    [a, b, c, d, e, f, g, hh] = h
    for i in [0...64]
      t1 = (hh + s1(e) + ch(e, f, g) + K[i] + w[i]) >>> 0
      t2 = (s0(a) + maj(a, b, c)) >>> 0
      hh = g
      g = f
      f = e
      e = (d + t1) >>> 0
      d = c
      c = b
      b = a
      a = (t1 + t2) >>> 0

    h[0] = (h[0] + a) >>> 0
    h[1] = (h[1] + b) >>> 0
    h[2] = (h[2] + c) >>> 0
    h[3] = (h[3] + d) >>> 0
    h[4] = (h[4] + e) >>> 0
    h[5] = (h[5] + f) >>> 0
    h[6] = (h[6] + g) >>> 0
    h[7] = (h[7] + hh) >>> 0
    offset += 64

  (x.toString(16).padStart(8, '0') for x in h).join ''

reverseLast8 = (hex) ->
  hex.slice(0, 56) + hex.slice(56).split('').reverse().join('')

interleave = (a, b) ->
  maxLen = Math.max a.length, b.length
  out = new Uint8Array(a.length + b.length)
  ptr = 0
  for i in [0...maxLen]
    out[ptr++] = a[i] if i < a.length
    out[ptr++] = b[i] if i < b.length
  out

sha257sum = (data) ->
  buf = data
  for i in [0...35]
    inter = reverseLast8 sha256 buf
    hashBytes = Buffer.from inter, 'utf8'
    saltBytes = Buffer.from SALTS[i % 10], 'utf8'
    buf = interleave hashBytes, saltBytes
  reverseLast8 sha256 buf

args = process.argv.slice 2
if args.length < 1
  console.error 'Usage: coffee sha257sum.coffee [-f <file> | <string>]'
  process.exit 1

if args[0] is '-f'
  if args.length < 2
    console.error 'Missing file path'
    process.exit 1
  input = fs.readFileSync args[1]
else
  input = Buffer.from args[0], 'utf8'

console.log sha257sum input
