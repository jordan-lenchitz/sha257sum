MODULE sha257sum;

FROM SYSTEM IMPORT ADR, BITSET32, CARDINAL32, CARDINAL64, SHIFT;
FROM Args IMPORT GetArg, Narg;
FROM FIO IMPORT File, StdOut, StdErr, OpenToRead, IsNoError, ReadNBytes, Close,
                WriteString, WriteLine, FlushOutErr;
FROM StrLib IMPORT StrLen, StrEqual;

CONST
  FULL32 = BITSET32{0..31};

TYPE
  StateArr = ARRAY [0..7] OF BITSET32;
  KArr     = ARRAY [0..63] OF BITSET32;
  BlockArr = ARRAY [0..63] OF CARDINAL;
  HexArr   = ARRAY [0..64] OF CHAR;
  InterArr = ARRAY [0..255] OF CHAR;
  SaltStr  = ARRAY [0..79] OF CHAR;

VAR
  K     : KArr;
  Salts : ARRAY [0..9] OF SaltStr;
  HexCh : ARRAY [0..15] OF CHAR;

  shaState : StateArr;
  shaTotal : CARDINAL64;
  shaBlen  : CARDINAL;
  shaBlock : BlockArr;

  hexBuf   : HexArr;
  interBuf : InterArr;
  interLen : CARDINAL;
  ioBuf    : ARRAY [0..4095] OF CHAR;
  arg1     : ARRAY [0..4095] OF CHAR;
  arg2     : ARRAY [0..4095] OF CHAR;

PROCEDURE Add32(a, b: BITSET32): BITSET32;
VAR
  ua, ub, sum: CARDINAL64;
BEGIN
  ua := VAL(CARDINAL64, VAL(CARDINAL32, a));
  ub := VAL(CARDINAL64, VAL(CARDINAL32, b));
  sum := (ua + ub) MOD 4294967296;
  RETURN VAL(BITSET32, VAL(CARDINAL32, sum))
END Add32;

PROCEDURE Rotr(x: BITSET32; n: INTEGER): BITSET32;
BEGIN
  RETURN SHIFT(x, -n) + SHIFT(x, 32 - n)
END Rotr;

PROCEDURE BigS0(a: BITSET32): BITSET32;
BEGIN
  RETURN Rotr(a, 2) / Rotr(a, 13) / Rotr(a, 22)
END BigS0;

PROCEDURE BigS1(e: BITSET32): BITSET32;
BEGIN
  RETURN Rotr(e, 6) / Rotr(e, 11) / Rotr(e, 25)
END BigS1;

PROCEDURE MsgS0(w: BITSET32): BITSET32;
BEGIN
  RETURN Rotr(w, 7) / Rotr(w, 18) / SHIFT(w, -3)
END MsgS0;

PROCEDURE MsgS1(w: BITSET32): BITSET32;
BEGIN
  RETURN Rotr(w, 17) / Rotr(w, 19) / SHIFT(w, -10)
END MsgS1;

PROCEDURE ShaCh(e, f, g: BITSET32): BITSET32;
BEGIN
  RETURN (e * f) / ((FULL32 - e) * g)
END ShaCh;

PROCEDURE ShaMaj(a, b, c: BITSET32): BITSET32;
BEGIN
  RETURN (a * b) / (a * c) / (b * c)
END ShaMaj;

PROCEDURE W32(v: CARDINAL64): BITSET32;
BEGIN
  RETURN VAL(BITSET32, VAL(CARDINAL32, v))
END W32;

