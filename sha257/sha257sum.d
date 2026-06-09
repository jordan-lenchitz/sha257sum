import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.algorithm;
import std.array;
import std.digest;

uint right_rotate(uint n, uint b) {
    return (n >> b) | (n << (32 - b));
}

uint right_shift(uint n, uint b) {
    return n >> b;
}

uint ch(uint e, uint f, uint g) {
    return (e & f) ^ (~e & g);
}

uint maj(uint a, uint b, uint c) {
    return (a & b) ^ (a & c) ^ (b & c);
}

uint s0_func(uint a) {
    return right_rotate(a, 2) ^ right_rotate(a, 13) ^ right_rotate(a, 22);
}

uint s1_func(uint e) {
    return right_rotate(e, 6) ^ right_rotate(e, 11) ^ right_rotate(e, 25);
}

uint msg_s0(uint w) {
    return right_rotate(w, 7) ^ right_rotate(w, 18) ^ (w >> 3);
}

uint msg_s1(uint w) {
    return right_rotate(w, 17) ^ right_rotate(w, 19) ^ (w >> 10);
}

immutable uint[64] K = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];

string sha256_compute(const ubyte[] msg) {
    uint[8] h = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
    
    ulong bits = msg.length * 8;
    ubyte[] padded = msg.dup;
    padded ~= 0x80;
    while (padded.length % 64 != 56) padded ~= 0;
    
    for (int i = 7; i >= 0; i--) {
        padded ~= cast(ubyte)((bits >> (i * 8)) & 0xFF);
    }
    
    for (size_t offset = 0; offset < padded.length; offset += 64) {
        uint[64] w;
        for (int i = 0; i < 16; i++) {
            w[i] = (cast(uint)padded[offset + i*4] << 24) |
                   (cast(uint)padded[offset + i*4 + 1] << 16) |
                   (cast(uint)padded[offset + i*4 + 2] << 8) |
                   (cast(uint)padded[offset + i*4 + 3]);
        }
        for (int i = 16; i < 64; i++) {
            w[i] = msg_s1(w[i-2]) + w[i-7] + msg_s0(w[i-15]) + w[i-16];
        }
        
        uint a = h[0], b = h[1], c = h[2], d = h[3];
        uint e = h[4], f = h[5], g = h[6], hh = h[7];
        
        for (int i = 0; i < 64; i++) {
            uint t1 = hh + s1_func(e) + ch(e, f, g) + K[i] + w[i];
            uint t2 = s0_func(a) + maj(a, b, c);
            hh = g; g = f; f = e; e = d + t1;
            d = c; c = b; b = a; a = t1 + t2;
        }
        h[0] += a; h[1] += b; h[2] += c; h[3] += d;
        h[4] += e; h[5] += f; h[6] += g; h[7] += hh;
    }
    
    string res = "";
    foreach (val; h) res ~= format("%08x", val);
    return res;
}

immutable string[10] SALTS = [
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
];

ubyte[] interleave(string hash, string salt) {
    ubyte[] res;
    size_t hl = hash.length;
    size_t sl = salt.length;
    size_t ml = hl > sl ? hl : sl;
    for (size_t i = 0; i < ml; i++) {
        if (i < hl) res ~= cast(ubyte)hash[i];
        if (i < sl) res ~= cast(ubyte)salt[i];
    }
    return res;
}

string calculate_sha257sum(ubyte[] data) {
    ubyte[] current = data;
    
    int[35] salt_indices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4];
    
    foreach (idx; salt_indices) {
        string h = sha256_compute(current);
        string prefix = h[0..$-8];
        string suffix = h[$-8..$];
        string rev_suffix = suffix.dup.reverse.idup;
        current = interleave(prefix ~ rev_suffix, SALTS[idx]);
    }
    
    string final_h = sha256_compute(current);
    return final_h[0..$-8] ~ final_h[$-8..$].dup.reverse.idup;
}

int main(string[] args) {
    if (args.length < 2) {
        writeln("Usage: ./sha257sum <string_to_hash_or_file_path>");
        writeln("To hash a file, prefix with '-f': ./sha257sum -f <file_path>");
        return 1;
    }
    
    ubyte[] input;
    if (args[1] == "-f") {
        if (args.length < 3) return 1;
        input = cast(ubyte[])read(args[2]);
    } else {
        input = cast(ubyte[])args[1];
    }
    
    writeln(calculate_sha257sum(input));
    return 0;
}
