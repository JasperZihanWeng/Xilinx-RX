`timescale 1ns/1ps
`default_nettype none

// Align the recovered serial stream to the reversed K28.5 words emitted by
// the Lattice serializer, normalize each complete symbol, then use the
// original clock_test_ex 8b/10b decoder convention.
module qwn_symbol_decoder #(
    parameter CODE_ERR_LIM = 8,
    parameter GOOD_K_LIM = 8
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] recovered_bits,
    input  wire [3:0] recovered_count,
    output reg  [7:0] byte_o,
    output reg        k_o,
    output reg        byte_valid,
    output reg        code_err,
    output reg        comma_locked,
    output reg        k285_healthy,
    output reg [2:0]  byte_bit_pos
);
    localparam [9:0] K285_NEG_REVERSED = 10'b0101111100;
    localparam [9:0] K285_POS_REVERSED = 10'b1010000011;

    function [9:0] reverse10;
        input [9:0] value;
        integer n;
        begin
            for (n = 0; n < 10; n = n + 1)
                reverse10[n] = value[9-n];
        end
    endfunction

    // Recurrence state. sr[9] is the oldest received bit. countdown is the
    // number of bits through the next aligned symbol, including its last bit.
    reg [9:0] shift_reg;
    reg [3:0] countdown;
    reg [3:0] error_streak;
    reg [3:0] good_k_streak;

    reg [9:0] v_sr;
    reg [9:0] v_next_sr;
    reg [3:0] v_countdown;
    reg       v_locked;
    reg       reversed_k_match;
    reg       symbol_hit;
    reg [9:0] normalized_symbol;
    reg [2:0] normalized_symbol_pos;
    integer i;

    // Feed-forward pipeline around the decoder ROM. There can be at most one
    // completed 10-bit symbol in a cycle containing <=8 recovered bits.
    reg [9:0] symbol_q;
    reg       symbol_valid_q;
    reg [2:0] symbol_pos_q;
    reg [9:0] decoder_input;
    reg       decoder_valid;
    reg [2:0] decoder_pos;
    wire [7:0] decoded_byte;
    wire decoded_k;
    wire decoded_error;

    dec_8b10b decoder_i (
        .datain(decoder_input),
        .dout(decoded_byte),
        .kout(decoded_k),
        .code_err(decoded_error)
    );

    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= 10'd0;
            countdown <= 4'd0;
            error_streak <= 4'd0;
            good_k_streak <= 4'd0;
            comma_locked <= 1'b0;
            k285_healthy <= 1'b0;
            symbol_valid_q <= 1'b0;
            decoder_valid <= 1'b0;
            byte_o <= 8'd0;
            k_o <= 1'b0;
            byte_valid <= 1'b0;
            code_err <= 1'b0;
            byte_bit_pos <= 3'd0;
        end else begin
            v_sr = shift_reg;
            v_countdown = countdown;
            v_locked = comma_locked;
            symbol_hit = 1'b0;
            normalized_symbol = 10'd0;
            normalized_symbol_pos = 3'd0;

            // Consume the recovered bits in chronological order. A complete
            // reversed K28.5 can only occur at its legal symbol boundary in
            // a valid 8b/10b stream, so it both acquires and re-snaps lock.
            for (i = 0; i < 8; i = i + 1) begin
                if (i < recovered_count) begin
                    v_next_sr = {v_sr[8:0], recovered_bits[i]};
                    reversed_k_match =
                        (v_next_sr == K285_NEG_REVERSED) ||
                        (v_next_sr == K285_POS_REVERSED);

                    if (reversed_k_match) begin
                        v_locked = 1'b1;
                        v_countdown = 4'd10;
                        normalized_symbol = reverse10(v_next_sr);
                        normalized_symbol_pos = i[2:0];
                        symbol_hit = 1'b1;
                    end else if (v_locked) begin
                        if (v_countdown == 4'd1) begin
                            v_countdown = 4'd10;
                            normalized_symbol = reverse10(v_next_sr);
                            normalized_symbol_pos = i[2:0];
                            symbol_hit = 1'b1;
                        end else begin
                            v_countdown = v_countdown - 1'b1;
                        end
                    end
                    v_sr = v_next_sr;
                end
            end

            shift_reg <= v_sr;
            countdown <= v_countdown;
            comma_locked <= v_locked;

            symbol_valid_q <= symbol_hit;
            if (symbol_hit) begin
                symbol_q <= normalized_symbol;
                symbol_pos_q <= normalized_symbol_pos;
            end

            decoder_valid <= symbol_valid_q;
            if (symbol_valid_q) begin
                decoder_input <= symbol_q;
                decoder_pos <= symbol_pos_q;
            end

            byte_valid <= 1'b0;
            code_err <= 1'b0;
            if (decoder_valid) begin
                byte_o <= decoded_byte;
                k_o <= decoded_k;
                byte_valid <= 1'b1;
                code_err <= decoded_error;
                byte_bit_pos <= decoder_pos;

                if (decoded_error) begin
                    good_k_streak <= 4'd0;
                    if (error_streak == CODE_ERR_LIM-1) begin
                        comma_locked <= 1'b0;
                        countdown <= 4'd0;
                        error_streak <= 4'd0;
                    end else begin
                        error_streak <= error_streak + 1'b1;
                    end
                end else begin
                    error_streak <= 4'd0;
                    if (decoded_k && (decoded_byte == 8'hBC)) begin
                        if (good_k_streak < GOOD_K_LIM)
                            good_k_streak <= good_k_streak + 1'b1;
                        if (good_k_streak >= GOOD_K_LIM-1)
                            k285_healthy <= 1'b1;
                    end else begin
                        good_k_streak <= 4'd0;
                    end
                end
            end
        end
    end
endmodule

`default_nettype wire
