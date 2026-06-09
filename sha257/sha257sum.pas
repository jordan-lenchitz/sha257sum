program sha257sum;

{$mode objfpc}{$H+}

uses
  sysutils, classes;

type
  TUInt32Array = array[0..63] of LongWord;
  TByteArray = array of Byte;

function RightRotate(n, b: LongWord): LongWord;
begin
  Result := (n shr b) or (n shl (32 - b));
end;

function Ch(e, f, g: LongWord): LongWord;
begin
  Result := (e and f) xor ((not e) and g);
end;

function Maj(a, b, c: LongWord): LongWord;
begin
  Result := (a and b) xor (a and c) xor (b and c);
end;

function S0Func(a: LongWord): LongWord;
begin
  Result := RightRotate(a, 2) xor RightRotate(a, 13) xor RightRotate(a, 22);
end;

function S1Func(e: LongWord): LongWord;
begin
  Result := RightRotate(e, 6) xor RightRotate(e, 11) xor RightRotate(e, 25);
end;

function MsgS0(w: LongWord): LongWord;
begin
  Result := RightRotate(w, 7) xor RightRotate(w, 18) xor (w shr 3);
end;

function MsgS1(w: LongWord): LongWord;
begin
  Result := RightRotate(w, 17) xor RightRotate(w, 19) xor (w shr 10);
end;

const
  K: array[0..63] of LongWord = (
    $428a2f98, $71374491, $b5c0fbcf, $e9b5dba5, $3956c25b, $59f111f1, $923f82a4, $ab1c5ed5,
    $d807aa98, $12835b01, $243185be, $550c7dc3, $72be5d74, $80deb1fe, $9bdc06a7, $c19bf174,
    $e49b69c1, $efbe4786, $0fc19dc6, $240ca1cc, $2de92c6f, $4a7484aa, $5cb0a9dc, $76f988da,
    $983e5152, $a831c66d, $b00327c8, $bf597fc7, $c6e00bf3, $d5a79147, $06ca6351, $14292967,
    $27b70a85, $2e1b2138, $4d2c6dfc, $53380d13, $650a7354, $766a0abb, $81c2c92e, $92722c85,
    $a2bfe8a1, $a81a664b, $c24b8b70, $c76c51a3, $d192e819, $d6990624, $f40e3585, $106aa070,
    $19a4c116, $1e376c08, $2748774c, $34b0bcb5, $391c0cb3, $4ed8aa4a, $5b9cca4f, $682e6ff3,
    $748f82ee, $78a5636f, $84c87814, $8cc70208, $90befffa, $a4506ceb, $bef9a3f7, $c67178f2
  );

function Sha256Compute(msg: TByteArray): string;
var
  h: array[0..7] of LongWord;
  bits: UInt64;
  padded: TByteArray;
  len, i, j: integer;
  offset: integer;
  w: TUInt32Array;
  a, b, c, d, e, f, g, hh, t1, t2: LongWord;
begin
  h[0] := $6a09e667; h[1] := $bb67ae85; h[2] := $3c6ef372; h[3] := $a54ff53a;
  h[4] := $510e527f; h[5] := $9b05688c; h[6] := $1f83d9ab; h[7] := $5be0cd19;

  len := Length(msg);
  bits := UInt64(len) * 8;
  
  SetLength(padded, len + 1);
  for i := 0 to len - 1 do padded[i] := msg[i];
  padded[len] := $80;
  
  while (Length(padded) mod 64) <> 56 do
  begin
    SetLength(padded, Length(padded) + 1);
    padded[High(padded)] := 0;
  end;
  
  for i := 7 downto 0 do
  begin
    SetLength(padded, Length(padded) + 1);
    padded[High(padded)] := Byte((bits shr (i * 8)) and $FF);
  end;
  
  offset := 0;
  while offset < Length(padded) do
  begin
    for j := 0 to 15 do
      w[j] := (LongWord(padded[offset + j*4]) shl 24) or
              (LongWord(padded[offset + j*4 + 1]) shl 16) or
              (LongWord(padded[offset + j*4 + 2]) shl 8) or
              (LongWord(padded[offset + j*4 + 3]));
              
    for j := 16 to 63 do
      w[j] := MsgS1(w[j-2]) + w[j-7] + MsgS0(w[j-15]) + w[j-16];
      
    a := h[0]; b := h[1]; c := h[2]; d := h[3];
    e := h[4]; f := h[5]; g := h[6]; hh := h[7];
    
    for j := 0 to 63 do
    begin
      t1 := hh + S1Func(e) + Ch(e, f, g) + K[j] + w[j];
      t2 := S0Func(a) + Maj(a, b, c);
      hh := g; g := f; f := e; e := d + t1;
      d := c; c := b; b := a; a := t1 + t2;
    end;
    
    h[0] := h[0] + a; h[1] := h[1] + b; h[2] := h[2] + c; h[3] := h[3] + d;
    h[4] := h[4] + e; h[5] := h[5] + f; h[6] := h[6] + g; h[7] := h[7] + hh;
    
    inc(offset, 64);
  end;
  
  Result := '';
  for i := 0 to 7 do Result := Result + IntToHex(h[i], 8);
  Result := LowerCase(Result);
end;

const
  SALTS: array[0..9] of string = (
    'jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA',
    'jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB',
    'jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC',
    'jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD',
    'jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE',
    'jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF',
    'jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG',
    'jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH',
    'jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II',
    'jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ'
  );

function Interleave(hash, salt: string): TByteArray;
var
  hl, sl, ml, i, j: integer;
begin
  hl := Length(hash);
  sl := Length(salt);
  if hl > sl then ml := hl else ml := sl;
  SetLength(Result, 0);
  j := 0;
  for i := 1 to ml do
  begin
    if i <= hl then
    begin
      SetLength(Result, j + 1);
      Result[j] := Byte(hash[i]);
      inc(j);
    end;
    if i <= sl then
    begin
      SetLength(Result, j + 1);
      Result[j] := Byte(salt[i]);
      inc(j);
    end;
  end;
end;

function ReverseSuffix(hash: string): string;
var
  prefix, suffix: string;
  i: integer;
begin
  prefix := Copy(hash, 1, Length(hash) - 8);
  suffix := Copy(hash, Length(hash) - 7, 8);
  Result := prefix;
  for i := 8 downto 1 do Result := Result + suffix[i];
end;

function CalculateSha257Sum(data: TByteArray): string;
var
  current: TByteArray;
  salt_indices: array[0..34] of integer = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4);
  i: integer;
  h: string;
begin
  current := data;
  for i := 0 to 34 do
  begin
    h := Sha256Compute(current);
    h := ReverseSuffix(h);
    current := Interleave(h, SALTS[salt_indices[i]]);
  end;
  h := Sha256Compute(current);
  Result := ReverseSuffix(h);
end;

var
  input: TByteArray;
  s: string;
  i: integer;
  F: TFileStream;
begin
  if ParamCount < 1 then
  begin
    writeln('Usage: ./sha257sum <string_or_-f_file>');
    halt(1);
  end;
  
  if ParamStr(1) = '-f' then
  begin
    if ParamCount < 2 then halt(1);
    F := TFileStream.Create(ParamStr(2), fmOpenRead);
    try
      SetLength(input, F.Size);
      if F.Size > 0 then F.Read(input[0], F.Size);
    finally
      F.Free;
    end;
  end
  else
  begin
    s := ParamStr(1);
    SetLength(input, Length(s));
    for i := 1 to Length(s) do input[i-1] := Byte(s[i]);
  end;
  
  writeln(CalculateSha257Sum(input));
end.
