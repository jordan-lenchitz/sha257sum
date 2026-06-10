require "digest/sha256"

def reverse_string(s : String) : String
  s.reverse
end

def interleave(intermediate : Bytes, salt : Bytes) : Bytes
  max_len = [intermediate.size, salt.size].max
  new_buf = IO::Memory.new
  max_len.times do |i|
    new_buf.write_byte intermediate[i] if i < intermediate.size
    new_buf.write_byte salt[i] if i < salt.size
  end
  new_buf.to_slice
end

def sha256_hex(data : Bytes) : String
  Digest::SHA256.hexdigest(data)
end

def sha257sum(data : Bytes) : String
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

  buf = data

  35.times do |i|
    hex = sha256_hex(buf)
    prefix = hex[0...56]
    suffix = hex[56...64]
    rev_suffix = reverse_string(suffix)
    intermediate = (prefix + rev_suffix).to_slice
    salt = salts[i % 10].to_slice
    buf = interleave(intermediate, salt)
  end

  hex = sha256_hex(buf)
  prefix = hex[0...56]
  suffix = hex[56...64]
  rev_suffix = reverse_string(suffix)
  prefix + rev_suffix
end

args = ARGV
if args.empty?
  exit
end

buf = if args[0] == "-f"
        File.read(args[1]).to_slice
      else
        args[0].to_slice
      end

puts sha257sum(buf)
