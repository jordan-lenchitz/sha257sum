bits 64
default rel

%define SYS_READ   0
%define SYS_WRITE  1
%define SYS_OPEN   2
%define SYS_CLOSE  3
%define SYS_EXIT   60
%define O_RDONLY   0

section .rodata

align 4
SHA256_H0:
    dd 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
    dd 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

align 4
SHA256_K:
    dd 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
    dd 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
    dd 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
    dd 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
    dd 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc
    dd 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
    dd 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7
    dd 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
    dd 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13
    dd 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
    dd 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3
    dd 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
    dd 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5
    dd 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
    dd 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208
    dd 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

HEX_CHARS:
    db "0123456789abcdef"

salt0: db "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
salt0_len equ $ - salt0
salt1: db "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
salt1_len equ $ - salt1
salt2: db "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
salt2_len equ $ - salt2
salt3: db "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
salt3_len equ $ - salt3
salt4: db "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
salt4_len equ $ - salt4
salt5: db "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
salt5_len equ $ - salt5
salt6: db "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
salt6_len equ $ - salt6
salt7: db "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
salt7_len equ $ - salt7
salt8: db "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
salt8_len equ $ - salt8
salt9: db "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"
salt9_len equ $ - salt9

align 8
SALT_PTRS:
    dq salt0, salt1, salt2, salt3, salt4
    dq salt5, salt6, salt7, salt8, salt9

align 8
SALT_LENS:
    dq salt0_len, salt1_len, salt2_len, salt3_len, salt4_len
    dq salt5_len, salt6_len, salt7_len, salt8_len, salt9_len

usage_msg:
    db "Usage: sha257sum <string> | -f <file>", 10
usage_len equ $ - usage_msg

open_err_msg:
    db "Error: could not open file", 10
open_err_len equ $ - open_err_msg

section .bss

align 8
sha_state:     resd 8
sha_total_len: resq 1
sha_buf_len:   resq 1
sha_block:     resb 64

hex_buf:       resb 65          ; 64 hex chars + trailing newline
inter_buf:     resb 256         ; max interleaved len is 64 + 73 = 137
io_buf:        resb 4096        ; streaming file read buffer

section .text
global _start

_start:
    ; Linux x86-64 process entry stack layout:
    ; [rsp]      = argc
    ; [rsp + 8]  = argv[0]
    ; [rsp + 16] = argv[1]
    ; [rsp + 24] = argv[2]
    mov rbx, [rsp]              ; rbx = argc
    cmp rbx, 2
    jl .usage_error

    mov r12, [rsp + 16]         ; r12 = argv[1]

    ; Check if argv[1] == "-f"
    cmp byte [r12], '-'
    jne .hash_string
    cmp byte [r12 + 1], 'f'
    jne .hash_string
    cmp byte [r12 + 2], 0
    jne .hash_string

    ; File mode: require argc >= 3
    cmp rbx, 3
    jl .usage_error
    mov r13, [rsp + 24]         ; r13 = filename (argv[2])

    ; open(filename, O_RDONLY, 0)
    mov eax, SYS_OPEN
    mov rdi, r13
    xor esi, esi                ; O_RDONLY = 0
    xor edx, edx
    syscall
    test rax, rax
    js .open_error
    mov r14, rax                ; r14 = fd

    call sha256_init

.read_loop:
    mov eax, SYS_READ
    mov rdi, r14
    lea rsi, [io_buf]
    mov edx, 4096
    syscall
    test rax, rax
    js .read_error
    jz .read_done

    lea rdi, [io_buf]
    mov rsi, rax
    call sha256_update
    jmp .read_loop

.read_error:
    mov eax, SYS_CLOSE
    mov rdi, r14
    syscall
    jmp .open_error

.read_done:
    mov eax, SYS_CLOSE
    mov rdi, r14
    syscall
    lea rdi, [hex_buf]
    call sha256_final
    jmp .run_rounds

.hash_string:
    ; Compute strlen(argv[1])
    mov rdi, r12
    xor rcx, rcx
.strlen_loop:
    cmp byte [rdi + rcx], 0
    je .strlen_done
    inc rcx
    jmp .strlen_loop
.strlen_done:
    push rcx
    call sha256_init
    pop rsi                     ; len
    mov rdi, r12                ; ptr
    call sha256_update
    lea rdi, [hex_buf]
    call sha256_final

.run_rounds:
    ; 35 super stupid processing blocks:
    ; for round = 0..34:
    ;   reverse last 8 chars of hex_buf
    ;   interleave hex_buf (64) with SALTS[round % 10] -> inter_buf
    ;   hex_buf = sha256(inter_buf, inter_len)
    xor r12d, r12d              ; round = 0
    xor r13d, r13d              ; salt_idx = 0 (cycles 0..9)

