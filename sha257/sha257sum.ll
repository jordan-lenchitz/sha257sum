@K = private unnamed_addr constant [64 x i32] [
  i32 1116352408, i32 1899447441, i32 -1245643825, i32 -373957723,
  i32 961987163,  i32 1508970993, i32 -1841331548, i32 -1424204075,
  i32 -670586216, i32 310598401,  i32 607225278,   i32 1426881987,
  i32 1925078388, i32 -2132889090,i32 -1680079193, i32 -1046744716,
  i32 -459576895, i32 -272742522, i32 264347078,   i32 604807628,
  i32 770255983,  i32 1249150122, i32 1555081692,  i32 1996064986,
  i32 -1740746414,i32 -1473132947,i32 -1341970488, i32 -1084653625,
  i32 -958395405, i32 -710438585, i32 113926993,   i32 338241895,
  i32 666307205,  i32 773529912,  i32 1294757372,  i32 1396182291,
  i32 1695183700, i32 1986661051, i32 2177026350,  i32 -1838011259,
  i32 -1564481375,i32 -1474664885,i32 -1035236496, i32 -949202525,
  i32 -778901479, i32 -694614492, i32 -200395387,  i32 275423344,
  i32 430227734,  i32 506948616,  i32 659060556,   i32 883997877,
  i32 958139571,  i32 1322822218, i32 1537002063,  i32 1747873779,
  i32 1955562222, i32 2024104815, i32 -2067236844, i32 -1933114872,
  i32 -1866530822,i32 -1538233109,i32 -1090935817, i32 -965641998
]

@IV = private unnamed_addr constant [8 x i32] [
  i32 1779033703, i32 -1150833019, i32 1013904242, i32 -1521486534,
  i32 1359893119, i32 -1694144372, i32 528734635,  i32 1541459225
]

@HEX = private unnamed_addr constant [16 x i8] c"0123456789abcdef"

@S0 = private unnamed_addr constant [72 x i8] c"jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
@S1 = private unnamed_addr constant [70 x i8] c"jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
@S2 = private unnamed_addr constant [68 x i8] c"jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
@S3 = private unnamed_addr constant [69 x i8] c"jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
@S4 = private unnamed_addr constant [70 x i8] c"jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
@S5 = private unnamed_addr constant [67 x i8] c"jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
@S6 = private unnamed_addr constant [66 x i8] c"jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
@S7 = private unnamed_addr constant [67 x i8] c"jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
@S8 = private unnamed_addr constant [64 x i8] c"jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
@S9 = private unnamed_addr constant [73 x i8] c"jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"

@SALTS = private unnamed_addr constant [10 x ptr] [
  ptr @S0, ptr @S1, ptr @S2, ptr @S3, ptr @S4,
  ptr @S5, ptr @S6, ptr @S7, ptr @S8, ptr @S9
]

@SALT_LENS = private unnamed_addr constant [10 x i64] [
  i64 72, i64 70, i64 68, i64 69, i64 70,
  i64 67, i64 66, i64 67, i64 64, i64 73
]

@FLAG_F = private unnamed_addr constant [3 x i8] c"-f\00"
@MODE_RB = private unnamed_addr constant [3 x i8] c"rb\00"
@USAGE = private unnamed_addr constant [42 x i8] c"Usage: sha257sum <string> | -f <file>\00\00\00\00\00"

declare ptr @malloc(i64)
declare ptr @realloc(ptr, i64)
declare void @free(ptr)
declare ptr @fopen(ptr, ptr)
declare i64 @fread(ptr, i64, i64, ptr)
declare i32 @fclose(ptr)
declare i64 @strlen(ptr)
declare i32 @strcmp(ptr, ptr)
declare i32 @puts(ptr)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
declare i32 @llvm.fshr.i32(i32, i32, i32)

