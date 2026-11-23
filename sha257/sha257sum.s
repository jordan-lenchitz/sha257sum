.option norelax

.equ SYS_OPENAT, 56
.equ SYS_CLOSE,  57
.equ SYS_READ,   63
.equ SYS_WRITE,  64
.equ SYS_EXIT,   93
.equ AT_FDCWD,   -100
.equ O_RDONLY,   0

.macro rotr32 dst, src, n, tmp
    srlw \dst, \src, \n
    sllw \tmp, \src, (32 - \n)
    or   \dst, \dst, \tmp
.endm

.section .rodata
.balign 4
SHA256_H0:
    .word 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
    .word 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

.balign 4
SHA256_K:
    .word 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
    .word 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
    .word 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
    .word 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
    .word 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc
    .word 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
    .word 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7
    .word 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
    .word 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13
    .word 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
    .word 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3
    .word 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
    .word 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5
    .word 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
    .word 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208
    .word 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

HEX_CHARS:
    .ascii "0123456789abcdef"

salt0: .ascii "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
.equ salt0_len, . - salt0
salt1: .ascii "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
.equ salt1_len, . - salt1
salt2: .ascii "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
.equ salt2_len, . - salt2
salt3: .ascii "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
.equ salt3_len, . - salt3
salt4: .ascii "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
.equ salt4_len, . - salt4
salt5: .ascii "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
.equ salt5_len, . - salt5
salt6: .ascii "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
.equ salt6_len, . - salt6
salt7: .ascii "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
.equ salt7_len, . - salt7
salt8: .ascii "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
.equ salt8_len, . - salt8
salt9: .ascii "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"
.equ salt9_len, . - salt9

.balign 8
SALT_PTRS:
    .dword salt0, salt1, salt2, salt3, salt4
    .dword salt5, salt6, salt7, salt8, salt9

.balign 8
SALT_LENS:
    .dword salt0_len, salt1_len, salt2_len, salt3_len, salt4_len
    .dword salt5_len, salt6_len, salt7_len, salt8_len, salt9_len

usage_msg:
    .ascii "Usage: sha257sum <string> | -f <file>\n"
.equ usage_len, . - usage_msg

open_err_msg:
    .ascii "Error: could not open file\n"
.equ open_err_len, . - open_err_msg

.section .bss
.balign 8
sha_state:     .space 32
sha_total_len: .space 8
sha_buf_len:   .space 8
sha_block:     .space 64
hex_buf:       .space 65
inter_buf:     .space 256
io_buf:        .space 4096

.section .text
.globl _start

_start:
    ld   s0, 0(sp)              # s0 = argc
    li   t0, 2
    blt  s0, t0, .usage_error

    ld   s1, 16(sp)             # s1 = argv[1]

    # Check if argv[1] == "-f"
    lbu  t0, 0(s1)
    li   t1, '-'
    bne  t0, t1, .hash_string
    lbu  t0, 1(s1)
    li   t1, 'f'
    bne  t0, t1, .hash_string
    lbu  t0, 2(s1)
    bnez t0, .hash_string

    # File mode: require argc >= 3
    li   t0, 3
    blt  s0, t0, .usage_error
    ld   s2, 24(sp)             # s2 = argv[2] (filename)

    # openat(AT_FDCWD, filename, O_RDONLY, 0)
    li   a7, SYS_OPENAT
    li   a0, AT_FDCWD
    mv   a1, s2
    li   a2, O_RDONLY
    li   a3, 0
    ecall
    bltz a0, .open_error
    mv   s3, a0                 # s3 = fd

    call sha256_init

.read_loop:
    li   a7, SYS_READ
    mv   a0, s3
    la   a1, io_buf
    li   a2, 4096
    ecall
    bltz a0, .read_error
    beqz a0, .read_done

    mv   a1, a0
    la   a0, io_buf
    call sha256_update
    j    .read_loop

.read_error:
    li   a7, SYS_CLOSE
    mv   a0, s3
    ecall
    j    .open_error

.read_done:
    li   a7, SYS_CLOSE
    mv   a0, s3
    ecall
    la   a0, hex_buf
    call sha256_final
    j    .run_rounds

.hash_string:
    # Compute strlen(argv[1])
    mv   t0, s1
    li   s2, 0
.strlen_loop:
    add  t1, t0, s2
    lbu  t2, 0(t1)
    beqz t2, .strlen_done
    addi s2, s2, 1
    j    .strlen_loop
.strlen_done:
    call sha256_init
    mv   a0, s1
    mv   a1, s2
    call sha256_update
    la   a0, hex_buf
    call sha256_final

