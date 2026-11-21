(module
  (import "wasi_snapshot_preview1" "args_sizes_get" (func $args_sizes_get (param i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "args_get" (func $args_get (param i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "path_open" (func $path_open (param i32 i32 i32 i32 i32 i64 i64 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_read" (func $fd_read (param i32 i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_close" (func $fd_close (param i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "proc_exit" (func $proc_exit (param i32)))

  (memory (export "memory") 16)

  (data (i32.const 0x0000)
    "\98\2f\8a\42\91\44\37\71\cf\fb\c0\b5\a5\db\b5\e9"
    "\5b\c2\56\39\f1\11\f1\59\a4\82\3f\92\d5\5e\1c\ab"
    "\98\aa\07\d8\01\5b\83\12\be\85\31\24\c3\7d\0c\55"
    "\74\5d\be\72\fe\b1\de\80\a7\06\dc\9b\74\f1\9b\c1"
    "\c1\69\9b\e4\86\47\be\ef\c6\9d\c1\0f\cc\a1\0c\24"
    "\6f\2c\e9\2d\aa\84\74\4a\dc\a9\b0\5c\da\88\f9\76"
    "\52\51\3e\98\6d\c6\31\a8\c8\27\03\b0\c7\7f\59\bf"
    "\f3\0b\e0\c6\47\91\a7\d5\51\63\ca\06\67\29\29\14"
    "\85\0a\b7\27\38\21\1b\2e\fc\6d\2c\4d\13\0d\38\53"
    "\54\73\0a\65\bb\0a\6a\76\2e\c9\c2\81\85\2c\72\92"
    "\a1\e8\bf\a2\4b\66\1a\a8\70\8b\4b\c2\a3\51\6c\c7"
    "\19\e8\92\d1\24\06\99\d6\85\35\0e\f4\70\a0\6a\10"
    "\16\c1\a4\19\08\6c\37\1e\4c\77\48\27\b5\bc\b0\34"
    "\b3\0c\1c\39\4a\aa\d8\4e\4f\ca\9c\5b\f3\6f\2e\68"
    "\ee\82\8f\74\6f\63\a5\78\14\78\c8\84\08\02\c7\8c"
    "\fa\ff\be\90\eb\6c\50\a4\f7\a3\f9\be\f2\78\71\c6"
  )

  (data (i32.const 0x0100)
    "\67\e6\09\6a\85\ae\67\bb\72\f3\6e\3c\3a\f5\4f\a5"
    "\7f\52\0e\51\8c\68\05\9b\ab\d9\83\1f\19\cd\e0\5b"
  )

  (data (i32.const 0x0120) "0123456789abcdef")

  (data (i32.const 0x0140)
    "\00\02\00\00\50\02\00\00\a0\02\00\00\f0\02\00\00\40\03\00\00\90\03\00\00\e0\03\00\00\30\04\00\00\80\04\00\00\d0\04\00\00"
  )
  (data (i32.const 0x0180)
    "\48\00\00\00\46\00\00\00\44\00\00\00\45\00\00\00\46\00\00\00\43\00\00\00\42\00\00\00\43\00\00\00\40\00\00\00\49\00\00\00"
  )

  (data (i32.const 0x0200) "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA")
  (data (i32.const 0x0250) "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB")
  (data (i32.const 0x02a0) "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC")
  (data (i32.const 0x02f0) "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD")
  (data (i32.const 0x0340) "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE")
  (data (i32.const 0x0390) "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF")
  (data (i32.const 0x03e0) "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG")
  (data (i32.const 0x0430) "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH")
  (data (i32.const 0x0480) "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II")
  (data (i32.const 0x04d0) "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ")

  (func $strlen (param $p i32) (result i32)
    (local $n i32)
    (block $done
      (loop $loop
        (br_if $done (i32.eqz (i32.load8_u (i32.add (local.get $p) (local.get $n)))))
        (local.set $n (i32.add (local.get $n) (i32.const 1)))
        (br $loop)
      )
    )
    (local.get $n)
  )

  (func $ensure_mem (param $needed i32)
    (local $cur i32)
    (local $pages i32)
    (local.set $cur (i32.shl (memory.size) (i32.const 16)))
    (if (i32.gt_u (local.get $needed) (local.get $cur))
      (then
        (local.set $pages
          (i32.shr_u
            (i32.add (i32.sub (local.get $needed) (local.get $cur)) (i32.const 65535))
            (i32.const 16)))
        (drop (memory.grow (local.get $pages)))
      )
    )
  )

  (func $sha256 (param $buf i32) (param $len i32) (param $out i32)
    (local $rem i32) (local $plen i32) (local $i i32) (local $j i32)
    (local $bits i64) (local $blk i32) (local $nblk i32) (local $off i32)
    (local $w0 i32) (local $w15 i32) (local $w2 i32) (local $s0 i32) (local $s1 i32)
    (local $a i32) (local $b i32) (local $c i32) (local $d i32)
    (local $e i32) (local $f i32) (local $g i32) (local $hh i32)
    (local $t1 i32) (local $t2 i32) (local $ch i32) (local $maj i32)
    (local $val i32)

    (local.set $i (i32.const 0))
    (loop $init_h
      (i32.store
        (i32.add (i32.const 0x0600) (i32.shl (local.get $i) (i32.const 2)))
        (i32.load (i32.add (i32.const 0x0100) (i32.shl (local.get $i) (i32.const 2)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $init_h (i32.lt_u (local.get $i) (i32.const 8)))
    )

    (local.set $rem (i32.rem_u (i32.add (local.get $len) (i32.const 9)) (i32.const 64)))
    (local.set $plen
      (i32.add
        (i32.add (local.get $len) (i32.const 9))
        (if (result i32) (i32.eqz (local.get $rem))
          (then (i32.const 0))
          (else (i32.sub (i32.const 64) (local.get $rem))))))

    (call $ensure_mem (i32.add (local.get $buf) (local.get $plen)))

    (i32.store8 (i32.add (local.get $buf) (local.get $len)) (i32.const 0x80))
    (local.set $i (i32.add (local.get $len) (i32.const 1)))
    (block $zdone
      (loop $zloop
        (br_if $zdone (i32.ge_u (local.get $i) (i32.sub (local.get $plen) (i32.const 8))))
        (i32.store8 (i32.add (local.get $buf) (local.get $i)) (i32.const 0))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $zloop)
      )
    )

    (local.set $bits (i64.shl (i64.extend_i32_u (local.get $len)) (i64.const 3)))
    (local.set $i (i32.const 0))
    (loop $len_bytes
      (i32.store8
        (i32.add (local.get $buf) (i32.add (i32.sub (local.get $plen) (i32.const 8)) (local.get $i)))
        (i32.wrap_i64
          (i64.shr_u
            (local.get $bits)
            (i64.extend_i32_u (i32.shl (i32.sub (i32.const 7) (local.get $i)) (i32.const 3))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $len_bytes (i32.lt_u (local.get $i) (i32.const 8)))
    )

    (local.set $nblk (i32.shr_u (local.get $plen) (i32.const 6)))
    (local.set $blk (i32.const 0))
    (loop $blk_loop
      (local.set $off (i32.add (local.get $buf) (i32.shl (local.get $blk) (i32.const 6))))

      (local.set $i (i32.const 0))
      (loop $wload
        (local.set $j (i32.add (local.get $off) (i32.shl (local.get $i) (i32.const 2))))
        (local.set $w0
          (i32.or
            (i32.or
              (i32.shl (i32.load8_u (local.get $j)) (i32.const 24))
              (i32.shl (i32.load8_u (i32.add (local.get $j) (i32.const 1))) (i32.const 16)))
            (i32.or
              (i32.shl (i32.load8_u (i32.add (local.get $j) (i32.const 2))) (i32.const 8))
              (i32.load8_u (i32.add (local.get $j) (i32.const 3))))))
        (i32.store (i32.add (i32.const 0x0620) (i32.shl (local.get $i) (i32.const 2))) (local.get $w0))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br_if $wload (i32.lt_u (local.get $i) (i32.const 16)))
      )

      (local.set $i (i32.const 16))
      (loop $wexp
        (local.set $w15 (i32.load (i32.add (i32.const 0x0620) (i32.shl (i32.sub (local.get $i) (i32.const 15)) (i32.const 2)))))
        (local.set $w2  (i32.load (i32.add (i32.const 0x0620) (i32.shl (i32.sub (local.get $i) (i32.const 2)) (i32.const 2)))))
        (local.set $s0
          (i32.xor
            (i32.xor (i32.rotr (local.get $w15) (i32.const 7)) (i32.rotr (local.get $w15) (i32.const 18)))
            (i32.shr_u (local.get $w15) (i32.const 3))))
        (local.set $s1
          (i32.xor
            (i32.xor (i32.rotr (local.get $w2) (i32.const 17)) (i32.rotr (local.get $w2) (i32.const 19)))
            (i32.shr_u (local.get $w2) (i32.const 10))))
        (i32.store
          (i32.add (i32.const 0x0620) (i32.shl (local.get $i) (i32.const 2)))
          (i32.add
            (i32.add
              (i32.load (i32.add (i32.const 0x0620) (i32.shl (i32.sub (local.get $i) (i32.const 16)) (i32.const 2))))
              (local.get $s0))
            (i32.add
              (i32.load (i32.add (i32.const 0x0620) (i32.shl (i32.sub (local.get $i) (i32.const 7)) (i32.const 2))))
              (local.get $s1))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br_if $wexp (i32.lt_u (local.get $i) (i32.const 64)))
      )

      (local.set $a  (i32.load (i32.const 0x0600)))
      (local.set $b  (i32.load (i32.const 0x0604)))
      (local.set $c  (i32.load (i32.const 0x0608)))
      (local.set $d  (i32.load (i32.const 0x060c)))
      (local.set $e  (i32.load (i32.const 0x0610)))
      (local.set $f  (i32.load (i32.const 0x0614)))
      (local.set $g  (i32.load (i32.const 0x0618)))
      (local.set $hh (i32.load (i32.const 0x061c)))

      (local.set $i (i32.const 0))
      (loop $comp
        (local.set $s1
          (i32.xor
            (i32.xor (i32.rotr (local.get $e) (i32.const 6)) (i32.rotr (local.get $e) (i32.const 11)))
            (i32.rotr (local.get $e) (i32.const 25))))
        (local.set $ch
          (i32.xor
            (i32.and (local.get $e) (local.get $f))
            (i32.and (i32.xor (local.get $e) (i32.const -1)) (local.get $g))))
        (local.set $t1
          (i32.add
            (i32.add
              (i32.add (local.get $hh) (local.get $s1))
              (i32.add (local.get $ch) (i32.load (i32.shl (local.get $i) (i32.const 2)))))
            (i32.load (i32.add (i32.const 0x0620) (i32.shl (local.get $i) (i32.const 2))))))
        (local.set $s0
          (i32.xor
            (i32.xor (i32.rotr (local.get $a) (i32.const 2)) (i32.rotr (local.get $a) (i32.const 13)))
            (i32.rotr (local.get $a) (i32.const 22))))
        (local.set $maj
          (i32.xor
            (i32.xor (i32.and (local.get $a) (local.get $b)) (i32.and (local.get $a) (local.get $c)))
            (i32.and (local.get $b) (local.get $c))))
        (local.set $t2 (i32.add (local.get $s0) (local.get $maj)))
        (local.set $hh (local.get $g))
        (local.set $g (local.get $f))
        (local.set $f (local.get $e))
        (local.set $e (i32.add (local.get $d) (local.get $t1)))
        (local.set $d (local.get $c))
        (local.set $c (local.get $b))
        (local.set $b (local.get $a))
        (local.set $a (i32.add (local.get $t1) (local.get $t2)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br_if $comp (i32.lt_u (local.get $i) (i32.const 64)))
      )

      (i32.store (i32.const 0x0600) (i32.add (i32.load (i32.const 0x0600)) (local.get $a)))
      (i32.store (i32.const 0x0604) (i32.add (i32.load (i32.const 0x0604)) (local.get $b)))
      (i32.store (i32.const 0x0608) (i32.add (i32.load (i32.const 0x0608)) (local.get $c)))
      (i32.store (i32.const 0x060c) (i32.add (i32.load (i32.const 0x060c)) (local.get $d)))
      (i32.store (i32.const 0x0610) (i32.add (i32.load (i32.const 0x0610)) (local.get $e)))
      (i32.store (i32.const 0x0614) (i32.add (i32.load (i32.const 0x0614)) (local.get $f)))
      (i32.store (i32.const 0x0618) (i32.add (i32.load (i32.const 0x0618)) (local.get $g)))
      (i32.store (i32.const 0x061c) (i32.add (i32.load (i32.const 0x061c)) (local.get $hh)))

      (local.set $blk (i32.add (local.get $blk) (i32.const 1)))
      (br_if $blk_loop (i32.lt_u (local.get $blk) (local.get $nblk)))
    )

    (local.set $i (i32.const 0))
    (loop $hex_w
      (local.set $val (i32.load (i32.add (i32.const 0x0600) (i32.shl (local.get $i) (i32.const 2)))))
      (local.set $j (i32.const 0))
      (loop $hex_n
        (i32.store8
          (i32.add (local.get $out) (i32.add (i32.shl (local.get $i) (i32.const 3)) (local.get $j)))
          (i32.load8_u
            (i32.add
              (i32.const 0x0120)
              (i32.and
                (i32.shr_u (local.get $val) (i32.shl (i32.sub (i32.const 7) (local.get $j)) (i32.const 2)))
                (i32.const 15)))))
        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br_if $hex_n (i32.lt_u (local.get $j) (i32.const 8)))
      )
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $hex_w (i32.lt_u (local.get $i) (i32.const 8)))
    )
  )

  (func $reverse_suffix (param $p i32)
    (local $i i32) (local $lo i32) (local $hi i32) (local $tmp i32)
    (local.set $i (i32.const 0))
    (loop $swap
      (local.set $lo (i32.add (local.get $p) (i32.add (i32.const 56) (local.get $i))))
      (local.set $hi (i32.add (local.get $p) (i32.sub (i32.const 63) (local.get $i))))
      (local.set $tmp (i32.load8_u (local.get $lo)))
      (i32.store8 (local.get $lo) (i32.load8_u (local.get $hi)))
      (i32.store8 (local.get $hi) (local.get $tmp))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $swap (i32.lt_u (local.get $i) (i32.const 4)))
    )
  )

  (func $interleave (param $a i32) (param $la i32) (param $b i32) (param $lb i32) (param $out i32) (result i32)
    (local $i i32) (local $m i32) (local $pos i32)
    (local.set $m (select (local.get $la) (local.get $lb) (i32.gt_u (local.get $la) (local.get $lb))))
    (local.set $i (i32.const 0))
    (local.set $pos (i32.const 0))
    (block $done
      (loop $loop
        (br_if $done (i32.ge_u (local.get $i) (local.get $m)))
        (if (i32.lt_u (local.get $i) (local.get $la))
          (then
            (i32.store8 (i32.add (local.get $out) (local.get $pos)) (i32.load8_u (i32.add (local.get $a) (local.get $i))))
            (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
          )
        )
        (if (i32.lt_u (local.get $i) (local.get $lb))
          (then
            (i32.store8 (i32.add (local.get $out) (local.get $pos)) (i32.load8_u (i32.add (local.get $b) (local.get $i))))
            (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
          )
        )
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)
      )
    )
    (local.get $pos)
  )

  (func (export "_start")
    (local $argc i32) (local $arg1 i32) (local $arg1_len i32)
    (local $arg2 i32) (local $arg2_len i32) (local $fd i32)
    (local $data_ptr i32) (local $data_len i32) (local $nread i32)
    (local $r i32) (local $sidx i32) (local $sptr i32) (local $slen i32)
    (local $i i32)

    (drop (call $args_sizes_get (i32.const 0x0900) (i32.const 0x0904)))
    (local.set $argc (i32.load (i32.const 0x0900)))
    (if (i32.lt_u (local.get $argc) (i32.const 2))
      (then (call $proc_exit (i32.const 1)))
    )
    (drop (call $args_get (i32.const 0x0a00) (i32.const 0x1000)))

    (local.set $arg1 (i32.load (i32.const 0x0a04)))
    (local.set $arg1_len (call $strlen (local.get $arg1)))
    (local.set $data_ptr (i32.const 0x4000))

    (if
      (i32.and
        (i32.eq (local.get $arg1_len) (i32.const 2))
        (i32.and
          (i32.eq (i32.load8_u (local.get $arg1)) (i32.const 45))
          (i32.eq (i32.load8_u (i32.add (local.get $arg1) (i32.const 1))) (i32.const 102))))
      (then
        (if (i32.lt_u (local.get $argc) (i32.const 3))
          (then (call $proc_exit (i32.const 1)))
        )
        (local.set $arg2 (i32.load (i32.const 0x0a08)))
        (local.set $arg2_len (call $strlen (local.get $arg2)))
        (if
          (call $path_open
            (i32.const 3) (i32.const 0)
            (local.get $arg2) (local.get $arg2_len)
            (i32.const 0) (i64.const 2) (i64.const 0) (i32.const 0)
            (i32.const 0x0910))
          (then (call $proc_exit (i32.const 1)))
        )
        (local.set $fd (i32.load (i32.const 0x0910)))
        (local.set $data_len (i32.const 0))
        (block $eof
          (loop $rd
            (call $ensure_mem (i32.add (i32.add (local.get $data_ptr) (local.get $data_len)) (i32.const 4224)))
            (i32.store (i32.const 0x0920) (i32.add (local.get $data_ptr) (local.get $data_len)))
            (i32.store (i32.const 0x0924) (i32.const 4096))
            (if (call $fd_read (local.get $fd) (i32.const 0x0920) (i32.const 1) (i32.const 0x0928))
              (then (call $proc_exit (i32.const 1)))
            )
            (local.set $nread (i32.load (i32.const 0x0928)))
            (br_if $eof (i32.eqz (local.get $nread)))
            (local.set $data_len (i32.add (local.get $data_len) (local.get $nread)))
            (br $rd)
          )
        )
        (drop (call $fd_close (local.get $fd)))
      )
      (else
        (local.set $data_len (local.get $arg1_len))
        (call $ensure_mem (i32.add (i32.add (local.get $data_ptr) (local.get $data_len)) (i32.const 128)))
        (local.set $i (i32.const 0))
        (block $cdone
          (loop $cloop
            (br_if $cdone (i32.ge_u (local.get $i) (local.get $data_len)))
            (i32.store8
              (i32.add (local.get $data_ptr) (local.get $i))
              (i32.load8_u (i32.add (local.get $arg1) (local.get $i))))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $cloop)
          )
        )
      )
    )

    (local.set $r (i32.const 0))
    (loop $rounds
      (call $sha256 (local.get $data_ptr) (local.get $data_len) (i32.const 0x0720))
      (call $reverse_suffix (i32.const 0x0720))
      (local.set $sidx (i32.rem_u (local.get $r) (i32.const 10)))
      (local.set $sptr (i32.load (i32.add (i32.const 0x0140) (i32.shl (local.get $sidx) (i32.const 2)))))
      (local.set $slen (i32.load (i32.add (i32.const 0x0180) (i32.shl (local.get $sidx) (i32.const 2)))))
      (local.set $data_len (call $interleave (i32.const 0x0720) (i32.const 64) (local.get $sptr) (local.get $slen) (i32.const 0x0780)))
      (local.set $data_ptr (i32.const 0x0780))
      (local.set $r (i32.add (local.get $r) (i32.const 1)))
      (br_if $rounds (i32.lt_u (local.get $r) (i32.const 35)))
    )

    (call $sha256 (local.get $data_ptr) (local.get $data_len) (i32.const 0x0720))
    (call $reverse_suffix (i32.const 0x0720))
    (i32.store8 (i32.const 0x0760) (i32.const 10))

    (i32.store (i32.const 0x0920) (i32.const 0x0720))
    (i32.store (i32.const 0x0924) (i32.const 65))
    (drop (call $fd_write (i32.const 1) (i32.const 0x0920) (i32.const 1) (i32.const 0x0928)))
  )
)
