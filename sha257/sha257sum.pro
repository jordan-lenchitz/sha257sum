:- use_module(library(lists)).

% SHA-256 round constants
k_consts([
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
]).

% Initial hash values
init_hash([0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
           0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]).

% The 10 cyclic salts
salts([
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
]).

% 32-bit helpers
ror32(X, N, R) :-
    L is 32 - N,
    R is ((X >> N) \/ ((X /\ 0xFFFFFFFF) << L)) /\ 0xFFFFFFFF.

% SHA-256 boolean functions
ch(E, F, G, R) :-
    NotE is (\ E) /\ 0xFFFFFFFF,
    R is ((E /\ F) xor (NotE /\ G)) /\ 0xFFFFFFFF.

maj(A, B, C, R) :-
    R is ((A /\ B) xor (A /\ C) xor (B /\ C)) /\ 0xFFFFFFFF.

sigma0(A, R) :-
    ror32(A,  2, R0), ror32(A, 13, R1), ror32(A, 22, R2),
    R is R0 xor R1 xor R2.

sigma1(E, R) :-
    ror32(E,  6, R0), ror32(E, 11, R1), ror32(E, 25, R2),
    R is R0 xor R1 xor R2.

msg_sigma0(W, R) :-
    ror32(W, 7, R0), ror32(W, 18, R1),
    R is (R0 xor R1 xor (W >> 3)) /\ 0xFFFFFFFF.

msg_sigma1(W, R) :-
    ror32(W, 17, R0), ror32(W, 19, R1),
    R is (R0 xor R1 xor (W >> 10)) /\ 0xFFFFFFFF.

% Convert 4 bytes (big-endian) to a Word32
bytes_to_word32([B0,B1,B2,B3], W) :-
    W is (B0 << 24) \/ (B1 << 16) \/ (B2 << 8) \/ B3.

% Split a list into chunks of N elements
chunks_of(_, [], []).
chunks_of(N, List, [Chunk|Rest]) :-
    length(Chunk, N),
    append(Chunk, Tail, List),
    chunks_of(N, Tail, Rest).

% Extend 16-word initial block to 64-word message schedule
extend_schedule(S, S) :- length(S, 64), !.
extend_schedule(S, Final) :-
    length(S, N), N < 64,
    N2  is N - 2,  nth0(N2,  S, Wn2),
    N7  is N - 7,  nth0(N7,  S, Wn7),
    N15 is N - 15, nth0(N15, S, Wn15),
    N16 is N - 16, nth0(N16, S, Wn16),
    msg_sigma1(Wn2, MS1), msg_sigma0(Wn15, MS0),
    W is (MS1 + Wn7 + MS0 + Wn16) /\ 0xFFFFFFFF,
    append(S, [W], SNext),
    extend_schedule(SNext, Final).

% 64-round SHA-256 compression
compress([], [], State, State).
compress([W|Ws], [Kc|Ks], [A,B,C,D,E,F,G,H], Final) :-
    sigma1(E, Sig1), ch(E, F, G, Ch),
    sigma0(A, Sig0), maj(A, B, C, Mj),
    T1 is (H + Sig1 + Ch + Kc + W) /\ 0xFFFFFFFF,
    T2 is (Sig0 + Mj) /\ 0xFFFFFFFF,
    NA is (T1 + T2) /\ 0xFFFFFFFF,
    NE is (D  + T1) /\ 0xFFFFFFFF,
    compress(Ws, Ks, [NA,A,B,C,NE,E,F,G], Final).

% Add two hash states element-wise (mod 2^32)
add_states([], [], []).
add_states([A|As], [B|Bs], [C|Cs]) :-
    C is (A + B) /\ 0xFFFFFFFF,
    add_states(As, Bs, Cs).

% Process one 64-byte block
process_block(Block, H, K, HNew) :-
    chunks_of(4, Block, ByteGroups),
    maplist(bytes_to_word32, ByteGroups, W16),
    extend_schedule(W16, W64),
    compress(W64, K, H, HComp),
    add_states(H, HComp, HNew).

% Process all 64-byte blocks against running hash
process_blocks([], H, _, H).
process_blocks(Data, H, K, HFinal) :-
    Data \= [],
    length(Block, 64),
    append(Block, Rest, Data),
    process_block(Block, H, K, H1),
    process_blocks(Rest, H1, K, HFinal).

% SHA-256 message padding
pad_message(Msg, Padded) :-
    length(Msg, Len),
    BitLen is Len * 8,
    PadLen is (55 - Len) mod 64,
    length(Zeros, PadLen), maplist(=(0), Zeros),
    B7 is (BitLen >> 56) /\ 0xFF, B6 is (BitLen >> 48) /\ 0xFF,
    B5 is (BitLen >> 40) /\ 0xFF, B4 is (BitLen >> 32) /\ 0xFF,
    B3 is (BitLen >> 24) /\ 0xFF, B2 is (BitLen >> 16) /\ 0xFF,
    B1 is (BitLen >>  8) /\ 0xFF, B0 is  BitLen         /\ 0xFF,
    append(Msg, [0x80|Zeros], Tmp),
    append(Tmp, [B7,B6,B5,B4,B3,B2,B1,B0], Padded).

% Format Word32 as 8-char lowercase zero-padded hex
word_hex8(W, Hex) :-
    format(string(Hex), '~`0t~16r~8|', [W]).

% SHA-256: byte list → 64-char hex string
sha256(Bytes, HexStr) :-
    pad_message(Bytes, Padded),
    init_hash(H0),
    k_consts(K),
    process_blocks(Padded, H0, K, HFinal),
    maplist(word_hex8, HFinal, Parts),
    atomic_list_concat(Parts, HexStr).

% Reverse last 8 characters of a 64-char hex string
reverse_last8(HexStr, Result) :-
    string_codes(HexStr, Codes),
    length(Front56, 56),
    append(Front56, Last8, Codes),
    reverse(Last8, RevLast8),
    append(Front56, RevLast8, ResultCodes),
    string_codes(Result, ResultCodes).

% Interleave two byte lists element by element
interleave([], Ys, Ys).
interleave(Xs, [], Xs).
interleave([X|Xs], [Y|Ys], [X,Y|Rest]) :-
    interleave(Xs, Ys, Rest).

% One super stupid processing block
stupid_block(Buf, Round, NewBuf) :-
    sha256(Buf, HexStr),
    reverse_last8(HexStr, Modified),
    string_codes(Modified, HashBytes),
    salts(Salts),
    Idx is Round mod 10,
    nth0(Idx, Salts, SaltStr),
    string_codes(SaltStr, SaltBytes),
    interleave(HashBytes, SaltBytes, NewBuf).

% 35 rounds of super stupid processing
pipeline(Buf, 35, Buf) :- !.
pipeline(Buf, Round, Final) :-
    Round < 35,
    stupid_block(Buf, Round, NewBuf),
    Next is Round + 1,
    pipeline(NewBuf, Next, Final).

% Read file as list of byte codes
read_file_bytes(Filename, Bytes) :-
    read_file_to_codes(Filename, Bytes, [encoding(octet)]).

:- initialization(main, main).

main :-
    current_prolog_flag(argv, Argv),
    ( Argv = ['-f', File | _] ->
        atom_string(File, FileStr),
        read_file_bytes(FileStr, Bytes)
    ; Argv = [Input | _] ->
        atom_codes(Input, Bytes)
    ;
        Bytes = []
    ),
    pipeline(Bytes, 0, Result),
    sha256(Result, HexStr),
    reverse_last8(HexStr, Final),
    writeln(Final).
