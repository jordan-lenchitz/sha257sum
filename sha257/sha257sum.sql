WITH RECURSIVE
k_table(idx, val) AS (
  VALUES
    (0, 1116352408), (1, 1899447441), (2, 3049323471), (3, 3921009573),
    (4, 961987163),  (5, 1508970993), (6, 2453635748), (7, 2870763221),
    (8, 3624381080), (9, 310598401),  (10, 607225278), (11, 1426881987),
    (12, 1925078388),(13, 2162078206),(14, 2614888103),(15, 3248222580),
    (16, 3835390401),(17, 4022224774),(18, 264347078), (19, 604807628),
    (20, 770255983), (21, 1249150122),(22, 1555081692),(23, 1996064986),
    (24, 2554220882),(25, 2821834349),(26, 2952996808),(27, 3210313671),
    (28, 3336571891),(29, 3584528711),(30, 113926993), (31, 338241895),
    (32, 666307205), (33, 773529912), (34, 1294757372),(35, 1396182291),
    (36, 1695183700),(37, 1986661051),(38, 2177026350),(39, 2456956037),
    (40, 2730485921),(41, 2820302411),(42, 3259730800),(43, 3345764771),
    (44, 3516065817),(45, 3600352804),(46, 4094571909),(47, 275423344),
    (48, 430227734), (49, 506948616), (50, 659060556), (51, 883997877),
    (52, 958139571), (53, 1322822218),(54, 1537002063),(55, 1747873779),
    (56, 1955562222),(57, 2024104815),(58, 2227730452),(59, 2361852424),
    (60, 2428436474),(61, 2756734187),(62, 3204031479),(63, 3329325298)
),
salts(idx, s) AS (
  VALUES
    (0, 'jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA'),
    (1, 'jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB'),
    (2, 'jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC'),
    (3, 'jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD'),
    (4, 'jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE'),
    (5, 'jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF'),
    (6, 'jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG'),
    (7, 'jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH'),
    (8, 'jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II'),
    (9, 'jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ')
),
init_input(hex_msg) AS (
  SELECT CASE
    WHEN :mode = 'file' THEN hex(readfile(:arg))
    ELSE hex(CAST(:arg AS BLOB))
  END
),
st(
  phase, r, msg, padded, blk, nblk, i, wbuf,
  h0, h1, h2, h3, h4, h5, h6, h7,
  a, b, c, d, e, f, g, hh,
  rev, acc
) AS (
  SELECT
    'pad', 0, hex_msg, '', 0, 0, 0, '',
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    '', ''
  FROM init_input

  UNION ALL

  SELECT
    'wload', st.r, '',
    st.msg || '80' ||
      hex(zeroblob(CASE WHEN ((length(st.msg) / 2 + 9) % 64) = 0 THEN 0 ELSE 64 - ((length(st.msg) / 2 + 9) % 64) END)) ||
      printf('%016X', (length(st.msg) / 2) * 8),
    0,
    (length(st.msg) / 2 + 9 + CASE WHEN ((length(st.msg) / 2 + 9) % 64) = 0 THEN 0 ELSE 64 - ((length(st.msg) / 2 + 9) % 64) END) / 64,
    0, '',
    1779033703, 3144134277, 1013904242, 2773480762,
    1359893119, 2600822924, 528734635,  1541459225,
    0, 0, 0, 0, 0, 0, 0, 0,
    '', ''
  FROM st
  WHERE st.phase = 'pad'

  UNION ALL

  SELECT
    CASE WHEN st.i = 15 THEN 'wexp' ELSE 'wload' END,
    st.r, '', st.padded, st.blk, st.nblk, st.i + 1,
    st.wbuf || printf('%010d',
      ((instr('0123456789ABCDEF', substr(st.padded, st.blk * 128 + st.i * 8 + 1, 1)) - 1) << 28) |
      ((instr('0123456789ABCDEF', substr(st.padded, st.blk * 128 + st.i * 8 + 2, 1)) - 1) << 24) |
      ((instr('0123456789ABCDEF', substr(st.padded, st.blk * 128 + st.i * 8 + 3, 1)) - 1) << 20) |
      ((instr('0123456789ABCDEF', substr(st.padded, st.blk * 128 + st.i * 8 + 4, 1)) - 1) << 16) |
      ((instr('0123456789ABCDEF', substr(st.padded, st.blk * 128 + st.i * 8 + 5, 1)) - 1) << 12) |
      ((instr('0123456789ABCDEF', substr(st.padded, st.blk * 128 + st.i * 8 + 6, 1)) - 1) << 8)  |
      ((instr('0123456789ABCDEF', substr(st.padded, st.blk * 128 + st.i * 8 + 7, 1)) - 1) << 4)  |
       (instr('0123456789ABCDEF', substr(st.padded, st.blk * 128 + st.i * 8 + 8, 1)) - 1)
    ),
    st.h0, st.h1, st.h2, st.h3, st.h4, st.h5, st.h6, st.h7,
    st.h0, st.h1, st.h2, st.h3, st.h4, st.h5, st.h6, st.h7,
    '', ''
  FROM st
  WHERE st.phase = 'wload'

  UNION ALL

  SELECT
    CASE WHEN st.i = 63 THEN 'comp' ELSE 'wexp' END,
    st.r, '', st.padded, st.blk, st.nblk,
    CASE WHEN st.i = 63 THEN 0 ELSE st.i + 1 END,
    st.wbuf || printf('%010d', (
      CAST(substr(st.wbuf, (st.i - 16) * 10 + 1, 10) AS INTEGER) +
      ((
        (
          (((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) >> 7) | ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) << 25) & 4294967295)) |
           ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) >> 18) | ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) << 14) & 4294967295))) &
          ~(((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) >> 7) | ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) << 25) & 4294967295)) &
            ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) >> 18) | ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) << 14) & 4294967295)))
        ) | (CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) >> 3)
      ) & ~(
        (
          (((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) >> 7) | ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) << 25) & 4294967295)) |
           ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) >> 18) | ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) << 14) & 4294967295))) &
          ~(((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) >> 7) | ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) << 25) & 4294967295)) &
            ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) >> 18) | ((CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) << 14) & 4294967295)))
        ) & (CAST(substr(st.wbuf, (st.i - 15) * 10 + 1, 10) AS INTEGER) >> 3)
      )) +
      CAST(substr(st.wbuf, (st.i - 7) * 10 + 1, 10) AS INTEGER) +
      ((
        (
          (((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) >> 17) | ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) << 15) & 4294967295)) |
           ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) >> 19) | ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) << 13) & 4294967295))) &
          ~(((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) >> 17) | ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) << 15) & 4294967295)) &
            ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) >> 19) | ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) << 13) & 4294967295)))
        ) | (CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) >> 10)
      ) & ~(
        (
          (((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) >> 17) | ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) << 15) & 4294967295)) |
           ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) >> 19) | ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) << 13) & 4294967295))) &
          ~(((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) >> 17) | ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) << 15) & 4294967295)) &
            ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) >> 19) | ((CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) << 13) & 4294967295)))
        ) & (CAST(substr(st.wbuf, (st.i - 2) * 10 + 1, 10) AS INTEGER) >> 10)
      ))
    ) & 4294967295),
    st.h0, st.h1, st.h2, st.h3, st.h4, st.h5, st.h6, st.h7,
    st.h0, st.h1, st.h2, st.h3, st.h4, st.h5, st.h6, st.h7,
    '', ''
  FROM st
  WHERE st.phase = 'wexp'

  UNION ALL

  SELECT
    CASE
      WHEN st.i < 63 THEN 'comp'
      WHEN st.blk + 1 < st.nblk THEN 'wload'
      ELSE 'finish_hash'
    END,
    st.r, '', st.padded,
    CASE WHEN st.i = 63 AND st.blk + 1 < st.nblk THEN st.blk + 1 ELSE st.blk END,
    st.nblk,
    CASE WHEN st.i < 63 THEN st.i + 1 ELSE 0 END,
    CASE WHEN st.i < 63 THEN st.wbuf ELSE '' END,
    CASE WHEN st.i = 63 THEN (st.h0 + ((
      st.hh +
      ((
        (
          (((st.e >> 6) | ((st.e << 26) & 4294967295)) | ((st.e >> 11) | ((st.e << 21) & 4294967295))) &
          ~(((st.e >> 6) | ((st.e << 26) & 4294967295)) & ((st.e >> 11) | ((st.e << 21) & 4294967295)))
        ) | ((st.e >> 25) | ((st.e << 7) & 4294967295))
      ) & ~(
        (
          (((st.e >> 6) | ((st.e << 26) & 4294967295)) | ((st.e >> 11) | ((st.e << 21) & 4294967295))) &
          ~(((st.e >> 6) | ((st.e << 26) & 4294967295)) & ((st.e >> 11) | ((st.e << 21) & 4294967295)))
        ) & ((st.e >> 25) | ((st.e << 7) & 4294967295))
      )) +
      ((st.e & st.f) | ((4294967295 - st.e) & st.g)) +
      k_table.val +
      CAST(substr(st.wbuf, st.i * 10 + 1, 10) AS INTEGER) +
      ((
        (
          (((st.a >> 2) | ((st.a << 30) & 4294967295)) | ((st.a >> 13) | ((st.a << 19) & 4294967295))) &
          ~(((st.a >> 2) | ((st.a << 30) & 4294967295)) & ((st.a >> 13) | ((st.a << 19) & 4294967295)))
        ) | ((st.a >> 22) | ((st.a << 10) & 4294967295))
      ) & ~(
        (
          (((st.a >> 2) | ((st.a << 30) & 4294967295)) | ((st.a >> 13) | ((st.a << 19) & 4294967295))) &
          ~(((st.a >> 2) | ((st.a << 30) & 4294967295)) & ((st.a >> 13) | ((st.a << 19) & 4294967295)))
        ) & ((st.a >> 22) | ((st.a << 10) & 4294967295))
      )) +
      ((st.a & st.b) | (st.a & st.c) | (st.b & st.c))
    ) & 4294967295)) & 4294967295 ELSE st.h0 END,
    CASE WHEN st.i = 63 THEN (st.h1 + st.a) & 4294967295 ELSE st.h1 END,
    CASE WHEN st.i = 63 THEN (st.h2 + st.b) & 4294967295 ELSE st.h2 END,
    CASE WHEN st.i = 63 THEN (st.h3 + st.c) & 4294967295 ELSE st.h3 END,
    CASE WHEN st.i = 63 THEN (st.h4 + ((st.d + (
      st.hh +
      ((
        (
          (((st.e >> 6) | ((st.e << 26) & 4294967295)) | ((st.e >> 11) | ((st.e << 21) & 4294967295))) &
          ~(((st.e >> 6) | ((st.e << 26) & 4294967295)) & ((st.e >> 11) | ((st.e << 21) & 4294967295)))
        ) | ((st.e >> 25) | ((st.e << 7) & 4294967295))
      ) & ~(
        (
          (((st.e >> 6) | ((st.e << 26) & 4294967295)) | ((st.e >> 11) | ((st.e << 21) & 4294967295))) &
          ~(((st.e >> 6) | ((st.e << 26) & 4294967295)) & ((st.e >> 11) | ((st.e << 21) & 4294967295)))
        ) & ((st.e >> 25) | ((st.e << 7) & 4294967295))
      )) +
      ((st.e & st.f) | ((4294967295 - st.e) & st.g)) +
      k_table.val +
      CAST(substr(st.wbuf, st.i * 10 + 1, 10) AS INTEGER)
    )) & 4294967295)) & 4294967295 ELSE st.h4 END,
    CASE WHEN st.i = 63 THEN (st.h5 + st.e) & 4294967295 ELSE st.h5 END,
    CASE WHEN st.i = 63 THEN (st.h6 + st.f) & 4294967295 ELSE st.h6 END,
    CASE WHEN st.i = 63 THEN (st.h7 + st.g) & 4294967295 ELSE st.h7 END,
    (
      st.hh +
      ((
        (
          (((st.e >> 6) | ((st.e << 26) & 4294967295)) | ((st.e >> 11) | ((st.e << 21) & 4294967295))) &
          ~(((st.e >> 6) | ((st.e << 26) & 4294967295)) & ((st.e >> 11) | ((st.e << 21) & 4294967295)))
        ) | ((st.e >> 25) | ((st.e << 7) & 4294967295))
      ) & ~(
        (
          (((st.e >> 6) | ((st.e << 26) & 4294967295)) | ((st.e >> 11) | ((st.e << 21) & 4294967295))) &
          ~(((st.e >> 6) | ((st.e << 26) & 4294967295)) & ((st.e >> 11) | ((st.e << 21) & 4294967295)))
        ) & ((st.e >> 25) | ((st.e << 7) & 4294967295))
      )) +
      ((st.e & st.f) | ((4294967295 - st.e) & st.g)) +
      k_table.val +
      CAST(substr(st.wbuf, st.i * 10 + 1, 10) AS INTEGER) +
      ((
        (
          (((st.a >> 2) | ((st.a << 30) & 4294967295)) | ((st.a >> 13) | ((st.a << 19) & 4294967295))) &
          ~(((st.a >> 2) | ((st.a << 30) & 4294967295)) & ((st.a >> 13) | ((st.a << 19) & 4294967295)))
        ) | ((st.a >> 22) | ((st.a << 10) & 4294967295))
      ) & ~(
        (
          (((st.a >> 2) | ((st.a << 30) & 4294967295)) | ((st.a >> 13) | ((st.a << 19) & 4294967295))) &
          ~(((st.a >> 2) | ((st.a << 30) & 4294967295)) & ((st.a >> 13) | ((st.a << 19) & 4294967295)))
        ) & ((st.a >> 22) | ((st.a << 10) & 4294967295))
      )) +
      ((st.a & st.b) | (st.a & st.c) | (st.b & st.c))
    ) & 4294967295,
    st.a, st.b, st.c,
    (st.d +
      st.hh +
      ((
        (
          (((st.e >> 6) | ((st.e << 26) & 4294967295)) | ((st.e >> 11) | ((st.e << 21) & 4294967295))) &
          ~(((st.e >> 6) | ((st.e << 26) & 4294967295)) & ((st.e >> 11) | ((st.e << 21) & 4294967295)))
        ) | ((st.e >> 25) | ((st.e << 7) & 4294967295))
      ) & ~(
        (
          (((st.e >> 6) | ((st.e << 26) & 4294967295)) | ((st.e >> 11) | ((st.e << 21) & 4294967295))) &
          ~(((st.e >> 6) | ((st.e << 26) & 4294967295)) & ((st.e >> 11) | ((st.e << 21) & 4294967295)))
        ) & ((st.e >> 25) | ((st.e << 7) & 4294967295))
      )) +
      ((st.e & st.f) | ((4294967295 - st.e) & st.g)) +
      k_table.val +
      CAST(substr(st.wbuf, st.i * 10 + 1, 10) AS INTEGER)
    ) & 4294967295,
    st.e, st.f, st.g,
    '', ''
  FROM st
  JOIN k_table ON k_table.idx = st.i
  WHERE st.phase = 'comp'

  UNION ALL

  SELECT
    CASE WHEN st.r = 35 THEN 'done' ELSE 'inter' END,
    st.r,
    CASE WHEN st.r = 35 THEN
      printf('%08x%08x%08x%08x%08x%08x%08x', st.h0, st.h1, st.h2, st.h3, st.h4, st.h5, st.h6) ||
      substr(printf('%08x', st.h7), 8, 1) || substr(printf('%08x', st.h7), 7, 1) ||
      substr(printf('%08x', st.h7), 6, 1) || substr(printf('%08x', st.h7), 5, 1) ||
      substr(printf('%08x', st.h7), 4, 1) || substr(printf('%08x', st.h7), 3, 1) ||
      substr(printf('%08x', st.h7), 2, 1) || substr(printf('%08x', st.h7), 1, 1)
    ELSE '' END,
    '', 0, 0, 0, '',
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    printf('%08x%08x%08x%08x%08x%08x%08x', st.h0, st.h1, st.h2, st.h3, st.h4, st.h5, st.h6) ||
      substr(printf('%08x', st.h7), 8, 1) || substr(printf('%08x', st.h7), 7, 1) ||
      substr(printf('%08x', st.h7), 6, 1) || substr(printf('%08x', st.h7), 5, 1) ||
      substr(printf('%08x', st.h7), 4, 1) || substr(printf('%08x', st.h7), 3, 1) ||
      substr(printf('%08x', st.h7), 2, 1) || substr(printf('%08x', st.h7), 1, 1),
    ''
  FROM st
  WHERE st.phase = 'finish_hash'

  UNION ALL

  SELECT
    CASE WHEN st.i + 1 >= max(length(st.rev), length(salts.s)) THEN 'pad' ELSE 'inter' END,
    CASE WHEN st.i + 1 >= max(length(st.rev), length(salts.s)) THEN st.r + 1 ELSE st.r END,
    CASE WHEN st.i + 1 >= max(length(st.rev), length(salts.s))
      THEN hex(CAST(st.acc || substr(st.rev, st.i + 1, 1) || substr(salts.s, st.i + 1, 1) AS BLOB))
      ELSE '' END,
    '', 0, 0,
    CASE WHEN st.i + 1 >= max(length(st.rev), length(salts.s)) THEN 0 ELSE st.i + 1 END,
    '',
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    st.rev,
    st.acc || substr(st.rev, st.i + 1, 1) || substr(salts.s, st.i + 1, 1)
  FROM st
  JOIN salts ON salts.idx = st.r % 10
  WHERE st.phase = 'inter'
)
SELECT msg FROM st WHERE phase = 'done';
