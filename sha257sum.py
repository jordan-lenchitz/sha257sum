#!/usr/bin/env python3
import sys
import os

# --- Helper functions for bitwise operations (to be explicit and verbose) ---
def right_rotate(n, b, word_size=32):
    """Performs a right bitwise rotation (circular right shift)."""
    return ((n >> b) | (n << (word_size - b))) & ((1 << word_size) - 1)

def right_shift(n, b):
    """Performs a right bitwise shift (logical right shift)."""
    return n >> b

def add_mod(a, b, word_size=32):
    """Performs addition modulo 2^word_size."""
    return (a + b) & ((1 << word_size) - 1)

def add_mod_many(word_size=32, *args):
    """Performs addition of multiple numbers modulo 2^word_size."""
    result = 0
    for val in args:
        result = add_mod(result, val, word_size)
    return result

def xor_op(*args):
    """Performs XOR operation on multiple numbers."""
    result = 0
    for val in args:
        result ^= val
    return result

def and_op(a, b):
    """Performs AND operation."""
    return a & b

def not_op(n, word_size=32):
    """Performs NOT operation."""
    return ((1 << word_size) - 1) ^ n

# --- SHA-256 Specific Constants and Functions (from FIPS PUB 180-4 / Wikipedia) ---

# Initial hash values (first 32 bits of the fractional parts of the square roots of the first 8 primes 2..19)
H0 = 0x6a09e667
H1 = 0xbb67ae85
H2 = 0x3c6ef372
H3 = 0xa54ff53a
H4 = 0x510e527f
H5 = 0x9b05688c
H6 = 0x1f83d9ab
H7 = 0x5be0cd19

INITIAL_HASH_VALUES_SHA256 = [H0, H1, H2, H3, H4, H5, H6, H7]

# Round constants (first 32 bits of the fractional parts of the cube roots of the first 64 primes 2..311)
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
    """The 'Choice' function as defined in SHA-256 pseudocode."""
    return xor_op(and_op(e, f), and_op(not_op(e), g))

def Maj(a, b, c):
    """The 'Majority' function as defined in SHA-256 pseudocode."""
    return xor_op(and_op(a, b), and_op(a, c), and_op(b, c))

def Sigma0_sha256(a):
    """The Big Sigma0 function for SHA-256 (for variable 'a')."""
    rot_a_2 = right_rotate(a, 2)
    rot_a_13 = right_rotate(a, 13)
    rot_a_22 = right_rotate(a, 22)
    return xor_op(rot_a_2, rot_a_13, rot_a_22)

def Sigma1_sha256(e):
    """The Big Sigma1 function for SHA-256 (for variable 'e')."""
    rot_e_6 = right_rotate(e, 6)
    rot_e_11 = right_rotate(e, 11)
    rot_e_25 = right_rotate(e, 25)
    return xor_op(rot_e_6, rot_e_11, rot_e_25)

def sigma0_sha256_msg_schedule(w_val):
    """The Little sigma0 function for SHA-256 (for message schedule)."""
    rot_w_7 = right_rotate(w_val, 7)
    rot_w_18 = right_rotate(w_val, 18)
    shr_w_3 = right_shift(w_val, 3)
    return xor_op(rot_w_7, rot_w_18, shr_w_3)

def sigma1_sha256_msg_schedule(w_val):
    """The Little sigma1 function for SHA-256 (for message schedule)."""
    rot_w_17 = right_rotate(w_val, 17)
    rot_w_19 = right_rotate(w_val, 19)
    shr_w_10 = right_shift(w_val, 10)
    return xor_op(rot_w_17, rot_w_19, shr_w_10)