define private void @sha256(ptr %data, i64 %len, ptr %out) {
entry:
  %h = alloca [8 x i32], align 4
  %w = alloca [64 x i32], align 4
  call void @llvm.memcpy.p0.p0.i64(ptr %h, ptr @IV, i64 32, i1 false)

  %len9 = add i64 %len, 9
  %rem = urem i64 %len9, 64
  %iszero = icmp eq i64 %rem, 0
  %pad_add = sub i64 64, %rem
  %extra = select i1 %iszero, i64 0, i64 %pad_add
  %plen = add i64 %len9, %extra

  %buf = call ptr @malloc(i64 %plen)
  call void @llvm.memset.p0.i64(ptr %buf, i8 0, i64 %plen, i1 false)
  %has_data = icmp ugt i64 %len, 0
  br i1 %has_data, label %copy_data, label %set_bit

copy_data:
  call void @llvm.memcpy.p0.p0.i64(ptr %buf, ptr %data, i64 %len, i1 false)
  br label %set_bit

set_bit:
  %p80 = getelementptr i8, ptr %buf, i64 %len
  store i8 -128, ptr %p80, align 1
  %bits = shl i64 %len, 3
  %len_base = sub i64 %plen, 8
  br label %len_loop

len_loop:
  %li = phi i64 [ 0, %set_bit ], [ %li_next, %len_loop ]
  %lsh_t = sub i64 7, %li
  %lsh = shl i64 %lsh_t, 3
  %lval = lshr i64 %bits, %lsh
  %lbyte = trunc i64 %lval to i8
  %loff = add i64 %len_base, %li
  %lptr = getelementptr i8, ptr %buf, i64 %loff
  store i8 %lbyte, ptr %lptr, align 1
  %li_next = add i64 %li, 1
  %li_done = icmp eq i64 %li_next, 8
  br i1 %li_done, label %blk_init, label %len_loop

blk_init:
  %nblk = lshr i64 %plen, 6
  br label %blk_loop

blk_loop:
  %blk = phi i64 [ 0, %blk_init ], [ %blk_next, %blk_end ]
  %boff = shl i64 %blk, 6
  br label %wload

wload:
  %wi = phi i64 [ 0, %blk_loop ], [ %wi_next, %wload ]
  %wpos0 = shl i64 %wi, 2
  %wpos = add i64 %boff, %wpos0
  %bp0 = getelementptr i8, ptr %buf, i64 %wpos
  %bp1 = getelementptr i8, ptr %bp0, i64 1
  %bp2 = getelementptr i8, ptr %bp0, i64 2
  %bp3 = getelementptr i8, ptr %bp0, i64 3
  %b0 = load i8, ptr %bp0, align 1
  %b1 = load i8, ptr %bp1, align 1
  %b2 = load i8, ptr %bp2, align 1
  %b3 = load i8, ptr %bp3, align 1
  %z0 = zext i8 %b0 to i32
  %z1 = zext i8 %b1 to i32
  %z2 = zext i8 %b2 to i32
  %z3 = zext i8 %b3 to i32
  %s0 = shl i32 %z0, 24
  %s1 = shl i32 %z1, 16
  %s2 = shl i32 %z2, 8
  %o01 = or i32 %s0, %s1
  %o23 = or i32 %s2, %z3
  %word = or i32 %o01, %o23
  %wptr = getelementptr [64 x i32], ptr %w, i64 0, i64 %wi
  store i32 %word, ptr %wptr, align 4
  %wi_next = add i64 %wi, 1
  %wi_done = icmp eq i64 %wi_next, 16
  br i1 %wi_done, label %wexp, label %wload

wexp:
  %ei = phi i64 [ 16, %wload ], [ %ei_next, %wexp ]
  %i15 = sub i64 %ei, 15
  %i2 = sub i64 %ei, 2
  %i16 = sub i64 %ei, 16
  %i7 = sub i64 %ei, 7
  %p15 = getelementptr [64 x i32], ptr %w, i64 0, i64 %i15
  %p2 = getelementptr [64 x i32], ptr %w, i64 0, i64 %i2
  %p16 = getelementptr [64 x i32], ptr %w, i64 0, i64 %i16
  %p7 = getelementptr [64 x i32], ptr %w, i64 0, i64 %i7
  %v15 = load i32, ptr %p15, align 4
  %v2 = load i32, ptr %p2, align 4
  %v16 = load i32, ptr %p16, align 4
  %v7 = load i32, ptr %p7, align 4
  %r7 = call i32 @llvm.fshr.i32(i32 %v15, i32 %v15, i32 7)
  %r18 = call i32 @llvm.fshr.i32(i32 %v15, i32 %v15, i32 18)
  %sh3 = lshr i32 %v15, 3
  %ms0_a = xor i32 %r7, %r18
  %ms0 = xor i32 %ms0_a, %sh3
  %r17 = call i32 @llvm.fshr.i32(i32 %v2, i32 %v2, i32 17)
  %r19 = call i32 @llvm.fshr.i32(i32 %v2, i32 %v2, i32 19)
  %sh10 = lshr i32 %v2, 10
  %ms1_a = xor i32 %r17, %r19
  %ms1 = xor i32 %ms1_a, %sh10
  %sum0 = add i32 %v16, %ms0
  %sum1 = add i32 %sum0, %v7
  %sum2 = add i32 %sum1, %ms1
  %pe = getelementptr [64 x i32], ptr %w, i64 0, i64 %ei
  store i32 %sum2, ptr %pe, align 4
  %ei_next = add i64 %ei, 1
  %ei_done = icmp eq i64 %ei_next, 64
  br i1 %ei_done, label %comp_init, label %wexp

comp_init:
  %hp0 = getelementptr [8 x i32], ptr %h, i64 0, i64 0
  %hp1 = getelementptr [8 x i32], ptr %h, i64 0, i64 1
  %hp2 = getelementptr [8 x i32], ptr %h, i64 0, i64 2
  %hp3 = getelementptr [8 x i32], ptr %h, i64 0, i64 3
  %hp4 = getelementptr [8 x i32], ptr %h, i64 0, i64 4
  %hp5 = getelementptr [8 x i32], ptr %h, i64 0, i64 5
  %hp6 = getelementptr [8 x i32], ptr %h, i64 0, i64 6
  %hp7 = getelementptr [8 x i32], ptr %h, i64 0, i64 7
  %ih0 = load i32, ptr %hp0, align 4
  %ih1 = load i32, ptr %hp1, align 4
  %ih2 = load i32, ptr %hp2, align 4
  %ih3 = load i32, ptr %hp3, align 4
  %ih4 = load i32, ptr %hp4, align 4
  %ih5 = load i32, ptr %hp5, align 4
  %ih6 = load i32, ptr %hp6, align 4
  %ih7 = load i32, ptr %hp7, align 4
  br label %comp_loop

comp_loop:
  %ci = phi i64 [ 0, %comp_init ], [ %ci_next, %comp_loop ]
  %a = phi i32 [ %ih0, %comp_init ], [ %na, %comp_loop ]
  %b = phi i32 [ %ih1, %comp_init ], [ %a, %comp_loop ]
  %c = phi i32 [ %ih2, %comp_init ], [ %b, %comp_loop ]
  %d = phi i32 [ %ih3, %comp_init ], [ %c, %comp_loop ]
  %e = phi i32 [ %ih4, %comp_init ], [ %ne, %comp_loop ]
  %f = phi i32 [ %ih5, %comp_init ], [ %e, %comp_loop ]
  %g = phi i32 [ %ih6, %comp_init ], [ %f, %comp_loop ]
  %hh = phi i32 [ %ih7, %comp_init ], [ %g, %comp_loop ]

  %re6 = call i32 @llvm.fshr.i32(i32 %e, i32 %e, i32 6)
  %re11 = call i32 @llvm.fshr.i32(i32 %e, i32 %e, i32 11)
  %re25 = call i32 @llvm.fshr.i32(i32 %e, i32 %e, i32 25)
  %bs1_a = xor i32 %re6, %re11
  %bs1 = xor i32 %bs1_a, %re25

  %ef = and i32 %e, %f
  %note = xor i32 %e, -1
  %neg = and i32 %note, %g
  %ch = xor i32 %ef, %neg

  %kp = getelementptr [64 x i32], ptr @K, i64 0, i64 %ci
  %kv = load i32, ptr %kp, align 4
  %wp = getelementptr [64 x i32], ptr %w, i64 0, i64 %ci
  %wv = load i32, ptr %wp, align 4

  %t1_0 = add i32 %hh, %bs1
  %t1_1 = add i32 %t1_0, %ch
  %t1_2 = add i32 %t1_1, %kv
  %t1 = add i32 %t1_2, %wv

  %ra2 = call i32 @llvm.fshr.i32(i32 %a, i32 %a, i32 2)
  %ra13 = call i32 @llvm.fshr.i32(i32 %a, i32 %a, i32 13)
  %ra22 = call i32 @llvm.fshr.i32(i32 %a, i32 %a, i32 22)
  %bs0_a = xor i32 %ra2, %ra13
  %bs0 = xor i32 %bs0_a, %ra22

  %ab = and i32 %a, %b
  %ac = and i32 %a, %c
  %bc = and i32 %b, %c
  %maj_a = xor i32 %ab, %ac
  %maj = xor i32 %maj_a, %bc
  %t2 = add i32 %bs0, %maj

  %ne = add i32 %d, %t1
  %na = add i32 %t1, %t2

  %ci_next = add i64 %ci, 1
  %ci_done = icmp eq i64 %ci_next, 64
  br i1 %ci_done, label %blk_end, label %comp_loop

blk_end:
  %nh0 = add i32 %ih0, %na
  %nh1 = add i32 %ih1, %a
  %nh2 = add i32 %ih2, %b
  %nh3 = add i32 %ih3, %c
  %nh4 = add i32 %ih4, %ne
  %nh5 = add i32 %ih5, %e
  %nh6 = add i32 %ih6, %f
  %nh7 = add i32 %ih7, %g
  store i32 %nh0, ptr %hp0, align 4
  store i32 %nh1, ptr %hp1, align 4
  store i32 %nh2, ptr %hp2, align 4
  store i32 %nh3, ptr %hp3, align 4
  store i32 %nh4, ptr %hp4, align 4
  store i32 %nh5, ptr %hp5, align 4
  store i32 %nh6, ptr %hp6, align 4
  store i32 %nh7, ptr %hp7, align 4
  %blk_next = add i64 %blk, 1
  %blk_done = icmp eq i64 %blk_next, %nblk
  br i1 %blk_done, label %fmt_init, label %blk_loop

fmt_init:
  call void @free(ptr %buf)
  br label %fmt_outer

fmt_outer:
  %fi = phi i64 [ 0, %fmt_init ], [ %fi_next, %fmt_outer_end ]
  %fhp = getelementptr [8 x i32], ptr %h, i64 0, i64 %fi
  %fw = load i32, ptr %fhp, align 4
  br label %fmt_inner

fmt_inner:
  %fj = phi i64 [ 0, %fmt_outer ], [ %fj_next, %fmt_inner ]
  %fsh_t = sub i64 7, %fj
  %fsh_64 = shl i64 %fsh_t, 2
  %fsh = trunc i64 %fsh_64 to i32
  %fnib32 = lshr i32 %fw, %fsh
  %fnib_m = and i32 %fnib32, 15
  %fnib = zext i32 %fnib_m to i64
  %hcp = getelementptr [16 x i8], ptr @HEX, i64 0, i64 %fnib
  %hc = load i8, ptr %hcp, align 1
  %fidx0 = shl i64 %fi, 3
  %fidx = add i64 %fidx0, %fj
  %op = getelementptr i8, ptr %out, i64 %fidx
  store i8 %hc, ptr %op, align 1
  %fj_next = add i64 %fj, 1
  %fj_done = icmp eq i64 %fj_next, 8
  br i1 %fj_done, label %fmt_outer_end, label %fmt_inner

fmt_outer_end:
  %fi_next = add i64 %fi, 1
  %fi_done = icmp eq i64 %fi_next, 8
  br i1 %fi_done, label %ret, label %fmt_outer

ret:
  ret void
}

