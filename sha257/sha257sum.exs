defmodule SHA257sum do
  def sha256(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  def interleave(bytes_a, bytes_b) do
    len_a = byte_size(bytes_a)
    len_b = byte_size(bytes_b)
    max_len = max(len_a, len_b)

    Enum.reduce(0..(max_len - 1), <<>>, fn i, acc ->
      acc = if i < len_a, do: acc <> binary_part(bytes_a, i, 1), else: acc
      if i < len_b, do: acc <> binary_part(bytes_b, i, 1), else: acc
    end)
  end

  def reverse_string(s) do
    s |> String.reverse()
  end

  def sha257sum(data) do
    salts = [
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
    ]

    Enum.reduce(0..34, data, fn i, buf ->
      hex = sha256(buf)
      prefix = String.slice(hex, 0..55)
      suffix = String.slice(hex, 56..63)
      rev_suffix = reverse_string(suffix)
      intermediate = prefix <> rev_suffix
      salt = Enum.at(salts, rem(i, 10))
      interleave(intermediate, salt)
    end)
    |> (fn final_buf ->
      hex = sha256(final_buf)
      prefix = String.slice(hex, 0..55)
      suffix = String.slice(hex, 56..63)
      rev_suffix = reverse_string(suffix)
      prefix <> rev_suffix
    end).()
  end
end

args = System.argv()

case args do
  ["-f", path] ->
    File.read!(path) |> SHA257sum.sha257sum() |> IO.puts()
  [str] ->
    str |> SHA257sum.sha257sum() |> IO.puts()
  _ ->
    :ok
end