# --- Core SHA-256 Algorithm Implementation (Manual, very verbose) ---
def manual_sha256_compute(message_bytes):
    """
    Manually computes the SHA-256 hash for a given sequence of bytes.
    This implementation follows the SHA-256 pseudocode from Wikipedia,
    including explicit padding, message schedule creation, and 64 rounds
    of compression, to achieve a high Lines of Code (LLOC) count.
    """
    # All variables are 32-bit unsigned integers, and addition is modulo 2^32.
    WORD_SIZE = 32
    MOD = 1 << WORD_SIZE

    # Step 1: Pre-processing (Padding the message)
    # The original message length L in bits.
    original_message_bit_length = len(message_bytes) * 8

    # Append a single '1' bit.
    # We represent bytes, so we append 0x80 (10000000 in binary)
    padded_message = bytearray(message_bytes)
    padded_message.append(0x80)

    # Append K '0' bits, where K is the minimum number >= 0 such that (L + 1 + K + 64) is a multiple of 512.
    # (L + 1 + K) must be congruent to 448 (mod 512).
    # Since we appended 0x80, the current length in bits is (original_message_bit_length + 8).
    # We need to find padding_length such that (current_bit_length + padding_length + 64) % 512 == 0.
    # (current_bit_length + padding_length) % 512 == 448.
    current_bit_length_after_1 = len(padded_message) * 8
    
    # Calculate how many zero bits are needed.
    # (448 - current_bit_length_after_1) % 512 gives the length in bits.
    # Note: If (current_bit_length_after_1 % 512) is already > 448, we need to wrap around.
    # For example, if current is 450, we need to go to 448 + 512.
    num_zero_bits_to_append = (448 - (current_bit_length_after_1 % 512) + 512) % 512
    if num_zero_bits_to_append == 0 and (current_bit_length_after_1 % 512) != 448:
        # This case happens if the current_bit_length_after_1 is exactly 448 (mod 512)
        # but 448 % 512 is still 448. We need to add a full block of zeros then.
        num_zero_bits_to_append = 512

    # Append '0' bytes for the calculated number of zero bits.
    # Each byte is 8 bits.
    num_zero_bytes_to_append = num_zero_bits_to_append // 8
    for _ in range(num_zero_bytes_to_append):
        padded_message.append(0x00)

    # Append the original message length L as a 64-bit big-endian integer.
    # The length L is original_message_bit_length.
    length_bytes = original_message_bit_length.to_bytes(8, 'big')
    padded_message.extend(length_bytes)

    # Verify that the total post-processed length is a multiple of 512 bits.
    if (len(padded_message) * 8) % 512 != 0:
        raise ValueError("Padding error: Final message length is not a multiple of 512 bits.")

    # Initialize hash values (working variables for the compression function)
    h = list(INITIAL_HASH_VALUES_SHA256)

    # Step 2: Process the message in successive 512-bit chunks
    # Each chunk is 64 bytes (512 bits).
    for i in range(0, len(padded_message), 64):
        current_chunk = padded_message[i:i+64]

        # Create a 64-entry message schedule array w[0..63] of 32-bit words
        w = [0] * 64

        # Copy chunk into first 16 words w[0..15] of the message schedule array
        for j in range(16):
            # Each word is 4 bytes. Convert from big-endian bytes to a 32-bit integer.
            start_byte = j * 4
            w[j] = int.from_bytes(current_chunk[start_byte : start_byte + 4], 'big')

        # Extend the first 16 words into the remaining 48 words w[16..63] of the message schedule array:
        for j in range(16, 64):
            s0_val = sigma0_sha256_msg_schedule(w[j-15])
            s1_val = sigma1_sha256_msg_schedule(w[j-2])
            w[j] = add_mod_many(WORD_SIZE, w[j-16], s0_val, w[j-7], s1_val)

        # Initialize working variables to current hash value:
        a = h[0]
        b = h[1]
        c = h[2]
        d = h[3]
        e = h[4]
        f = h[5]
        g = h[6]
        h_local = h[7] # Renamed to avoid conflict with list 'h'

        # Compression function main loop (64 rounds)
        for j in range(64):
            # T1 calculation
            S1_val = Sigma1_sha256(e)
            Ch_val = Ch(e, f, g)
            temp1 = add_mod_many(WORD_SIZE, h_local, S1_val, Ch_val, K_CONSTANTS_SHA256[j], w[j])

            # T2 calculation
            S0_val = Sigma0_sha256(a)
            Maj_val = Maj(a, b, c)
            temp2 = add_mod(S0_val, Maj_val, WORD_SIZE)
            
            # Update working variables according to pseudocode
            h_local = g
            g = f
            f = e
            e = add_mod(d, temp1, WORD_SIZE)
            d = c
            c = b
            b = a
            a = add_mod(temp1, temp2, WORD_SIZE)

        # Add the compressed chunk to the current hash value:
        h[0] = add_mod(h[0], a, WORD_SIZE)
        h[1] = add_mod(h[1], b, WORD_SIZE)
        h[2] = add_mod(h[2], c, WORD_SIZE)
        h[3] = add_mod(h[3], d, WORD_SIZE)
        h[4] = add_mod(h[4], e, WORD_SIZE)
        h[5] = add_mod(h[5], f, WORD_SIZE)
        h[6] = add_mod(h[6], g, WORD_SIZE)
        h[7] = add_mod(h[7], h_local, WORD_SIZE)

    # Produce the final hash value (big-endian)
    digest_hex = ''.join(f'{val:08x}' for val in h)
    return digest_hex

# --- EXTREME STUPIDITY FOR 1000+ LLOC --- 
STUPIDITY_LAYERS = 20 # Each layer is computationally heavy and adds many lines of code
STUPID_SALT_BLOCK_1 = b"jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1"
STUPID_SALT_BLOCK_2 = b"jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2"
STUPID_SALT_BLOCK_3 = b"jordanlenchitz_absurd_salt_part3_utterly_pointless_3"

