library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity sha257sum is
  generic (
    INPUT     : string := "";
    FILE_NAME : string := ""
  );
end entity sha257sum;

architecture behavioral of sha257sum is
  subtype word_t is unsigned(31 downto 0);
  type word_arr64_t is array (0 to 63) of word_t;
  type word_arr8_t is array (0 to 7) of word_t;
  type byte_arr_t is array (natural range <>) of natural range 0 to 255;

  constant K : word_arr64_t := (
    x"428a2f98", x"71374491", x"b5c0fbcf", x"e9b5dba5",
    x"3956c25b", x"59f111f1", x"923f82a4", x"ab1c5ed5",
    x"d807aa98", x"12835b01", x"243185be", x"550c7dc3",
    x"72be5d74", x"80deb1fe", x"9bdc06a7", x"c19bf174",
    x"e49b69c1", x"efbe4786", x"0fc19dc6", x"240ca1cc",
    x"2de92c6f", x"4a7484aa", x"5cb0a9dc", x"76f988da",
    x"983e5152", x"a831c66d", x"b00327c8", x"bf597fc7",
    x"c6e00bf3", x"d5a79147", x"06ca6351", x"14292967",
    x"27b70a85", x"2e1b2138", x"4d2c6dfc", x"53380d13",
    x"650a7354", x"766a0abb", x"81c2c92e", x"92722c85",
    x"a2bfe8a1", x"a81a664b", x"c24b8b70", x"c76c51a3",
    x"d192e819", x"d6990624", x"f40e3585", x"106aa070",
    x"19a4c116", x"1e376c08", x"2748774c", x"34b0bcb5",
    x"391c0cb3", x"4ed8aa4a", x"5b9cca4f", x"682e6ff3",
    x"748f82ee", x"78a5636f", x"84c87814", x"8cc70208",
    x"90befffa", x"a4506ceb", x"bef9a3f7", x"c67178f2"
  );

  constant IV : word_arr8_t := (
    x"6a09e667", x"bb67ae85", x"3c6ef372", x"a54ff53a",
    x"510e527f", x"9b05688c", x"1f83d9ab", x"5be0cd19"
  );

  constant HEX_CHARS : string(1 to 16) := "0123456789abcdef";

  function get_salt(idx : natural) return string is
  begin
    case idx is
      when 0 => return "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA";
      when 1 => return "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB";
      when 2 => return "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC";
      when 3 => return "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD";
      when 4 => return "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE";
      when 5 => return "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF";
      when 6 => return "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG";
      when 7 => return "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH";
      when 8 => return "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II";
      when others => return "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ";
    end case;
  end function get_salt;

  function sha256(msg : byte_arr_t) return string is
    constant mlen : natural := msg'length;
    constant rem_len : natural := (mlen + 9) mod 64;
    constant plen : natural := mlen + 9 + ((64 - rem_len) mod 64);
    constant nblk : natural := plen / 64;
    variable buf : byte_arr_t(0 to plen - 1) := (others => 0);
    variable h : word_arr8_t := IV;
    variable w : word_arr64_t;
    variable a, b, c, d, e, f, g, hh : word_t;
    variable s0, s1, ch, maj, t1, t2 : word_t;
    variable bits : unsigned(63 downto 0);
    variable off : natural;
    variable out_str : string(1 to 64);
    variable nib : natural;
  begin
    for i in 0 to mlen - 1 loop
      buf(i) := msg(msg'low + i);
    end loop;
    buf(mlen) := 16#80#;
    bits := shift_left(to_unsigned(mlen, 64), 3);
    for i in 0 to 7 loop
      buf(plen - 8 + i) := to_integer(bits(63 - i * 8 downto 56 - i * 8));
    end loop;

    for blk in 0 to nblk - 1 loop
      off := blk * 64;
      for i in 0 to 15 loop
        w(i) := to_unsigned(buf(off + i * 4), 8) &
                to_unsigned(buf(off + i * 4 + 1), 8) &
                to_unsigned(buf(off + i * 4 + 2), 8) &
                to_unsigned(buf(off + i * 4 + 3), 8);
      end loop;
      for i in 16 to 63 loop
        s0 := rotate_right(w(i - 15), 7) xor rotate_right(w(i - 15), 18) xor shift_right(w(i - 15), 3);
        s1 := rotate_right(w(i - 2), 17) xor rotate_right(w(i - 2), 19) xor shift_right(w(i - 2), 10);
        w(i) := w(i - 16) + s0 + w(i - 7) + s1;
      end loop;

      a := h(0); b := h(1); c := h(2); d := h(3);
      e := h(4); f := h(5); g := h(6); hh := h(7);

      for i in 0 to 63 loop
        s1 := rotate_right(e, 6) xor rotate_right(e, 11) xor rotate_right(e, 25);
        ch := (e and f) xor ((not e) and g);
        t1 := hh + s1 + ch + K(i) + w(i);
        s0 := rotate_right(a, 2) xor rotate_right(a, 13) xor rotate_right(a, 22);
        maj := (a and b) xor (a and c) xor (b and c);
        t2 := s0 + maj;
        hh := g; g := f; f := e; e := d + t1;
        d := c; c := b; b := a; a := t1 + t2;
      end loop;

      h(0) := h(0) + a; h(1) := h(1) + b; h(2) := h(2) + c; h(3) := h(3) + d;
      h(4) := h(4) + e; h(5) := h(5) + f; h(6) := h(6) + g; h(7) := h(7) + hh;
    end loop;

    for i in 0 to 7 loop
      for j in 0 to 7 loop
        nib := to_integer(h(i)(31 - j * 4 downto 28 - j * 4));
        out_str(i * 8 + j + 1) := HEX_CHARS(nib + 1);
      end loop;
    end loop;
    return out_str;
  end function sha256;

  function reverse_suffix(s : string(1 to 64)) return string is
    variable r : string(1 to 64) := s;
  begin
    for i in 0 to 7 loop
      r(57 + i) := s(64 - i);
    end loop;
    return r;
  end function reverse_suffix;

  procedure interleave_into(
    a       : in  string;
    b       : in  string;
    out_buf : out byte_arr_t(0 to 255);
    out_len : out natural
  ) is
    constant la : natural := a'length;
    constant lb : natural := b'length;
    variable m : natural;
    variable pos : natural := 0;
  begin
    if la > lb then m := la; else m := lb; end if;
    for i in 0 to m - 1 loop
      if i < la then
        out_buf(pos) := character'pos(a(a'low + i));
        pos := pos + 1;
      end if;
      if i < lb then
        out_buf(pos) := character'pos(b(b'low + i));
        pos := pos + 1;
      end if;
    end loop;
    out_len := pos;
  end procedure interleave_into;

  function calculate_sha257(initial : byte_arr_t) return string is
    variable rev : string(1 to 64);
    variable cur_buf : byte_arr_t(0 to 255) := (others => 0);
    variable cur_len : natural := 0;
  begin
    for r in 0 to 34 loop
      if r = 0 then
        rev := reverse_suffix(sha256(initial));
      else
        rev := reverse_suffix(sha256(cur_buf(0 to cur_len - 1)));
      end if;
      interleave_into(rev, get_salt(r mod 10), cur_buf, cur_len);
    end loop;
    return reverse_suffix(sha256(cur_buf(0 to cur_len - 1)));
  end function calculate_sha257;

  procedure hash_file_sized(path : string; flen : natural) is
    type char_file_t is file of character;
    file f : char_file_t;
    variable status : file_open_status;
    variable ch : character;
    variable fbuf : byte_arr_t(0 to flen - 1);
    variable idx : natural := 0;
    variable l : line;
  begin
    file_open(status, f, path, read_mode);
    while not endfile(f) loop
      read(f, ch);
      fbuf(idx) := character'pos(ch);
      idx := idx + 1;
    end loop;
    file_close(f);
    write(l, calculate_sha257(fbuf));
    writeline(output, l);
  end procedure hash_file_sized;

  procedure run_file(path : string) is
    type char_file_t is file of character;
    file f : char_file_t;
    variable status : file_open_status;
    variable ch : character;
    variable flen : natural := 0;
    variable empty_buf : byte_arr_t(1 to 0);
    variable l : line;
  begin
    file_open(status, f, path, read_mode);
    if status /= open_ok then
      report "Error: could not open file " & path severity failure;
    end if;
    while not endfile(f) loop
      read(f, ch);
      flen := flen + 1;
    end loop;
    file_close(f);

    if flen = 0 then
      write(l, calculate_sha257(empty_buf));
      writeline(output, l);
    else
      hash_file_sized(path, flen);
    end if;
  end procedure run_file;

  procedure run_string(s : string) is
    variable sbuf : byte_arr_t(0 to s'length - 1);
    variable l : line;
  begin
    for i in 0 to s'length - 1 loop
      sbuf(i) := character'pos(s(s'low + i));
    end loop;
    write(l, calculate_sha257(sbuf));
    writeline(output, l);
  end procedure run_string;

begin
  process
  begin
    if FILE_NAME'length > 0 then
      run_file(FILE_NAME);
    else
      run_string(INPUT);
    end if;
    wait;
  end process;
end architecture behavioral;
