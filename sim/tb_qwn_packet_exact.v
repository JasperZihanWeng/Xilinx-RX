`timescale 1ns/1ps

// Bit-for-bit comparison against the 660x64-bit image deployed by the
// original two-Xilinx QWN transmitter. qwn_tx_words stores chronological
// wire bits at increasing bit addresses; the Lattice PMA emits each fabric
// symbol MSB-first, hence reverse10 before comparison.
module tb_qwn_packet_exact;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire [9:0] symbol;
    wire fid_stb;
    wire packet_stb;
    wire burst_stb;
    wire guard_active;
    wire dark_active;

    reg [63:0] original_words [0:659];
    reg [9:0] expected_wire_symbol;
    integer symbol_index;
    integer bit_index;
    integer absolute_bit;
    integer burst_number;
    integer guard_count;
    integer dark_count;

    always #4 clk = ~clk;

    qwn_packet_tx dut (
        .clk(clk), .reset_n(rst_n), .symbol(symbol),
        .fid_stb(fid_stb), .packet_stb(packet_stb),
        .burst_stb(burst_stb), .guard_active(guard_active),
        .dark_active(dark_active)
    );

    function [9:0] reverse10;
        input [9:0] value;
        integer n;
        begin
            for (n = 0; n < 10; n = n + 1)
                reverse10[n] = value[9-n];
        end
    endfunction

    initial begin
        $readmemh("../CPCC_QWN/clock_test_ex.srcs/sources_1/new/qwn_tx_words.mem",
                  original_words);
        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        for (burst_number = 0; burst_number < 2;
             burst_number = burst_number + 1) begin
            for (symbol_index = 0; symbol_index < 4224;
                 symbol_index = symbol_index + 1) begin
                @(negedge clk);
                expected_wire_symbol = 10'd0;
                for (bit_index = 0; bit_index < 10; bit_index = bit_index + 1) begin
                    absolute_bit = symbol_index*10 + bit_index;
                    expected_wire_symbol[bit_index] =
                        original_words[absolute_bit/64][absolute_bit%64];
                end
                if (reverse10(symbol) !== expected_wire_symbol)
                    $fatal(1, "burst %0d symbol %0d mismatch: got=%010b expected=%010b",
                           burst_number, symbol_index,
                           reverse10(symbol), expected_wire_symbol);
                if (fid_stb !== (symbol_index == 4128))
                    $fatal(1, "FID strobe mismatch at burst %0d symbol %0d",
                           burst_number, symbol_index);
                if (packet_stb !== (symbol_index == 4136))
                    $fatal(1, "packet strobe mismatch at burst %0d symbol %0d",
                           burst_number, symbol_index);
            end

            if (burst_number == 0) begin
                guard_count = guard_active ? 1 : 0;
                dark_count = 0;
                while (!burst_stb) begin
                    @(negedge clk);
                    if (guard_active)
                        guard_count = guard_count + 1;
                    if (dark_active)
                        dark_count = dark_count + 1;
                end
                if (guard_count != 1639)
                    $fatal(1, "guard length mismatch: %0d", guard_count);
                if (dark_count != 13107)
                    $fatal(1, "dark length mismatch: %0d", dark_count);
            end
        end

        $display("PASS: two exact QWN bursts with 1639-symbol guard and 13107-symbol dark");
        $finish;
    end
endmodule