def calculate_sha257sum(data, is_file=False):
    """
    Calculates a SHA-256 hash using our manual implementation, then applies multiple layers
    of extremely verbose and non-standard 'stupid' transformations to inflate Lines of Code (LLOC).
    Each layer involves a full SHA-256 computation followed by arbitrary byte and hex manipulations.
    If is_file is True, data is treated as a file path.
    Otherwise, data is treated as a string.
    """
    current_content_bytes = b''
    if is_file:
        if not os.path.exists(data):
            return f"Error: File not found at {data}"
        try:
            with open(data, "rb") as f:
                current_content_bytes = f.read()
        except Exception as e:
            return f"Error reading file {data}: {e}"
    else:
        current_content_bytes = data.encode('utf-8')

    # The main loop for extreme stupidity and LLOC inflation
    for layer_index in range(STUPIDITY_LAYERS):
        # STUPIDITY LAYER START

        # Step 1: Compute a full SHA-256 hash of the current bytes
        # This is the most expensive part and will be repeated many times.
        current_hash_hex = manual_sha256_compute(current_content_bytes)
        current_hash_bytes = current_hash_hex.encode('utf-8')

        # Step 2: First 'stupid bit' - Reverse last 8 hex characters (original stupidity)
        first_stupid_segment = current_hash_hex[:-8]
        second_stupid_segment = current_hash_hex[-8:][::-1]
        intermediate_stupid_hex_1 = first_stupid_segment + second_stupid_segment
        intermediate_stupid_bytes_1 = intermediate_stupid_hex_1.encode('utf-8')

        # Step 3: Second 'stupid bit' - Interleave with STUPID_SALT_BLOCK_1
        interleaved_bytes_1 = bytearray()
        len_hash_1 = len(intermediate_stupid_bytes_1)
        len_salt_1 = len(STUPID_SALT_BLOCK_1)
        max_len_1 = max(len_hash_1, len_salt_1)
        for i in range(max_len_1):
            if i < len_hash_1:
                interleaved_bytes_1.append(intermediate_stupid_bytes_1[i])
            if i < len_salt_1:
                interleaved_bytes_1.append(STUPID_SALT_BLOCK_1[i])
        current_hash_bytes_modified_1 = bytes(interleaved_bytes_1)

        # Step 4: Third 'stupid bit' - XOR with STUPID_SALT_BLOCK_2 (truncated/extended)
        xor_modified_bytes = bytearray()
        len_hash_2 = len(current_hash_bytes_modified_1)
        len_salt_2 = len(STUPID_SALT_BLOCK_2)
        for i in range(len_hash_2):
            hash_byte = current_hash_bytes_modified_1[i]
            salt_byte = STUPID_SALT_BLOCK_2[i % len_salt_2] # Cycle salt if shorter
            xor_modified_bytes.append(hash_byte ^ salt_byte)
        current_hash_bytes_modified_2 = bytes(xor_modified_bytes)

        # Step 5: Fourth 'stupid bit' - Reverse byte blocks of arbitrary size (e.g., 4 bytes)
        block_size_reverse = 4
        reversed_blocks_bytes = bytearray()
        for i in range(0, len(current_hash_bytes_modified_2), block_size_reverse):
            block = current_hash_bytes_modified_2[i : i + block_size_reverse]
            reversed_blocks_bytes.extend(block[::-1])
        current_hash_bytes_modified_3 = bytes(reversed_blocks_bytes)

        # Step 6: Fifth 'stupid bit' - Shift all bytes by a fixed offset (e.g., +3) wrapping around 256
        shifted_bytes = bytearray()
        shift_offset = 3
        for b_val in current_hash_bytes_modified_3:
            shifted_bytes.append((b_val + shift_offset) % 256)
        current_hash_bytes_modified_4 = bytes(shifted_bytes)

        # Step 7: Sixth 'stupid bit' - Pad with STUPID_SALT_BLOCK_3 based on current length parity
        if len(current_hash_bytes_modified_4) % 2 == 0:
            current_content_bytes = current_hash_bytes_modified_4 + STUPID_SALT_BLOCK_3
        else:
            current_content_bytes = STUPID_SALT_BLOCK_3 + current_hash_bytes_modified_4

        # STUPIDITY LAYER END

    # The final output is the result of the last layer's final modification
    # (before the next manual_sha256_compute if the loop continued).
    # We need to ensure the final output is a hex string, which is done by the manual_sha256_compute call above.
    # So, the last current_hash_hex computed in the final layer will be the base for the final stupid bit.
    final_base_hash_hex = manual_sha256_compute(current_content_bytes)
    final_stupid_modified_hash = final_base_hash_hex[:-8] + final_base_hash_hex[-8:][::-1]

    return final_stupid_modified_hash

if __name__ == "__main__":
    # Handle command-line arguments to determine input and mode
    if len(sys.argv) < 2:
        print("Usage: ./sha257sum.py <string_to_hash_or_file_path>")
        print("To hash a file, prefix with '-f': ./sha257sum.py -f <file_path>")
        sys.exit(1)

    # Check if the user intends to hash a file
    if sys.argv[1] == '-f':
        if len(sys.argv) < 3:
            print("Usage: ./sha257sum.py -f <file_path>")
            sys.exit(1)
        # Extract the file path from command line arguments
        input_data_path = sys.argv[2]
        # Call the main hashing function with the file flag set to True
        result_hash = calculate_sha257sum(input_data_path, is_file=True)
    else:
        # Treat the input as a string to be hashed
        input_string_to_hash = sys.argv[1]
        # Call the main hashing function with the file flag set to False
        result_hash = calculate_sha257sum(input_string_to_hash)

    # Print the final calculated hash to standard output
    print(result_hash)