.run_rounds:
    li   s0, 0                  # round = 0..34
    li   s1, 0                  # salt_idx = 0..9

.round_loop:
    li   t0, 35
    bge  s0, t0, .rounds_done

    call reverse_suffix

    slli t0, s1, 3
    la   t1, SALT_PTRS
    add  t1, t1, t0
    ld   a0, 0(t1)              # salt ptr
    la   t2, SALT_LENS
    add  t2, t2, t0
    ld   a1, 0(t2)              # salt len
    call interleave_with_hex
    mv   s2, a0                 # interleaved length

    call sha256_init
    la   a0, inter_buf
    mv   a1, s2
    call sha256_update
    la   a0, hex_buf
    call sha256_final

    addi s0, s0, 1
    addi s1, s1, 1
    li   t0, 10
    blt  s1, t0, .round_loop
    li   s1, 0
    j    .round_loop

.rounds_done:
    call reverse_suffix
    la   t0, hex_buf
    li   t1, 10                 # '\n'
    sb   t1, 64(t0)

    li   a7, SYS_WRITE
    li   a0, 1
    la   a1, hex_buf
    li   a2, 65
    ecall

    li   a7, SYS_EXIT
    li   a0, 0
    ecall

.usage_error:
    li   a7, SYS_WRITE
    li   a0, 2
    la   a1, usage_msg
    li   a2, usage_len
    ecall
    li   a7, SYS_EXIT
    li   a0, 1
    ecall

.open_error:
    li   a7, SYS_WRITE
    li   a0, 2
    la   a1, open_err_msg
    li   a2, open_err_len
    ecall
    li   a7, SYS_EXIT
    li   a0, 1
    ecall


reverse_suffix:
    la   t0, hex_buf
    addi t0, t0, 56
    lbu  t1, 0(t0)
    lbu  t2, 7(t0)
    sb   t2, 0(t0)
    sb   t1, 7(t0)
    lbu  t1, 1(t0)
    lbu  t2, 6(t0)
    sb   t2, 1(t0)
    sb   t1, 6(t0)
    lbu  t1, 2(t0)
    lbu  t2, 5(t0)
    sb   t2, 2(t0)
    sb   t1, 5(t0)
    lbu  t1, 3(t0)
    lbu  t2, 4(t0)
    sb   t2, 3(t0)
    sb   t1, 4(t0)
    ret


interleave_with_hex:
    # a0 = salt_ptr, a1 = salt_len -> returns out_len in a0
    la   t0, hex_buf
    la   t1, inter_buf
    li   t2, 0                  # k = 0
    li   t3, 0                  # out_idx = 0
    li   t4, 64                 # max_len = max(64, salt_len)
    bge  t4, a1, .il_loop
    mv   t4, a1

.il_loop:
    bge  t2, t4, .il_done

    li   t5, 64
    bge  t2, t5, .il_check_salt
    add  t5, t0, t2
    lbu  t6, 0(t5)
    add  t5, t1, t3
    sb   t6, 0(t5)
    addi t3, t3, 1

.il_check_salt:
    bge  t2, a1, .il_next
    add  t5, a0, t2
    lbu  t6, 0(t5)
    add  t5, t1, t3
    sb   t6, 0(t5)
    addi t3, t3, 1

.il_next:
    addi t2, t2, 1
    j    .il_loop

.il_done:
    mv   a0, t3
    ret


sha256_init:
    la   t0, SHA256_H0
    la   t1, sha_state
    li   t2, 8
.init_loop:
    lw   t3, 0(t0)
    sw   t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    addi t2, t2, -1
    bnez t2, .init_loop

    la   t0, sha_total_len
    sd   zero, 0(t0)
    la   t0, sha_buf_len
    sd   zero, 0(t0)
    ret


sha256_update:
    # a0 = data_ptr, a1 = len
    addi sp, sp, -32
    sd   ra, 24(sp)
    sd   s0, 16(sp)
    sd   s1, 8(sp)
    sd   s2, 0(sp)

    mv   s0, a0                 # data_ptr
    mv   s1, a1                 # remaining

    la   t0, sha_total_len
    ld   t1, 0(t0)
    add  t1, t1, s1
    sd   t1, 0(t0)

.upd_loop:
    beqz s1, .upd_done

    la   t0, sha_buf_len
    ld   s2, 0(t0)
    la   t1, sha_block
    add  t2, t1, s2
    lbu  t3, 0(s0)
    sb   t3, 0(t2)

    addi s0, s0, 1
    addi s2, s2, 1
    addi s1, s1, -1

    li   t3, 64
    bne  s2, t3, .upd_store_len

    la   a0, sha_block
    call sha256_compress
    li   s2, 0

