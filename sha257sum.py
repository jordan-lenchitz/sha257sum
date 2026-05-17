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
STUPIDITY_LAYERS = 500 # THIS IS THE KEY TO 1000+ LLOC
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

    layer_iteration_counter_outer = 0
    while layer_iteration_counter_outer < STUPIDITY_LAYERS:
        # BEGIN OF AN EXTREMELY VERBOSE STUPIDITY LAYER

        hash_input_for_layer_step1 = current_content_bytes_for_processing
        computed_hash_hex_for_this_layer_step1 = manual_sha256_compute(hash_input_for_layer_step1)
        encoded_hash_bytes_for_this_layer_step1 = computed_hash_hex_for_this_layer_step1.encode('utf-8')

        # STUPID STEP 1.1: Original 'stupid bit' - Reverse last 8 hex characters (MAX VERBOSITY)
        full_hex_string_1_1_var = computed_hash_hex_for_this_layer_step1
        prefix_segment_1_1_var = full_hex_string_1_1_var[0:-8]
        suffix_segment_1_1_var = full_hex_string_1_1_var[-8:]
        reversed_suffix_1_1_var = suffix_segment_1_1_var[::-1]
        intermediate_hex_result_1_1_var = prefix_segment_1_1_var + reversed_suffix_1_1_var
        intermediate_bytes_result_1_1_var = intermediate_hex_result_1_1_var.encode('utf-8')
        processed_bytes_step_1_1 = intermediate_bytes_result_1_1_var

        # STUPID STEP 1.2: Interleave with STUPID_SALT_BLOCK_1 (MAX VERBOSITY)
        buffer_for_interleaving_1_2_var = bytearray()
        source_bytes_1_2_var = processed_bytes_step_1_1
        salt_bytes_1_2_var = STUPID_SALT_BLOCK_1
        length_source_1_2_var = len(source_bytes_1_2_var)
        length_salt_1_2_var = len(salt_bytes_1_2_var)
        max_length_1_2_var = max(length_source_1_2_var, length_salt_1_2_var)
        current_index_1_2_var = 0
        while current_index_1_2_var < max_length_1_2_var:
            if current_index_1_2_var < length_source_1_2_var:
                byte_from_source_1_2_temp = source_bytes_1_2_var[current_index_1_2_var]
                buffer_for_interleaving_1_2_var.append(byte_from_source_1_2_temp)
            if current_index_1_2_var < length_salt_1_2_var:
                byte_from_salt_1_2_temp = salt_bytes_1_2_var[current_index_1_2_var]
                buffer_for_interleaving_1_2_var.append(byte_from_salt_1_2_temp)
            current_index_1_2_var += 1
        processed_bytes_step_1_2 = bytes(buffer_for_interleaving_1_2_var)

        # STUPID STEP 1.3: XOR with STUPID_SALT_BLOCK_2 (MAX VERBOSITY)
        xor_output_buffer_1_3_var = bytearray()
        source_bytes_1_3_var = processed_bytes_step_1_2
        salt_bytes_1_3_var = STUPID_SALT_BLOCK_2
        length_source_1_3_var = len(source_bytes_1_3_var)
        length_salt_1_3_var = len(salt_bytes_1_3_var)
        loop_index_1_3_var = 0
        while loop_index_1_3_var < length_source_1_3_var:
            byte_s_1_3_temp = source_bytes_1_3_var[loop_index_1_3_var]
            salt_b_1_3_temp = salt_bytes_1_3_var[loop_index_1_3_var % length_salt_1_3_var]
            xored_byte_1_3_calc = byte_s_1_3_temp ^ salt_b_1_3_temp
            xor_output_buffer_1_3_var.append(xored_byte_1_3_calc)
            loop_index_1_3_var += 1
        processed_bytes_step_1_3 = bytes(xor_output_buffer_1_3_var)

        # STUPID STEP 1.4: Reverse byte blocks of arbitrary size (e.g., 6 bytes) and re-concatenate (MAX VERBOSITY)
        block_size_1_4_var = 6
        reverse_blocks_buffer_1_4_var = bytearray()
        current_source_length_1_4_var = len(processed_bytes_step_1_3)
        block_start_index_1_4_var = 0
        while block_start_index_1_4_var < current_source_length_1_4_var:
            block_end_index_1_4_var = block_start_index_1_4_var + block_size_1_4_var
            current_block_1_4_temp = processed_bytes_step_1_3[block_start_index_1_4_var : block_end_index_1_4_var]
            reversed_current_block_1_4_temp = current_block_1_4_temp[::-1]
            reverse_blocks_buffer_1_4_var.extend(reversed_current_block_1_4_temp)
            block_start_index_1_4_var += block_size_1_4_var
        processed_bytes_step_1_4 = bytes(reverse_blocks_buffer_1_4_var)

        # STUPID STEP 1.5: Shift all bytes by a fixed offset (e.g., +11) wrapping around 256 (MAX VERBOSITY)
        shift_offset_1_5_var = 11
        shifted_bytes_buffer_1_5_var = bytearray()
        for byte_value_1_5_temp in processed_bytes_step_1_4:
            shifted_calculated_byte_1_5_temp = (byte_value_1_5_temp + shift_offset_1_5_var) % 256
            shifted_bytes_buffer_1_5_var.append(shifted_calculated_byte_1_5_temp)
        processed_bytes_step_1_5 = bytes(shifted_bytes_buffer_1_5_var)

        # STUPID STEP 1.6: Conditional padding with STUPID_SALT_BLOCK_3 based on current length sum parity (MAX VERBOSITY)
        len_proc_bytes_1_6_var = len(current_content_bytes_for_processing)
        len_inter_bytes_1_6_var = len(processed_bytes_step_1_5)
        sum_of_lengths_1_6_var = len_proc_bytes_1_6_var + len_inter_bytes_1_6_var
        parity_check_1_6_calc = sum_of_lengths_1_6_var % 2
        if parity_check_1_6_calc == 0:
            current_content_bytes_for_processing = processed_bytes_step_1_5 + STUPID_SALT_BLOCK_3
        else:
            current_content_bytes_for_processing = STUPID_SALT_BLOCK_3 + processed_bytes_step_1_5

        # STUPID STEP 1.7: Sub-hash and re-interleave with STUPID_SALT_BLOCK_4 (MAX VERBOSITY)
        sub_hash_input_1_7_var = current_content_bytes_for_processing
        sub_hash_hex_1_7_calc = manual_sha256_compute(sub_hash_input_1_7_var)
        sub_hash_bytes_1_7_encoded = sub_hash_hex_1_7_calc.encode('utf-8')
        
        interleave_buffer_1_7_var = bytearray()
        len_sub_hash_1_7_var = len(sub_hash_bytes_1_7_encoded)
        len_salt_1_7_var = len(STUPID_SALT_BLOCK_4)
        max_len_1_7_var = max(len_sub_hash_1_7_var, len_salt_1_7_var)
        interleave_index_1_7_var = 0
        while interleave_index_1_7_var < max_len_1_7_var:
            if interleave_index_1_7_var < len_sub_hash_1_7_var:
                byte_from_sub_hash_1_7_temp = sub_hash_bytes_1_7_encoded[interleave_index_1_7_var]
                interleave_buffer_1_7_var.append(byte_from_sub_hash_1_7_temp)
            if interleave_index_1_7_var < len_salt_1_7_var:
                byte_from_salt_1_7_temp = STUPID_SALT_BLOCK_4[interleave_index_1_7_var]
                interleave_buffer_1_7_var.append(byte_from_salt_1_7_temp)
            interleave_index_1_7_var += 1
        current_content_bytes_for_processing = bytes(interleave_buffer_1_7_var)

        # STUPID STEP 1.8: Final re-ordering of segments based on layer index (MAX VERBOSITY)
        current_hash_hex_for_reorder_1_8 = manual_sha256_compute(current_content_bytes_for_processing)
        total_length_reorder_1_8 = len(current_hash_hex_for_reorder_1_8)
        quarter_length_reorder_1_8 = total_length_reorder_1_8 // 4
        
        segment_p1_reorder_1_8 = current_hash_hex_for_reorder_1_8[0:quarter_length_reorder_1_8]
        segment_p2_reorder_1_8 = current_hash_hex_for_reorder_1_8[quarter_length_reorder_1_8:2*quarter_length_reorder_1_8]
        segment_p3_reorder_1_8 = current_hash_hex_for_reorder_1_8[2*quarter_length_reorder_1_8:3*quarter_length_reorder_1_8]
        segment_p4_reorder_1_8 = current_hash_hex_for_reorder_1_8[3*quarter_length_reorder_1_8:]

        layer_modulo_3_1_8 = layer_iteration_counter_outer % 3
        combined_segments_reorder_1_8 = ""
        if layer_modulo_3_1_8 == 0:
            combined_segments_reorder_1_8 = segment_p4_reorder_1_8 + segment_p2_reorder_1_8 + segment_p1_reorder_1_8 + segment_p3_reorder_1_8
        elif layer_modulo_3_1_8 == 1:
            combined_segments_reorder_1_8 = segment_p1_reorder_1_8 + segment_p3_reorder_1_8 + segment_p2_reorder_1_8 + segment_p4_reorder_1_8
        else:
            combined_segments_reorder_1_8 = segment_p3_reorder_1_8 + segment_p4_reorder_1_8 + segment_p1_reorder_1_8 + segment_p2_reorder_1_8
        
        current_content_bytes_for_processing = combined_segments_reorder_1_8.encode('utf-8')

        # STUPID STEP 1.9: Redundant hash and further interleaving with STUPID_SALT_BLOCK_5 (MAX VERBOSITY)
        redundant_hash_input_1_9 = current_content_bytes_for_processing
        redundant_hash_hex_1_9_calc = manual_sha256_compute(redundant_hash_input_1_9)
        redundant_hash_bytes_1_9_encoded = redundant_hash_hex_1_9_calc.encode('utf-8')

        interleave_buffer_1_9_var = bytearray()
        len_redundant_hash_1_9_var = len(redundant_hash_bytes_1_9_encoded)
        len_salt_1_9_var = len(STUPID_SALT_BLOCK_5)
        max_len_1_9_var = max(len_redundant_hash_1_9_var, len_salt_1_9_var)
        interleave_index_1_9_var = 0
        while interleave_index_1_9_var < max_len_1_9_var:
            if interleave_index_1_9_var < len_redundant_hash_1_9_var:
                byte_from_redundant_1_9_temp = redundant_hash_bytes_1_9_encoded[interleave_index_1_9_var]
                interleave_buffer_1_9_var.append(byte_from_redundant_1_9_temp)
            if interleave_index_1_9_var < len_salt_1_9_var:
                byte_from_salt_1_9_temp = STUPID_SALT_BLOCK_5[interleave_index_1_9_var]
                interleave_buffer_1_9_var.append(byte_from_salt_1_9_temp)
            interleave_index_1_9_var += 1
        current_content_bytes_for_processing = bytes(interleave_buffer_1_9_var)

        # STUPID STEP 1.10: Byte-level XOR with layer index and STUPID_SALT_BLOCK_6 (MAX VERBOSITY)
        xor_buffer_1_10_var = bytearray()
        source_bytes_1_10_var = current_content_bytes_for_processing
        salt_bytes_1_10_var = STUPID_SALT_BLOCK_6
        len_source_1_10_var = len(source_bytes_1_10_var)
        len_salt_1_10_var = len(salt_bytes_1_10_var)
        loop_idx_1_10_var = 0
        while loop_idx_1_10_var < len_source_1_10_var:
            byte_from_source_1_10_temp = source_bytes_1_10_var[loop_idx_1_10_var]
            salt_byte_1_10_temp = salt_bytes_1_10_var[loop_idx_1_10_var % len_salt_1_10_var]
            xor_with_layer_1_10_calc = (byte_from_source_1_10_temp ^ salt_byte_1_10_temp ^ layer_iteration_counter_outer) % 256
            xor_buffer_1_10_var.append(xor_with_layer_1_10_calc)
            loop_idx_1_10_var += 1
        current_content_bytes_for_processing = bytes(xor_buffer_1_10_var)

        # STUPID STEP 1.11: Generate a dynamic useless string and hash it (for LLOC) (MAX VERBOSITY)
        useless_string_parts_1_11 = []
        useless_prefix_1_11 = "dynamic_useless_prefix_LLOC_"
        useless_string_parts_1_11.append(useless_prefix_1_11)
        useless_layer_str_1_11 = str(layer_iteration_counter_outer)
        useless_string_parts_1_11.append(useless_layer_str_1_11)
        useless_suffix_1_11 = "_suffix_data_MAX_LINES"
        useless_string_parts_1_11.append(useless_suffix_1_11)
        useless_string_concat_1_11 = ''.join(useless_string_parts_1_11)
        useless_hash_input_1_11 = useless_string_concat_1_11.encode('utf-8')
        useless_hash_output_1_11 = manual_sha256_compute(useless_hash_input_1_11)
        dummy_var_for_lloc_1_11 = useless_hash_output_1_11

        # STUPID STEP 1.12: Interleave with STUPID_SALT_BLOCK_7 based on index parity (MAX VERBOSITY)
        interleave_buffer_1_12_var = bytearray()
        source_bytes_1_12_var = current_content_bytes_for_processing
        salt_bytes_1_12_var = STUPID_SALT_BLOCK_7
        len_source_1_12_var = len(source_bytes_1_12_var)
        len_salt_1_12_var = len(salt_bytes_1_12_var)
        loop_idx_1_12_var = 0
        while loop_idx_1_12_var < len_source_1_12_var:
            byte_from_source_1_12_temp = source_bytes_1_12_var[loop_idx_1_12_var]
            interleave_buffer_1_12_var.append(byte_from_source_1_12_temp)
            if loop_idx_1_12_var % 2 == 0 and loop_idx_1_12_var < len_salt_1_12_var:
                byte_from_salt_1_12_temp = salt_bytes_1_12_var[loop_idx_1_12_var]
                interleave_buffer_1_12_var.append(byte_from_salt_1_12_temp)
            loop_idx_1_12_var += 1
        current_content_bytes_for_processing = bytes(interleave_buffer_1_12_var)

        # STUPID STEP 1.13: Arbitrary byte reversal every 3 bytes and re-encode (MAX VERBOSITY)
        reverse_chunk_size_1_13_var = 3
        reversal_buffer_1_13_var = bytearray()
        source_bytes_1_13_var = current_content_bytes_for_processing
        len_source_1_13_var = len(source_bytes_1_13_var)
        chunk_idx_1_13_var = 0
        while chunk_idx_1_13_var < len_source_1_13_var:
            chunk_end_idx_1_13_var = chunk_idx_1_13_var + reverse_chunk_size_1_13_var
            current_chunk_1_13_temp = source_bytes_1_13_var[chunk_idx_1_13_var : chunk_end_idx_1_13_var]
            reversed_chunk_1_13_temp = current_chunk_1_13_temp[::-1]
            reversal_buffer_1_13_var.extend(reversed_chunk_1_13_temp)
            chunk_idx_1_13_var += reverse_chunk_size_1_13_var
        current_content_bytes_for_processing = bytes(reversal_buffer_1_13_var)

        # STUPID STEP 1.14: Concatenate with STUPID_SALT_BLOCK_8 based on conditional length (MAX VERBOSITY)
        len_current_content_1_14_var = len(current_content_bytes_for_processing)
        len_salt_1_14_var = len(STUPID_SALT_BLOCK_8)
        if len_current_content_1_14_var > len_salt_1_14_var:
            current_content_bytes_for_processing = current_content_bytes_for_processing + STUPID_SALT_BLOCK_8
        else:
            current_content_bytes_for_processing = STUPID_SALT_BLOCK_8 + current_content_bytes_for_processing

        # STUPID STEP 1.15: Perform a dummy loop with complex calculation for LLOC (MAX VERBOSITY)
        dummy_sum_1_15_var = 0
        dummy_limit_1_15_var = len(current_content_bytes_for_processing) // 2
        dummy_index_1_15_var = 0
        while dummy_index_1_15_var < dummy_limit_1_15_var:
            byte_a_1_15_temp = current_content_bytes_for_processing[dummy_index_1_15_var]
            byte_b_1_15_temp = current_content_bytes_for_processing[len_current_content_1_14_var - 1 - dummy_index_1_15_var]
            calc_val_1_15_temp = (byte_a_1_15_temp * 3) + (byte_b_1_15_temp // 2) - layer_iteration_counter_outer
            dummy_sum_1_15_var = add_mod(dummy_sum_1_15_var, calc_val_1_15_temp)
            dummy_index_1_15_var += 1
        dummy_final_value_1_15_var = dummy_sum_1_15_var

        # STUPID STEP 1.16: Extra XOR with STUPID_SALT_BLOCK_9 and dynamic value
        xor_buffer_1_16_var = bytearray()
        source_bytes_1_16_var = current_content_bytes_for_processing
        salt_bytes_1_16_var = STUPID_SALT_BLOCK_9
        len_source_1_16_var = len(source_bytes_1_16_var)
        len_salt_9 = len(salt_bytes_1_16_var)
        loop_idx_1_16_var = 0
        while loop_idx_1_16_var < len_source_1_16_var:
            byte_from_source_1_16_temp = source_bytes_1_16_var[loop_idx_1_16_var]
            salt_byte_1_16_temp = salt_bytes_1_16_var[loop_idx_1_16_var % len_salt_9]
            dynamic_xor_val_1_16 = (layer_iteration_counter_outer * loop_idx_1_16_var) % 256
            xor_calculated_byte_1_16 = (byte_from_source_1_16_temp ^ salt_byte_1_16_temp ^ dynamic_xor_val_1_16) % 256
            xor_buffer_1_16_var.append(xor_calculated_byte_1_16)
            loop_idx_1_16_var += 1
        current_content_bytes_for_processing = bytes(xor_buffer_1_16_var)

        # STUPID STEP 1.17: More byte shifting based on multiple offsets
        shift_offset_a_1_17 = 5
        shift_offset_b_1_17 = 13
        shifted_bytes_buffer_1_17_var = bytearray()
        for byte_val_1_17_temp in current_content_bytes_for_processing:
            shifted_a_1_17 = (byte_val_1_17_temp + shift_offset_a_1_17) % 256
            shifted_b_1_17 = (shifted_a_1_17 + shift_offset_b_1_17) % 256
            shifted_bytes_buffer_1_17_var.append(shifted_b_1_17)
        current_content_bytes_for_processing = bytes(shifted_bytes_buffer_1_17_var)

        # STUPID STEP 1.18: Dynamic string construction and hashing (more LLOC)
        dynamic_str_parts_1_18 = []
        dynamic_str_parts_1_18.append("LLOC_GENERATOR_START_")
        dynamic_str_parts_1_18.append(str(layer_iteration_counter_outer))
        dynamic_str_parts_1_18.append("_INTERMEDIATE_")
        dynamic_str_parts_1_18.append(str(len(current_content_bytes_for_processing)))
        dynamic_str_parts_1_18.append("_END_LLOC_GEN").append(str(layer_iteration_counter_outer * 7))
        dynamic_useless_string_1_18 = ''.join(dynamic_str_parts_1_18)
        dynamic_useless_bytes_1_18 = dynamic_useless_string_1_18.encode('utf-8')
        dynamic_hash_output_1_18 = manual_sha256_compute(dynamic_useless_bytes_1_18)
        dummy_var_for_lloc_1_18 = dynamic_hash_output_1_18

        # STUPID STEP 1.19: Final interleaving with STUPID_SALT_BLOCK_10
        interleave_buffer_1_19_var = bytearray()
        source_bytes_1_19_var = current_content_bytes_for_processing
        salt_bytes_1_19_var = STUPID_SALT_BLOCK_10
        len_source_1_19_var = len(source_bytes_1_19_var)
        len_salt_10 = len(salt_bytes_1_19_var)
        loop_idx_1_19_var = 0
        while loop_idx_1_19_var < len_source_1_19_var:
            byte_from_source_1_19_temp = source_bytes_1_19_var[loop_idx_1_19_var]
            interleave_buffer_1_19_var.append(byte_from_source_1_19_temp)
            if loop_idx_1_19_var % 4 == 0 and loop_idx_1_19_var < len_salt_10:
                interleave_buffer_1_19_var.append(salt_bytes_1_19_var[loop_idx_1_19_var])
            loop_idx_1_19_var += 1
        current_content_bytes_for_processing = bytes(interleave_buffer_1_19_var)

        layer_iteration_counter_outer += 1
        # END OF AN EXTREMELY VERBOSE STUPIDITY LAYER

    final_hash_input_bytes_after_all = current_content_bytes_for_processing
    final_hash_hex_computed_ultimate = manual_sha256_compute(final_hash_input_bytes_after_all)
    
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