PROCEDURE InitConstants;
BEGIN
  HexCh := "0123456789abcdef";

  K[0]  := W32(0428A2F98H); K[1]  := W32(071374491H); K[2]  := W32(0B5C0FBCFH); K[3]  := W32(0E9B5DBA5H);
  K[4]  := W32(03956C25BH); K[5]  := W32(059F111F1H); K[6]  := W32(0923F82A4H); K[7]  := W32(0AB1C5ED5H);
  K[8]  := W32(0D807AA98H); K[9]  := W32(012835B01H); K[10] := W32(0243185BEH); K[11] := W32(0550C7DC3H);
  K[12] := W32(072BE5D74H); K[13] := W32(080DEB1FEH); K[14] := W32(09BDC06A7H); K[15] := W32(0C19BF174H);
  K[16] := W32(0E49B69C1H); K[17] := W32(0EFBE4786H); K[18] := W32(00FC19DC6H); K[19] := W32(0240CA1CCH);
  K[20] := W32(02DE92C6FH); K[21] := W32(04A7484AAH); K[22] := W32(05CB0A9DCH); K[23] := W32(076F988DAH);
  K[24] := W32(0983E5152H); K[25] := W32(0A831C66DH); K[26] := W32(0B00327C8H); K[27] := W32(0BF597FC7H);
  K[28] := W32(0C6E00BF3H); K[29] := W32(0D5A79147H); K[30] := W32(006CA6351H); K[31] := W32(014292967H);
  K[32] := W32(027B70A85H); K[33] := W32(02E1B2138H); K[34] := W32(04D2C6DFCH); K[35] := W32(053380D13H);
  K[36] := W32(0650A7354H); K[37] := W32(0766A0ABBH); K[38] := W32(081C2C92EH); K[39] := W32(092722C85H);
  K[40] := W32(0A2BFE8A1H); K[41] := W32(0A81A664BH); K[42] := W32(0C24B8B70H); K[43] := W32(0C76C51A3H);
  K[44] := W32(0D192E819H); K[45] := W32(0D6990624H); K[46] := W32(0F40E3585H); K[47] := W32(0106AA070H);
  K[48] := W32(019A4C116H); K[49] := W32(01E376C08H); K[50] := W32(02748774CH); K[51] := W32(034B0BCB5H);
  K[52] := W32(0391C0CB3H); K[53] := W32(04ED8AA4AH); K[54] := W32(05B9CCA4FH); K[55] := W32(0682E6FF3H);
  K[56] := W32(0748F82EEH); K[57] := W32(078A5636FH); K[58] := W32(084C87814H); K[59] := W32(08CC70208H);
  K[60] := W32(090BEFFFAH); K[61] := W32(0A4506CEBH); K[62] := W32(0BEF9A3F7H); K[63] := W32(0C67178F2H);

  Salts[0] := "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA";
  Salts[1] := "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB";
  Salts[2] := "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC";
  Salts[3] := "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD";
  Salts[4] := "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE";
  Salts[5] := "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF";
  Salts[6] := "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG";
  Salts[7] := "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH";
  Salts[8] := "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II";
  Salts[9] := "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"
END InitConstants;

PROCEDURE Sha256Init;
BEGIN
  shaState[0] := W32(06A09E667H);
  shaState[1] := W32(0BB67AE85H);
  shaState[2] := W32(03C6EF372H);
  shaState[3] := W32(0A54FF53AH);
  shaState[4] := W32(0510E527FH);
  shaState[5] := W32(09B05688CH);
  shaState[6] := W32(01F83D9ABH);
  shaState[7] := W32(05BE0CD19H);
  shaTotal := 0;
  shaBlen  := 0
END Sha256Init;

PROCEDURE Sha256Compress;
VAR
  W: ARRAY [0..63] OF BITSET32;
  a, b, c, d, e, f, g, h, t1, t2: BITSET32;
  i, p: CARDINAL;
BEGIN
  FOR i := 0 TO 15 DO
    p := i * 4;
    W[i] := SHIFT(W32(shaBlock[p]), 24)
          + SHIFT(W32(shaBlock[p + 1]), 16)
          + SHIFT(W32(shaBlock[p + 2]), 8)
          + W32(shaBlock[p + 3])
  END;

  FOR i := 16 TO 63 DO
    W[i] := Add32(Add32(W[i - 16], MsgS0(W[i - 15])),
                  Add32(W[i - 7],  MsgS1(W[i - 2])))
  END;

  a := shaState[0]; b := shaState[1]; c := shaState[2]; d := shaState[3];
  e := shaState[4]; f := shaState[5]; g := shaState[6]; h := shaState[7];

  FOR i := 0 TO 63 DO
    t1 := Add32(Add32(Add32(h, BigS1(e)), Add32(ShaCh(e, f, g), K[i])), W[i]);
    t2 := Add32(BigS0(a), ShaMaj(a, b, c));
    h := g; g := f; f := e; e := Add32(d, t1);
    d := c; c := b; b := a; a := Add32(t1, t2)
  END;

  shaState[0] := Add32(shaState[0], a);
  shaState[1] := Add32(shaState[1], b);
  shaState[2] := Add32(shaState[2], c);
  shaState[3] := Add32(shaState[3], d);
  shaState[4] := Add32(shaState[4], e);
  shaState[5] := Add32(shaState[5], f);
  shaState[6] := Add32(shaState[6], g);
  shaState[7] := Add32(shaState[7], h)
END Sha256Compress;

