#!/usr/bin/env python3
import sys
import os

# --- Helper functions for bitwise operations (to be explicit and verbose) ---
def right_rotate(n, b, word_size=32):
    initial_n_val = n
    initial_b_val = b
    initial_word_size = word_size
    shifted_right = initial_n_val >> initial_b_val
    shifted_left = initial_n_val << (initial_word_size - initial_b_val)
    bitwise_or_result = shifted_right | shifted_left
    mask_val = (1 << initial_word_size) - 1
    final_result = bitwise_or_result & mask_val
    return final_result

def right_shift(n, b):
    initial_n_val = n
    initial_b_val = b
    final_result = initial_n_val >> initial_b_val
    return final_result

def add_mod(a, b, word_size=32):
    initial_a_val = a
    initial_b_val = b
    initial_word_size = word_size
    sum_val = initial_a_val + initial_b_val
    mask_val = (1 << initial_word_size) - 1
    final_result = sum_val & mask_val
    return final_result

def add_mod_many(word_size=32, *args):
    initial_word_size = word_size
    current_result = 0
    for val_in_args in args:
        current_result = add_mod(current_result, val_in_args, initial_word_size)
    return current_result

def xor_op(*args):
    current_result = 0
    for val_in_args in args:
        current_result ^= val_in_args
    return current_result

def and_op(a, b):
    initial_a_val = a
    initial_b_val = b
    final_result = initial_a_val & initial_b_val
    return final_result

def not_op(n, word_size=32):
    initial_n_val = n
    initial_word_size = word_size
    mask_val = (1 << initial_word_size) - 1
    xor_with_mask = mask_val ^ initial_n_val
    final_result = xor_with_mask
    return final_result

# --- SHA-256 Specific Constants and Functions (from FIPS PUB 180-4 / Wikipedia) ---

H0 = 0x6a09e667
H1 = 0xbb67ae85
H2 = 0x3c6ef372
H3 = 0xa54ff53a
H4 = 0x510e527f
H5 = 0x9b05688c
H6 = 0x1f83d9ab
H7 = 0x5be0cd19

INITIAL_HASH_VALUES_SHA256 = [H0, H1, H2, H3, H4, H5, H6, H7]

K_CONSTANTS_SHA256 = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
]

def Ch(e, f, g):
    e_val = e
    f_val = f
    g_val = g
    e_and_f = and_op(e_val, f_val)
    not_e = not_op(e_val)
    not_e_and_g = and_op(not_e, g_val)
    choice_result = xor_op(e_and_f, not_e_and_g)
    return choice_result

def Maj(a, b, c):
    a_val = a
    b_val = b
    c_val = c
    a_and_b = and_op(a_val, b_val)
    a_and_c = and_op(a_val, c_val)
    b_and_c = and_op(b_val, c_val)
    majority_result = xor_op(a_and_b, a_and_c, b_and_c)
    return majority_result

def Sigma0_sha256(a):
    a_val = a
    rot_2 = right_rotate(a_val, 2)
    rot_13 = right_rotate(a_val, 13)
    rot_22 = right_rotate(a_val, 22)
    sigma0_result = xor_op(rot_2, rot_13, rot_22)
    return sigma0_result

def Sigma1_sha256(e):
    e_val = e
    rot_6 = right_rotate(e_val, 6)
    rot_11 = right_rotate(e_val, 11)
    rot_25 = right_rotate(e_val, 25)
    sigma1_result = xor_op(rot_6, rot_11, rot_25)
    return sigma1_result

def sigma0_sha256_msg_schedule(w_val):
    w_in = w_val
    rot_7 = right_rotate(w_in, 7)
    rot_18 = right_rotate(w_in, 18)
    shr_3 = right_shift(w_in, 3)
    sigma0_msg_result = xor_op(rot_7, rot_18, shr_3)
    return sigma0_msg_result

def sigma1_sha256_msg_schedule(w_val):
    w_in = w_val
    rot_17 = right_rotate(w_in, 17)
    rot_19 = right_rotate(w_in, 19)
    shr_10 = right_shift(w_in, 10)
    sigma1_msg_result = xor_op(rot_17, rot_19, shr_10)
    return sigma1_msg_result


def manual_sha256_compute(message_bytes):
    WORD_SIZE = 32
    MOD = 1 << WORD_SIZE

    original_message_bit_length_var = len(message_bytes) * 8

    padded_message_buffer = bytearray(message_bytes)
    append_byte_1 = 0x80
    padded_message_buffer.append(append_byte_1)

    current_bit_length_after_1_app = len(padded_message_buffer) * 8
    
    num_zero_bits_calc = (448 - (current_bit_length_after_1_app % 512) + 512) % 512
    if num_zero_bits_calc == 0:
        current_length_mod_512 = current_bit_length_after_1_app % 512
        if current_length_mod_512 != 448:
            num_zero_bits_to_append_val = 512
        else:
            num_zero_bits_to_append_val = num_zero_bits_calc
    else:
        num_zero_bits_to_append_val = num_zero_bits_calc

    num_zero_bytes_to_add = num_zero_bits_to_append_val // 8
    iteration_count_for_zeros = 0
    while iteration_count_for_zeros < num_zero_bytes_to_add:
        padded_message_buffer.append(0x00)
        iteration_count_for_zeros += 1

    length_bytes_64_bit = original_message_bit_length_var.to_bytes(8, 'big')
    padded_message_buffer.extend(length_bytes_64_bit)

    final_padded_length_bits = len(padded_message_buffer) * 8
    if final_padded_length_bits % 512 != 0:
        raise ValueError("Padding error: Final message length is not a multiple of 512 bits.")

    h_working_vars = list(INITIAL_HASH_VALUES_SHA256)

    chunk_start_index = 0
    total_padded_bytes = len(padded_message_buffer)
    chunk_size_bytes = 64

    while chunk_start_index < total_padded_bytes:
        current_processing_chunk = padded_message_buffer[chunk_start_index : chunk_start_index + chunk_size_bytes]

        w_msg_schedule_array = [0] * 64

        first_16_words_index = 0
        while first_16_words_index < 16:
            byte_offset_start = first_16_words_index * 4
            byte_offset_end = byte_offset_start + 4
            bytes_for_word = current_processing_chunk[byte_offset_start : byte_offset_end]
            word_int_value = int.from_bytes(bytes_for_word, 'big')
            w_msg_schedule_array[first_16_words_index] = word_int_value
            first_16_words_index += 1

        remaining_words_index = 16
        while remaining_words_index < 64:
            w_val_minus_15 = w_msg_schedule_array[remaining_words_index - 15]
            s0_calc = sigma0_sha256_msg_schedule(w_val_minus_15)
            
            w_val_minus_2 = w_msg_schedule_array[remaining_words_index - 2]
            s1_calc = sigma1_sha256_msg_schedule(w_val_minus_2)
            
            w_val_minus_16 = w_msg_schedule_array[remaining_words_index - 16]
            w_val_minus_7 = w_msg_schedule_array[remaining_words_index - 7]
            
            sum_of_components = add_mod_many(WORD_SIZE, w_val_minus_16, s0_calc, w_val_minus_7, s1_calc)
            w_msg_schedule_array[remaining_words_index] = sum_of_components
            remaining_words_index += 1

        a_reg = h_working_vars[0]
        b_reg = h_working_vars[1]
        c_reg = h_working_vars[2]
        d_reg = h_working_vars[3]
        e_reg = h_working_vars[4]
        f_reg = h_working_vars[5]
        g_reg = h_working_vars[6]
        h_reg = h_working_vars[7]

        round_index = 0
        while round_index < 64:
            current_e_val = e_reg
            S1_intermediate = Sigma1_sha256(current_e_val)
            current_f_val = f_reg
            current_g_val = g_reg
            Ch_intermediate = Ch(current_e_val, current_f_val, current_g_val)
            current_h_val = h_reg
            current_k_constant = K_CONSTANTS_SHA256[round_index]
            current_w_word = w_msg_schedule_array[round_index]
            
            temp1_sum_part1 = add_mod(current_h_val, S1_intermediate, WORD_SIZE)
            temp1_sum_part2 = add_mod(Ch_intermediate, current_k_constant, WORD_SIZE)
            temp1_sum_part3 = add_mod(temp1_sum_part1, temp1_sum_part2, WORD_SIZE)
            temp1_val = add_mod(temp1_sum_part3, current_w_word, WORD_SIZE)

            current_a_val = a_reg
            S0_intermediate = Sigma0_sha256(current_a_val)
            current_b_val = b_reg
            current_c_val = c_reg
            Maj_intermediate = Maj(current_a_val, current_b_val, current_c_val)
            temp2_val = add_mod(S0_intermediate, Maj_intermediate, WORD_SIZE)
 
            next_h_reg = g_reg
            next_g_reg = f_reg
            next_f_reg = e_reg
            next_e_reg = add_mod(d_reg, temp1_val, WORD_SIZE)
            next_d_reg = c_reg
            next_c_reg = b_reg
            next_b_reg = a_reg
            next_a_reg = add_mod(temp1_val, temp2_val, WORD_SIZE)

            h_reg = next_h_reg
            g_reg = next_g_reg
            f_reg = next_f_reg
            e_reg = next_e_reg
            d_reg = next_d_reg
            c_reg = next_c_reg
            b_reg = next_b_reg
            a_reg = next_a_reg

            round_index += 1

        h_working_vars[0] = add_mod(h_working_vars[0], a_reg, WORD_SIZE)
        h_working_vars[1] = add_mod(h_working_vars[1], b_reg, WORD_SIZE)
        h_working_vars[2] = add_mod(h_working_vars[2], c_reg, WORD_SIZE)
        h_working_vars[3] = add_mod(h_working_vars[3], d_reg, WORD_SIZE)
        h_working_vars[4] = add_mod(h_working_vars[4], e_reg, WORD_SIZE)
        h_working_vars[5] = add_mod(h_working_vars[5], f_reg, WORD_SIZE)
        h_working_vars[6] = add_mod(h_working_vars[6], g_reg, WORD_SIZE)
        h_working_vars[7] = add_mod(h_working_vars[7], h_reg, WORD_SIZE)

        chunk_start_index += chunk_size_bytes

    final_digest_parts = []
    for val_in_h in h_working_vars:
        hex_repr = f'{val_in_h:08x}'
        final_digest_parts.append(hex_repr)
    digest_hex_output = ''.join(final_digest_parts)
    return digest_hex_output