define private void @reverse_suffix(ptr %s) {
entry:
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %i_next, %loop ]
  %lo_idx = add i64 56, %i
  %hi_idx = sub i64 63, %i
  %plo = getelementptr i8, ptr %s, i64 %lo_idx
  %phi = getelementptr i8, ptr %s, i64 %hi_idx
  %vlo = load i8, ptr %plo, align 1
  %vhi = load i8, ptr %phi, align 1
  store i8 %vhi, ptr %plo, align 1
  store i8 %vlo, ptr %phi, align 1
  %i_next = add i64 %i, 1
  %done = icmp eq i64 %i_next, 4
  br i1 %done, label %exit, label %loop

exit:
  ret void
}

define private i64 @interleave(ptr %a, i64 %la, ptr %b, i64 %lb, ptr %out) {
entry:
  %gt = icmp ugt i64 %la, %lb
  %m = select i1 %gt, i64 %la, i64 %lb
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %i_next, %step_end ]
  %pos = phi i64 [ 0, %entry ], [ %pos2, %step_end ]
  %has_a = icmp ult i64 %i, %la
  br i1 %has_a, label %take_a, label %check_b

take_a:
  %pa = getelementptr i8, ptr %a, i64 %i
  %va = load i8, ptr %pa, align 1
  %poa = getelementptr i8, ptr %out, i64 %pos
  store i8 %va, ptr %poa, align 1
  %pos1_a = add i64 %pos, 1
  br label %check_b

