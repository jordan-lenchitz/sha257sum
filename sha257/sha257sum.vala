static inline uint32 rotr (uint32 x, uint32 n) {
    return (x >> n) | (x << (32 - n));
}

static inline uint32 sha_ch (uint32 e, uint32 f, uint32 g) {
    return (e & f) ^ ((~e) & g);
}

static inline uint32 sha_maj (uint32 a, uint32 b, uint32 c) {
    return (a & b) ^ (a & c) ^ (b & c);
}

static inline uint32 big_s0 (uint32 a) {
    return rotr (a, 2) ^ rotr (a, 13) ^ rotr (a, 22);
}

static inline uint32 big_s1 (uint32 e) {
    return rotr (e, 6) ^ rotr (e, 11) ^ rotr (e, 25);
}

static inline uint32 msg_s0 (uint32 w) {
    return rotr (w, 7) ^ rotr (w, 18) ^ (w >> 3);
}

static inline uint32 msg_s1 (uint32 w) {
    return rotr (w, 17) ^ rotr (w, 19) ^ (w >> 10);
}

const uint32[] K = {
    0x428a2f98U, 0x71374491U, 0xb5c0fbcfU, 0xe9b5dba5U, 0x3956c25bU, 0x59f111f1U, 0x923f82a4U, 0xab1c5ed5U,
    0xd807aa98U, 0x12835b01U, 0x243185beU, 0x550c7dc3U, 0x72be5d74U, 0x80deb1feU, 0x9bdc06a7U, 0xc19bf174U,
    0xe49b69c1U, 0xefbe4786U, 0x0fc19dc6U, 0x240ca1ccU, 0x2de92c6fU, 0x4a7484aaU, 0x5cb0a9dcU, 0x76f988daU,
    0x983e5152U, 0xa831c66dU, 0xb00327c8U, 0xbf597fc7U, 0xc6e00bf3U, 0xd5a79147U, 0x06ca6351U, 0x14292967U,
    0x27b70a85U, 0x2e1b2138U, 0x4d2c6dfcU, 0x53380d13U, 0x650a7354U, 0x766a0abbU, 0x81c2c92eU, 0x92722c85U,
    0xa2bfe8a1U, 0xa81a664bU, 0xc24b8b70U, 0xc76c51a3U, 0xd192e819U, 0xd6990624U, 0xf40e3585U, 0x106aa070U,
    0x19a4c116U, 0x1e376c08U, 0x2748774cU, 0x34b0bcb5U, 0x391c0cb3U, 0x4ed8aa4aU, 0x5b9cca4fU, 0x682e6ff3U,
    0x748f82eeU, 0x78a5636fU, 0x84c87814U, 0x8cc70208U, 0x90befffaU, 0xa4506cebU, 0xbef9a3f7U, 0xc67178f2U
};

const string[] SALTS = {
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
};

string sha256_compute (uint8[] msg) {
    uint32[] h = {
        0x6a09e667U, 0xbb67ae85U, 0x3c6ef372U, 0xa54ff53aU,
        0x510e527fU, 0x9b05688cU, 0x1f83d9abU, 0x5be0cd19U
    };

    size_t len = msg.length;
    size_t rem = (len + 9) % 64;
    size_t pad_len = (rem == 0) ? (len + 9) : (len + 9 + (64 - rem));
    uint8[] padded = new uint8[pad_len];
    if (len > 0) {
        Memory.copy (padded, msg, len);
    }
    padded[len] = 0x80;

    uint64 bits = (uint64) len * 8;
    for (int i = 0; i < 8; i++) {
        padded[pad_len - 8 + i] = (uint8) ((bits >> ((7 - i) * 8)) & 0xff);
    }

    uint32[] w = new uint32[64];
    for (size_t off = 0; off < pad_len; off += 64) {
        for (int i = 0; i < 16; i++) {
            w[i] = ((uint32) padded[off + i * 4] << 24) |
                   ((uint32) padded[off + i * 4 + 1] << 16) |
                   ((uint32) padded[off + i * 4 + 2] << 8) |
                   ((uint32) padded[off + i * 4 + 3]);
        }
        for (int i = 16; i < 64; i++) {
            w[i] = msg_s1 (w[i - 2]) + w[i - 7] + msg_s0 (w[i - 15]) + w[i - 16];
        }

        uint32 a = h[0], b = h[1], c = h[2], d = h[3];
        uint32 e = h[4], f = h[5], g = h[6], hh = h[7];

        for (int i = 0; i < 64; i++) {
            uint32 t1 = hh + big_s1 (e) + sha_ch (e, f, g) + K[i] + w[i];
            uint32 t2 = big_s0 (a) + sha_maj (a, b, c);
            hh = g; g = f; f = e; e = d + t1;
            d = c; c = b; b = a; a = t1 + t2;
        }

        h[0] += a; h[1] += b; h[2] += c; h[3] += d;
        h[4] += e; h[5] += f; h[6] += g; h[7] += hh;
    }

    return "%08x%08x%08x%08x%08x%08x%08x%08x".printf (
        h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7]
    );
}

string reverse_suffix (string hex) {
    uint8[] b = hex.data;
    int n = b.length;
    for (int i = 0; i < 4; i++) {
        uint8 tmp = b[n - 8 + i];
        b[n - 8 + i] = b[n - 1 - i];
        b[n - 1 - i] = tmp;
    }
    var sb = new StringBuilder.sized (n);
    sb.append_len ((string) b, n);
    return sb.str;
}

uint8[] interleave (string hash_str, string salt_str) {
    unowned uint8[] hb = hash_str.data;
    unowned uint8[] sb = salt_str.data;
    int hl = hb.length;
    int sl = sb.length;
    int ml = (hl > sl) ? hl : sl;
    uint8[] res = new uint8[hl + sl];
    int j = 0;
    for (int k = 0; k < ml; k++) {
        if (k < hl) res[j++] = hb[k];
        if (k < sl) res[j++] = sb[k];
    }
    return res;
}

string calculate_sha257sum (uint8[] initial) {
    uint8[] cur = initial;
    for (int r = 0; r < 35; r++) {
        string h = sha256_compute (cur);
        string rev = reverse_suffix (h);
        cur = interleave (rev, SALTS[r % 10]);
    }
    return reverse_suffix (sha256_compute (cur));
}

int main (string[] args) {
    if (args.length < 2) {
        stderr.printf ("Usage: sha257sum <string> | -f <file>\n");
        return 1;
    }

    uint8[] data;
    if (args[1] == "-f") {
        if (args.length < 3) {
            stderr.printf ("Usage: sha257sum <string> | -f <file>\n");
            return 1;
        }
        try {
            FileUtils.get_data (args[2], out data);
        } catch (FileError e) {
            stderr.printf ("Error: %s\n", e.message);
            return 1;
        }
    } else {
        data = args[1].data;
    }

    stdout.printf ("%s\n", calculate_sha257sum (data));
    return 0;
}