PROCEDURE Sha256Update(VAR data: ARRAY OF CHAR; len: CARDINAL);
VAR
  i: CARDINAL;
BEGIN
  IF len = 0 THEN RETURN END;
  shaTotal := shaTotal + VAL(CARDINAL64, len);
  FOR i := 0 TO len - 1 DO
    shaBlock[shaBlen] := ORD(data[i]);
    INC(shaBlen);
    IF shaBlen = 64 THEN
      Sha256Compress;
      shaBlen := 0
    END
  END
END Sha256Update;

PROCEDURE Sha256Final;
VAR
  bits: CARDINAL64;
  i, j, nib: CARDINAL;
  w: CARDINAL32;
BEGIN
  bits := shaTotal * 8;
  shaBlock[shaBlen] := 080H;
  INC(shaBlen);

  IF shaBlen > 56 THEN
    WHILE shaBlen < 64 DO
      shaBlock[shaBlen] := 0;
      INC(shaBlen)
    END;
    Sha256Compress;
    shaBlen := 0
  END;

  WHILE shaBlen < 56 DO
    shaBlock[shaBlen] := 0;
    INC(shaBlen)
  END;

  FOR i := 0 TO 7 DO
    shaBlock[63 - i] := VAL(CARDINAL, bits MOD 256);
    bits := bits DIV 256
  END;

  Sha256Compress;

  FOR i := 0 TO 7 DO
    w := VAL(CARDINAL32, shaState[i]);
    FOR j := 0 TO 7 DO
      nib := VAL(CARDINAL, w MOD 16);
      hexBuf[i * 8 + (7 - j)] := HexCh[nib];
      w := w DIV 16
    END
  END;
  hexBuf[64] := 0C
END Sha256Final;

PROCEDURE ReverseSuffix;
VAR
  i: CARDINAL;
  tmp: CHAR;
BEGIN
  FOR i := 0 TO 3 DO
    tmp := hexBuf[56 + i];
    hexBuf[56 + i] := hexBuf[63 - i];
    hexBuf[63 - i] := tmp
  END
END ReverseSuffix;

PROCEDURE InterleaveSalt(saltIdx: CARDINAL);
VAR
  slen, maxLen, i: CARDINAL;
BEGIN
  slen := StrLen(Salts[saltIdx]);
  IF slen > 64 THEN maxLen := slen ELSE maxLen := 64 END;
  interLen := 0;
  FOR i := 0 TO maxLen - 1 DO
    IF i < 64 THEN
      interBuf[interLen] := hexBuf[i];
      INC(interLen)
    END;
    IF i < slen THEN
      interBuf[interLen] := Salts[saltIdx][i];
      INC(interLen)
    END
  END
END InterleaveSalt;

PROCEDURE RunRounds;
VAR
  r: CARDINAL;
BEGIN
  FOR r := 0 TO 34 DO
    ReverseSuffix;
    InterleaveSalt(r MOD 10);
    Sha256Init;
    Sha256Update(interBuf, interLen);
    Sha256Final
  END;
  ReverseSuffix
END RunRounds;

PROCEDURE HashFile(VAR path: ARRAY OF CHAR);
VAR
  f: File;
  n: CARDINAL;
BEGIN
  f := OpenToRead(path);
  IF NOT IsNoError(f) THEN
    WriteString(StdErr, "Error: could not open file");
    WriteLine(StdErr);
    FlushOutErr;
    HALT(1)
  END;
  Sha256Init;
  LOOP
    n := ReadNBytes(f, 4096, ADR(ioBuf));
    IF n = 0 THEN EXIT END;
    Sha256Update(ioBuf, n)
  END;
  Close(f);
  Sha256Final
END HashFile;

BEGIN
  InitConstants;
  IF Narg() < 2 THEN
    WriteString(StdErr, "Usage: sha257sum <string> | -f <file>");
    WriteLine(StdErr);
    FlushOutErr;
    HALT(1)
  END;

  IF NOT GetArg(arg1, 1) THEN HALT(1) END;

  IF StrEqual(arg1, "-f") THEN
    IF (Narg() < 3) OR (NOT GetArg(arg2, 2)) THEN
      WriteString(StdErr, "Error: missing filename after -f");
      WriteLine(StdErr);
      FlushOutErr;
      HALT(1)
    END;
    HashFile(arg2)
  ELSE
    Sha256Init;
    Sha256Update(arg1, StrLen(arg1));
    Sha256Final
  END;

  RunRounds;
  WriteString(StdOut, hexBuf);
  WriteLine(StdOut);
  FlushOutErr
END sha257sum.
