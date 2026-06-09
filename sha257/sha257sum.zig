const std = @import("std");

fn rightRotate(n: u32, b: u32) u32 {
    return (n >> @intCast(b)) | (n << @intCast(32 - b));
}

fn ch(e: u32, f: u32, g: u32) u32 {
    return (e & f) ^ (~e & g);
}

fn maj(a: u32, b: u32, c: u32) u32 {
    return (a & b) ^ (a & c) ^ (b & c);
}

fn s0_func(a: u32) u32 {
    return rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22);
}

fn s1_func(e: u32) u32 {
    return rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25);
}

fn msg_s0(w: u32) u32 {
    return rightRotate(w, 7) ^ rightRotate(w, 18) ^ (w >> 3);
}

fn msg_s1(w: u32) u32 {
    return rightRotate(w, 17) ^ rightRotate(w, 19) ^ (w >> 10);
}

const K = [_]u32{
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
};

fn sha256_compute(allocator: std.mem.Allocator, msg: []const u8) ![]u8 {
    var h = [_]u32{
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    };

    const bits = msg.len * 8;
    var padded = std.ArrayList(u8).init(allocator);
    defer padded.deinit();
    try padded.appendSlice(msg);
    try padded.append(0x80);
    while (padded.items.len % 64 != 56) try padded.append(0);

    var i: i32 = 7;
    while (i >= 0) : (i -= 1) {
        try padded.append(@intCast((bits >> @intCast(i * 8)) & 0xFF));
    }

    var offset: usize = 0;
    while (offset < padded.items.len) : (offset += 64) {
        var w = [_]u32{0} ** 64;
        for (0..16) |j| {
            w[j] = (@as(u32, padded.items[offset + j * 4]) << 24) |
                   (@as(u32, padded.items[offset + j * 4 + 1]) << 16) |
                   (@as(u32, padded.items[offset + j * 4 + 2]) << 8) |
                   (@as(u32, padded.items[offset + j * 4 + 3]));
        }
        for (16..64) |j| {
            w[j] = msg_s1(w[j - 2]) +% w[j - 7] +% msg_s0(w[j - 15]) +% w[j - 16];
        }

        var a = h[0]; var b = h[1]; var c = h[2]; var d = h[3];
        var e = h[4]; var f = h[5]; var g = h[6]; var hh = h[7];

        for (0..64) |j| {
            const t1 = hh +% s1_func(e) +% ch(e, f, g) +% K[j] +% w[j];
            const t2 = s0_func(a) +% maj(a, b, c);
            hh = g; g = f; f = e; e = d +% t1;
            d = c; c = b; b = a; a = t1 +% t2;
        }
        h[0] +%= a; h[1] +%= b; h[2] +%= c; h[3] +%= d;
        h[4] +%= e; h[5] +%= f; h[6] +%= g; h[7] +%= hh;
    }

    return std.fmt.allocPrint(allocator, "{x:0>8}{x:0>8}{x:0>8}{x:0>8}{x:0>8}{x:0>8}{x:0>8}{x:0>8}", .{
        h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7],
    });
}

const SALTS = [_][]const u8{
    "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA",
    "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB",
    "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC",
    "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD",
    "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE",
    "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF",
    "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG",
    "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH",
    "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II",
    "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ",
};

fn interleave(allocator: std.mem.Allocator, hash: []const u8, salt: []const u8) ![]u8 {
    const hl = hash.len;
    const sl = salt.len;
    const ml = if (hl > sl) hl else sl;
    var res = try allocator.alloc(u8, hl + sl);
    var j: usize = 0;
    for (0..ml) |k| {
        if (k < hl) { res[j] = hash[k]; j += 1; }
        if (k < sl) { res[j] = salt[k]; j += 1; }
    }
    return res[0..j];
}

fn reverseSuffix(allocator: std.mem.Allocator, hash: []const u8) ![]u8 {
    var res = try allocator.alloc(u8, hash.len);
    @memcpy(res[0 .. hash.len - 8], hash[0 .. hash.len - 8]);
    for (0..8) |i| {
        res[hash.len - 8 + i] = hash[hash.len - 1 - i];
    }
    return res;
}

fn calculate_sha257sum(allocator: std.mem.Allocator, data: []const u8) ![]u8 {
    var current = try allocator.alloc(u8, data.len);
    @memcpy(current, data);
    
    const salt_indices = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4 };
    
    for (salt_indices) |idx| {
        const h = try sha256_compute(allocator, current);
        defer allocator.free(h);
        const rev = try reverseSuffix(allocator, h);
        defer allocator.free(rev);
        const next = try interleave(allocator, rev, SALTS[idx]);
        allocator.free(current);
        current = next;
    }
    
    const final_h = try sha256_compute(allocator, current);
    defer allocator.free(final_h);
    allocator.free(current);
    return try reverseSuffix(allocator, final_h);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <string_or_-f_file>\n", .{args[0]});
        return;
    }

    var input: []u8 = undefined;
    if (std.mem.eql(u8, args[1], "-f")) {
        if (args.len < 3) return;
        const file = try std.fs.cwd().openFile(args[2], .{});
        defer file.close();
        input = try file.readToEndAlloc(allocator, 1024 * 1024 * 1024);
    } else {
        input = try allocator.alloc(u8, args[1].len);
        @memcpy(input, args[1]);
    }
    defer allocator.free(input);

    const result = try calculate_sha257sum(allocator, input);
    defer allocator.free(result);
    try std.io.getStdOut().writer().print("{s}\n", .{result});
}
