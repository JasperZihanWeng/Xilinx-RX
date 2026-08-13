`timescale 1ns/1ps

module tb_qwn_symbol_decoder;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [7:0] recovered_bits = 8'd0;
    reg [3:0] recovered_count = 4'd0;
    wire [7:0] byte_o;
    wire k_o;
    wire byte_valid;
    wire code_err;
    wire comma_locked;
    wire k285_healthy;

    reg stream [0:255];
    reg [9:0] symbol;
    integer offset;
    integer s;
    integer b;
    integer j;
    integer pos;
    integer total;
    integer valid_now;
    integer decoded_count;

    always #3.2 clk = ~clk;

    qwn_symbol_decoder dut (
        .clk(clk), .rst(rst),
        .recovered_bits(recovered_bits),
        .recovered_count(recovered_count),
        .byte_o(byte_o), .k_o(k_o), .byte_valid(byte_valid),
        .code_err(code_err), .comma_locked(comma_locked),
        .k285_healthy(k285_healthy)
    );

    always @(posedge clk) begin
        if (rst)
            decoded_count <= 0;
        else if (byte_valid) begin
            if (code_err || !k_o || (byte_o != 8'hBC))
                $fatal(1, "invalid decode: byte=%02x k=%b err=%b", byte_o, k_o, code_err);
            decoded_count <= decoded_count + 1;
        end
    end

    initial begin
        // Exercise every possible 10-bit symbol starting offset while the
        // DUT consumes realistic groups of eight recovered bits per cycle.
        for (offset = 0; offset < 10; offset = offset + 1) begin
            for (j = 0; j < 256; j = j + 1)
                stream[j] = 1'b0;

            for (s = 0; s < 12; s = s + 1) begin
                symbol = s[0] ? 10'b1010000011 : 10'b0101111100;
                for (b = 0; b < 10; b = b + 1)
                    stream[offset + s*10 + b] = symbol[9-b];
            end

            rst = 1'b1;
            recovered_count = 4'd0;
            repeat (3) @(negedge clk);
            rst = 1'b0;

            total = offset + 120;
            pos = 0;
            while (pos < total) begin
                @(negedge clk);
                valid_now = ((total-pos) >= 8) ? 8 : (total-pos);
                recovered_count = valid_now;
                recovered_bits = 8'd0;
                for (j = 0; j < 8; j = j + 1)
                    if (j < valid_now)
                        recovered_bits[j] = stream[pos+j];
                pos = pos + valid_now;
            end

            @(negedge clk);
            recovered_count = 4'd0;
            repeat (6) @(posedge clk);
            if (!comma_locked || !k285_healthy || (decoded_count < 8))
                $fatal(1, "offset %0d failed: lock=%b healthy=%b decoded=%0d",
                       offset, comma_locked, k285_healthy, decoded_count);
        end

        $display("PASS: all ten starting offsets align and decode K28.5 as K/0xBC");
        $finish;
    end
endmodule
