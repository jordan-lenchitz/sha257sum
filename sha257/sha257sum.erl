#!/usr/bin/env escript
%%! -noshell

-define(M32, 16#ffffffff).

k_tuple() ->
    {16#428a2f98, 16#71374491, 16#b5c0fbcf, 16#e9b5dba5,
     16#3956c25b, 16#59f111f1, 16#923f82a4, 16#ab1c5ed5,
     16#d807aa98, 16#12835b01, 16#243185be, 16#550c7dc3,
     16#72be5d74, 16#80deb1fe, 16#9bdc06a7, 16#c19bf174,
     16#e49b69c1, 16#efbe4786, 16#0fc19dc6, 16#240ca1cc,
     16#2de92c6f, 16#4a7484aa, 16#5cb0a9dc, 16#76f988da,
     16#983e5152, 16#a831c66d, 16#b00327c8, 16#bf597fc7,
     16#c6e00bf3, 16#d5a79147, 16#06ca6351, 16#14292967,
     16#27b70a85, 16#2e1b2138, 16#4d2c6dfc, 16#53380d13,
     16#650a7354, 16#766a0abb, 16#81c2c92e, 16#92722c85,
     16#a2bfe8a1, 16#a81a664b, 16#c24b8b70, 16#c76c51a3,
     16#d192e819, 16#d6990624, 16#f40e3585, 16#106aa070,
     16#19a4c116, 16#1e376c08, 16#2748774c, 16#34b0bcb5,
     16#391c0cb3, 16#4ed8aa4a, 16#5b9cca4f, 16#682e6ff3,
     16#748f82ee, 16#78a5636f, 16#84c87814, 16#8cc70208,
     16#90befffa, 16#a4506ceb, 16#bef9a3f7, 16#c67178f2}.

salts() ->
    {<<"jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA">>,
     <<"jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB">>,
     <<"jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC">>,
     <<"jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD">>,
     <<"jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE">>,
     <<"jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF">>,
     <<"jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG">>,
     <<"jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH">>,
     <<"jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II">>,
     <<"jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ">>}.

rotr(X, N) ->
    ((X bsr N) bor ((X bsl (32 - N)) band ?M32)) band ?M32.

pad(Bin) ->
    Len = byte_size(Bin),
    Rem = (Len + 9) rem 64,
    Zeros = case Rem of 0 -> 0; _ -> 64 - Rem end,
    <<Bin/binary, 16#80:8, 0:(Zeros * 8), (Len * 8):64/big-unsigned-integer>>.

expand_words(Block) ->
    W0 = [W || <<W:32/big-unsigned-integer>> <= Block],
    expand_loop(16, list_to_tuple(W0 ++ lists:duplicate(48, 0))).

expand_loop(64, W) ->
    W;
expand_loop(I, W) ->
    W15 = element(I - 14, W),
    W2  = element(I - 1, W),
    S0 = rotr(W15, 7) bxor rotr(W15, 18) bxor (W15 bsr 3),
    S1 = rotr(W2, 17) bxor rotr(W2, 19) bxor (W2 bsr 10),
    Val = (element(I - 15, W) + S0 + element(I - 6, W) + S1) band ?M32,
    expand_loop(I + 1, setelement(I + 1, W, Val)).

compress(64, _W, _K, State) ->
    State;
compress(I, W, K, {A, B, C, D, E, F, G, H}) ->
    S1 = rotr(E, 6) bxor rotr(E, 11) bxor rotr(E, 25),
    Ch = (E band F) bxor ((bnot E band ?M32) band G),
    T1 = (H + S1 + Ch + element(I + 1, K) + element(I + 1, W)) band ?M32,
    S0 = rotr(A, 2) bxor rotr(A, 13) bxor rotr(A, 22),
    Maj = (A band B) bxor (A band C) bxor (B band C),
    T2 = (S0 + Maj) band ?M32,
    compress(I + 1, W, K, {(T1 + T2) band ?M32, A, B, C, (D + T1) band ?M32, E, F, G}).

hash_blocks(<<>>, State, _K) ->
    State;
hash_blocks(<<Block:64/binary, Rest/binary>>, {H0, H1, H2, H3, H4, H5, H6, H7}, K) ->
    W = expand_words(Block),
    {A, B, C, D, E, F, G, H} = compress(0, W, K, {H0, H1, H2, H3, H4, H5, H6, H7}),
    Next = {(H0 + A) band ?M32, (H1 + B) band ?M32, (H2 + C) band ?M32, (H3 + D) band ?M32,
            (H4 + E) band ?M32, (H5 + F) band ?M32, (H6 + G) band ?M32, (H7 + H) band ?M32},
    hash_blocks(Rest, Next, K).

hex_word(W) ->
    list_to_binary(io_lib:format("~8.16.0b", [W])).

sha256(Bin, K) ->
    Init = {16#6a09e667, 16#bb67ae85, 16#3c6ef372, 16#a54ff53a,
            16#510e527f, 16#9b05688c, 16#1f83d9ab, 16#5be0cd19},
    Res = hash_blocks(pad(Bin), Init, K),
    iolist_to_binary([hex_word(W) || W <- tuple_to_list(Res)]).

reverse_suffix(<<Prefix:56/binary, C0, C1, C2, C3, C4, C5, C6, C7>>) ->
    <<Prefix/binary, C7, C6, C5, C4, C3, C2, C1, C0>>.

interleave(A, B) ->
    interleave_loop(A, B, []).

interleave_loop(<<>>, <<>>, Acc) ->
    iolist_to_binary(lists:reverse(Acc));
interleave_loop(<<A, RA/binary>>, <<B, RB/binary>>, Acc) ->
    interleave_loop(RA, RB, [B, A | Acc]);
interleave_loop(<<A, RA/binary>>, <<>>, Acc) ->
    interleave_loop(RA, <<>>, [A | Acc]);
interleave_loop(<<>>, <<B, RB/binary>>, Acc) ->
    interleave_loop(<<>>, RB, [B | Acc]).

rounds(35, Data, _Salts, K) ->
    reverse_suffix(sha256(Data, K));
rounds(R, Data, Salts, K) ->
    Rev = reverse_suffix(sha256(Data, K)),
    Next = interleave(Rev, element((R rem 10) + 1, Salts)),
    rounds(R + 1, Next, Salts, K).

main(["-f", Path]) ->
    case file:read_file(Path) of
        {ok, Bin} ->
            io:format("~s~n", [rounds(0, Bin, salts(), k_tuple())]);
        {error, Reason} ->
            io:format(standard_error, "Error: ~p~n", [Reason]),
            halt(1)
    end;
main([Str]) ->
    Bin = unicode:characters_to_binary(Str),
    io:format("~s~n", [rounds(0, Bin, salts(), k_tuple())]);
main(_) ->
    io:format(standard_error, "Usage: escript sha257sum.erl <string> | -f <file>~n", []),
    halt(1).
