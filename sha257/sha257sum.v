`timescale 1ns/1ps

module sha256_core (
    input  wire         clk,
    input  wire         rst,
    input  wire         init,
    input  wire         start,
    input  wire [511:0] block_in,
    output reg          busy,
    output wire [255:0] digest
);
    localparam [31:0] H0_0 = 32'h6a09e667;
    localparam [31:0] H0_1 = 32'hbb67ae85;
    localparam [31:0] H0_2 = 32'h3c6ef372;
    localparam [31:0] H0_3 = 32'ha54ff53a;
    localparam [31:0] H0_4 = 32'h510e527f;
    localparam [31:0] H0_5 = 32'h9b05688c;
    localparam [31:0] H0_6 = 32'h1f83d9ab;
    localparam [31:0] H0_7 = 32'h5be0cd19;

    reg [31:0] h0, h1, h2, h3, h4, h5, h6, h7;
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [31:0] w [0:15];
    reg [5:0]  round;

    assign digest = {h0, h1, h2, h3, h4, h5, h6, h7};

    function [31:0] big_s0;
        input [31:0] x;
        begin
            big_s0 = {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};
        end
    endfunction

    function [31:0] big_s1;
        input [31:0] x;
        begin
            big_s1 = {x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]};
        end
    endfunction

    function [31:0] msg_s0;
        input [31:0] x;
        begin
            msg_s0 = {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ {3'b0, x[31:3]};
        end
    endfunction

    function [31:0] msg_s1;
        input [31:0] x;
        begin
            msg_s1 = {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ {10'b0, x[31:10]};
        end
    endfunction

    function [31:0] sha256_k;
        input [5:0] idx;
        begin
            case (idx)
                6'd0:  sha256_k = 32'h428a2f98; 6'd1:  sha256_k = 32'h71374491;
                6'd2:  sha256_k = 32'hb5c0fbcf; 6'd3:  sha256_k = 32'he9b5dba5;
                6'd4:  sha256_k = 32'h3956c25b; 6'd5:  sha256_k = 32'h59f111f1;
                6'd6:  sha256_k = 32'h923f82a4; 6'd7:  sha256_k = 32'hab1c5ed5;
                6'd8:  sha256_k = 32'hd807aa98; 6'd9:  sha256_k = 32'h12835b01;
                6'd10: sha256_k = 32'h243185be; 6'd11: sha256_k = 32'h550c7dc3;
                6'd12: sha256_k = 32'h72be5d74; 6'd13: sha256_k = 32'h80deb1fe;
                6'd14: sha256_k = 32'h9bdc06a7; 6'd15: sha256_k = 32'hc19bf174;
                6'd16: sha256_k = 32'he49b69c1; 6'd17: sha256_k = 32'hefbe4786;
                6'd18: sha256_k = 32'h0fc19dc6; 6'd19: sha256_k = 32'h240ca1cc;
                6'd20: sha256_k = 32'h2de92c6f; 6'd21: sha256_k = 32'h4a7484aa;
                6'd22: sha256_k = 32'h5cb0a9dc; 6'd23: sha256_k = 32'h76f988da;
                6'd24: sha256_k = 32'h983e5152; 6'd25: sha256_k = 32'ha831c66d;
                6'd26: sha256_k = 32'hb00327c8; 6'd27: sha256_k = 32'hbf597fc7;
                6'd28: sha256_k = 32'hc6e00bf3; 6'd29: sha256_k = 32'hd5a79147;
                6'd30: sha256_k = 32'h06ca6351; 6'd31: sha256_k = 32'h14292967;
                6'd32: sha256_k = 32'h27b70a85; 6'd33: sha256_k = 32'h2e1b2138;
                6'd34: sha256_k = 32'h4d2c6dfc; 6'd35: sha256_k = 32'h53380d13;
                6'd36: sha256_k = 32'h650a7354; 6'd37: sha256_k = 32'h766a0abb;
                6'd38: sha256_k = 32'h81c2c92e; 6'd39: sha256_k = 32'h92722c85;
                6'd40: sha256_k = 32'ha2bfe8a1; 6'd41: sha256_k = 32'ha81a664b;
                6'd42: sha256_k = 32'hc24b8b70; 6'd43: sha256_k = 32'hc76c51a3;
                6'd44: sha256_k = 32'hd192e819; 6'd45: sha256_k = 32'hd6990624;
                6'd46: sha256_k = 32'hf40e3585; 6'd47: sha256_k = 32'h106aa070;
                6'd48: sha256_k = 32'h19a4c116; 6'd49: sha256_k = 32'h1e376c08;
                6'd50: sha256_k = 32'h2748774c; 6'd51: sha256_k = 32'h34b0bcb5;
                6'd52: sha256_k = 32'h391c0cb3; 6'd53: sha256_k = 32'h4ed8aa4a;
                6'd54: sha256_k = 32'h5b9cca4f; 6'd55: sha256_k = 32'h682e6ff3;
                6'd56: sha256_k = 32'h748f82ee; 6'd57: sha256_k = 32'h78a5636f;
                6'd58: sha256_k = 32'h84c87814; 6'd59: sha256_k = 32'h8cc70208;
                6'd60: sha256_k = 32'h90befffa; 6'd61: sha256_k = 32'ha4506ceb;
                6'd62: sha256_k = 32'hbef9a3f7; 6'd63: sha256_k = 32'hc67178f2;
            endcase
        end
    endfunction

    wire [31:0] ch_w   = (e & f) ^ ((~e) & g);
    wire [31:0] maj_w  = (a & b) ^ (a & c) ^ (b & c);
    wire [31:0] t1     = h + big_s1(e) + ch_w + sha256_k(round) + w[0];
    wire [31:0] t2     = big_s0(a) + maj_w;
    wire [31:0] w_next = msg_s1(w[14]) + w[9] + msg_s0(w[1]) + w[0];

    wire [31:0] a_next = t1 + t2;
    wire [31:0] b_next = a;
    wire [31:0] c_next = b;
    wire [31:0] d_next = c;
    wire [31:0] e_next = d + t1;
    wire [31:0] f_next = e;
    wire [31:0] g_next = f;
    wire [31:0] h_next = g;

    integer idx;

    always @(posedge clk) begin
        if (rst) begin
            busy  <= 1'b0;
            round <= 6'd0;
            h0 <= H0_0; h1 <= H0_1; h2 <= H0_2; h3 <= H0_3;
            h4 <= H0_4; h5 <= H0_5; h6 <= H0_6; h7 <= H0_7;
            a <= 32'd0; b <= 32'd0; c <= 32'd0; d <= 32'd0;
            e <= 32'd0; f <= 32'd0; g <= 32'd0; h <= 32'd0;
        end else if (start && !busy) begin
            for (idx = 0; idx < 16; idx = idx + 1) begin
                w[idx] <= block_in[(15 - idx)*32 +: 32];
            end
            if (init) begin
                h0 <= H0_0; h1 <= H0_1; h2 <= H0_2; h3 <= H0_3;
                h4 <= H0_4; h5 <= H0_5; h6 <= H0_6; h7 <= H0_7;
                a  <= H0_0; b  <= H0_1; c  <= H0_2; d  <= H0_3;
                e  <= H0_4; f  <= H0_5; g  <= H0_6; h  <= H0_7;
            end else begin
                a <= h0; b <= h1; c <= h2; d <= h3;
                e <= h4; f <= h5; g <= h6; h <= h7;
            end
            round <= 6'd0;
            busy  <= 1'b1;
        end else if (busy) begin
            for (idx = 0; idx < 15; idx = idx + 1) begin
                w[idx] <= w[idx + 1];
            end
            w[15] <= w_next;

            a <= a_next; b <= b_next; c <= c_next; d <= d_next;
            e <= e_next; f <= f_next; g <= g_next; h <= h_next;

            if (round == 6'd63) begin
                h0   <= h0 + a_next;
                h1   <= h1 + b_next;
                h2   <= h2 + c_next;
                h3   <= h3 + d_next;
                h4   <= h4 + e_next;
                h5   <= h5 + f_next;
                h6   <= h6 + g_next;
                h7   <= h7 + h_next;
                busy <= 1'b0;
            end else begin
                round <= round + 6'd1;
            end
        end
    end
endmodule

module sha257_rounds (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [255:0] init_digest,
    output reg          done,
    output reg  [511:0] final_hex
);
    localparam [8*72-1:0] SALT0 = "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA";
    localparam [8*70-1:0] SALT1 = "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB";
    localparam [8*68-1:0] SALT2 = "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC";
    localparam [8*69-1:0] SALT3 = "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD";
    localparam [8*70-1:0] SALT4 = "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE";
    localparam [8*67-1:0] SALT5 = "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF";
    localparam [8*66-1:0] SALT6 = "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG";
    localparam [8*67-1:0] SALT7 = "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH";
    localparam [8*64-1:0] SALT8 = "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II";
    localparam [8*73-1:0] SALT9 = "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ";

    function [7:0] nibble_to_ascii;
        input [3:0] nib;
        begin
            nibble_to_ascii = (nib < 4'd10) ? (8'd48 + {4'd0, nib}) : (8'd87 + {4'd0, nib});
        end
    endfunction

    function [7:0] salt_len;
        input [3:0] sid;
        begin
            case (sid)
                4'd0: salt_len = 8'd72;
                4'd1: salt_len = 8'd70;
                4'd2: salt_len = 8'd68;
                4'd3: salt_len = 8'd69;
                4'd4: salt_len = 8'd70;
                4'd5: salt_len = 8'd67;
                4'd6: salt_len = 8'd66;
                4'd7: salt_len = 8'd67;
                4'd8: salt_len = 8'd64;
                4'd9: salt_len = 8'd73;
                default: salt_len = 8'd0;
            endcase
        end
    endfunction

    function [7:0] salt_byte;
        input [3:0] sid;
        input [7:0] pos;
        begin
            case (sid)
                4'd0: salt_byte = SALT0[(71 - pos)*8 +: 8];
                4'd1: salt_byte = SALT1[(69 - pos)*8 +: 8];
                4'd2: salt_byte = SALT2[(67 - pos)*8 +: 8];
                4'd3: salt_byte = SALT3[(68 - pos)*8 +: 8];
                4'd4: salt_byte = SALT4[(69 - pos)*8 +: 8];
                4'd5: salt_byte = SALT5[(66 - pos)*8 +: 8];
                4'd6: salt_byte = SALT6[(65 - pos)*8 +: 8];
                4'd7: salt_byte = SALT7[(66 - pos)*8 +: 8];
                4'd8: salt_byte = SALT8[(63 - pos)*8 +: 8];
                4'd9: salt_byte = SALT9[(72 - pos)*8 +: 8];
                default: salt_byte = 8'd0;
            endcase
        end
    endfunction

    // Convert 256-bit digest to 64 ASCII hex bytes with last 8 chars reversed
    function [511:0] digest_to_rev_hex;
        input [255:0] d;
        integer k, src;
        reg [3:0] nib;
        begin
            for (k = 0; k < 64; k = k + 1) begin
                src = (k < 56) ? k : (119 - k);
                nib = d[(63 - src)*4 +: 4];
                digest_to_rev_hex[(63 - k)*8 +: 8] = nibble_to_ascii(nib);
            end
        end
    endfunction

    localparam [2:0]
        S_IDLE      = 3'd0,
        S_PREP      = 3'd1,
        S_START_BLK = 3'd2,
        S_WAIT_BLK  = 3'd3,
        S_DONE      = 3'd4;

    reg [2:0]    state;
    reg [5:0]    round_cnt;     // 0..34
    reg [3:0]    salt_idx;      // 0..9
    reg [1:0]    blk_idx;       // 0..2 (all interleaved buffers are 128..137 bytes -> always 3 blocks)
    reg [255:0]  cur_digest;
    reg [1535:0] padded_buf;    // 192 bytes = 3 SHA-256 blocks

    reg          core_init;
    reg          core_start;
    reg  [511:0] core_block;
    wire         core_busy;
    wire [255:0] core_digest;

    sha256_core u_sha256 (
        .clk      (clk),
        .rst      (rst),
        .init     (core_init),
        .start    (core_start),
        .block_in (core_block),
        .busy     (core_busy),
        .digest   (core_digest)
    );

    integer k, out_pos, slen, ilen;
    reg [511:0] rev_hex;
    reg [1535:0] next_padded;

    always @(posedge clk) begin
        if (rst) begin
            state      <= S_IDLE;
            done       <= 1'b0;
            core_init  <= 1'b0;
            core_start <= 1'b0;
            core_block <= 512'd0;
            round_cnt  <= 6'd0;
            salt_idx   <= 4'd0;
            blk_idx    <= 2'd0;
            cur_digest <= 256'd0;
            final_hex  <= 512'd0;
        end else begin
            core_start <= 1'b0;

            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        cur_digest <= init_digest;
                        round_cnt  <= 6'd0;
                        salt_idx   <= 4'd0;
                        state      <= S_PREP;
                    end
                end

                S_PREP: begin
                    // Build interleaved + SHA-256-padded 3-block buffer
                    rev_hex     = digest_to_rev_hex(cur_digest);
                    slen        = salt_len(salt_idx);
                    next_padded = 1536'd0;
                    out_pos     = 0;

                    for (k = 0; k < 73; k = k + 1) begin
                        if (k < 64) begin
                            next_padded[(191 - out_pos)*8 +: 8] = rev_hex[(63 - k)*8 +: 8];
                            out_pos = out_pos + 1;
                        end
                        if (k < slen) begin
                            next_padded[(191 - out_pos)*8 +: 8] = salt_byte(salt_idx, k[7:0]);
                            out_pos = out_pos + 1;
                        end
                    end

                    ilen = out_pos;
                    next_padded[(191 - ilen)*8 +: 8] = 8'h80;
                    // 64-bit big-endian bit length at bytes 184..191 (low 64 bits of 1536-bit buffer)
                    next_padded[63:0] = {53'd0, ilen[7:0], 3'b000};

                    padded_buf <= next_padded;
                    blk_idx    <= 2'd0;
                    state      <= S_START_BLK;
                end

                S_START_BLK: begin
                    core_init  <= (blk_idx == 2'd0);
                    core_start <= 1'b1;
                    case (blk_idx)
                        2'd0: core_block <= padded_buf[1535:1024];
                        2'd1: core_block <= padded_buf[1023:512];
                        default: core_block <= padded_buf[511:0];
                    endcase
                    state <= S_WAIT_BLK;
                end

                S_WAIT_BLK: begin
                    // Wait until core starts and finishes (core_start already low)
                    if (!core_start && !core_busy) begin
                        if (blk_idx < 2'd2) begin
                            blk_idx <= blk_idx + 2'd1;
                            state   <= S_START_BLK;
                        end else begin
                            cur_digest <= core_digest;
                            if (round_cnt == 6'd34) begin
                                final_hex <= digest_to_rev_hex(core_digest);
                                done      <= 1'b1;
                                state     <= S_DONE;
                            end else begin
                                round_cnt <= round_cnt + 6'd1;
                                salt_idx  <= (salt_idx == 4'd9) ? 4'd0 : (salt_idx + 4'd1);
                                state     <= S_PREP;
                            end
                        end
                    end
                end

                S_DONE: begin
                    if (!start) begin
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end
endmodule

module sha257sum;
    localparam MAX_STR = 1024;

    reg          clk;
    reg          rst;

    // Initial input streaming SHA-256 core signals
    reg          in_init;
    reg          in_start;
    reg  [511:0] in_block;
    wire         in_busy;
    wire [255:0] in_digest;

    // 35-round hardware engine signals
    reg          r_start;
    wire         r_done;
    wire [511:0] r_final_hex;

    sha256_core u_in_sha256 (
        .clk      (clk),
        .rst      (rst),
        .init     (in_init),
        .start    (in_start),
        .block_in (in_block),
        .busy     (in_busy),
        .digest   (in_digest)
    );

    sha257_rounds u_rounds (
        .clk         (clk),
        .rst         (rst),
        .start       (r_start),
        .init_digest (in_digest),
        .done        (r_done),
        .final_hex   (r_final_hex)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Streaming block buffer state
    reg [511:0] blk_buf;
    integer     blk_pos;
    reg [63:0]  total_bytes;
    reg         first_blk;

    task compress_current_block;
        begin
            @(negedge clk);
            in_init  = first_blk;
            in_block = blk_buf;
            in_start = 1'b1;
            @(posedge clk);
            @(negedge clk);
            in_start  = 1'b0;
            first_blk = 1'b0;
            while (in_busy) @(posedge clk);
            blk_buf = 512'd0;
            blk_pos = 0;
        end
    endtask

    task feed_byte;
        input [7:0] b;
        begin
            blk_buf[(63 - blk_pos)*8 +: 8] = b;
            blk_pos     = blk_pos + 1;
            total_bytes = total_bytes + 64'd1;
            if (blk_pos == 64) begin
                compress_current_block();
            end
        end
    endtask

    task finalize_input_sha256;
        reg [63:0] total_bits;
        begin
            total_bits = total_bytes << 3;
            blk_buf[(63 - blk_pos)*8 +: 8] = 8'h80;
            blk_pos = blk_pos + 1;
            if (blk_pos > 56) begin
                compress_current_block();
            end
            blk_buf[63:0] = total_bits;
            compress_current_block();
        end
    endtask

    reg [8*MAX_STR-1:0] input_str;
    reg [8*MAX_STR-1:0] file_path;
    integer fd, ch, i, started;

    initial begin
        rst         = 1'b1;
        in_init     = 1'b0;
        in_start    = 1'b0;
        in_block    = 512'd0;
        r_start     = 1'b0;
        blk_buf     = 512'd0;
        blk_pos     = 0;
        total_bytes = 64'd0;
        first_blk   = 1'b1;
        input_str   = 0;
        file_path   = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        if ($value$plusargs("FILE=%s", file_path)) begin
            fd = $fopen(file_path, "rb");
            if (fd == 0) begin
                $display("Error: could not open file");
                $finish(1);
            end
            ch = $fgetc(fd);
            while (ch != -1) begin
                feed_byte(ch[7:0]);
                ch = $fgetc(fd);
            end
            $fclose(fd);
        end else if ($test$plusargs("INPUT=")) begin
            if ($value$plusargs("INPUT=%s", input_str)) begin end
            started = 0;
            for (i = MAX_STR - 1; i >= 0; i = i - 1) begin
                if (input_str[i*8 +: 8] != 8'd0) started = 1;
                if (started) feed_byte(input_str[i*8 +: 8]);
            end
        end else begin
            $display("Usage: vvp sha257sum.vvp +INPUT=<string> | +FILE=<file>");
            $finish(1);
        end

        // Finalize initial SHA-256 digest in hardware
        finalize_input_sha256();

        // Trigger the 35-round hardware salt-interleaving FSM
        @(negedge clk);
        r_start = 1'b1;
        @(posedge clk);
        @(negedge clk);
        r_start = 1'b0;

        // Wait for all 35 rounds to complete
        while (!r_done) @(posedge clk);

        $display("%0s", r_final_hex);
        $finish(0);
    end
endmodule