check_b:
  %pos1 = phi i64 [ %pos, %loop ], [ %pos1_a, %take_a ]
  %has_b = icmp ult i64 %i, %lb
  br i1 %has_b, label %take_b, label %step_end

take_b:
  %pb = getelementptr i8, ptr %b, i64 %i
  %vb = load i8, ptr %pb, align 1
  %pob = getelementptr i8, ptr %out, i64 %pos1
  store i8 %vb, ptr %pob, align 1
  %pos2_b = add i64 %pos1, 1
  br label %step_end

step_end:
  %pos2 = phi i64 [ %pos1, %check_b ], [ %pos2_b, %take_b ]
  %i_next = add i64 %i, 1
  %done = icmp eq i64 %i_next, %m
  br i1 %done, label %exit, label %loop

exit:
  ret i64 %pos2
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %hex = alloca [65 x i8], align 1
  %inter = alloca [256 x i8], align 1
  %has_args = icmp sge i32 %argc, 2
  br i1 %has_args, label %check_flag, label %usage

usage:
  %u = call i32 @puts(ptr @USAGE)
  ret i32 1

check_flag:
  %arg1p = getelementptr ptr, ptr %argv, i64 1
  %arg1 = load ptr, ptr %arg1p, align 8
  %cmpf = call i32 @strcmp(ptr %arg1, ptr @FLAG_F)
  %is_file = icmp eq i32 %cmpf, 0
  br i1 %is_file, label %read_file, label %use_string