.round_loop:
    cmp r12d, 35
    jge .rounds_done

    ; Reverse last 8 chars of hex_buf
    call reverse_suffix

    ; Interleave hex_buf (64 bytes) with SALT_PTRS[r13] (length SALT_LENS[r13])
    lea r8, [SALT_PTRS]
    mov rdi, [r8 + r13*8]       ; salt ptr
    lea r8, [SALT_LENS]
    mov rsi, [r8 + r13*8]       ; salt len
    call interleave_with_hex    ; returns interleaved length in rax

    ; Hash inter_buf[0..rax-1] -> hex_buf
    push rax
    call sha256_init
    lea rdi, [inter_buf]
    pop rsi
    call sha256_update
    lea rdi, [hex_buf]
    call sha256_final

    inc r12d
    inc r13d
    cmp r13d, 10
    jl .round_loop
    xor r13d, r13d
    jmp .round_loop

.rounds_done:
    ; Final suffix reversal and write to stdout
    call reverse_suffix
    mov byte [hex_buf + 64], 10 ; '\n'

    mov eax, SYS_WRITE
    mov edi, 1                  ; stdout
    lea rsi, [hex_buf]
    mov edx, 65
    syscall

    mov eax, SYS_EXIT
    xor edi, edi
    syscall

.usage_error:
    mov eax, SYS_WRITE
    mov edi, 2                  ; stderr
    lea rsi, [usage_msg]
    mov edx, usage_len
    syscall
    mov eax, SYS_EXIT
    mov edi, 1
    syscall

.open_error:
    mov eax, SYS_WRITE
    mov edi, 2                  ; stderr
    lea rsi, [open_err_msg]
    mov edx, open_err_len
    syscall
    mov eax, SYS_EXIT
    mov edi, 1
    syscall


reverse_suffix:
    lea rax, [hex_buf + 56]
    mov dl, [rax]
    mov cl, [rax + 7]
    mov [rax], cl
    mov [rax + 7], dl
    mov dl, [rax + 1]
    mov cl, [rax + 6]
    mov [rax + 1], cl
    mov [rax + 6], dl
    mov dl, [rax + 2]
    mov cl, [rax + 5]
    mov [rax + 2], cl
    mov [rax + 5], dl
    mov dl, [rax + 3]
    mov cl, [rax + 4]
    mov [rax + 3], cl
    mov [rax + 4], dl
    ret

interleave_with_hex:
    lea r8, [hex_buf]
    lea r9, [inter_buf]
    xor rcx, rcx                ; k = 0
    xor rdx, rdx                ; out_idx = 0

    ; ml = max(64, salt_len)
    mov r10, 64
    cmp rsi, r10
    cmovg r10, rsi

.il_loop:
    cmp rcx, r10
    jge .il_done

    cmp rcx, 64
    jge .il_check_salt
    mov al, [r8 + rcx]
    mov [r9 + rdx], al
    inc rdx

.il_check_salt:
    cmp rcx, rsi
    jge .il_next
    mov al, [rdi + rcx]
    mov [r9 + rdx], al
    inc rdx

.il_next:
    inc rcx
    jmp .il_loop

.il_done:
    mov rax, rdx
    ret


sha256_init:
    lea rsi, [SHA256_H0]
    lea rdi, [sha_state]
    mov ecx, 8
.init_loop:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .init_loop

    mov qword [sha_total_len], 0
    mov qword [sha_buf_len], 0
    ret

sha256_update:
    push rbx
    push r12
    push r13

    mov r12, rdi                ; data ptr
    mov r13, rsi                ; remaining bytes
    add [sha_total_len], r13

.upd_loop:
    test r13, r13
    jz .upd_done

    mov rbx, [sha_buf_len]
    lea rdi, [sha_block]
    mov al, [r12]
    mov [rdi + rbx], al
    inc r12
    inc rbx
    dec r13

    cmp rbx, 64
    jne .upd_store_len

    ; Block full: compress sha_block
    lea rdi, [sha_block]
    call sha256_compress
    xor rbx, rbx

.upd_store_len:
    mov [sha_buf_len], rbx
    jmp .upd_loop

.upd_done:
    pop r13
    pop r12
    pop rbx
    ret


sha256_final:
    push rbx
    push r12
    mov r12, rdi                ; hex_out ptr

    mov rbx, [sha_buf_len]
    lea rdi, [sha_block]
    mov byte [rdi + rbx], 0x80
    inc rbx

    ; If buf_len > 56, zero rest of block, compress, and start fresh block
    cmp rbx, 56
    jle .pad_zeros

.zero_tail:
    cmp rbx, 64
    jge .compress_first
    mov byte [rdi + rbx], 0
    inc rbx
    jmp .zero_tail

.compress_first:
    call sha256_compress
    xor rbx, rbx
    lea rdi, [sha_block]

.pad_zeros:
    cmp rbx, 56
    jge .write_bitlen
    mov byte [rdi + rbx], 0
    inc rbx
    jmp .pad_zeros

