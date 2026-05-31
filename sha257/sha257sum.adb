with Ada.Text_IO;               use Ada.Text_IO;
with Ada.Command_Line;          use Ada.Command_Line;
with Ada.Strings.Unbounded;     use Ada.Strings.Unbounded;
with Ada.Sequential_IO;
with Ada.Unchecked_Deallocation;
with Interfaces;                use Interfaces;

procedure SHA257Sum is

   subtype Byte   is Unsigned_8;
   subtype Word32 is Unsigned_32;
   subtype Word64 is Unsigned_64;

   type Byte_Array        is array (Natural range <>) of Byte;
   type Byte_Array_Access is access Byte_Array;
   procedure Free is new Ada.Unchecked_Deallocation (Byte_Array, Byte_Array_Access);

   type Hash_Words  is array (0 ..  7) of Word32;
   type Sched_Words is array (0 .. 63) of Word32;

   package Byte_IO is new Ada.Sequential_IO (Byte);

   -- SHA-256 round constants
   K : constant Sched_Words :=
     (16#428a2f98#, 16#71374491#, 16#b5c0fbcf#, 16#e9b5dba5#,
      16#3956c25b#, 16#59f111f1#, 16#923f82a4#, 16#ab1c5ed5#,
      16#d807aa98#, 16#12835b01#, 16#243185be#, 16#550c7dc3#,
      16#72be5d74#, 16#80deb1fe#, 16#9bdc06a7#, 16#c19bf174#,
      16#e49b69c1#, 16#efbe4786#, 16#0fc19dc6#, 16#240ca1cc#,
      16#2de92c6f#, 16#4a7484aa#, 16#5cb0a9dc#, 16#76f988da#,
      16#983e5152#, 16#a831c66d#, 16#b00327c8#, 16#bf597fc7#,
      16#c6e00bf3#, 16#d5a79147#, 16#06ca6351#, 16#14292967#,
      16#27b70a85#, 16#2e1b2138#, 16#4d2c6dfc#, 16#53380d13#,
      16#650a7354#, 16#766a0abb#, 16#81c2c92e#, 16#92722c85#,
      16#a2bfe8a1#, 16#a81a664b#, 16#c24b8b70#, 16#c76c51a3#,
      16#d192e819#, 16#d6990624#, 16#f40e3585#, 16#106aa070#,
      16#19a4c116#, 16#1e376c08#, 16#2748774c#, 16#34b0bcb5#,
      16#391c0cb3#, 16#4ed8aa4a#, 16#5b9cca4f#, 16#682e6ff3#,
      16#748f82ee#, 16#78a5636f#, 16#84c87814#, 16#8cc70208#,
      16#90befffa#, 16#a4506ceb#, 16#bef9a3f7#, 16#c67178f2#);

   -- Initial hash values
   H_Init : constant Hash_Words :=
     (16#6a09e667#, 16#bb67ae85#, 16#3c6ef372#, 16#a54ff53a#,
      16#510e527f#, 16#9b05688c#, 16#1f83d9ab#, 16#5be0cd19#);

   -- SHA-256 helper functions
   function Ch (E, F, G : Word32) return Word32 is
   begin
      return (E and F) xor ((not E) and G);
   end Ch;

   function Maj (A, B, C : Word32) return Word32 is
   begin
      return (A and B) xor (A and C) xor (B and C);
   end Maj;

   function Sigma0 (A : Word32) return Word32 is
   begin
      return Rotate_Right (A, 2) xor Rotate_Right (A, 13) xor Rotate_Right (A, 22);
   end Sigma0;

   function Sigma1 (E : Word32) return Word32 is
   begin
      return Rotate_Right (E, 6) xor Rotate_Right (E, 11) xor Rotate_Right (E, 25);
   end Sigma1;

   function Msg_Sigma0 (W : Word32) return Word32 is
   begin
      return Rotate_Right (W, 7) xor Rotate_Right (W, 18) xor Shift_Right (W, 3);
   end Msg_Sigma0;

   function Msg_Sigma1 (W : Word32) return Word32 is
   begin
      return Rotate_Right (W, 17) xor Rotate_Right (W, 19) xor Shift_Right (W, 10);
   end Msg_Sigma1;

   function To_Word32_BE (B : Byte_Array; Off : Natural) return Word32 is
   begin
      return Shift_Left (Word32 (B (Off)),     24) or
             Shift_Left (Word32 (B (Off + 1)), 16) or
             Shift_Left (Word32 (B (Off + 2)),  8) or
                         Word32 (B (Off + 3));
   end To_Word32_BE;

   function Pad_Message (Msg : Byte_Array) return Byte_Array is
      Len     : constant Natural := Msg'Length;
      Bit_Len : constant Word64  := Word64 (Len) * 8;
      Pad_Len : constant Natural := (55 - Len) mod 64;
      New_Len : constant Natural := Len + 1 + Pad_Len + 8;
      Result  : Byte_Array (0 .. New_Len - 1) := (others => 0);
   begin
      if Len > 0 then
         Result (0 .. Len - 1) := Msg;
      end if;
      Result (Len) := 16#80#;
      Result (New_Len - 8) := Byte (Shift_Right (Bit_Len, 56) and 16#FF#);
      Result (New_Len - 7) := Byte (Shift_Right (Bit_Len, 48) and 16#FF#);
      Result (New_Len - 6) := Byte (Shift_Right (Bit_Len, 40) and 16#FF#);
      Result (New_Len - 5) := Byte (Shift_Right (Bit_Len, 32) and 16#FF#);
      Result (New_Len - 4) := Byte (Shift_Right (Bit_Len, 24) and 16#FF#);
      Result (New_Len - 3) := Byte (Shift_Right (Bit_Len, 16) and 16#FF#);
      Result (New_Len - 2) := Byte (Shift_Right (Bit_Len,  8) and 16#FF#);
      Result (New_Len - 1) := Byte (Bit_Len and 16#FF#);
      return Result;
   end Pad_Message;

   function SHA256 (Msg : Byte_Array) return String is
      Padded  : constant Byte_Array := Pad_Message (Msg);
      H       : Hash_Words  := H_Init;
      W       : Sched_Words;
      A, B, C, D, E, F, G, HH, T1, T2 : Word32;
      Hex     : String (1 .. 64) := (others => '0');
      Hex_Map : constant String  := "0123456789abcdef";

      procedure Word_To_Hex (Val : Word32; Pos : Positive) is
         V : Word32 := Val;
      begin
         for I in reverse 0 .. 7 loop
            Hex (Pos + I) := Hex_Map (Natural (V and 16#F#) + 1);
            V := Shift_Right (V, 4);
         end loop;
      end Word_To_Hex;

   begin
      for Blk in 0 .. Padded'Length / 64 - 1 loop
         declare
            Off : constant Natural := Blk * 64;
         begin
            for J in 0 .. 15 loop
               W (J) := To_Word32_BE (Padded, Off + J * 4);
            end loop;
            for J in 16 .. 63 loop
               W (J) := Msg_Sigma1 (W (J - 2)) + W (J - 7) +
                         Msg_Sigma0 (W (J - 15)) + W (J - 16);
            end loop;
            A := H (0); B := H (1); C := H (2); D := H (3);
            E := H (4); F := H (5); G := H (6); HH := H (7);
            for J in 0 .. 63 loop
               T1 := HH + Sigma1 (E) + Ch (E, F, G) + K (J) + W (J);
               T2 := Sigma0 (A) + Maj (A, B, C);
               HH := G; G := F; F := E; E := D + T1;
               D  := C; C := B; B := A; A := T1 + T2;
            end loop;
            H (0) := H (0) + A; H (1) := H (1) + B;
            H (2) := H (2) + C; H (3) := H (3) + D;
            H (4) := H (4) + E; H (5) := H (5) + F;
            H (6) := H (6) + G; H (7) := H (7) + HH;
         end;
      end loop;
      for I in 0 .. 7 loop
         Word_To_Hex (H (I), I * 8 + 1);
      end loop;
      return Hex;
   end SHA256;

   function Reverse_Last_8 (S : String) return String is
      R : String (1 .. 64) := S;
      T : constant String (1 .. 8) := S (57 .. 64);
   begin
      for I in 1 .. 8 loop
         R (56 + I) := T (9 - I);
      end loop;
      return R;
   end Reverse_Last_8;

   function To_Bytes (S : String) return Byte_Array is
      Result : Byte_Array (0 .. S'Length - 1);
   begin
      for I in S'Range loop
         Result (I - S'First) := Byte (Character'Pos (S (I)));
      end loop;
      return Result;
   end To_Bytes;

   function Interleave (A, B : Byte_Array) return Byte_Array is
      Result : Byte_Array (0 .. A'Length + B'Length - 1);
      Idx    : Natural := 0;
      Max_I  : constant Natural := Natural'Max (A'Length, B'Length);
   begin
      for I in 0 .. Max_I - 1 loop
         if I < A'Length then
            Result (Idx) := A (A'First + I);
            Idx := Idx + 1;
         end if;
         if I < B'Length then
            Result (Idx) := B (B'First + I);
            Idx := Idx + 1;
         end if;
      end loop;
      return Result;
   end Interleave;

   function Stupid_Block (Buf : Byte_Array; Salt : String) return Byte_Array is
   begin
      return Interleave (To_Bytes (Reverse_Last_8 (SHA256 (Buf))),
                         To_Bytes (Salt));
   end Stupid_Block;

   -- 10 cyclic salts
   Salts : constant array (0 .. 9) of Unbounded_String :=
     (To_Unbounded_String ("jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"),
      To_Unbounded_String ("jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"),
      To_Unbounded_String ("jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"),
      To_Unbounded_String ("jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"),
      To_Unbounded_String ("jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"),
      To_Unbounded_String ("jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"),
      To_Unbounded_String ("jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"),
      To_Unbounded_String ("jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"),
      To_Unbounded_String ("jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"),
      To_Unbounded_String ("jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"));

   function Super_Stupid_Pipeline (Initial : Byte_Array) return Byte_Array is
      Current : Byte_Array_Access := new Byte_Array'(Initial);
      Next    : Byte_Array_Access;
   begin
      for Round in 0 .. 34 loop
         declare
            New_Buf : constant Byte_Array :=
               Stupid_Block (Current.all, To_String (Salts (Round mod 10)));
         begin
            Next := new Byte_Array'(New_Buf);
            Free (Current);
            Current := Next;
         end;
      end loop;
      declare
         Result : constant Byte_Array := Current.all;
      begin
         Free (Current);
         return Result;
      end;
   end Super_Stupid_Pipeline;

   function Read_File (Filename : String) return Byte_Array is
      File   : Byte_IO.File_Type;
      Accum  : Unbounded_String := Null_Unbounded_String;
      B      : Byte;
   begin
      Byte_IO.Open (File, Byte_IO.In_File, Filename);
      while not Byte_IO.End_Of_File (File) loop
         Byte_IO.Read (File, B);
         Append (Accum, Character'Val (B));
      end loop;
      Byte_IO.Close (File);
      return To_Bytes (To_String (Accum));
   exception
      when others =>
         if Byte_IO.Is_Open (File) then Byte_IO.Close (File); end if;
         return Byte_Array'(1 .. 0 => 0);
   end Read_File;

   Buf : Byte_Array_Access;

begin
   if Argument_Count = 0 then
      return;
   end if;

   if Argument_Count >= 2 and then Argument (1) = "-f" then
      Buf := new Byte_Array'(Read_File (Argument (2)));
   else
      Buf := new Byte_Array'(To_Bytes (Argument (1)));
   end if;

   declare
      Result : constant Byte_Array := Super_Stupid_Pipeline (Buf.all);
   begin
      Free (Buf);
      Put_Line (Reverse_Last_8 (SHA256 (Result)));
   end;
end SHA257Sum;
