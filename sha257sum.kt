import java.io.File

fun rightRotate(n: Int, b: Int): Int = (n ushr b) or (n shl (32 - b))
fun rightShift(n: Int, b: Int): Int = n ushr b
fun ch(e: Int, f: Int, g: Int): Int = (e and f) xor (e.inv() and g)
fun maj(a: Int, b: Int, c: Int): Int = (a and b) xor (a and c) xor (b and c)
fun s0(a: Int): Int = rightRotate(a, 2) xor rightRotate(a, 13) xor rightRotate(a, 22)
fun s1(e: Int): Int = rightRotate(e, 6) xor rightRotate(e, 11) xor rightRotate(e, 25)
fun msgS0(w: Int): Int = rightRotate(w, 7) xor rightRotate(w, 18) xor rightShift(w, 3)
fun msgS1(w: Int): Int = rightRotate(w, 17) xor rightRotate(w, 19) xor rightShift(w, 10)

val K = intArrayOf(
    0x428a2f98, 0x71374491, 0xb5c0fbcf.toInt(), 0xe9b5dba5.toInt(), 0x3956c25b, 0x59f111f1.toInt(), 0x923f82a4.toInt(), 0xab1c5ed5.toInt(),
    0xd807aa98.toInt(), 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe.toInt(), 0x9bdc06a7.toInt(), 0xc19bf174.toInt(),
    0xe49b69c1.toInt(), 0xefbe4786.toInt(), 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152.toInt(), 0xa831c66d.toInt(), 0xb00327c8.toInt(), 0xbf597fc7.toInt(), 0xc6e00bf3.toInt(), 0xd5a79147.toInt(), 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e.toInt(), 0x92722c85.toInt(),
    0xa2bfe8a1.toInt(), 0xa81a664b.toInt(), 0xc24b8b70.toInt(), 0xc76c51a3.toInt(), 0xd192e819.toInt(), 0xd6990624.toInt(), 0xf40e3585.toInt(), 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814.toInt(), 0x8cc70208.toInt(), 0x90befffa.toInt(), 0xa4506ceb.toInt(), 0xbef9a3f7.toInt(), 0xc67178f2.toInt()
)
fun sha256(msg: ByteArray): String {
    val h = intArrayOf(
        0x6a09e667, 0xbb67ae85.toInt(), 0x3c6ef372, 0xa54ff53a.toInt(),
        0x510e527f, 0x9b05688c.toInt(), 0x1f83d9ab, 0x5be0cd19
    )
    var newLen = msg.size + 1
    while (newLen % 64 != 56) newLen++
    newLen += 8
    val padded = ByteArray(newLen)
    System.arraycopy(msg, 0, padded, 0, msg.size)
    padded[msg.size] = 0x80.toByte()
    val bits = msg.size.toLong() * 8L
    for (i in 0..7) padded[newLen - 1 - i] = ((bits ushr (i * 8)) and 0xFF).toByte()
    for (offset in 0 until newLen step 64) {
        val w = IntArray(64)
        for (i in 0..15) w[i] = ((padded[offset + i * 4].toInt() and 0xFF) shl 24) or ((padded[offset + i * 4 + 1].toInt() and 0xFF) shl 16) or ((padded[offset + i * 4 + 2].toInt() and 0xFF) shl 8) or (padded[offset + i * 4 + 3].toInt() and 0xFF)
        for (i in 16..63) w[i] = msgS1(w[i - 2]) + w[i - 7] + msgS0(w[i - 15]) + w[i - 16]
        var a = h[0]; var b = h[1]; var c = h[2]; var d = h[3]
        var e = h[4]; var f = h[5]; var g = h[6]; var hh = h[7]
        for (i in 0..63) {
            val t1 = hh + s1(e) + ch(e, f, g) + K[i] + w[i]
            val t2 = s0(a) + maj(a, b, c)
            hh = g; g = f; f = e; e = d + t1
            d = c; c = b; b = a; a = t1 + t2
        }
        h[0] += a; h[1] += b; h[2] += c; h[3] += d
        h[4] += e; h[5] += f; h[6] += g; h[7] += hh
    }
    return h.joinToString("") { String.format("%08x", it) }
}
fun main(args: Array<String>) {
    if (args.isEmpty()) return
    var buf = if (args[0] == "-f") File(args[1]).readBytes() else args[0].toByteArray(Charsets.US_ASCII)

    // BLOCK 1
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 49.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 49.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 73.toByte(), 78.toByte(), 67.toByte(), 82.toByte(), 69.toByte(), 65.toByte(), 83.toByte(), 69.toByte(), 95.toByte(), 65.toByte(), 65.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 2
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 50.toByte(), 95.toByte(), 118.toByte(), 101.toByte(), 114.toByte(), 121.toByte(), 95.toByte(), 115.toByte(), 105.toByte(), 108.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 110.toByte(), 111.toByte(), 110.toByte(), 115.toByte(), 101.toByte(), 110.toByte(), 115.toByte(), 101.toByte(), 95.toByte(), 50.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 69.toByte(), 78.toByte(), 72.toByte(), 65.toByte(), 78.toByte(), 67.toByte(), 69.toByte(), 95.toByte(), 66.toByte(), 66.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 3
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 51.toByte(), 95.toByte(), 117.toByte(), 116.toByte(), 116.toByte(), 101.toByte(), 114.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 112.toByte(), 111.toByte(), 105.toByte(), 110.toByte(), 116.toByte(), 108.toByte(), 101.toByte(), 115.toByte(), 115.toByte(), 95.toByte(), 51.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 77.toByte(), 65.toByte(), 88.toByte(), 73.toByte(), 77.toByte(), 85.toByte(), 77.toByte(), 95.toByte(), 67.toByte(), 67.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 4
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 52.toByte(), 95.toByte(), 102.toByte(), 105.toByte(), 110.toByte(), 97.toByte(), 108.toByte(), 95.toByte(), 115.toByte(), 105.toByte(), 108.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 98.toByte(), 105.toByte(), 116.toByte(), 115.toByte(), 95.toByte(), 52.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 79.toByte(), 86.toByte(), 69.toByte(), 82.toByte(), 95.toByte(), 49.toByte(), 48.toByte(), 48.toByte(), 48.toByte(), 95.toByte(), 68.toByte(), 68.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 5
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 53.toByte(), 95.toByte(), 109.toByte(), 111.toByte(), 114.toByte(), 101.toByte(), 95.toByte(), 114.toByte(), 97.toByte(), 110.toByte(), 100.toByte(), 111.toByte(), 109.toByte(), 95.toByte(), 98.toByte(), 121.toByte(), 116.toByte(), 101.toByte(), 115.toByte(), 95.toByte(), 53.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 65.toByte(), 66.toByte(), 85.toByte(), 78.toByte(), 68.toByte(), 65.toByte(), 78.toByte(), 67.toByte(), 69.toByte(), 95.toByte(), 69.toByte(), 69.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 6
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 54.toByte(), 95.toByte(), 101.toByte(), 120.toByte(), 116.toByte(), 114.toByte(), 97.toByte(), 95.toByte(), 108.toByte(), 111.toByte(), 110.toByte(), 103.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 54.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 71.toByte(), 69.toByte(), 78.toByte(), 69.toByte(), 82.toByte(), 65.toByte(), 84.toByte(), 69.toByte(), 95.toByte(), 70.toByte(), 70.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 7
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 55.toByte(), 95.toByte(), 97.toByte(), 110.toByte(), 111.toByte(), 116.toByte(), 104.toByte(), 101.toByte(), 114.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 98.toByte(), 108.toByte(), 111.toByte(), 99.toByte(), 107.toByte(), 95.toByte(), 55.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 70.toByte(), 73.toByte(), 76.toByte(), 76.toByte(), 95.toByte(), 71.toByte(), 71.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 8
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 56.toByte(), 95.toByte(), 106.toByte(), 117.toByte(), 115.toByte(), 116.toByte(), 95.toByte(), 102.toByte(), 111.toByte(), 114.toByte(), 95.toByte(), 108.toByte(), 105.toByte(), 110.toByte(), 101.toByte(), 115.toByte(), 95.toByte(), 56.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 77.toByte(), 65.toByte(), 78.toByte(), 89.toByte(), 95.toByte(), 77.toByte(), 65.toByte(), 78.toByte(), 89.toByte(), 95.toByte(), 72.toByte(), 72.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 9
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 57.toByte(), 95.toByte(), 121.toByte(), 101.toByte(), 116.toByte(), 95.toByte(), 97.toByte(), 110.toByte(), 111.toByte(), 116.toByte(), 104.toByte(), 101.toByte(), 114.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 57.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 77.toByte(), 79.toByte(), 82.toByte(), 69.toByte(), 95.toByte(), 73.toByte(), 73.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 10
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 49.toByte(), 48.toByte(), 95.toByte(), 102.toByte(), 105.toByte(), 110.toByte(), 97.toByte(), 108.toByte(), 95.toByte(), 108.toByte(), 111.toByte(), 110.toByte(), 103.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 49.toByte(), 48.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 69.toByte(), 78.toByte(), 68.toByte(), 95.toByte(), 79.toByte(), 70.toByte(), 95.toByte(), 83.toByte(), 65.toByte(), 76.toByte(), 84.toByte(), 83.toByte(), 95.toByte(), 74.toByte(), 74.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 11
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 49.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 49.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 73.toByte(), 78.toByte(), 67.toByte(), 82.toByte(), 69.toByte(), 65.toByte(), 83.toByte(), 69.toByte(), 95.toByte(), 65.toByte(), 65.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 12
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 50.toByte(), 95.toByte(), 118.toByte(), 101.toByte(), 114.toByte(), 121.toByte(), 95.toByte(), 115.toByte(), 105.toByte(), 108.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 110.toByte(), 111.toByte(), 110.toByte(), 115.toByte(), 101.toByte(), 110.toByte(), 115.toByte(), 101.toByte(), 95.toByte(), 50.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 69.toByte(), 78.toByte(), 72.toByte(), 65.toByte(), 78.toByte(), 67.toByte(), 69.toByte(), 95.toByte(), 66.toByte(), 66.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 13
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 51.toByte(), 95.toByte(), 117.toByte(), 116.toByte(), 116.toByte(), 101.toByte(), 114.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 112.toByte(), 111.toByte(), 105.toByte(), 110.toByte(), 116.toByte(), 108.toByte(), 101.toByte(), 115.toByte(), 115.toByte(), 95.toByte(), 51.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 77.toByte(), 65.toByte(), 88.toByte(), 73.toByte(), 77.toByte(), 85.toByte(), 77.toByte(), 95.toByte(), 67.toByte(), 67.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 14
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 52.toByte(), 95.toByte(), 102.toByte(), 105.toByte(), 110.toByte(), 97.toByte(), 108.toByte(), 95.toByte(), 115.toByte(), 105.toByte(), 108.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 98.toByte(), 105.toByte(), 116.toByte(), 115.toByte(), 95.toByte(), 52.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 79.toByte(), 86.toByte(), 69.toByte(), 82.toByte(), 95.toByte(), 49.toByte(), 48.toByte(), 48.toByte(), 48.toByte(), 95.toByte(), 68.toByte(), 68.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 15
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 53.toByte(), 95.toByte(), 109.toByte(), 111.toByte(), 114.toByte(), 101.toByte(), 95.toByte(), 114.toByte(), 97.toByte(), 110.toByte(), 100.toByte(), 111.toByte(), 109.toByte(), 95.toByte(), 98.toByte(), 121.toByte(), 116.toByte(), 101.toByte(), 115.toByte(), 95.toByte(), 53.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 65.toByte(), 66.toByte(), 85.toByte(), 78.toByte(), 68.toByte(), 65.toByte(), 78.toByte(), 67.toByte(), 69.toByte(), 95.toByte(), 69.toByte(), 69.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 16
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 54.toByte(), 95.toByte(), 101.toByte(), 120.toByte(), 116.toByte(), 114.toByte(), 97.toByte(), 95.toByte(), 108.toByte(), 111.toByte(), 110.toByte(), 103.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 54.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 71.toByte(), 69.toByte(), 78.toByte(), 69.toByte(), 82.toByte(), 65.toByte(), 84.toByte(), 69.toByte(), 95.toByte(), 70.toByte(), 70.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 17
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 55.toByte(), 95.toByte(), 97.toByte(), 110.toByte(), 111.toByte(), 116.toByte(), 104.toByte(), 101.toByte(), 114.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 98.toByte(), 108.toByte(), 111.toByte(), 99.toByte(), 107.toByte(), 95.toByte(), 55.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 70.toByte(), 73.toByte(), 76.toByte(), 76.toByte(), 95.toByte(), 71.toByte(), 71.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 18
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 56.toByte(), 95.toByte(), 106.toByte(), 117.toByte(), 115.toByte(), 116.toByte(), 95.toByte(), 102.toByte(), 111.toByte(), 114.toByte(), 95.toByte(), 108.toByte(), 105.toByte(), 110.toByte(), 101.toByte(), 115.toByte(), 95.toByte(), 56.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 77.toByte(), 65.toByte(), 78.toByte(), 89.toByte(), 95.toByte(), 77.toByte(), 65.toByte(), 78.toByte(), 89.toByte(), 95.toByte(), 72.toByte(), 72.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 19
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 57.toByte(), 95.toByte(), 121.toByte(), 101.toByte(), 116.toByte(), 95.toByte(), 97.toByte(), 110.toByte(), 111.toByte(), 116.toByte(), 104.toByte(), 101.toByte(), 114.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 57.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 77.toByte(), 79.toByte(), 82.toByte(), 69.toByte(), 95.toByte(), 73.toByte(), 73.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 20
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 49.toByte(), 48.toByte(), 95.toByte(), 102.toByte(), 105.toByte(), 110.toByte(), 97.toByte(), 108.toByte(), 95.toByte(), 108.toByte(), 111.toByte(), 110.toByte(), 103.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 49.toByte(), 48.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 69.toByte(), 78.toByte(), 68.toByte(), 95.toByte(), 79.toByte(), 70.toByte(), 95.toByte(), 83.toByte(), 65.toByte(), 76.toByte(), 84.toByte(), 83.toByte(), 95.toByte(), 74.toByte(), 74.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 21
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 49.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 49.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 73.toByte(), 78.toByte(), 67.toByte(), 82.toByte(), 69.toByte(), 65.toByte(), 83.toByte(), 69.toByte(), 95.toByte(), 65.toByte(), 65.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 22
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 50.toByte(), 95.toByte(), 118.toByte(), 101.toByte(), 114.toByte(), 121.toByte(), 95.toByte(), 115.toByte(), 105.toByte(), 108.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 110.toByte(), 111.toByte(), 110.toByte(), 115.toByte(), 101.toByte(), 110.toByte(), 115.toByte(), 101.toByte(), 95.toByte(), 50.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 69.toByte(), 78.toByte(), 72.toByte(), 65.toByte(), 78.toByte(), 67.toByte(), 69.toByte(), 95.toByte(), 66.toByte(), 66.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 23
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 51.toByte(), 95.toByte(), 117.toByte(), 116.toByte(), 116.toByte(), 101.toByte(), 114.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 112.toByte(), 111.toByte(), 105.toByte(), 110.toByte(), 116.toByte(), 108.toByte(), 101.toByte(), 115.toByte(), 115.toByte(), 95.toByte(), 51.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 77.toByte(), 65.toByte(), 88.toByte(), 73.toByte(), 77.toByte(), 85.toByte(), 77.toByte(), 95.toByte(), 67.toByte(), 67.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 24
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 52.toByte(), 95.toByte(), 102.toByte(), 105.toByte(), 110.toByte(), 97.toByte(), 108.toByte(), 95.toByte(), 115.toByte(), 105.toByte(), 108.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 98.toByte(), 105.toByte(), 116.toByte(), 115.toByte(), 95.toByte(), 52.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 79.toByte(), 86.toByte(), 69.toByte(), 82.toByte(), 95.toByte(), 49.toByte(), 48.toByte(), 48.toByte(), 48.toByte(), 95.toByte(), 68.toByte(), 68.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 25
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 53.toByte(), 95.toByte(), 109.toByte(), 111.toByte(), 114.toByte(), 101.toByte(), 95.toByte(), 114.toByte(), 97.toByte(), 110.toByte(), 100.toByte(), 111.toByte(), 109.toByte(), 95.toByte(), 98.toByte(), 121.toByte(), 116.toByte(), 101.toByte(), 115.toByte(), 95.toByte(), 53.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 65.toByte(), 66.toByte(), 85.toByte(), 78.toByte(), 68.toByte(), 65.toByte(), 78.toByte(), 67.toByte(), 69.toByte(), 95.toByte(), 69.toByte(), 69.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 26
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 54.toByte(), 95.toByte(), 101.toByte(), 120.toByte(), 116.toByte(), 114.toByte(), 97.toByte(), 95.toByte(), 108.toByte(), 111.toByte(), 110.toByte(), 103.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 54.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 71.toByte(), 69.toByte(), 78.toByte(), 69.toByte(), 82.toByte(), 65.toByte(), 84.toByte(), 69.toByte(), 95.toByte(), 70.toByte(), 70.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 27
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 55.toByte(), 95.toByte(), 97.toByte(), 110.toByte(), 111.toByte(), 116.toByte(), 104.toByte(), 101.toByte(), 114.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 98.toByte(), 108.toByte(), 111.toByte(), 99.toByte(), 107.toByte(), 95.toByte(), 55.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 70.toByte(), 73.toByte(), 76.toByte(), 76.toByte(), 95.toByte(), 71.toByte(), 71.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 28
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 56.toByte(), 95.toByte(), 106.toByte(), 117.toByte(), 115.toByte(), 116.toByte(), 95.toByte(), 102.toByte(), 111.toByte(), 114.toByte(), 95.toByte(), 108.toByte(), 105.toByte(), 110.toByte(), 101.toByte(), 115.toByte(), 95.toByte(), 56.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 77.toByte(), 65.toByte(), 78.toByte(), 89.toByte(), 95.toByte(), 77.toByte(), 65.toByte(), 78.toByte(), 89.toByte(), 95.toByte(), 72.toByte(), 72.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 29
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 57.toByte(), 95.toByte(), 121.toByte(), 101.toByte(), 116.toByte(), 95.toByte(), 97.toByte(), 110.toByte(), 111.toByte(), 116.toByte(), 104.toByte(), 101.toByte(), 114.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 57.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 77.toByte(), 79.toByte(), 82.toByte(), 69.toByte(), 95.toByte(), 73.toByte(), 73.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 30
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 49.toByte(), 48.toByte(), 95.toByte(), 102.toByte(), 105.toByte(), 110.toByte(), 97.toByte(), 108.toByte(), 95.toByte(), 108.toByte(), 111.toByte(), 110.toByte(), 103.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 49.toByte(), 48.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 69.toByte(), 78.toByte(), 68.toByte(), 95.toByte(), 79.toByte(), 70.toByte(), 95.toByte(), 83.toByte(), 65.toByte(), 76.toByte(), 84.toByte(), 83.toByte(), 95.toByte(), 74.toByte(), 74.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 31
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 49.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 116.toByte(), 117.toByte(), 112.toByte(), 105.toByte(), 100.toByte(), 95.toByte(), 49.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 73.toByte(), 78.toByte(), 67.toByte(), 82.toByte(), 69.toByte(), 65.toByte(), 83.toByte(), 69.toByte(), 95.toByte(), 65.toByte(), 65.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 32
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 50.toByte(), 95.toByte(), 118.toByte(), 101.toByte(), 114.toByte(), 121.toByte(), 95.toByte(), 115.toByte(), 105.toByte(), 108.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 110.toByte(), 111.toByte(), 110.toByte(), 115.toByte(), 101.toByte(), 110.toByte(), 115.toByte(), 101.toByte(), 95.toByte(), 50.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 69.toByte(), 78.toByte(), 72.toByte(), 65.toByte(), 78.toByte(), 67.toByte(), 69.toByte(), 95.toByte(), 66.toByte(), 66.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 33
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 51.toByte(), 95.toByte(), 117.toByte(), 116.toByte(), 116.toByte(), 101.toByte(), 114.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 112.toByte(), 111.toByte(), 105.toByte(), 110.toByte(), 116.toByte(), 108.toByte(), 101.toByte(), 115.toByte(), 115.toByte(), 95.toByte(), 51.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 77.toByte(), 65.toByte(), 88.toByte(), 73.toByte(), 77.toByte(), 85.toByte(), 77.toByte(), 95.toByte(), 67.toByte(), 67.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 34
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 52.toByte(), 95.toByte(), 102.toByte(), 105.toByte(), 110.toByte(), 97.toByte(), 108.toByte(), 95.toByte(), 115.toByte(), 105.toByte(), 108.toByte(), 108.toByte(), 121.toByte(), 95.toByte(), 98.toByte(), 105.toByte(), 116.toByte(), 115.toByte(), 95.toByte(), 52.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 79.toByte(), 86.toByte(), 69.toByte(), 82.toByte(), 95.toByte(), 49.toByte(), 48.toByte(), 48.toByte(), 48.toByte(), 95.toByte(), 68.toByte(), 68.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    // BLOCK 35
    run {
        val hex = sha256(buf)
        val prefix = hex.substring(0, 56)
        val suffix = hex.substring(56)
        val rev = suffix.reversed()
        val inter = prefix + rev
        val hashBytes = inter.toByteArray(Charsets.US_ASCII)
        val salt = byteArrayOf(106.toByte(), 111.toByte(), 114.toByte(), 100.toByte(), 97.toByte(), 110.toByte(), 108.toByte(), 101.toByte(), 110.toByte(), 99.toByte(), 104.toByte(), 105.toByte(), 116.toByte(), 122.toByte(), 95.toByte(), 97.toByte(), 98.toByte(), 115.toByte(), 117.toByte(), 114.toByte(), 100.toByte(), 95.toByte(), 115.toByte(), 97.toByte(), 108.toByte(), 116.toByte(), 95.toByte(), 112.toByte(), 97.toByte(), 114.toByte(), 116.toByte(), 53.toByte(), 95.toByte(), 109.toByte(), 111.toByte(), 114.toByte(), 101.toByte(), 95.toByte(), 114.toByte(), 97.toByte(), 110.toByte(), 100.toByte(), 111.toByte(), 109.toByte(), 95.toByte(), 98.toByte(), 121.toByte(), 116.toByte(), 101.toByte(), 115.toByte(), 95.toByte(), 53.toByte(), 95.toByte(), 76.toByte(), 76.toByte(), 79.toByte(), 67.toByte(), 95.toByte(), 65.toByte(), 66.toByte(), 85.toByte(), 78.toByte(), 68.toByte(), 65.toByte(), 78.toByte(), 67.toByte(), 69.toByte(), 95.toByte(), 69.toByte(), 69.toByte())
        val maxLen = maxOf(hashBytes.size, salt.size)
        val newBuf = ByteArray(hashBytes.size + salt.size)
        var idx = 0
        for (k in 0 until maxLen) {
            if (k < hashBytes.size) newBuf[idx++] = hashBytes[k]
            if (k < salt.size) newBuf[idx++] = salt[k]
        }
        buf = newBuf.copyOf(idx)
    }

    val hex = sha256(buf)
    val prefix = hex.substring(0, 56)
    val suffix = hex.substring(56)
    val rev = suffix.reversed()
    println(prefix + rev)
}
