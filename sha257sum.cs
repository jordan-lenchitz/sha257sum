using System;
using System.IO;
using System.Text;
using System.Linq;
using System.Collections.Generic;

class Sha257Sum {
    static uint rightRotate(uint n, int b) { return (n >> b) | (n << (32 - b)); }
    static uint rightShift(uint n, int b) { return n >> b; }
    static uint ch(uint e, uint f, uint g) { return (e & f) ^ (~e & g); }
    static uint maj(uint a, uint b, uint c) { return (a & b) ^ (a & c) ^ (b & c); }
    static uint s0(uint a) { return rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22); }
    static uint s1(uint e) { return rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25); }
    static uint msg_s0(uint w) { return rightRotate(w, 7) ^ rightRotate(w, 18) ^ rightShift(w, 3); }
    static uint msg_s1(uint w) { return rightRotate(w, 17) ^ rightRotate(w, 19) ^ rightShift(w, 10); }

    static readonly uint[] K = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    };

    static string sha256(byte[] msg) {
        uint[] h = { 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 
                     0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19 };
        
        int newLen = msg.Length + 1;
        while (newLen % 64 != 56) newLen++;
        newLen += 8;
        
        byte[] padded = new byte[newLen];
        Array.Copy(msg, padded, msg.Length);
        padded[msg.Length] = 0x80;
        
        ulong bits = (ulong)msg.Length * 8;
        for (int i = 0; i < 8; i++) {
            padded[newLen - 1 - i] = (byte)((bits >> (i * 8)) & 0xFF);
        }
        
        for (int offset = 0; offset < newLen; offset += 64) {
            uint[] w = new uint[64];
            for (int i = 0; i < 16; i++) {
                w[i] = ((uint)padded[offset + i*4] << 24) | ((uint)padded[offset + i*4 + 1] << 16) | 
                       ((uint)padded[offset + i*4 + 2] << 8) | (uint)padded[offset + i*4 + 3];
            }
            for (int i = 16; i < 64; i++) {
                w[i] = msg_s1(w[i-2]) + w[i-7] + msg_s0(w[i-15]) + w[i-16];
            }
            
            uint a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
            
            for (int i = 0; i < 64; i++) {
                uint t1 = hh + s1(e) + ch(e, f, g) + K[i] + w[i];
                uint t2 = s0(a) + maj(a, b, c);
                hh = g; g = f; f = e; e = d + t1;
                d = c; c = b; b = a; a = t1 + t2;
            }
            h[0] += a; h[1] += b; h[2] += c; h[3] += d;
            h[4] += e; h[5] += f; h[6] += g; h[7] += hh;
        }
        
        return string.Join("", h.Select(x => x.ToString("x8")));
    }

    static void Main(string[] args) {
        if (args.Length < 1) return;
        byte[] buf;
        if (args[0] == "-f") buf = File.ReadAllBytes(args[1]);
        else buf = Encoding.ASCII.GetBytes(args[0]);

        // BLOCK 1
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 49, 95, 76, 76, 79, 67, 95, 73, 78, 67, 82, 69, 65, 83, 69, 95, 65, 65 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 2
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 50, 95, 118, 101, 114, 121, 95, 115, 105, 108, 108, 121, 95, 110, 111, 110, 115, 101, 110, 115, 101, 95, 50, 95, 76, 76, 79, 67, 95, 69, 78, 72, 65, 78, 67, 69, 95, 66, 66 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 3
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 51, 95, 117, 116, 116, 101, 114, 108, 121, 95, 112, 111, 105, 110, 116, 108, 101, 115, 115, 95, 51, 95, 76, 76, 79, 67, 95, 77, 65, 88, 73, 77, 85, 77, 95, 67, 67 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 4
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 52, 95, 102, 105, 110, 97, 108, 95, 115, 105, 108, 108, 121, 95, 98, 105, 116, 115, 95, 52, 95, 76, 76, 79, 67, 95, 79, 86, 69, 82, 95, 49, 48, 48, 48, 95, 68, 68 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 5
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 53, 95, 109, 111, 114, 101, 95, 114, 97, 110, 100, 111, 109, 95, 98, 121, 116, 101, 115, 95, 53, 95, 76, 76, 79, 67, 95, 65, 66, 85, 78, 68, 65, 78, 67, 69, 95, 69, 69 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 6
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 54, 95, 101, 120, 116, 114, 97, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 54, 95, 76, 76, 79, 67, 95, 71, 69, 78, 69, 82, 65, 84, 69, 95, 70, 70 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 7
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 55, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 98, 108, 111, 99, 107, 95, 55, 95, 76, 76, 79, 67, 95, 70, 73, 76, 76, 95, 71, 71 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 8
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 56, 95, 106, 117, 115, 116, 95, 102, 111, 114, 95, 108, 105, 110, 101, 115, 95, 56, 95, 76, 76, 79, 67, 95, 77, 65, 78, 89, 95, 77, 65, 78, 89, 95, 72, 72 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 9
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 57, 95, 121, 101, 116, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 57, 95, 76, 76, 79, 67, 95, 77, 79, 82, 69, 95, 73, 73 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 10
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 48, 95, 102, 105, 110, 97, 108, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 49, 48, 95, 76, 76, 79, 67, 95, 69, 78, 68, 95, 79, 70, 95, 83, 65, 76, 84, 83, 95, 74, 74 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 11
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 49, 95, 76, 76, 79, 67, 95, 73, 78, 67, 82, 69, 65, 83, 69, 95, 65, 65 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 12
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 50, 95, 118, 101, 114, 121, 95, 115, 105, 108, 108, 121, 95, 110, 111, 110, 115, 101, 110, 115, 101, 95, 50, 95, 76, 76, 79, 67, 95, 69, 78, 72, 65, 78, 67, 69, 95, 66, 66 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 13
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 51, 95, 117, 116, 116, 101, 114, 108, 121, 95, 112, 111, 105, 110, 116, 108, 101, 115, 115, 95, 51, 95, 76, 76, 79, 67, 95, 77, 65, 88, 73, 77, 85, 77, 95, 67, 67 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 14
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 52, 95, 102, 105, 110, 97, 108, 95, 115, 105, 108, 108, 121, 95, 98, 105, 116, 115, 95, 52, 95, 76, 76, 79, 67, 95, 79, 86, 69, 82, 95, 49, 48, 48, 48, 95, 68, 68 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 15
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 53, 95, 109, 111, 114, 101, 95, 114, 97, 110, 100, 111, 109, 95, 98, 121, 116, 101, 115, 95, 53, 95, 76, 76, 79, 67, 95, 65, 66, 85, 78, 68, 65, 78, 67, 69, 95, 69, 69 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 16
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 54, 95, 101, 120, 116, 114, 97, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 54, 95, 76, 76, 79, 67, 95, 71, 69, 78, 69, 82, 65, 84, 69, 95, 70, 70 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 17
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 55, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 98, 108, 111, 99, 107, 95, 55, 95, 76, 76, 79, 67, 95, 70, 73, 76, 76, 95, 71, 71 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 18
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 56, 95, 106, 117, 115, 116, 95, 102, 111, 114, 95, 108, 105, 110, 101, 115, 95, 56, 95, 76, 76, 79, 67, 95, 77, 65, 78, 89, 95, 77, 65, 78, 89, 95, 72, 72 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 19
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 57, 95, 121, 101, 116, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 57, 95, 76, 76, 79, 67, 95, 77, 79, 82, 69, 95, 73, 73 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 20
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 48, 95, 102, 105, 110, 97, 108, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 49, 48, 95, 76, 76, 79, 67, 95, 69, 78, 68, 95, 79, 70, 95, 83, 65, 76, 84, 83, 95, 74, 74 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 21
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 49, 95, 76, 76, 79, 67, 95, 73, 78, 67, 82, 69, 65, 83, 69, 95, 65, 65 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 22
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 50, 95, 118, 101, 114, 121, 95, 115, 105, 108, 108, 121, 95, 110, 111, 110, 115, 101, 110, 115, 101, 95, 50, 95, 76, 76, 79, 67, 95, 69, 78, 72, 65, 78, 67, 69, 95, 66, 66 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 23
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 51, 95, 117, 116, 116, 101, 114, 108, 121, 95, 112, 111, 105, 110, 116, 108, 101, 115, 115, 95, 51, 95, 76, 76, 79, 67, 95, 77, 65, 88, 73, 77, 85, 77, 95, 67, 67 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 24
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 52, 95, 102, 105, 110, 97, 108, 95, 115, 105, 108, 108, 121, 95, 98, 105, 116, 115, 95, 52, 95, 76, 76, 79, 67, 95, 79, 86, 69, 82, 95, 49, 48, 48, 48, 95, 68, 68 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 25
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 53, 95, 109, 111, 114, 101, 95, 114, 97, 110, 100, 111, 109, 95, 98, 121, 116, 101, 115, 95, 53, 95, 76, 76, 79, 67, 95, 65, 66, 85, 78, 68, 65, 78, 67, 69, 95, 69, 69 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 26
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 54, 95, 101, 120, 116, 114, 97, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 54, 95, 76, 76, 79, 67, 95, 71, 69, 78, 69, 82, 65, 84, 69, 95, 70, 70 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 27
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 55, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 98, 108, 111, 99, 107, 95, 55, 95, 76, 76, 79, 67, 95, 70, 73, 76, 76, 95, 71, 71 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 28
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 56, 95, 106, 117, 115, 116, 95, 102, 111, 114, 95, 108, 105, 110, 101, 115, 95, 56, 95, 76, 76, 79, 67, 95, 77, 65, 78, 89, 95, 77, 65, 78, 89, 95, 72, 72 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 29
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 57, 95, 121, 101, 116, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 57, 95, 76, 76, 79, 67, 95, 77, 79, 82, 69, 95, 73, 73 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 30
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 48, 95, 102, 105, 110, 97, 108, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 49, 48, 95, 76, 76, 79, 67, 95, 69, 78, 68, 95, 79, 70, 95, 83, 65, 76, 84, 83, 95, 74, 74 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 31
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 49, 95, 76, 76, 79, 67, 95, 73, 78, 67, 82, 69, 65, 83, 69, 95, 65, 65 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 32
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 50, 95, 118, 101, 114, 121, 95, 115, 105, 108, 108, 121, 95, 110, 111, 110, 115, 101, 110, 115, 101, 95, 50, 95, 76, 76, 79, 67, 95, 69, 78, 72, 65, 78, 67, 69, 95, 66, 66 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 33
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 51, 95, 117, 116, 116, 101, 114, 108, 121, 95, 112, 111, 105, 110, 116, 108, 101, 115, 115, 95, 51, 95, 76, 76, 79, 67, 95, 77, 65, 88, 73, 77, 85, 77, 95, 67, 67 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 34
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 52, 95, 102, 105, 110, 97, 108, 95, 115, 105, 108, 108, 121, 95, 98, 105, 116, 115, 95, 52, 95, 76, 76, 79, 67, 95, 79, 86, 69, 82, 95, 49, 48, 48, 48, 95, 68, 68 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        // BLOCK 35
        {
            string hex = sha256(buf);
            string prefix = hex.Substring(0, 56);
            string suffix = hex.Substring(56);
            char[] suffixArray = suffix.ToCharArray();
            Array.Reverse(suffixArray);
            string rev = new string(suffixArray);
            string inter = prefix + rev;
            byte[] hashBytes = Encoding.ASCII.GetBytes(inter);
            byte[] salt = new byte[] { 106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 53, 95, 109, 111, 114, 101, 95, 114, 97, 110, 100, 111, 109, 95, 98, 121, 116, 101, 115, 95, 53, 95, 76, 76, 79, 67, 95, 65, 66, 85, 78, 68, 65, 78, 67, 69, 95, 69, 69 };
            int maxLen = Math.Max(hashBytes.Length, salt.Length);
            
            List<byte> newBuf = new List<byte>();
            for (int k = 0; k < maxLen; k++) {
                if (k < hashBytes.Length) newBuf.Add(hashBytes[k]);
                if (k < salt.Length) newBuf.Add(salt[k]);
            }
            buf = newBuf.ToArray();
        }

        string fhex = sha256(buf);
        string fprefix = fhex.Substring(0, 56);
        string fsuffix = fhex.Substring(56);
        char[] fsuffixArray = fsuffix.ToCharArray();
        Array.Reverse(fsuffixArray);
        string frev = new string(fsuffixArray);
        Console.WriteLine(fprefix + frev);
    }
}
