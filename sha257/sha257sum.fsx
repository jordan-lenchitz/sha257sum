open System
open System.IO
open System.Text

let K: uint32 array = [|
    0x428a2f98u; 0x71374491u; 0xb5c0fbcfu; 0xe9b5dba5u; 0x3956c25bu; 0x59f111f1u; 0x923f82a4u; 0xab1c5ed5u
    0xd807aa98u; 0x12835b01u; 0x243185beu; 0x550c7dc3u; 0x72be5d74u; 0x80deb1feu; 0x9bdc06a7u; 0xc19bf174u
    0xe49b69c1u; 0xefbe4786u; 0x0fc19dc6u; 0x240ca1ccu; 0x2de92c6fu; 0x4a7484aau; 0x5cb0a9dcu; 0x76f988dau
    0x983e5152u; 0xa831c66du; 0xb00327c8u; 0xbf597fc7u; 0xc6e00bf3u; 0xd5a79147u; 0x06ca6351u; 0x14292967u
    0x27b70a85u; 0x2e1b2138u; 0x4d2c6dfcu; 0x53380d13u; 0x650a7354u; 0x766a0abbu; 0x81c2c92eu; 0x92722c85u
    0xa2bfe8a1u; 0xa81a664bu; 0xc24b8b70u; 0xc76c51a3u; 0xd192e819u; 0xd6990624u; 0xf40e3585u; 0x106aa070u
    0x19a4c116u; 0x1e376c08u; 0x2748774cu; 0x34b0bcb5u; 0x391c0cb3u; 0x4ed8aa4au; 0x5b9cca4fu; 0x682e6ff3u
    0x748f82eeu; 0x78a5636fu; 0x84c87814u; 0x8cc70208u; 0x90befffau; 0xa4506cebu; 0xbef9a3f7u; 0xc67178f2u
|]

let salts: string array = [|
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
|]

let inline rotr (n: uint32) (b: int) = (n >>> b) ||| (n <<< (32 - b))
let inline ch e f g = (e &&& f) ^^^ ((~~~e) &&& g)
let inline maj a b c = (a &&& b) ^^^ (a &&& c) ^^^ (b &&& c)
let inline s0 a = rotr a 2 ^^^ rotr a 13 ^^^ rotr a 22
let inline s1 e = rotr e 6 ^^^ rotr e 11 ^^^ rotr e 25
let inline msgS0 w = rotr w 7 ^^^ rotr w 18 ^^^ (w >>> 3)
let inline msgS1 w = rotr w 17 ^^^ rotr w 19 ^^^ (w >>> 10)

let sha256 (msg: byte array) : string =
    let h = [|
        0x6a09e667u; 0xbb67ae85u; 0x3c6ef372u; 0xa54ff53au
        0x510e527fu; 0x9b05688cu; 0x1f83d9abu; 0x5be0cd19u
    |]

    let mutable newLen = msg.Length + 1
    while newLen % 64 <> 56 do
        newLen <- newLen + 1
    newLen <- newLen + 8

    let padded = Array.zeroCreate<byte> newLen
    Array.Copy(msg, padded, msg.Length)
    padded.[msg.Length] <- 0x80uy

    let bits = uint64 msg.Length * 8UL
    for i = 0 to 7 do
        padded.[newLen - 1 - i] <- byte ((bits >>> (i * 8)) &&& 0xFFUL)

    let w = Array.zeroCreate<uint32> 64
    let mutable offset = 0
    while offset < newLen do
        for i = 0 to 15 do
            w.[i] <-
                (uint32 padded.[offset + i * 4] <<< 24)
                ||| (uint32 padded.[offset + i * 4 + 1] <<< 16)
                ||| (uint32 padded.[offset + i * 4 + 2] <<< 8)
                ||| uint32 padded.[offset + i * 4 + 3]
        for i = 16 to 63 do
            w.[i] <- msgS1 w.[i - 2] + w.[i - 7] + msgS0 w.[i - 15] + w.[i - 16]

        let mutable a = h.[0]
        let mutable b = h.[1]
        let mutable c = h.[2]
        let mutable d = h.[3]
        let mutable e = h.[4]
        let mutable f = h.[5]
        let mutable g = h.[6]
        let mutable hh = h.[7]

        for i = 0 to 63 do
            let t1 = hh + s1 e + ch e f g + K.[i] + w.[i]
            let t2 = s0 a + maj a b c
            hh <- g
            g <- f
            f <- e
            e <- d + t1
            d <- c
            c <- b
            b <- a
            a <- t1 + t2

        h.[0] <- h.[0] + a
        h.[1] <- h.[1] + b
        h.[2] <- h.[2] + c
        h.[3] <- h.[3] + d
        h.[4] <- h.[4] + e
        h.[5] <- h.[5] + f
        h.[6] <- h.[6] + g
        h.[7] <- h.[7] + hh
        offset <- offset + 64

    h |> Array.map (fun x -> x.ToString("x8")) |> String.concat ""

let reverseLast8 (hex: string) : string =
    let prefix = hex.Substring(0, 56)
    let suffix = hex.Substring(56, 8).ToCharArray() |> Array.rev |> String
    prefix + suffix

let interleave (a: byte array) (b: byte array) : byte array =
    let maxLen = max a.Length b.Length
    let out = Array.zeroCreate<byte> (a.Length + b.Length)
    let mutable ptr = 0
    for i = 0 to maxLen - 1 do
        if i < a.Length then
            out.[ptr] <- a.[i]
            ptr <- ptr + 1
        if i < b.Length then
            out.[ptr] <- b.[i]
            ptr <- ptr + 1
    out

let sha257sum (data: byte array) : string =
    let mutable buf = data
    for i = 0 to 34 do
        let inter = sha256 buf |> reverseLast8
        let hashBytes = Encoding.UTF8.GetBytes(inter)
        let saltBytes = Encoding.UTF8.GetBytes(salts.[i % 10])
        buf <- interleave hashBytes saltBytes
    sha256 buf |> reverseLast8

let rawArgs = fsi.CommandLineArgs |> Array.skip 1
let args =
    if rawArgs.Length > 0 && rawArgs.[0] = "--" then rawArgs |> Array.skip 1
    else rawArgs

match args with
| [| "-f"; path |] ->
    File.ReadAllBytes(path) |> sha257sum |> printf "%s\n"
| [| str |] ->
    Encoding.UTF8.GetBytes(str) |> sha257sum |> printf "%s\n"
| _ ->
    eprintfn "Usage: dotnet fsi sha257sum.fsx -- [-f <file> | <string>]"
    Environment.Exit(1)