.write_bitlen:
    mov rax, [sha_total_len]
    shl rax, 3                  ; bits = bytes * 8
    bswap rax                   ; 64-bit big-endian
    mov [rdi + 56], rax
    call sha256_compress

    ; Convert sha_state[0..7] to 64 lowercase ASCII hex digits
    lea rsi, [sha_state]
    lea r8, [HEX_CHARS]
    xor rcx, rcx                ; word index 0..7
.hex_word_loop:
    mov eax, [rsi + rcx*4]
    mov edx, 8                  ; 8 nibbles per 32-bit word
.hex_nib_loop:
    rol eax, 4
    mov ebx, eax
    and ebx, 0x0f
    mov bl, [r8 + rbx]
    mov [r12], bl
    inc r12
    dec edx
    jnz .hex_nib_loop

    inc rcx
    cmp rcx, 8
    jl .hex_word_loop

    pop r12
    pop rbx
    ret


sha256_compress:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 256                ; W[0..63] (64 * 4 bytes)

    ; Load W[0..15] from big-endian block
    xor rcx, rcx
.load_w:
    mov eax, [rdi + rcx*4]
    bswap eax
    mov [rsp + rcx*4], eax
    inc rcx
    cmp rcx, 16
    jl .load_w

    ; Expand W[16..63]
.expand_w:
    ; s0 = ror(w[i-15], 7) ^ ror(w[i-15], 18) ^ (w[i-15] >> 3)
    mov eax, [rsp + rcx*4 - 60]
    mov edx, eax
    ror edx, 7
    mov ebx, eax
    ror ebx, 18
    shr eax, 3
    xor eax, edx
    xor eax, ebx

    ; s1 = ror(w[i-2], 17) ^ ror(w[i-2], 19) ^ (w[i-2] >> 10)
    mov esi, [rsp + rcx*4 - 8]
    mov edx, esi
    ror edx, 17
    mov ebx, esi
    ror ebx, 19
    shr esi, 10
    xor esi, edx
    xor esi, ebx

    add eax, esi
    add eax, [rsp + rcx*4 - 64] ; + w[i-16]
    add eax, [rsp + rcx*4 - 28] ; + w[i-7]
    mov [rsp + rcx*4], eax

    inc rcx
    cmp rcx, 64
    jl .expand_w

    ; Load working state a..h into r8d..r15d
    lea rsi, [sha_state]
    mov r8d,  [rsi]             ; a
    mov r9d,  [rsi + 4]         ; b
    mov r10d, [rsi + 8]         ; c
    mov r11d, [rsi + 12]        ; d
    mov r12d, [rsi + 16]        ; e
    mov r13d, [rsi + 20]        ; f
    mov r14d, [rsi + 24]        ; g
    mov r15d, [rsi + 28]        ; h

    lea rdi, [SHA256_K]
    xor rcx, rcx                ; round 0..63

.compress_loop:
    ; S1(e) = ror(e, 6) ^ ror(e, 11) ^ ror(e, 25)
    mov eax, r12d
    ror eax, 6
    mov edx, r12d
    ror edx, 11
    xor eax, edx
    mov edx, r12d
    ror edx, 25
    xor eax, edx

    ; ch(e, f, g) = (e & f) ^ (~e & g)
    mov edx, r12d
    and edx, r13d
    mov ebx, r12d
    not ebx
    and ebx, r14d
    xor edx, ebx

    ; t1 (ebp) = h + S1(e) + ch + K[i] + W[i]
    mov ebp, r15d
    add ebp, eax
    add ebp, edx
    add ebp, [rdi + rcx*4]
    add ebp, [rsp + rcx*4]

    ; S0(a) = ror(a, 2) ^ ror(a, 13) ^ ror(a, 22)
    mov eax, r8d
    ror eax, 2
    mov edx, r8d
    ror edx, 13
    xor eax, edx
    mov edx, r8d
    ror edx, 22
    xor eax, edx

    ; maj(a, b, c) = (a & b) ^ (a & c) ^ (b & c)
    mov edx, r8d
    and edx, r9d
    mov ebx, r8d
    and ebx, r10d
    xor edx, ebx
    mov ebx, r9d
    and ebx, r10d
    xor edx, ebx

    ; t2 (eax) = S0(a) + maj(a, b, c)
    add eax, edx

    ; Shift registers
    mov r15d, r14d              ; h = g
    mov r14d, r13d              ; g = f
    mov r13d, r12d              ; f = e
    mov r12d, r11d
    add r12d, ebp               ; e = d + t1
    mov r11d, r10d              ; d = c
    mov r10d, r9d               ; c = b
    mov r9d,  r8d               ; b = a
    mov r8d,  ebp
    add r8d,  eax               ; a = t1 + t2

    inc rcx
    cmp rcx, 64
    jl .compress_loop

    ; Accumulate into sha_state
    add [rsi],      r8d
    add [rsi + 4],  r9d
    add [rsi + 8],  r10d
    add [rsi + 12], r11d
    add [rsi + 16], r12d
    add [rsi + 20], r13d
    add [rsi + 24], r14d
    add [rsi + 28], r15d

    add rsp, 256
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
