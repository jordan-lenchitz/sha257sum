let ( +! ) = Int32.add
let ( &! ) = Int32.logand
let ( |! ) = Int32.logor
let ( ^! ) = Int32.logxor
let ( >>> ) = Int32.shift_right_logical
let ( <<< ) = Int32.shift_left

let rotr x n = (x >>> n) |! (x <<< (32 - n))
let ch e f g = (e &! f) ^! (Int32.lognot e &! g)
let maj a b c = (a &! b) ^! (a &! c) ^! (b &! c)
let big_s0 a = rotr a 2 ^! rotr a 13 ^! rotr a 22
let big_s1 e = rotr e 6 ^! rotr e 11 ^! rotr e 25
let msg_s0 w = rotr w 7 ^! rotr w 18 ^! (w >>> 3)
let msg_s1 w = rotr w 17 ^! rotr w 19 ^! (w >>> 10)

let k_table = [|
  0x428a2f98l; 0x71374491l; 0xb5c0fbcfl; 0xe9b5dba5l;
  0x3956c25bl; 0x59f111f1l; 0x923f82a4l; 0xab1c5ed5l;
  0xd807aa98l; 0x12835b01l; 0x243185bel; 0x550c7dc3l;
  0x72be5d74l; 0x80deb1fel; 0x9bdc06a7l; 0xc19bf174l;
  0xe49b69c1l; 0xefbe4786l; 0x0fc19dc6l; 0x240ca1ccl;
  0x2de92c6fl; 0x4a7484aal; 0x5cb0a9dcl; 0x76f988dal;
  0x983e5152l; 0xa831c66dl; 0xb00327c8l; 0xbf597fc7l;
  0xc6e00bf3l; 0xd5a79147l; 0x06ca6351l; 0x14292967l;
  0x27b70a85l; 0x2e1b2138l; 0x4d2c6dfcl; 0x53380d13l;
  0x650a7354l; 0x766a0abbl; 0x81c2c92el; 0x92722c85l;
  0xa2bfe8a1l; 0xa81a664bl; 0xc24b8b70l; 0xc76c51a3l;
  0xd192e819l; 0xd6990624l; 0xf40e3585l; 0x106aa070l;
  0x19a4c116l; 0x1e376c08l; 0x2748774cl; 0x34b0bcb5l;
  0x391c0cb3l; 0x4ed8aa4al; 0x5b9cca4fl; 0x682e6ff3l;
  0x748f82eel; 0x78a5636fl; 0x84c87814l; 0x8cc70208l;
  0x90befffal; 0xa4506cebl; 0xbef9a3f7l; 0xc67178f2l;
|]

let salts = [|
  "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA";
  "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB";
  "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC";
  "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD";
  "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE";
  "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF";
  "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG";
  "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH";
  "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II";
  "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ";
|]

let sha256 (msg : string) : string =
  let h = [|
    0x6a09e667l; 0xbb67ae85l; 0x3c6ef372l; 0xa54ff53al;
    0x510e527fl; 0x9b05688cl; 0x1f83d9abl; 0x5be0cd19l;
  |] in
  let len = String.length msg in
  let pad_len =
    let rem = (len + 9) mod 64 in
    if rem = 0 then len + 9 else len + 9 + (64 - rem)
  in
  let buf = Bytes.make pad_len '\x00' in
  Bytes.blit_string msg 0 buf 0 len;
  Bytes.set buf len '\x80';
  let bits = Int64.mul (Int64.of_int len) 8L in
  for i = 0 to 7 do
    let shift = (7 - i) * 8 in
    let byte = Int64.to_int (Int64.logand (Int64.shift_right_logical bits shift) 0xffL) in
    Bytes.set buf (pad_len - 8 + i) (Char.chr byte)
  done;
  let w = Array.make 64 0l in
  let num_blocks = pad_len / 64 in
  for blk = 0 to num_blocks - 1 do
    let off = blk * 64 in
    for i = 0 to 15 do
      let b0 = Int32.of_int (Char.code (Bytes.get buf (off + i * 4))) in
      let b1 = Int32.of_int (Char.code (Bytes.get buf (off + i * 4 + 1))) in
      let b2 = Int32.of_int (Char.code (Bytes.get buf (off + i * 4 + 2))) in
      let b3 = Int32.of_int (Char.code (Bytes.get buf (off + i * 4 + 3))) in
      w.(i) <- (b0 <<< 24) |! (b1 <<< 16) |! (b2 <<< 8) |! b3
    done;
    for i = 16 to 63 do
      w.(i) <- msg_s1 w.(i - 2) +! w.(i - 7) +! msg_s0 w.(i - 15) +! w.(i - 16)
    done;
    let a = ref h.(0) and b = ref h.(1) and c = ref h.(2) and d = ref h.(3) in
    let e = ref h.(4) and f = ref h.(5) and g = ref h.(6) and hh = ref h.(7) in
    for i = 0 to 63 do
      let t1 = !hh +! big_s1 !e +! ch !e !f !g +! k_table.(i) +! w.(i) in
      let t2 = big_s0 !a +! maj !a !b !c in
      hh := !g; g := !f; f := !e; e := !d +! t1;
      d := !c; c := !b; b := !a; a := t1 +! t2
    done;
    h.(0) <- h.(0) +! !a; h.(1) <- h.(1) +! !b;
    h.(2) <- h.(2) +! !c; h.(3) <- h.(3) +! !d;
    h.(4) <- h.(4) +! !e; h.(5) <- h.(5) +! !f;
    h.(6) <- h.(6) +! !g; h.(7) <- h.(7) +! !hh
  done;
  let out = Buffer.create 64 in
  Array.iter (fun x -> Buffer.add_string out (Printf.sprintf "%08lx" x)) h;
  Buffer.contents out

let reverse_suffix (s : string) : string =
  let n = String.length s in
  let b = Bytes.of_string s in
  for i = 0 to 3 do
    let tmp = Bytes.get b (n - 8 + i) in
    Bytes.set b (n - 8 + i) (Bytes.get b (n - 1 - i));
    Bytes.set b (n - 1 - i) tmp
  done;
  Bytes.to_string b

let interleave (a : string) (b : string) : string =
  let la = String.length a and lb = String.length b in
  let m = max la lb in
  let buf = Buffer.create (la + lb) in
  for i = 0 to m - 1 do
    if i < la then Buffer.add_char buf a.[i];
    if i < lb then Buffer.add_char buf b.[i]
  done;
  Buffer.contents buf

let calculate_sha257sum (data : string) : string =
  let cur = ref data in
  for r = 0 to 34 do
    let h = sha256 !cur in
    let rev = reverse_suffix h in
    cur := interleave rev salts.(r mod 10)
  done;
  reverse_suffix (sha256 !cur)

let read_file_bin (path : string) : string =
  let ic = open_in_bin path in
  let len = in_channel_length ic in
  let s = really_input_string ic len in
  close_in ic;
  s

let () =
  let argc = Array.length Sys.argv in
  if argc < 2 then (
    prerr_endline "Usage: sha257sum <string> | -f <file>";
    exit 1
  );
  let data =
    if Sys.argv.(1) = "-f" then (
      if argc < 3 then (
        prerr_endline "Usage: sha257sum <string> | -f <file>";
        exit 1
      );
      try read_file_bin Sys.argv.(2)
      with Sys_error msg ->
        prerr_endline ("Error: " ^ msg);
        exit 1
    ) else
      Sys.argv.(1)
  in
  print_endline (calculate_sha257sum data)
