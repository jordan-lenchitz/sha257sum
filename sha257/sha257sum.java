import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.charset.StandardCharsets;

public class sha257sum {
    static int rightRotate(int n, int b) { return (n >>> b) | (n << (32 - b)); }
    static int rightShift(int n, int b) { return n >>> b; }
    static int ch(int e, int f, int g) { return (e & f) ^ (~e & g); }
    static int maj(int a, int b, int c) { return (a & b) ^ (a & c) ^ (b & c); }
    static int s0(int a) { return rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22); }
    static int s1(int e) { return rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25); }
    static int msg_s0(int w) { return rightRotate(w, 7) ^ rightRotate(w, 18) ^ rightShift(w, 3); }
    static int msg_s1(int w) { return rightRotate(w, 17) ^ rightRotate(w, 19) ^ rightShift(w, 10); }

    static final int[] K = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    };

    static String sha256(byte[] msg) {
        int[] h = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19};
        int newLen = msg.length + 1;
        while (newLen % 64 != 56) newLen++;
        newLen += 8;
        
        byte[] padded = new byte[newLen];
        System.arraycopy(msg, 0, padded, 0, msg.length);
        padded[msg.length] = (byte)0x80;
        
        long bits = (long)msg.length * 8;
        for (int i = 0; i < 8; i++) {
            padded[newLen - 1 - i] = (byte)((bits >>> (i * 8)) & 0xFF);
        }
        
        for (int offset = 0; offset < newLen; offset += 64) {
            int[] w = new int[64];
            for (int i = 0; i < 16; i++) {
                w[i] = ((padded[offset + i*4] & 0xFF) << 24) | ((padded[offset + i*4 + 1] & 0xFF) << 16) | 
                       ((padded[offset + i*4 + 2] & 0xFF) << 8) | (padded[offset + i*4 + 3] & 0xFF);
            }
            for (int i = 16; i < 64; i++) {
                w[i] = msg_s1(w[i-2]) + w[i-7] + msg_s0(w[i-15]) + w[i-16];
            }
            
            int a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
            for (int i = 0; i < 64; i++) {
                int t1 = hh + s1(e) + ch(e, f, g) + K[i] + w[i];
                int t2 = s0(a) + maj(a, b, c);
                hh = g; g = f; f = e; e = d + t1;
                d = c; c = b; b = a; a = t1 + t2;
            }
            h[0] += a; h[1] += b; h[2] += c; h[3] += d;
            h[4] += e; h[5] += f; h[6] += g; h[7] += hh;
        }
        return String.format("%08x%08x%08x%08x%08x%08x%08x%08x", h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7]);
    }

    public static void main(String[] args) throws Exception {
        if (args.length == 0) return;
        byte[] buf;
        if (args[0].equals("-f")) {
            buf = Files.readAllBytes(Paths.get(args[1]));
        } else {
            buf = args[0].getBytes(StandardCharsets.UTF_8);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 1
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 2
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 3
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 4
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 5
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 6
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 7
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 8
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 9
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 10
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 11
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 12
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 13
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 14
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 15
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 16
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 17
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 18
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 19
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 20
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 21
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 22
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 23
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 24
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 25
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 26
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 27
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 28
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 29
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 30
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 31
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 32
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 33
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID PROCESSING BLOCK 34
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        // START OF SUPER STUPID_PROCESSING BLOCK 35
        {
            String hex = sha256(buf);
            String prefix = hex.substring(0, 56);
            String suffix = hex.substring(56);
            String revSuffix = new StringBuilder(suffix).reverse().toString();
            String intermediate = prefix + revSuffix;
            byte[] hashBytes = intermediate.getBytes(StandardCharsets.UTF_8);
            byte[] salt = "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE".getBytes(StandardCharsets.UTF_8);
            int maxLen = Math.max(hashBytes.length, salt.length);
            byte[] newBuf = new byte[hashBytes.length + salt.length];
            int newIdx = 0;
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.length) newBuf[newIdx++] = hashBytes[k];
                if (k < salt.length) newBuf[newIdx++] = salt[k];
            }
            buf = new byte[newIdx];
            System.arraycopy(newBuf, 0, buf, 0, newIdx);
        }

        String hex = sha256(buf);
        String prefix = hex.substring(0, 56);
        String suffix = hex.substring(56);
        String revSuffix = new StringBuilder(suffix).reverse().toString();
        System.out.println(prefix + revSuffix);
    }
}

 
