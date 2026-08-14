`timescale 1ns/1ps

// Integration test for the first compatibility milestone. The Lattice packet
// source is decoded and passed directly into the original Xilinx QWN header
// parser. Symbol alignment/CDR are tested separately by tb_qwn_symbol_decoder.
module tb_qwn_packet_header;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire [9:0] symbol;
    wire fid_stb;
    wire packet_stb;
    wire burst_stb;
    wire guard_active;
    wire dark_active;
    wire [7:0] decoded_byte;
    wire decoded_k;
    wire decoded_error;

    wire fid_pulse;
    wire hdr_valid;
    wire hdr_discard;
    wire [7:0] destination;
    wire [15:0] payload_dur;
    wire [23:0] gate_delay;
    wire [2:0] ui_offset;

    integer cycle_count = 0;
    integer fid_count = 0;
    integer packet_count = 0;
    integer header_count = 0;
    integer discard_count = 0;

    always #4 clk = ~clk;

    qwn_packet_tx source_i (
        .clk(clk), .reset_n(rst_n), .symbol(symbol),
        .fid_stb(fid_stb), .packet_stb(packet_stb),
        .burst_stb(burst_stb), .guard_active(guard_active),
        .dark_active(dark_active)
    );

    dec_8b10b decoder_i (
        .datain(symbol), .dout(decoded_byte),
        .kout(decoded_k), .code_err(decoded_error)
    );

    rx_header parser_i (
        .clk(clk), .rst(!rst_n), .byte_valid(rst_n && !dark_active),
        .code_err(decoded_error), .k_i(decoded_k), .byte_i(decoded_byte),
        .byte_bit_pos(3'd3), .fid_pulse(fid_pulse),
        .hdr_valid(hdr_valid), .hdr_discard(hdr_discard),
        .destination(destination), .payload_dur(payload_dur),
        .gate_delay(gate_delay), .ui_offset(ui_offset)
    );

    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
            if (fid_stb)
                fid_count <= fid_count + 1;
            if (packet_stb)
                packet_count <= packet_count + 1;
            if (hdr_discard)
                discard_count <= discard_count + 1;
            if (hdr_valid) begin
                header_count <= header_count + 1;
                if (destination !== 8'h02)
                    $fatal(1, "destination mismatch: %02x", destination);
                if (payload_dur !== 16'h0040)
                    $fatal(1, "payload duration mismatch: %04x", payload_dur);
                if (gate_delay !== 24'h00089A)
                    $fatal(1, "gate delay mismatch: %06x", gate_delay);
                if (ui_offset !== 3'd3)
                    $fatal(1, "FID UI offset mismatch: %0d", ui_offset);
            end
        end
    end

    initial begin
        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        wait (header_count == 2);
        @(negedge clk);
        if (discard_count != 0)
            $fatal(1, "parser discarded %0d header(s)", discard_count);
        if ((fid_count != 2) || (packet_count != 2))
            $fatal(1, "strobe count mismatch: fid=%0d packet=%0d",
                   fid_count, packet_count);
        $display("PASS: original QWN header validated after two burst/dark cycles: dst=%02x pd=%0d gd=%0d",
                 destination, payload_dur, gate_delay);
        $finish;
    end

    initial begin
        repeat (25000) @(posedge clk);
        $fatal(1, "timeout waiting for repeated original QWN headers");
    end
endmodule
