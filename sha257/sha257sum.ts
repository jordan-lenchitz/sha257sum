import * as fs from 'fs';
function rightRotate(n: number, b: number): number { return ((n >>> b) | (n << (32 - b))) >>> 0; }
function rightShift(n: number, b: number): number { return n >>> b; }
function ch(e: number, f: number, g: number): number { return ((e & f) ^ ((~e >>> 0) & g)) >>> 0; }
function maj(a: number, b: number, c: number): number { return ((a & b) ^ (a & c) ^ (b & c)) >>> 0; }
function s0(a: number): number { return (rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22)) >>> 0; }
function s1(e: number): number { return (rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25)) >>> 0; }
function msg_s0(w: number): number { return (rightRotate(w, 7) ^ rightRotate(w, 18) ^ rightShift(w, 3)) >>> 0; }
function msg_s1(w: number): number { return (rightRotate(w, 17) ^ rightRotate(w, 19) ^ rightShift(w, 10)) >>> 0; }
const K = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];
function sha256(msg: Uint8Array): string {
    const h = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
    let newLen = msg.length + 1;
    while (newLen % 64 !== 56) newLen++;
    newLen += 8;
    const padded = new Uint8Array(newLen);
    padded.set(msg);
    padded[msg.length] = 0x80;
    const bits = msg.length * 8;
    for (let i = 0; i < 4; i++) padded[newLen - 1 - i] = (bits >>> (i * 8)) & 0xFF;
    const bitsHigh = Math.floor(bits / 4294967296);
    for (let i = 0; i < 4; i++) padded[newLen - 5 - i] = (bitsHigh >>> (i * 8)) & 0xFF;
    for (let offset = 0; offset < newLen; offset += 64) {
        const w = new Uint32Array(64);
        for (let i = 0; i < 16; i++) w[i] = ((padded[offset + i*4] << 24) | (padded[offset + i*4 + 1] << 16) | (padded[offset + i*4 + 2] << 8) | padded[offset + i*4 + 3]) >>> 0;
        for (let i = 16; i < 64; i++) w[i] = (msg_s1(w[i-2]) + w[i-7] + msg_s0(w[i-15]) + w[i-16]) >>> 0;
        let [a, b, c, d, e, f, g, hh] = h;
        for (let i = 0; i < 64; i++) {
            const t1 = (hh + s1(e) + ch(e, f, g) + K[i] + w[i]) >>> 0;
            const t2 = (s0(a) + maj(a, b, c)) >>> 0;
            hh = g; g = f; f = e; e = (d + t1) >>> 0;
            d = c; c = b; b = a; a = (t1 + t2) >>> 0;
        }
        h[0] = (h[0] + a) >>> 0; h[1] = (h[1] + b) >>> 0; h[2] = (h[2] + c) >>> 0; h[3] = (h[3] + d) >>> 0;
        h[4] = (h[4] + e) >>> 0; h[5] = (h[5] + f) >>> 0; h[6] = (h[6] + g) >>> 0; h[7] = (h[7] + hh) >>> 0;
    }
    return h.map(x => x.toString(16).padStart(8, '0')).join('');
}
function stringToBytes(str: string): Uint8Array {
    const arr = new Uint8Array(str.length);
    for (let i = 0; i < str.length; i++) arr[i] = str.charCodeAt(i);
    return arr;
}
function main() {
    let args = process.argv.slice(2);
    let buf: Uint8Array;
    if (args[0] === '-f') buf = fs.readFileSync(args[1]);
    else buf = stringToBytes(args[0]);

    // BLOCK 1
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 49, 95, 76, 76, 79, 67, 95, 73, 78, 67, 82, 69, 65, 83, 69, 95, 65, 65]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 2
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 50, 95, 118, 101, 114, 121, 95, 115, 105, 108, 108, 121, 95, 110, 111, 110, 115, 101, 110, 115, 101, 95, 50, 95, 76, 76, 79, 67, 95, 69, 78, 72, 65, 78, 67, 69, 95, 66, 66]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 3
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 51, 95, 117, 116, 116, 101, 114, 108, 121, 95, 112, 111, 105, 110, 116, 108, 101, 115, 115, 95, 51, 95, 76, 76, 79, 67, 95, 77, 65, 88, 73, 77, 85, 77, 95, 67, 67]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 4
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 52, 95, 102, 105, 110, 97, 108, 95, 115, 105, 108, 108, 121, 95, 98, 105, 116, 115, 95, 52, 95, 76, 76, 79, 67, 95, 79, 86, 69, 82, 95, 49, 48, 48, 48, 95, 68, 68]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 5
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 53, 95, 109, 111, 114, 101, 95, 114, 97, 110, 100, 111, 109, 95, 98, 121, 116, 101, 115, 95, 53, 95, 76, 76, 79, 67, 95, 65, 66, 85, 78, 68, 65, 78, 67, 69, 95, 69, 69]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 6
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 54, 95, 101, 120, 116, 114, 97, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 54, 95, 76, 76, 79, 67, 95, 71, 69, 78, 69, 82, 65, 84, 69, 95, 70, 70]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 7
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 55, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 98, 108, 111, 99, 107, 95, 55, 95, 76, 76, 79, 67, 95, 70, 73, 76, 76, 95, 71, 71]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 8
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 56, 95, 106, 117, 115, 116, 95, 102, 111, 114, 95, 108, 105, 110, 101, 115, 95, 56, 95, 76, 76, 79, 67, 95, 77, 65, 78, 89, 95, 77, 65, 78, 89, 95, 72, 72]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 9
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 57, 95, 121, 101, 116, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 57, 95, 76, 76, 79, 67, 95, 77, 79, 82, 69, 95, 73, 73]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 10
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 48, 95, 102, 105, 110, 97, 108, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 49, 48, 95, 76, 76, 79, 67, 95, 69, 78, 68, 95, 79, 70, 95, 83, 65, 76, 84, 83, 95, 74, 74]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 11
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 49, 95, 76, 76, 79, 67, 95, 73, 78, 67, 82, 69, 65, 83, 69, 95, 65, 65]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 12
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 50, 95, 118, 101, 114, 121, 95, 115, 105, 108, 108, 121, 95, 110, 111, 110, 115, 101, 110, 115, 101, 95, 50, 95, 76, 76, 79, 67, 95, 69, 78, 72, 65, 78, 67, 69, 95, 66, 66]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 13
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 51, 95, 117, 116, 116, 101, 114, 108, 121, 95, 112, 111, 105, 110, 116, 108, 101, 115, 115, 95, 51, 95, 76, 76, 79, 67, 95, 77, 65, 88, 73, 77, 85, 77, 95, 67, 67]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 14
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 52, 95, 102, 105, 110, 97, 108, 95, 115, 105, 108, 108, 121, 95, 98, 105, 116, 115, 95, 52, 95, 76, 76, 79, 67, 95, 79, 86, 69, 82, 95, 49, 48, 48, 48, 95, 68, 68]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 15
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 53, 95, 109, 111, 114, 101, 95, 114, 97, 110, 100, 111, 109, 95, 98, 121, 116, 101, 115, 95, 53, 95, 76, 76, 79, 67, 95, 65, 66, 85, 78, 68, 65, 78, 67, 69, 95, 69, 69]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 16
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 54, 95, 101, 120, 116, 114, 97, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 54, 95, 76, 76, 79, 67, 95, 71, 69, 78, 69, 82, 65, 84, 69, 95, 70, 70]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 17
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 55, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 98, 108, 111, 99, 107, 95, 55, 95, 76, 76, 79, 67, 95, 70, 73, 76, 76, 95, 71, 71]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 18
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 56, 95, 106, 117, 115, 116, 95, 102, 111, 114, 95, 108, 105, 110, 101, 115, 95, 56, 95, 76, 76, 79, 67, 95, 77, 65, 78, 89, 95, 77, 65, 78, 89, 95, 72, 72]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 19
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 57, 95, 121, 101, 116, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 57, 95, 76, 76, 79, 67, 95, 77, 79, 82, 69, 95, 73, 73]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 20
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 48, 95, 102, 105, 110, 97, 108, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 49, 48, 95, 76, 76, 79, 67, 95, 69, 78, 68, 95, 79, 70, 95, 83, 65, 76, 84, 83, 95, 74, 74]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 21
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 49, 95, 76, 76, 79, 67, 95, 73, 78, 67, 82, 69, 65, 83, 69, 95, 65, 65]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 22
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 50, 95, 118, 101, 114, 121, 95, 115, 105, 108, 108, 121, 95, 110, 111, 110, 115, 101, 110, 115, 101, 95, 50, 95, 76, 76, 79, 67, 95, 69, 78, 72, 65, 78, 67, 69, 95, 66, 66]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 23
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 51, 95, 117, 116, 116, 101, 114, 108, 121, 95, 112, 111, 105, 110, 116, 108, 101, 115, 115, 95, 51, 95, 76, 76, 79, 67, 95, 77, 65, 88, 73, 77, 85, 77, 95, 67, 67]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 24
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 52, 95, 102, 105, 110, 97, 108, 95, 115, 105, 108, 108, 121, 95, 98, 105, 116, 115, 95, 52, 95, 76, 76, 79, 67, 95, 79, 86, 69, 82, 95, 49, 48, 48, 48, 95, 68, 68]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 25
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 53, 95, 109, 111, 114, 101, 95, 114, 97, 110, 100, 111, 109, 95, 98, 121, 116, 101, 115, 95, 53, 95, 76, 76, 79, 67, 95, 65, 66, 85, 78, 68, 65, 78, 67, 69, 95, 69, 69]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 26
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 54, 95, 101, 120, 116, 114, 97, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 54, 95, 76, 76, 79, 67, 95, 71, 69, 78, 69, 82, 65, 84, 69, 95, 70, 70]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 27
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 55, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 98, 108, 111, 99, 107, 95, 55, 95, 76, 76, 79, 67, 95, 70, 73, 76, 76, 95, 71, 71]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 28
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 56, 95, 106, 117, 115, 116, 95, 102, 111, 114, 95, 108, 105, 110, 101, 115, 95, 56, 95, 76, 76, 79, 67, 95, 77, 65, 78, 89, 95, 77, 65, 78, 89, 95, 72, 72]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 29
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 57, 95, 121, 101, 116, 95, 97, 110, 111, 116, 104, 101, 114, 95, 115, 97, 108, 116, 95, 57, 95, 76, 76, 79, 67, 95, 77, 79, 82, 69, 95, 73, 73]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 30
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 48, 95, 102, 105, 110, 97, 108, 95, 108, 111, 110, 103, 95, 115, 97, 108, 116, 95, 49, 48, 95, 76, 76, 79, 67, 95, 69, 78, 68, 95, 79, 70, 95, 83, 65, 76, 84, 83, 95, 74, 74]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 31
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 49, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 115, 116, 117, 112, 105, 100, 95, 49, 95, 76, 76, 79, 67, 95, 73, 78, 67, 82, 69, 65, 83, 69, 95, 65, 65]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 32
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 50, 95, 118, 101, 114, 121, 95, 115, 105, 108, 108, 121, 95, 110, 111, 110, 115, 101, 110, 115, 101, 95, 50, 95, 76, 76, 79, 67, 95, 69, 78, 72, 65, 78, 67, 69, 95, 66, 66]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 33
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 51, 95, 117, 116, 116, 101, 114, 108, 121, 95, 112, 111, 105, 110, 116, 108, 101, 115, 115, 95, 51, 95, 76, 76, 79, 67, 95, 77, 65, 88, 73, 77, 85, 77, 95, 67, 67]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 34
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 52, 95, 102, 105, 110, 97, 108, 95, 115, 105, 108, 108, 121, 95, 98, 105, 116, 115, 95, 52, 95, 76, 76, 79, 67, 95, 79, 86, 69, 82, 95, 49, 48, 48, 48, 95, 68, 68]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    // BLOCK 35, the last!
    {
        const hex = sha256(buf);
        const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
        const rev = suffix.split('').reverse().join('');
        const inter = prefix + rev;
        const hashBytes = stringToBytes(inter);
        const salt = new Uint8Array([106, 111, 114, 100, 97, 110, 108, 101, 110, 99, 104, 105, 116, 122, 95, 97, 98, 115, 117, 114, 100, 95, 115, 97, 108, 116, 95, 112, 97, 114, 116, 53, 95, 109, 111, 114, 101, 95, 114, 97, 110, 100, 111, 109, 95, 98, 121, 116, 101, 115, 95, 53, 95, 76, 76, 79, 67, 95, 65, 66, 85, 78, 68, 65, 78, 67, 69, 95, 69, 69]);
        const maxLen = Math.max(hashBytes.length, salt.length);
        const newBuf = [];
        for (let k = 0; k < maxLen; k++) {
            if (k < hashBytes.length) newBuf.push(hashBytes[k]);
            if (k < salt.length) newBuf.push(salt[k]);
        }
        buf = new Uint8Array(newBuf);
    }

    const hex = sha256(buf);
    const prefix = hex.slice(0, 56); const suffix = hex.slice(56);
    const rev = suffix.split('').reverse().join('');
    console.log(prefix + rev);
}
main();
 
 