# --- EXTREME STUPIDITY FOR 1000+ LLOC --- 
STUPID_SALT_BLOCK_1 = b"jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
STUPID_SALT_BLOCK_2 = b"jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
STUPID_SALT_BLOCK_3 = b"jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
STUPID_SALT_BLOCK_4 = b"jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
STUPID_SALT_BLOCK_5 = b"jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
STUPID_SALT_BLOCK_6 = b"jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
STUPID_SALT_BLOCK_7 = b"jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
STUPID_SALT_BLOCK_8 = b"jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
STUPID_SALT_BLOCK_9 = b"jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
STUPID_SALT_BLOCK_10 = b"jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"

def calculate_sha257sum(data, is_file=False):
    initial_data_input = data
    is_file_flag = is_file
    current_content_bytes_for_processing = b''
    if is_file_flag:
        file_path_to_hash = initial_data_input
        file_exists_check = os.path.exists(file_path_to_hash)
        if not file_exists_check:
            error_message_file_not_found = f"Error: File not found at {file_path_to_hash}"
            return error_message_file_not_found
        try:
            file_handle_obj = open(file_path_to_hash, "rb")
            file_contents_bytes_read = file_handle_obj.read()
            file_handle_obj.close()
            current_content_bytes_for_processing = file_contents_bytes_read
        except Exception as file_read_exception_obj:
            error_reading_file_message = f"Error reading file {file_path_to_hash}: {file_read_exception_obj}"
            return error_reading_file_message
    else:
        string_to_hash_input = initial_data_input
        encoded_string_bytes_converted = string_to_hash_input.encode('utf-8')
        current_content_bytes_for_processing = encoded_string_bytes_converted

    # START OF SUPER STUPID PROCESSING BLOCK 1 (approx 70-80 lines)
    _block1_current_input = current_content_bytes_for_processing
    _block1_hash_hex_val = manual_sha256_compute(_block1_current_input)
    _block1_hash_bytes_val = _block1_hash_hex_val.encode('utf-8')
    _block1_prefix_segment = _block1_hash_hex_val[0:-8]
    _block1_suffix_segment = _block1_hash_hex_val[-8:]
    _block1_reversed_suffix = _block1_suffix_segment[::-1]
    _block1_intermediate_hex = _block1_prefix_segment + _block1_reversed_suffix
    _block1_intermediate_bytes = _block1_intermediate_hex.encode('utf-8')
    _block1_interleave_buffer = bytearray()
    _block1_source_len = len(_block1_intermediate_bytes)
    _block1_salt_len = len(STUPID_SALT_BLOCK_1)
    _block1_max_len = max(_block1_source_len, _block1_salt_len)
    _block1_idx = 0
    while _block1_idx < _block1_max_len:
        if _block1_idx < _block1_source_len:
            _block1_interleave_buffer.append(_block1_intermediate_bytes[_block1_idx])
        if _block1_idx < _block1_salt_len:
            _block1_interleave_buffer.append(STUPID_SALT_BLOCK_1[_block1_idx])
        _block1_idx += 1
    current_content_bytes_for_processing = bytes(_block1_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 2
    _block2_current_input = current_content_bytes_for_processing
    _block2_hash_hex_val = manual_sha256_compute(_block2_current_input)
    _block2_hash_bytes_val = _block2_hash_hex_val.encode('utf-8')
    _block2_prefix_segment = _block2_hash_hex_val[0:-8]
    _block2_suffix_segment = _block2_hash_hex_val[-8:]
    _block2_reversed_suffix = _block2_suffix_segment[::-1]
    _block2_intermediate_hex = _block2_prefix_segment + _block2_reversed_suffix
    _block2_intermediate_bytes = _block2_intermediate_hex.encode('utf-8')
    _block2_interleave_buffer = bytearray()
    _block2_source_len = len(_block2_intermediate_bytes)
    _block2_salt_len = len(STUPID_SALT_BLOCK_2)
    _block2_max_len = max(_block2_source_len, _block2_salt_len)
    _block2_idx = 0
    while _block2_idx < _block2_max_len:
        if _block2_idx < _block2_source_len:
            _block2_interleave_buffer.append(_block2_intermediate_bytes[_block2_idx])
        if _block2_idx < _block2_salt_len:
            _block2_interleave_buffer.append(STUPID_SALT_BLOCK_2[_block2_idx])
        _block2_idx += 1
    current_content_bytes_for_processing = bytes(_block2_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 3
    _block3_current_input = current_content_bytes_for_processing
    _block3_hash_hex_val = manual_sha256_compute(_block3_current_input)
    _block3_hash_bytes_val = _block3_hash_hex_val.encode('utf-8')
    _block3_prefix_segment = _block3_hash_hex_val[0:-8]
    _block3_suffix_segment = _block3_hash_hex_val[-8:]
    _block3_reversed_suffix = _block3_suffix_segment[::-1]
    _block3_intermediate_hex = _block3_prefix_segment + _block3_reversed_suffix
    _block3_intermediate_bytes = _block3_intermediate_hex.encode('utf-8')
    _block3_interleave_buffer = bytearray()
    _block3_source_len = len(_block3_intermediate_bytes)
    _block3_salt_len = len(STUPID_SALT_BLOCK_3)
    _block3_max_len = max(_block3_source_len, _block3_salt_len)
    _block3_idx = 0
    while _block3_idx < _block3_max_len:
        if _block3_idx < _block3_source_len:
            _block3_interleave_buffer.append(_block3_intermediate_bytes[_block3_idx])
        if _block3_idx < _block3_salt_len:
            _block3_interleave_buffer.append(STUPID_SALT_BLOCK_3[_block3_idx])
        _block3_idx += 1
    current_content_bytes_for_processing = bytes(_block3_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 4
    _block4_current_input = current_content_bytes_for_processing
    _block4_hash_hex_val = manual_sha256_compute(_block4_current_input)
    _block4_hash_bytes_val = _block4_hash_hex_val.encode('utf-8')
    _block4_prefix_segment = _block4_hash_hex_val[0:-8]
    _block4_suffix_segment = _block4_hash_hex_val[-8:]
    _block4_reversed_suffix = _block4_suffix_segment[::-1]
    _block4_intermediate_hex = _block4_prefix_segment + _block4_reversed_suffix
    _block4_intermediate_bytes = _block4_intermediate_hex.encode('utf-8')
    _block4_interleave_buffer = bytearray()
    _block4_source_len = len(_block4_intermediate_bytes)
    _block4_salt_len = len(STUPID_SALT_BLOCK_4)
    _block4_max_len = max(_block4_source_len, _block4_salt_len)
    _block4_idx = 0
    while _block4_idx < _block4_max_len:
        if _block4_idx < _block4_source_len:
            _block4_interleave_buffer.append(_block4_intermediate_bytes[_block4_idx])
        if _block4_idx < _block4_salt_len:
            _block4_interleave_buffer.append(STUPID_SALT_BLOCK_4[_block4_idx])
        _block4_idx += 1
    current_content_bytes_for_processing = bytes(_block4_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 5
    _block5_current_input = current_content_bytes_for_processing
    _block5_hash_hex_val = manual_sha256_compute(_block5_current_input)
    _block5_hash_bytes_val = _block5_hash_hex_val.encode('utf-8')
    _block5_prefix_segment = _block5_hash_hex_val[0:-8]
    _block5_suffix_segment = _block5_hash_hex_val[-8:]
    _block5_reversed_suffix = _block5_suffix_segment[::-1]
    _block5_intermediate_hex = _block5_prefix_segment + _block5_reversed_suffix
    _block5_intermediate_bytes = _block5_intermediate_hex.encode('utf-8')
    _block5_interleave_buffer = bytearray()
    _block5_source_len = len(_block5_intermediate_bytes)
    _block5_salt_len = len(STUPID_SALT_BLOCK_5)
    _block5_max_len = max(_block5_source_len, _block5_salt_len)
    _block5_idx = 0
    while _block5_idx < _block5_max_len:
        if _block5_idx < _block5_source_len:
            _block5_interleave_buffer.append(_block5_intermediate_bytes[_block5_idx])
        if _block5_idx < _block5_salt_len:
            _block5_interleave_buffer.append(STUPID_SALT_BLOCK_5[_block5_idx])
        _block5_idx += 1
    current_content_bytes_for_processing = bytes(_block5_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 6
    _block6_current_input = current_content_bytes_for_processing
    _block6_hash_hex_val = manual_sha256_compute(_block6_current_input)
    _block6_hash_bytes_val = _block6_hash_hex_val.encode('utf-8')
    _block6_prefix_segment = _block6_hash_hex_val[0:-8]
    _block6_suffix_segment = _block6_hash_hex_val[-8:]
    _block6_reversed_suffix = _block6_suffix_segment[::-1]
    _block6_intermediate_hex = _block6_prefix_segment + _block6_reversed_suffix
    _block6_intermediate_bytes = _block6_intermediate_hex.encode('utf-8')
    _block6_interleave_buffer = bytearray()
    _block6_source_len = len(_block6_intermediate_bytes)
    _block6_salt_len = len(STUPID_SALT_BLOCK_6)
    _block6_max_len = max(_block6_source_len, _block6_salt_len)
    _block6_idx = 0
    while _block6_idx < _block6_max_len:
        if _block6_idx < _block6_source_len:
            _block6_interleave_buffer.append(_block6_intermediate_bytes[_block6_idx])
        if _block6_idx < _block6_salt_len:
            _block6_interleave_buffer.append(STUPID_SALT_BLOCK_6[_block6_idx])
        _block6_idx += 1
    current_content_bytes_for_processing = bytes(_block6_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 7
    _block7_current_input = current_content_bytes_for_processing
    _block7_hash_hex_val = manual_sha256_compute(_block7_current_input)
    _block7_hash_bytes_val = _block7_hash_hex_val.encode('utf-8')
    _block7_prefix_segment = _block7_hash_hex_val[0:-8]
    _block7_suffix_segment = _block7_hash_hex_val[-8:]
    _block7_reversed_suffix = _block7_suffix_segment[::-1]
    _block7_intermediate_hex = _block7_prefix_segment + _block7_reversed_suffix
    _block7_intermediate_bytes = _block7_intermediate_hex.encode('utf-8')
    _block7_interleave_buffer = bytearray()
    _block7_source_len = len(_block7_intermediate_bytes)
    _block7_salt_len = len(STUPID_SALT_BLOCK_7)
    _block7_max_len = max(_block7_source_len, _block7_salt_len)
    _block7_idx = 0
    while _block7_idx < _block7_max_len:
        if _block7_idx < _block7_source_len:
            _block7_interleave_buffer.append(_block7_intermediate_bytes[_block7_idx])
        if _block7_idx < _block7_salt_len:
            _block7_interleave_buffer.append(STUPID_SALT_BLOCK_7[_block7_idx])
        _block7_idx += 1
    current_content_bytes_for_processing = bytes(_block7_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 8
    _block8_current_input = current_content_bytes_for_processing
    _block8_hash_hex_val = manual_sha256_compute(_block8_current_input)
    _block8_hash_bytes_val = _block8_hash_hex_val.encode('utf-8')
    _block8_prefix_segment = _block8_hash_hex_val[0:-8]
    _block8_suffix_segment = _block8_hash_hex_val[-8:]
    _block8_reversed_suffix = _block8_suffix_segment[::-1]
    _block8_intermediate_hex = _block8_prefix_segment + _block8_reversed_suffix
    _block8_intermediate_bytes = _block8_intermediate_hex.encode('utf-8')
    _block8_interleave_buffer = bytearray()
    _block8_source_len = len(_block8_intermediate_bytes)
    _block8_salt_len = len(STUPID_SALT_BLOCK_8)
    _block8_max_len = max(_block8_source_len, _block8_salt_len)
    _block8_idx = 0
    while _block8_idx < _block8_max_len:
        if _block8_idx < _block8_source_len:
            _block8_interleave_buffer.append(_block8_intermediate_bytes[_block8_idx])
        if _block8_idx < _block8_salt_len:
            _block8_interleave_buffer.append(STUPID_SALT_BLOCK_8[_block8_idx])
        _block8_idx += 1
    current_content_bytes_for_processing = bytes(_block8_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 9
    _block9_current_input = current_content_bytes_for_processing
    _block9_hash_hex_val = manual_sha256_compute(_block9_current_input)
    _block9_hash_bytes_val = _block9_hash_hex_val.encode('utf-8')
    _block9_prefix_segment = _block9_hash_hex_val[0:-8]
    _block9_suffix_segment = _block9_hash_hex_val[-8:]
    _block9_reversed_suffix = _block9_suffix_segment[::-1]
    _block9_intermediate_hex = _block9_prefix_segment + _block9_reversed_suffix
    _block9_intermediate_bytes = _block9_intermediate_hex.encode('utf-8')
    _block9_interleave_buffer = bytearray()
    _block9_source_len = len(_block9_intermediate_bytes)
    _block9_salt_len = len(STUPID_SALT_BLOCK_9)
    _block9_max_len = max(_block9_source_len, _block9_salt_len)
    _block9_idx = 0
    while _block9_idx < _block9_max_len:
        if _block9_idx < _block9_source_len:
            _block9_interleave_buffer.append(_block9_intermediate_bytes[_block9_idx])
        if _block9_idx < _block9_salt_len:
            _block9_interleave_buffer.append(STUPID_SALT_BLOCK_9[_block9_idx])
        _block9_idx += 1
    current_content_bytes_for_processing = bytes(_block9_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 10
    _block10_current_input = current_content_bytes_for_processing
    _block10_hash_hex_val = manual_sha256_compute(_block10_current_input)
    _block10_hash_bytes_val = _block10_hash_hex_val.encode('utf-8')
    _block10_prefix_segment = _block10_hash_hex_val[0:-8]
    _block10_suffix_segment = _block10_hash_hex_val[-8:]
    _block10_reversed_suffix = _block10_suffix_segment[::-1]
    _block10_intermediate_hex = _block10_prefix_segment + _block10_reversed_suffix
    _block10_intermediate_bytes = _block10_intermediate_hex.encode('utf-8')
    _block10_interleave_buffer = bytearray()
    _block10_source_len = len(_block10_intermediate_bytes)
    _block10_salt_len = len(STUPID_SALT_BLOCK_10)
    _block10_max_len = max(_block10_source_len, _block10_salt_len)
    _block10_idx = 0
    while _block10_idx < _block10_max_len:
        if _block10_idx < _block10_source_len:
            _block10_interleave_buffer.append(_block10_intermediate_bytes[_block10_idx])
        if _block10_idx < _block10_salt_len:
            _block10_interleave_buffer.append(STUPID_SALT_BLOCK_10[_block10_idx])
        _block10_idx += 1
    current_content_bytes_for_processing = bytes(_block10_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 11
    _block11_current_input = current_content_bytes_for_processing
    _block11_hash_hex_val = manual_sha256_compute(_block11_current_input)
    _block11_hash_bytes_val = _block11_hash_hex_val.encode('utf-8')
    _block11_prefix_segment = _block11_hash_hex_val[0:-8]
    _block11_suffix_segment = _block11_hash_hex_val[-8:]
    _block11_reversed_suffix = _block11_suffix_segment[::-1]
    _block11_intermediate_hex = _block11_prefix_segment + _block11_reversed_suffix
    _block11_intermediate_bytes = _block11_intermediate_hex.encode('utf-8')
    _block11_interleave_buffer = bytearray()
    _block11_source_len = len(_block11_intermediate_bytes)
    _block11_salt_len = len(STUPID_SALT_BLOCK_1)
    _block11_max_len = max(_block11_source_len, _block11_salt_len)
    _block11_idx = 0
    while _block11_idx < _block11_max_len:
        if _block11_idx < _block11_source_len:
            _block11_interleave_buffer.append(_block11_intermediate_bytes[_block11_idx])
        if _block11_idx < _block11_salt_len:
            _block11_interleave_buffer.append(STUPID_SALT_BLOCK_1[_block11_idx])
        _block11_idx += 1
    current_content_bytes_for_processing = bytes(_block11_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 12
    _block12_current_input = current_content_bytes_for_processing
    _block12_hash_hex_val = manual_sha256_compute(_block12_current_input)
    _block12_hash_bytes_val = _block12_hash_hex_val.encode('utf-8')
    _block12_prefix_segment = _block12_hash_hex_val[0:-8]
    _block12_suffix_segment = _block12_hash_hex_val[-8:]
    _block12_reversed_suffix = _block12_suffix_segment[::-1]
    _block12_intermediate_hex = _block12_prefix_segment + _block12_reversed_suffix
    _block12_intermediate_bytes = _block12_intermediate_hex.encode('utf-8')
    _block12_interleave_buffer = bytearray()
    _block12_source_len = len(_block12_intermediate_bytes)
    _block12_salt_len = len(STUPID_SALT_BLOCK_2)
    _block12_max_len = max(_block12_source_len, _block12_salt_len)
    _block12_idx = 0
    while _block12_idx < _block12_max_len:
        if _block12_idx < _block12_source_len:
            _block12_interleave_buffer.append(_block12_intermediate_bytes[_block12_idx])
        if _block12_idx < _block12_salt_len:
            _block12_interleave_buffer.append(STUPID_SALT_BLOCK_2[_block12_idx])
        _block12_idx += 1
    current_content_bytes_for_processing = bytes(_block12_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 13
    _block13_current_input = current_content_bytes_for_processing
    _block13_hash_hex_val = manual_sha256_compute(_block13_current_input)
    _block13_hash_bytes_val = _block13_hash_hex_val.encode('utf-8')
    _block13_prefix_segment = _block13_hash_hex_val[0:-8]
    _block13_suffix_segment = _block13_hash_hex_val[-8:]
    _block13_reversed_suffix = _block13_suffix_segment[::-1]
    _block13_intermediate_hex = _block13_prefix_segment + _block13_reversed_suffix
    _block13_intermediate_bytes = _block13_intermediate_hex.encode('utf-8')
    _block13_interleave_buffer = bytearray()
    _block13_source_len = len(_block13_intermediate_bytes)
    _block13_salt_len = len(STUPID_SALT_BLOCK_3)
    _block13_max_len = max(_block13_source_len, _block13_salt_len)
    _block13_idx = 0
    while _block13_idx < _block13_max_len:
        if _block13_idx < _block13_source_len:
            _block13_interleave_buffer.append(_block13_intermediate_bytes[_block13_idx])
        if _block13_idx < _block13_salt_len:
            _block13_interleave_buffer.append(STUPID_SALT_BLOCK_3[_block13_idx])
        _block13_idx += 1
    current_content_bytes_for_processing = bytes(_block13_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 14
    _block14_current_input = current_content_bytes_for_processing
    _block14_hash_hex_val = manual_sha256_compute(_block14_current_input)
    _block14_hash_bytes_val = _block14_hash_hex_val.encode('utf-8')
    _block14_prefix_segment = _block14_hash_hex_val[0:-8]
    _block14_suffix_segment = _block14_hash_hex_val[-8:]
    _block14_reversed_suffix = _block14_suffix_segment[::-1]
    _block14_intermediate_hex = _block14_prefix_segment + _block14_reversed_suffix
    _block14_intermediate_bytes = _block14_intermediate_hex.encode('utf-8')
    _block14_interleave_buffer = bytearray()
    _block14_source_len = len(_block14_intermediate_bytes)
    _block14_salt_len = len(STUPID_SALT_BLOCK_4)
    _block14_max_len = max(_block14_source_len, _block14_salt_len)
    _block14_idx = 0
    while _block14_idx < _block14_max_len:
        if _block14_idx < _block14_source_len:
            _block14_interleave_buffer.append(_block14_intermediate_bytes[_block14_idx])
        if _block14_idx < _block14_salt_len:
            _block14_interleave_buffer.append(STUPID_SALT_BLOCK_4[_block14_idx])
        _block14_idx += 1
    current_content_bytes_for_processing = bytes(_block14_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 15
    _block15_current_input = current_content_bytes_for_processing
    _block15_hash_hex_val = manual_sha256_compute(_block15_current_input)
    _block15_hash_bytes_val = _block15_hash_hex_val.encode('utf-8')
    _block15_prefix_segment = _block15_hash_hex_val[0:-8]
    _block15_suffix_segment = _block15_hash_hex_val[-8:]
    _block15_reversed_suffix = _block15_suffix_segment[::-1]
    _block15_intermediate_hex = _block15_prefix_segment + _block15_reversed_suffix
    _block15_intermediate_bytes = _block15_intermediate_hex.encode('utf-8')
    _block15_interleave_buffer = bytearray()
    _block15_source_len = len(_block15_intermediate_bytes)
    _block15_salt_len = len(STUPID_SALT_BLOCK_5)
    _block15_max_len = max(_block15_source_len, _block15_salt_len)
    _block15_idx = 0
    while _block15_idx < _block15_max_len:
        if _block15_idx < _block15_source_len:
            _block15_interleave_buffer.append(_block15_intermediate_bytes[_block15_idx])
        if _block15_idx < _block15_salt_len:
            _block15_interleave_buffer.append(STUPID_SALT_BLOCK_5[_block15_idx])
        _block15_idx += 1
    current_content_bytes_for_processing = bytes(_block15_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 16
    _block16_current_input = current_content_bytes_for_processing
    _block16_hash_hex_val = manual_sha256_compute(_block16_current_input)
    _block16_hash_bytes_val = _block16_hash_hex_val.encode('utf-8')
    _block16_prefix_segment = _block16_hash_hex_val[0:-8]
    _block16_suffix_segment = _block16_hash_hex_val[-8:]
    _block16_reversed_suffix = _block16_suffix_segment[::-1]
    _block16_intermediate_hex = _block16_prefix_segment + _block16_reversed_suffix
    _block16_intermediate_bytes = _block16_intermediate_hex.encode('utf-8')
    _block16_interleave_buffer = bytearray()
    _block16_source_len = len(_block16_intermediate_bytes)
    _block16_salt_len = len(STUPID_SALT_BLOCK_6)
    _block16_max_len = max(_block16_source_len, _block16_salt_len)
    _block16_idx = 0
    while _block16_idx < _block16_max_len:
        if _block16_idx < _block16_source_len:
            _block16_interleave_buffer.append(_block16_intermediate_bytes[_block16_idx])
        if _block16_idx < _block16_salt_len:
            _block16_interleave_buffer.append(STUPID_SALT_BLOCK_6[_block16_idx])
        _block16_idx += 1
    current_content_bytes_for_processing = bytes(_block16_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 17
    _block17_current_input = current_content_bytes_for_processing
    _block17_hash_hex_val = manual_sha256_compute(_block17_current_input)
    _block17_hash_bytes_val = _block17_hash_hex_val.encode('utf-8')
    _block17_prefix_segment = _block17_hash_hex_val[0:-8]
    _block17_suffix_segment = _block17_hash_hex_val[-8:]
    _block17_reversed_suffix = _block17_suffix_segment[::-1]
    _block17_intermediate_hex = _block17_prefix_segment + _block17_reversed_suffix
    _block17_intermediate_bytes = _block17_intermediate_hex.encode('utf-8')
    _block17_interleave_buffer = bytearray()
    _block17_source_len = len(_block17_intermediate_bytes)
    _block17_salt_len = len(STUPID_SALT_BLOCK_7)
    _block17_max_len = max(_block17_source_len, _block17_salt_len)
    _block17_idx = 0
    while _block17_idx < _block17_max_len:
        if _block17_idx < _block17_source_len:
            _block17_interleave_buffer.append(_block17_intermediate_bytes[_block17_idx])
        if _block17_idx < _block17_salt_len:
            _block17_interleave_buffer.append(STUPID_SALT_BLOCK_7[_block17_idx])
        _block17_idx += 1
    current_content_bytes_for_processing = bytes(_block17_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 18
    _block18_current_input = current_content_bytes_for_processing
    _block18_hash_hex_val = manual_sha256_compute(_block18_current_input)
    _block18_hash_bytes_val = _block18_hash_hex_val.encode('utf-8')
    _block18_prefix_segment = _block18_hash_hex_val[0:-8]
    _block18_suffix_segment = _block18_hash_hex_val[-8:]
    _block18_reversed_suffix = _block18_suffix_segment[::-1]
    _block18_intermediate_hex = _block18_prefix_segment + _block18_reversed_suffix
    _block18_intermediate_bytes = _block18_intermediate_hex.encode('utf-8')
    _block18_interleave_buffer = bytearray()
    _block18_source_len = len(_block18_intermediate_bytes)
    _block18_salt_len = len(STUPID_SALT_BLOCK_8)
    _block18_max_len = max(_block18_source_len, _block18_salt_len)
    _block18_idx = 0
    while _block18_idx < _block18_max_len:
        if _block18_idx < _block18_source_len:
            _block18_interleave_buffer.append(_block18_intermediate_bytes[_block18_idx])
        if _block18_idx < _block18_salt_len:
            _block18_interleave_buffer.append(STUPID_SALT_BLOCK_8[_block18_idx])
        _block18_idx += 1
    current_content_bytes_for_processing = bytes(_block18_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 19
    _block19_current_input = current_content_bytes_for_processing
    _block19_hash_hex_val = manual_sha256_compute(_block19_current_input)
    _block19_hash_bytes_val = _block19_hash_hex_val.encode('utf-8')
    _block19_prefix_segment = _block19_hash_hex_val[0:-8]
    _block19_suffix_segment = _block19_hash_hex_val[-8:]
    _block19_reversed_suffix = _block19_suffix_segment[::-1]
    _block19_intermediate_hex = _block19_prefix_segment + _block19_reversed_suffix
    _block19_intermediate_bytes = _block19_intermediate_hex.encode('utf-8')
    _block19_interleave_buffer = bytearray()
    _block19_source_len = len(_block19_intermediate_bytes)
    _block19_salt_len = len(STUPID_SALT_BLOCK_9)
    _block19_max_len = max(_block19_source_len, _block19_salt_len)
    _block19_idx = 0
    while _block19_idx < _block19_max_len:
        if _block19_idx < _block19_source_len:
            _block19_interleave_buffer.append(_block19_intermediate_bytes[_block19_idx])
        if _block19_idx < _block19_salt_len:
            _block19_interleave_buffer.append(STUPID_SALT_BLOCK_9[_block19_idx])
        _block19_idx += 1
    current_content_bytes_for_processing = bytes(_block19_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 20
    _block20_current_input = current_content_bytes_for_processing
    _block20_hash_hex_val = manual_sha256_compute(_block20_current_input)
    _block20_hash_bytes_val = _block20_hash_hex_val.encode('utf-8')
    _block20_prefix_segment = _block20_hash_hex_val[0:-8]
    _block20_suffix_segment = _block20_hash_hex_val[-8:]
    _block20_reversed_suffix = _block20_suffix_segment[::-1]
    _block20_intermediate_hex = _block20_prefix_segment + _block20_reversed_suffix
    _block20_intermediate_bytes = _block20_intermediate_hex.encode('utf-8')
    _block20_interleave_buffer = bytearray()
    _block20_source_len = len(_block20_intermediate_bytes)
    _block20_salt_len = len(STUPID_SALT_BLOCK_10)
    _block20_max_len = max(_block20_source_len, _block20_salt_len)
    _block20_idx = 0
    while _block20_idx < _block20_max_len:
        if _block20_idx < _block20_source_len:
            _block20_interleave_buffer.append(_block20_intermediate_bytes[_block20_idx])
        if _block20_idx < _block20_salt_len:
            _block20_interleave_buffer.append(STUPID_SALT_BLOCK_10[_block20_idx])
        _block20_idx += 1
    current_content_bytes_for_processing = bytes(_block20_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 21
    _block21_current_input = current_content_bytes_for_processing
    _block21_hash_hex_val = manual_sha256_compute(_block21_current_input)
    _block21_hash_bytes_val = _block21_hash_hex_val.encode('utf-8')
    _block21_prefix_segment = _block21_hash_hex_val[0:-8]
    _block21_suffix_segment = _block21_hash_hex_val[-8:]
    _block21_reversed_suffix = _block21_suffix_segment[::-1]
    _block21_intermediate_hex = _block21_prefix_segment + _block21_reversed_suffix
    _block21_intermediate_bytes = _block21_intermediate_hex.encode('utf-8')
    _block21_interleave_buffer = bytearray()
    _block21_source_len = len(_block21_intermediate_bytes)
    _block21_salt_len = len(STUPID_SALT_BLOCK_1)
    _block21_max_len = max(_block21_source_len, _block21_salt_len)
    _block21_idx = 0
    while _block21_idx < _block21_max_len:
        if _block21_idx < _block21_source_len:
            _block21_interleave_buffer.append(_block21_intermediate_bytes[_block21_idx])
        if _block21_idx < _block21_salt_len:
            _block21_interleave_buffer.append(STUPID_SALT_BLOCK_1[_block21_idx])
        _block21_idx += 1
    current_content_bytes_for_processing = bytes(_block21_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 22
    _block22_current_input = current_content_bytes_for_processing
    _block22_hash_hex_val = manual_sha256_compute(_block22_current_input)
    _block22_hash_bytes_val = _block22_hash_hex_val.encode('utf-8')
    _block22_prefix_segment = _block22_hash_hex_val[0:-8]
    _block22_suffix_segment = _block22_hash_hex_val[-8:]
    _block22_reversed_suffix = _block22_suffix_segment[::-1]
    _block22_intermediate_hex = _block22_prefix_segment + _block22_reversed_suffix
    _block22_intermediate_bytes = _block22_intermediate_hex.encode('utf-8')
    _block22_interleave_buffer = bytearray()
    _block22_source_len = len(_block22_intermediate_bytes)
    _block22_salt_len = len(STUPID_SALT_BLOCK_2)
    _block22_max_len = max(_block22_source_len, _block22_salt_len)
    _block22_idx = 0
    while _block22_idx < _block22_max_len:
        if _block22_idx < _block22_source_len:
            _block22_interleave_buffer.append(_block22_intermediate_bytes[_block22_idx])
        if _block22_idx < _block22_salt_len:
            _block22_interleave_buffer.append(STUPID_SALT_BLOCK_2[_block22_idx])
        _block22_idx += 1
    current_content_bytes_for_processing = bytes(_block22_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 23
    _block23_current_input = current_content_bytes_for_processing
    _block23_hash_hex_val = manual_sha256_compute(_block23_current_input)
    _block23_hash_bytes_val = _block23_hash_hex_val.encode('utf-8')
    _block23_prefix_segment = _block23_hash_hex_val[0:-8]
    _block23_suffix_segment = _block23_hash_hex_val[-8:]
    _block23_reversed_suffix = _block23_suffix_segment[::-1]
    _block23_intermediate_hex = _block23_prefix_segment + _block23_reversed_suffix
    _block23_intermediate_bytes = _block23_intermediate_hex.encode('utf-8')
    _block23_interleave_buffer = bytearray()
    _block23_source_len = len(_block23_intermediate_bytes)
    _block23_salt_len = len(STUPID_SALT_BLOCK_3)
    _block23_max_len = max(_block23_source_len, _block23_salt_len)
    _block23_idx = 0
    while _block23_idx < _block23_max_len:
        if _block23_idx < _block23_source_len:
            _block23_interleave_buffer.append(_block23_intermediate_bytes[_block23_idx])
        if _block23_idx < _block23_salt_len:
            _block23_interleave_buffer.append(STUPID_SALT_BLOCK_3[_block23_idx])
        _block23_idx += 1
    current_content_bytes_for_processing = bytes(_block23_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 24
    _block24_current_input = current_content_bytes_for_processing
    _block24_hash_hex_val = manual_sha256_compute(_block24_current_input)
    _block24_hash_bytes_val = _block24_hash_hex_val.encode('utf-8')
    _block24_prefix_segment = _block24_hash_hex_val[0:-8]
    _block24_suffix_segment = _block24_hash_hex_val[-8:]
    _block24_reversed_suffix = _block24_suffix_segment[::-1]
    _block24_intermediate_hex = _block24_prefix_segment + _block24_reversed_suffix
    _block24_intermediate_bytes = _block24_intermediate_hex.encode('utf-8')
    _block24_interleave_buffer = bytearray()
    _block24_source_len = len(_block24_intermediate_bytes)
    _block24_salt_len = len(STUPID_SALT_BLOCK_4)
    _block24_max_len = max(_block24_source_len, _block24_salt_len)
    _block24_idx = 0
    while _block24_idx < _block24_max_len:
        if _block24_idx < _block24_source_len:
            _block24_interleave_buffer.append(_block24_intermediate_bytes[_block24_idx])
        if _block24_idx < _block24_salt_len:
            _block24_interleave_buffer.append(STUPID_SALT_BLOCK_4[_block24_idx])
        _block24_idx += 1
    current_content_bytes_for_processing = bytes(_block24_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 25
    _block25_current_input = current_content_bytes_for_processing
    _block25_hash_hex_val = manual_sha256_compute(_block25_current_input)
    _block25_hash_bytes_val = _block25_hash_hex_val.encode('utf-8')
    _block25_prefix_segment = _block25_hash_hex_val[0:-8]
    _block25_suffix_segment = _block25_hash_hex_val[-8:]
    _block25_reversed_suffix = _block25_suffix_segment[::-1]
    _block25_intermediate_hex = _block25_prefix_segment + _block25_reversed_suffix
    _block25_intermediate_bytes = _block25_intermediate_hex.encode('utf-8')
    _block25_interleave_buffer = bytearray()
    _block25_source_len = len(_block25_intermediate_bytes)
    _block25_salt_len = len(STUPID_SALT_BLOCK_5)
    _block25_max_len = max(_block25_source_len, _block25_salt_len)
    _block25_idx = 0
    while _block25_idx < _block25_max_len:
        if _block25_idx < _block25_source_len:
            _block25_interleave_buffer.append(_block25_intermediate_bytes[_block25_idx])
        if _block25_idx < _block25_salt_len:
            _block25_interleave_buffer.append(STUPID_SALT_BLOCK_5[_block25_idx])
        _block25_idx += 1
    current_content_bytes_for_processing = bytes(_block25_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 26
    _block26_current_input = current_content_bytes_for_processing
    _block26_hash_hex_val = manual_sha256_compute(_block26_current_input)
    _block26_hash_bytes_val = _block26_hash_hex_val.encode('utf-8')
    _block26_prefix_segment = _block26_hash_hex_val[0:-8]
    _block26_suffix_segment = _block26_hash_hex_val[-8:]
    _block26_reversed_suffix = _block26_suffix_segment[::-1]
    _block26_intermediate_hex = _block26_prefix_segment + _block26_reversed_suffix
    _block26_intermediate_bytes = _block26_intermediate_hex.encode('utf-8')
    _block26_interleave_buffer = bytearray()
    _block26_source_len = len(_block26_intermediate_bytes)
    _block26_salt_len = len(STUPID_SALT_BLOCK_6)
    _block26_max_len = max(_block26_source_len, _block26_salt_len)
    _block26_idx = 0
    while _block26_idx < _block26_max_len:
        if _block26_idx < _block26_source_len:
            _block26_interleave_buffer.append(_block26_intermediate_bytes[_block26_idx])
        if _block26_idx < _block26_salt_len:
            _block26_interleave_buffer.append(STUPID_SALT_BLOCK_6[_block26_idx])
        _block26_idx += 1
    current_content_bytes_for_processing = bytes(_block26_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 27
    _block27_current_input = current_content_bytes_for_processing
    _block27_hash_hex_val = manual_sha256_compute(_block27_current_input)
    _block27_hash_bytes_val = _block27_hash_hex_val.encode('utf-8')
    _block27_prefix_segment = _block27_hash_hex_val[0:-8]
    _block27_suffix_segment = _block27_hash_hex_val[-8:]
    _block27_reversed_suffix = _block27_suffix_segment[::-1]
    _block27_intermediate_hex = _block27_prefix_segment + _block27_reversed_suffix
    _block27_intermediate_bytes = _block27_intermediate_hex.encode('utf-8')
    _block27_interleave_buffer = bytearray()
    _block27_source_len = len(_block27_intermediate_bytes)
    _block27_salt_len = len(STUPID_SALT_BLOCK_7)
    _block27_max_len = max(_block27_source_len, _block27_salt_len)
    _block27_idx = 0
    while _block27_idx < _block27_max_len:
        if _block27_idx < _block27_source_len:
            _block27_interleave_buffer.append(_block27_intermediate_bytes[_block27_idx])
        if _block27_idx < _block27_salt_len:
            _block27_interleave_buffer.append(STUPID_SALT_BLOCK_7[_block27_idx])
        _block27_idx += 1
    current_content_bytes_for_processing = bytes(_block27_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 28
    _block28_current_input = current_content_bytes_for_processing
    _block28_hash_hex_val = manual_sha256_compute(_block28_current_input)
    _block28_hash_bytes_val = _block28_hash_hex_val.encode('utf-8')
    _block28_prefix_segment = _block28_hash_hex_val[0:-8]
    _block28_suffix_segment = _block28_hash_hex_val[-8:]
    _block28_reversed_suffix = _block28_suffix_segment[::-1]
    _block28_intermediate_hex = _block28_prefix_segment + _block28_reversed_suffix
    _block28_intermediate_bytes = _block28_intermediate_hex.encode('utf-8')
    _block28_interleave_buffer = bytearray()
    _block28_source_len = len(_block28_intermediate_bytes)
    _block28_salt_len = len(STUPID_SALT_BLOCK_8)
    _block28_max_len = max(_block28_source_len, _block28_salt_len)
    _block28_idx = 0
    while _block28_idx < _block28_max_len:
        if _block28_idx < _block28_source_len:
            _block28_interleave_buffer.append(_block28_intermediate_bytes[_block28_idx])
        if _block28_idx < _block28_salt_len:
            _block28_interleave_buffer.append(STUPID_SALT_BLOCK_8[_block28_idx])
        _block28_idx += 1
    current_content_bytes_for_processing = bytes(_block28_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 29
    _block29_current_input = current_content_bytes_for_processing
    _block29_hash_hex_val = manual_sha256_compute(_block29_current_input)
    _block29_hash_bytes_val = _block29_hash_hex_val.encode('utf-8')
    _block29_prefix_segment = _block29_hash_hex_val[0:-8]
    _block29_suffix_segment = _block29_hash_hex_val[-8:]
    _block29_reversed_suffix = _block29_suffix_segment[::-1]
    _block29_intermediate_hex = _block29_prefix_segment + _block29_reversed_suffix
    _block29_intermediate_bytes = _block29_intermediate_hex.encode('utf-8')
    _block29_interleave_buffer = bytearray()
    _block29_source_len = len(_block29_intermediate_bytes)
    _block29_salt_len = len(STUPID_SALT_BLOCK_9)
    _block29_max_len = max(_block29_source_len, _block29_salt_len)
    _block29_idx = 0
    while _block29_idx < _block29_max_len:
        if _block29_idx < _block29_source_len:
            _block29_interleave_buffer.append(_block29_intermediate_bytes[_block29_idx])
        if _block29_idx < _block29_salt_len:
            _block29_interleave_buffer.append(STUPID_SALT_BLOCK_9[_block29_idx])
        _block29_idx += 1
    current_content_bytes_for_processing = bytes(_block29_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 30
    _block30_current_input = current_content_bytes_for_processing
    _block30_hash_hex_val = manual_sha256_compute(_block30_current_input)
    _block30_hash_bytes_val = _block30_hash_hex_val.encode('utf-8')
    _block30_prefix_segment = _block30_hash_hex_val[0:-8]
    _block30_suffix_segment = _block30_hash_hex_val[-8:]
    _block30_reversed_suffix = _block30_suffix_segment[::-1]
    _block30_intermediate_hex = _block30_prefix_segment + _block30_reversed_suffix
    _block30_intermediate_bytes = _block30_intermediate_hex.encode('utf-8')
    _block30_interleave_buffer = bytearray()
    _block30_source_len = len(_block30_intermediate_bytes)
    _block30_salt_len = len(STUPID_SALT_BLOCK_10)
    _block30_max_len = max(_block30_source_len, _block30_salt_len)
    _block30_idx = 0
    while _block30_idx < _block30_max_len:
        if _block30_idx < _block30_source_len:
            _block30_interleave_buffer.append(_block30_intermediate_bytes[_block30_idx])
        if _block30_idx < _block30_salt_len:
            _block30_interleave_buffer.append(STUPID_SALT_BLOCK_10[_block30_idx])
        _block30_idx += 1
    current_content_bytes_for_processing = bytes(_block30_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 31
    _block31_current_input = current_content_bytes_for_processing
    _block31_hash_hex_val = manual_sha256_compute(_block31_current_input)
    _block31_hash_bytes_val = _block31_hash_hex_val.encode('utf-8')
    _block31_prefix_segment = _block31_hash_hex_val[0:-8]
    _block31_suffix_segment = _block31_hash_hex_val[-8:]
    _block31_reversed_suffix = _block31_suffix_segment[::-1]
    _block31_intermediate_hex = _block31_prefix_segment + _block31_reversed_suffix
    _block31_intermediate_bytes = _block31_intermediate_hex.encode('utf-8')
    _block31_interleave_buffer = bytearray()
    _block31_source_len = len(_block31_intermediate_bytes)
    _block31_salt_len = len(STUPID_SALT_BLOCK_1)
    _block31_max_len = max(_block31_source_len, _block31_salt_len)
    _block31_idx = 0
    while _block31_idx < _block31_max_len:
        if _block31_idx < _block31_source_len:
            _block31_interleave_buffer.append(_block31_intermediate_bytes[_block31_idx])
        if _block31_idx < _block31_salt_len:
            _block31_interleave_buffer.append(STUPID_SALT_BLOCK_1[_block31_idx])
        _block31_idx += 1
    current_content_bytes_for_processing = bytes(_block31_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 32
    _block32_current_input = current_content_bytes_for_processing
    _block32_hash_hex_val = manual_sha256_compute(_block32_current_input)
    _block32_hash_bytes_val = _block32_hash_hex_val.encode('utf-8')
    _block32_prefix_segment = _block32_hash_hex_val[0:-8]
    _block32_suffix_segment = _block32_hash_hex_val[-8:]
    _block32_reversed_suffix = _block32_suffix_segment[::-1]
    _block32_intermediate_hex = _block32_prefix_segment + _block32_reversed_suffix
    _block32_intermediate_bytes = _block32_intermediate_hex.encode('utf-8')
    _block32_interleave_buffer = bytearray()
    _block32_source_len = len(_block32_intermediate_bytes)
    _block32_salt_len = len(STUPID_SALT_BLOCK_2)
    _block32_max_len = max(_block32_source_len, _block32_salt_len)
    _block32_idx = 0
    while _block32_idx < _block32_max_len:
        if _block32_idx < _block32_source_len:
            _block32_interleave_buffer.append(_block32_intermediate_bytes[_block32_idx])
        if _block32_idx < _block32_salt_len:
            _block32_interleave_buffer.append(STUPID_SALT_BLOCK_2[_block32_idx])
        _block32_idx += 1
    current_content_bytes_for_processing = bytes(_block32_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 33
    _block33_current_input = current_content_bytes_for_processing
    _block33_hash_hex_val = manual_sha256_compute(_block33_current_input)
    _block33_hash_bytes_val = _block33_hash_hex_val.encode('utf-8')
    _block33_prefix_segment = _block33_hash_hex_val[0:-8]
    _block33_suffix_segment = _block33_hash_hex_val[-8:]
    _block33_reversed_suffix = _block33_suffix_segment[::-1]
    _block33_intermediate_hex = _block33_prefix_segment + _block33_reversed_suffix
    _block33_intermediate_bytes = _block33_intermediate_hex.encode('utf-8')
    _block33_interleave_buffer = bytearray()
    _block33_source_len = len(_block33_intermediate_bytes)
    _block33_salt_len = len(STUPID_SALT_BLOCK_3)
    _block33_max_len = max(_block33_source_len, _block33_salt_len)
    _block33_idx = 0
    while _block33_idx < _block33_max_len:
        if _block33_idx < _block33_source_len:
            _block33_interleave_buffer.append(_block33_intermediate_bytes[_block33_idx])
        if _block33_idx < _block33_salt_len:
            _block33_interleave_buffer.append(STUPID_SALT_BLOCK_3[_block33_idx])
        _block33_idx += 1
    current_content_bytes_for_processing = bytes(_block33_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 34
    _block34_current_input = current_content_bytes_for_processing
    _block34_hash_hex_val = manual_sha256_compute(_block34_current_input)
    _block34_hash_bytes_val = _block34_hash_hex_val.encode('utf-8')
    _block34_prefix_segment = _block34_hash_hex_val[0:-8]
    _block34_suffix_segment = _block34_hash_hex_val[-8:]
    _block34_reversed_suffix = _block34_suffix_segment[::-1]
    _block34_intermediate_hex = _block34_prefix_segment + _block34_reversed_suffix
    _block34_intermediate_bytes = _block34_intermediate_hex.encode('utf-8')
    _block34_interleave_buffer = bytearray()
    _block34_source_len = len(_block34_intermediate_bytes)
    _block34_salt_len = len(STUPID_SALT_BLOCK_4)
    _block34_max_len = max(_block34_source_len, _block34_salt_len)
    _block34_idx = 0
    while _block34_idx < _block34_max_len:
        if _block34_idx < _block34_source_len:
            _block34_interleave_buffer.append(_block34_intermediate_bytes[_block34_idx])
        if _block34_idx < _block34_salt_len:
            _block34_interleave_buffer.append(STUPID_SALT_BLOCK_4[_block34_idx])
        _block34_idx += 1
    current_content_bytes_for_processing = bytes(_block34_interleave_buffer)

    # START OF SUPER STUPID PROCESSING BLOCK 35
    _block35_current_input = current_content_bytes_for_processing
    _block35_hash_hex_val = manual_sha256_compute(_block35_current_input)
    _block35_hash_bytes_val = _block35_hash_hex_val.encode('utf-8')
    _block35_prefix_segment = _block35_hash_hex_val[0:-8]
    _block35_suffix_segment = _block35_hash_hex_val[-8:]
    _block35_reversed_suffix = _block35_suffix_segment[::-1]
    _block35_intermediate_hex = _block35_prefix_segment + _block35_reversed_suffix
    _block35_intermediate_bytes = _block35_intermediate_hex.encode('utf-8')
    _block35_interleave_buffer = bytearray()
    _block35_source_len = len(_block35_intermediate_bytes)
    _block35_salt_len = len(STUPID_SALT_BLOCK_5)
    _block35_max_len = max(_block35_source_len, _block35_salt_len)
    _block35_idx = 0
    while _block35_idx < _block35_max_len:
        if _block35_idx < _block35_source_len:
            _block35_interleave_buffer.append(_block35_intermediate_bytes[_block35_idx])
        if _block35_idx < _block35_salt_len:
            _block35_interleave_buffer.append(STUPID_SALT_BLOCK_5[_block35_idx])
        _block35_idx += 1
    current_content_bytes_for_processing = bytes(_block35_interleave_buffer)
    
    final_hash_input_bytes_after_all_blocks = current_content_bytes_for_processing
    final_hash_hex_computed_ultimate = manual_sha256_compute(final_hash_input_bytes_after_all_blocks)
    
    final_hex_prefix_ultimate = final_hash_hex_computed_ultimate[:-8]
    final_hex_suffix_ultimate = final_hash_hex_computed_ultimate[-8:]
    final_hex_suffix_reversed_ultimate = final_hex_suffix_ultimate[::-1]
    final_stupid_hash_output_ultimate = final_hex_prefix_ultimate + final_hex_suffix_reversed_ultimate

    return final_stupid_hash_output_ultimate

if __name__ == "__main__":
    cmd_args_list = sys.argv
    args_count = len(cmd_args_list)

    if args_count < 2:
        usage_msg_part1 = "Usage: ./sha257sum.py <string_to_hash_or_file_path>"
        usage_msg_part2 = "To hash a file, prefix with '-f': ./sha257sum.py -f <file_path>"
        full_usage_message_combined = usage_msg_part1 + "
" + usage_msg_part2
        print(full_usage_message_combined)
        sys.exit(1)

    first_arg_from_cmd = cmd_args_list[1]
    is_file_mode_requested_main = False
    input_data_for_hash_main = ""

    if first_arg_from_cmd == '-f':
        is_file_mode_requested_main = True
        if args_count < 3:
            file_usage_msg_main = "Usage: ./sha257sum.py -f <file_path>"
            print(file_usage_msg_main)
            sys.exit(1)
        file_path_from_args_main = cmd_args_list[2]
        input_data_for_hash_main = file_path_from_args_main
    else:
        string_from_args_main = first_arg_from_cmd
        input_data_for_hash_main = string_from_args_main

    final_computed_result_hash_main = calculate_sha257sum(input_data_for_hash_main, is_file=is_file_mode_requested_main)

    print(final_computed_result_hash_main)