.upd_store_len:
    la   t0, sha_buf_len
    sd   s2, 0(t0)
    j    .upd_loop

.upd_done:
    ld   s2, 0(sp)
    ld   s1, 8(sp)
    ld   s0, 16(sp)
    ld   ra, 24(sp)
    addi sp, sp, 32
    ret


sha256_final:
    # a0 = hex_out_ptr
    addi sp, sp, -32
    sd   ra, 24(sp)
    sd   s0, 16(sp)
    sd   s1, 8(sp)
    sd   s2, 0(sp)

    mv   s2, a0                 # hex_out_ptr
    la   t0, sha_buf_len
    ld   s1, 0(t0)              # s1 = buf_len
    la   s0, sha_block

    add  t1, s0, s1
    li   t2, 0x80
    sb   t2, 0(t1)
    addi s1, s1, 1

    li   t2, 56
    ble  s1, t2, .pad_zeros

.zero_tail:
    li   t2, 64
    bge  s1, t2, .compress_first
    add  t1, s0, s1
    sb   zero, 0(t1)
    addi s1, s1, 1
    j    .zero_tail

.compress_first:
    mv   a0, s0
    call sha256_compress
    li   s1, 0

.pad_zeros:
    li   t2, 56
    bge  s1, t2, .write_bitlen
    add  t1, s0, s1
    sb   zero, 0(t1)
    addi s1, s1, 1
    j    .pad_zeros

.write_bitlen:
    la   t0, sha_total_len
    ld   t1, 0(t0)
    slli t1, t1, 3              # bits = bytes * 8
    srli t2, t1, 56
    sb   t2, 56(s0)
    srli t2, t1, 48
    sb   t2, 57(s0)
    srli t2, t1, 40
    sb   t2, 58(s0)
    srli t2, t1, 32
    sb   t2, 59(s0)
    srli t2, t1, 24
    sb   t2, 60(s0)
    srli t2, t1, 16
    sb   t2, 61(s0)
    srli t2, t1, 8
    sb   t2, 62(s0)
    sb   t1, 63(s0)

    mv   a0, s0
    call sha256_compress

    # Convert sha_state[0..7] to 64 hex chars at s2
    la   t0, sha_state
    la   t1, HEX_CHARS
    li   t2, 0                  # word idx 0..7
.hex_word_loop:
    slli t3, t2, 2
    add  t3, t0, t3
    lw   t4, 0(t3)              # 32-bit state word
    li   t5, 28                 # shift amount: 28, 24, ..., 0
.hex_nib_loop:
    srlw t6, t4, t5
    andi t6, t6, 0x0f
    add  t6, t1, t6
    lbu  t6, 0(t6)
    sb   t6, 0(s2)
    addi s2, s2, 1
    addi t5, t5, -4
    bgez t5, .hex_nib_loop

    addi t2, t2, 1
    li   t3, 8
    blt  t2, t3, .hex_word_loop

    ld   s2, 0(sp)
    ld   s1, 8(sp)
    ld   s0, 16(sp)
    ld   ra, 24(sp)
    addi sp, sp, 32
    ret


sha256_compress:
    # a0 = block_ptr (64 bytes)
    addi sp, sp, -336
    sd   s0,  256(sp)
    sd   s1,  264(sp)
    sd   s2,  272(sp)
    sd   s3,  280(sp)
    sd   s4,  288(sp)
    sd   s5,  296(sp)
    sd   s6,  304(sp)
    sd   s7,  312(sp)
    sd   s8,  320(sp)
    sd   s9,  328(sp)

    # Load W[0..15] big-endian from a0 into 0..60(sp)
    li   t0, 0
.load_w:
    slli t1, t0, 2
    add  t2, a0, t1
    lbu  t3, 0(t2)
    lbu  t4, 1(t2)
    lbu  t5, 2(t2)
    lbu  t6, 3(t2)
    slli t3, t3, 24
    slli t4, t4, 16
    slli t5, t5, 8
    or   t3, t3, t4
    or   t3, t3, t5
    or   t3, t3, t6
    add  t2, sp, t1
    sw   t3, 0(t2)
    addi t0, t0, 1
    li   t1, 16
    blt  t0, t1, .load_w

    # Expand W[16..63]
