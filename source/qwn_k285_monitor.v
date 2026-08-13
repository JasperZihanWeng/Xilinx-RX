`timescale 1ns/1ps
`default_nettype none

// Find both K28.5 running-disparity forms in both serializer bit orders.
// The detector is split into two registered stages so the cadence qualifier
// does not sit in the same timing cone as eight parallel 10-bit compares.
module qwn_k285_monitor (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] recovered_bits,
    input  wire [3:0] recovered_count,
    output reg        normal_seen,
    output reg        reversed_seen,
    output reg [31:0] normal_count,
    output reg [31:0] reversed_count
);
    localparam [9:0] K285_NEG = 10'b0011111010;
    localparam [9:0] K285_POS = 10'b1100000101;
    localparam [9:0] K285_NEG_REVERSED = 10'b0101111100;
    localparam [9:0] K285_POS_REVERSED = 10'b1010000011;

    // Stage 1: slide over this cycle's recovered bits and register one match
    // bit per input position. Bit zero from the CDR is the earliest bit.
    reg [9:0] history;
    reg [9:0] next_history;
    reg [7:0] normal_mask;
    reg [7:0] reversed_mask;
    reg normal_valid;
    reg reversed_valid;
    reg [3:0] normal_pos;
    reg [3:0] reversed_pos;
    reg next_normal_valid;
    reg next_reversed_valid;
    reg [3:0] next_normal_pos;
    reg [3:0] next_reversed_pos;
    reg [3:0] count_r;
    integer i;

    always @* begin
        next_history = history;
        normal_mask = 8'd0;
        reversed_mask = 8'd0;
        for (i = 0; i < 8; i = i + 1) begin
            if (i < recovered_count) begin
                next_history = {next_history[8:0], recovered_bits[i]};
                normal_mask[i] = (next_history == K285_NEG) ||
                                 (next_history == K285_POS);
                reversed_mask[i] = (next_history == K285_NEG_REVERSED) ||
                                   (next_history == K285_POS_REVERSED);
            end
        end
    end

    // Stage 2: priority-encode the (at most one) match in each <=8-bit input
    // group. A 10-bit symbol cannot end twice within one group.
    always @* begin
        next_normal_valid = 1'b0;
        next_reversed_valid = 1'b0;
        next_normal_pos = 4'd0;
        next_reversed_pos = 4'd0;
        for (i = 0; i < 8; i = i + 1) begin
            if (normal_mask[i]) begin
                next_normal_valid = 1'b1;
                next_normal_pos = i[3:0];
            end
            if (reversed_mask[i]) begin
                next_reversed_valid = 1'b1;
                next_reversed_pos = i[3:0];
            end
        end
    end

    // Stage 3: a valid symbol stream produces a match exactly every ten
    // recovered bits. Eight correctly spaced matches are required before a
    // sticky result is asserted, making random startup matches negligible.
    reg [4:0] normal_gap, reversed_gap;
    reg [4:0] next_normal_gap, next_reversed_gap;
    reg [3:0] normal_streak, reversed_streak;
    reg [3:0] next_normal_streak, next_reversed_streak;
    reg next_normal_seen, next_reversed_seen;
    reg [31:0] next_normal_count, next_reversed_count;
    reg [5:0] normal_distance;
    reg [5:0] reversed_distance;

    always @* begin
        next_normal_gap = normal_gap;
        next_reversed_gap = reversed_gap;
        next_normal_streak = normal_streak;
        next_reversed_streak = reversed_streak;
        next_normal_seen = normal_seen;
        next_reversed_seen = reversed_seen;
        next_normal_count = normal_count;
        next_reversed_count = reversed_count;
        normal_distance = {1'b0, normal_gap} + normal_pos + 1'b1;
        reversed_distance = {1'b0, reversed_gap} + reversed_pos + 1'b1;

        if (normal_valid) begin
            if (normal_distance == 6'd10)
                next_normal_streak = normal_streak + 1'b1;
            else
                next_normal_streak = 4'd1;
            next_normal_gap = count_r - normal_pos - 1'b1;
            next_normal_count = normal_count + 1'b1;
            if (next_normal_streak >= 4'd8)
                next_normal_seen = 1'b1;
        end else if ((normal_gap + count_r) < 5'd31) begin
            next_normal_gap = normal_gap + count_r;
        end else begin
            next_normal_gap = 5'd31;
        end

        if (reversed_valid) begin
            if (reversed_distance == 6'd10)
                next_reversed_streak = reversed_streak + 1'b1;
            else
                next_reversed_streak = 4'd1;
            next_reversed_gap = count_r - reversed_pos - 1'b1;
            next_reversed_count = reversed_count + 1'b1;
            if (next_reversed_streak >= 4'd8)
                next_reversed_seen = 1'b1;
        end else if ((reversed_gap + count_r) < 5'd31) begin
            next_reversed_gap = reversed_gap + count_r;
        end else begin
            next_reversed_gap = 5'd31;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            history <= 10'd0;
            normal_valid <= 1'b0;
            reversed_valid <= 1'b0;
            normal_pos <= 4'd0;
            reversed_pos <= 4'd0;
            count_r <= 4'd0;
            normal_gap <= 5'd31;
            reversed_gap <= 5'd31;
            normal_streak <= 4'd0;
            reversed_streak <= 4'd0;
            normal_seen <= 1'b0;
            reversed_seen <= 1'b0;
            normal_count <= 32'd0;
            reversed_count <= 32'd0;
        end else begin
            history <= next_history;
            normal_valid <= next_normal_valid;
            reversed_valid <= next_reversed_valid;
            normal_pos <= next_normal_pos;
            reversed_pos <= next_reversed_pos;
            count_r <= recovered_count;
            normal_gap <= next_normal_gap;
            reversed_gap <= next_reversed_gap;
            normal_streak <= next_normal_streak;
            reversed_streak <= next_reversed_streak;
            normal_seen <= next_normal_seen;
            reversed_seen <= next_reversed_seen;
            normal_count <= next_normal_count;
            reversed_count <= next_reversed_count;
        end
    end
endmodule

`default_nettype wire