use_string:
  %slen = call i64 @strlen(ptr %arg1)
  br label %start_rounds

read_file:
  %has_path = icmp sge i32 %argc, 3
  br i1 %has_path, label %open_file, label %usage

open_file:
  %arg2p = getelementptr ptr, ptr %argv, i64 2
  %path = load ptr, ptr %arg2p, align 8
  %fp = call ptr @fopen(ptr %path, ptr @MODE_RB)
  %fp_null = icmp eq ptr %fp, null
  br i1 %fp_null, label %file_err, label %read_init

file_err:
  ret i32 1

read_init:
  %fbuf0 = call ptr @malloc(i64 4096)
  br label %read_loop

read_loop:
  %fbuf = phi ptr [ %fbuf0, %read_init ], [ %fbuf_next, %read_grow ], [ %fbuf, %read_check ]
  %fcap = phi i64 [ 4096, %read_init ], [ %fcap_next, %read_grow ], [ %fcap, %read_check ]
  %flen = phi i64 [ 0, %read_init ], [ %flen_next, %read_grow ], [ %flen_next, %read_check ]
  %space = sub i64 %fcap, %flen
  %dst = getelementptr i8, ptr %fbuf, i64 %flen
  %nread = call i64 @fread(ptr %dst, i64 1, i64 %space, ptr %fp)
  %flen_next = add i64 %flen, %nread
  %eof = icmp eq i64 %nread, 0
  br i1 %eof, label %read_done, label %read_check

read_check:
  %need = icmp eq i64 %flen_next, %fcap
  br i1 %need, label %read_grow, label %read_loop

read_grow:
  %fcap_next = shl i64 %fcap, 1
  %fbuf_next = call ptr @realloc(ptr %fbuf, i64 %fcap_next)
  br label %read_loop

read_done:
  %cl = call i32 @fclose(ptr %fp)
  br label %start_rounds

start_rounds:
  %init_ptr = phi ptr [ %arg1, %use_string ], [ %fbuf, %read_done ]
  %init_len = phi i64 [ %slen, %use_string ], [ %flen_next, %read_done ]
  %must_free = phi i1 [ false, %use_string ], [ true, %read_done ]
  br label %round_loop

round_loop:
  %r = phi i64 [ 0, %start_rounds ], [ %r_next, %round_loop ]
  %cur_ptr = phi ptr [ %init_ptr, %start_rounds ], [ %inter, %round_loop ]
  %cur_len = phi i64 [ %init_len, %start_rounds ], [ %new_len, %round_loop ]
  call void @sha256(ptr %cur_ptr, i64 %cur_len, ptr %hex)
  call void @reverse_suffix(ptr %hex)
  %sidx = urem i64 %r, 10
  %sp_ptr = getelementptr [10 x ptr], ptr @SALTS, i64 0, i64 %sidx
  %sptr = load ptr, ptr %sp_ptr, align 8
  %sl_ptr = getelementptr [10 x i64], ptr @SALT_LENS, i64 0, i64 %sidx
  %slen_r = load i64, ptr %sl_ptr, align 8
  %new_len = call i64 @interleave(ptr %hex, i64 64, ptr %sptr, i64 %slen_r, ptr %inter)
  %r_next = add i64 %r, 1
  %r_done = icmp eq i64 %r_next, 35
  br i1 %r_done, label %final_hash, label %round_loop

final_hash:
  call void @sha256(ptr %inter, i64 %new_len, ptr %hex)
  call void @reverse_suffix(ptr %hex)
  %nul = getelementptr [65 x i8], ptr %hex, i64 0, i64 64
  store i8 0, ptr %nul, align 1
  %p = call i32 @puts(ptr %hex)
  br i1 %must_free, label %do_free, label %done

do_free:
  call void @free(ptr %init_ptr)
  br label %done

done:
  ret i32 0
}