.expand_w:
    slli t1, t0, 2
    add  t1, sp, t1             # &W[i]

    # s0 = rotr(w[i-15], 7) ^ rotr(w[i-15], 18) ^ (w[i-15] >> 3)
    lw   t2, -60(t1)            # w[i-15]
    rotr32 t3, t2, 7, t6
    rotr32 t4, t2, 18, t6
    srlw t5, t2, 3
    xor  t3, t3, t4
    xor  t3, t3, t5             # t3 = s0

    # s1 = rotr(w[i-2], 17) ^ rotr(w[i-2], 19) ^ (w[i-2] >> 10)
    lw   t2, -8(t1)             # w[i-2]
    rotr32 t4, t2, 17, t6
    rotr32 t5, t2, 19, t6
    srlw t2, t2, 10
    xor  t4, t4, t5
    xor  t4, t4, t2             # t4 = s1

    lw   t5, -64(t1)            # w[i-16]
    lw   t6, -28(t1)            # w[i-7]
    addw t3, t3, t4
    addw t3, t3, t5
    addw t3, t3, t6
    sw   t3, 0(t1)

    addi t0, t0, 1
    li   t2, 64
    blt  t0, t2, .expand_w

    # Load working state a..h into s0..s7
    la   t0, sha_state
    lw   s0,  0(t0)             # a
    lw   s1,  4(t0)             # b
    lw   s2,  8(t0)             # c
    lw   s3, 12(t0)             # d
    lw   s4, 16(t0)             # e
    lw   s5, 20(t0)             # f
    lw   s6, 24(t0)             # g
    lw   s7, 28(t0)             # h

    la   s8, SHA256_K
    li   s9, 0                  # round = 0..63

.compress_loop:
    # S1(e) = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)
    rotr32 t0, s4, 6, t3
    rotr32 t1, s4, 11, t3
    rotr32 t2, s4, 25, t3
    xor  t0, t0, t1
    xor  t0, t0, t2             # t0 = S1(e)

    # ch(e, f, g) = (e & f) ^ (~e & g)
    and  t1, s4, s5
    not  t2, s4
    and  t2, t2, s6
    xor  t1, t1, t2             # t1 = ch

    # t1 (t4) = h + S1(e) + ch + K[i] + W[i]
    slli t2, s9, 2
    add  t3, s8, t2
    lw   t3, 0(t3)              # K[i]
    add  t5, sp, t2
    lw   t5, 0(t5)              # W[i]
    addw t4, s7, t0
    addw t4, t4, t1
    addw t4, t4, t3
    addw t4, t4, t5             # t4 = temp1

    # S0(a) = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)
    rotr32 t0, s0, 2, t3
    rotr32 t1, s0, 13, t3
    rotr32 t2, s0, 22, t3
    xor  t0, t0, t1
    xor  t0, t0, t2             # t0 = S0(a)

    # maj(a, b, c) = (a & b) ^ (a & c) ^ (b & c)
    and  t1, s0, s1
    and  t2, s0, s2
    xor  t1, t1, t2
    and  t2, s1, s2
    xor  t1, t1, t2             # t1 = maj

    addw t5, t0, t1             # t5 = temp2

    mv   s7, s6                 # h = g
    mv   s6, s5                 # g = f
    mv   s5, s4                 # f = e
    addw s4, s3, t4             # e = d + temp1
    mv   s3, s2                 # d = c
    mv   s2, s1                 # c = b
    mv   s1, s0                 # b = a
    addw s0, t4, t5             # a = temp1 + temp2

    addi s9, s9, 1
    li   t0, 64
    blt  s9, t0, .compress_loop

    la   t0, sha_state
    lw   t1,  0(t0)
    addw t1, t1, s0
    sw   t1,  0(t0)
    lw   t1,  4(t0)
    addw t1, t1, s1
    sw   t1,  4(t0)
    lw   t1,  8(t0)
    addw t1, t1, s2
    sw   t1,  8(t0)
    lw   t1, 12(t0)
    addw t1, t1, s3
    sw   t1, 12(t0)
    lw   t1, 16(t0)
    addw t1, t1, s4
    sw   t1, 16(t0)
    lw   t1, 20(t0)
    addw t1, t1, s5
    sw   t1, 20(t0)
    lw   t1, 24(t0)
    addw t1, t1, s6
    sw   t1, 24(t0)
    lw   t1, 28(t0)
    addw t1, t1, s7
    sw   t1, 28(t0)

    ld   s0,  256(sp)
    ld   s1,  264(sp)
    ld   s2,  272(sp)
    ld   s3,  280(sp)
    ld   s4,  288(sp)
    ld   s5,  296(sp)
    ld   s6,  304(sp)
    ld   s7,  312(sp)
    ld   s8,  320(sp)
    ld   s9,  328(sp)
    addi sp, sp, 336
    ret
