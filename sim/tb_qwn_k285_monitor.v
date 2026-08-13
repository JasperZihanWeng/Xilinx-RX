`timescale 1ns/1ps

module tb_qwn_k285_monitor;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [7:0] bits = 8'd0;
    reg [3:0] count = 4'd0;
    wire normal_seen;
    wire reversed_seen;
    wire [31:0] normal_count;
    wire [31:0] reversed_count;
    integer i;
    reg [9:0] symbol;

    always #3.2 clk = ~clk;

    qwn_k285_monitor dut (
        .clk(clk), .rst(rst),
        .recovered_bits(bits), .recovered_count(count),
        .normal_seen(normal_seen), .reversed_seen(reversed_seen),
        .normal_count(normal_count), .reversed_count(reversed_count)
    );

    task send_symbol;
        input [9:0] value;
        begin
            symbol = value;
            for (i = 9; i >= 0; i = i - 1) begin
                @(negedge clk);
                bits[0] = symbol[i];
                count = 1;
            end
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        repeat (5) begin
            send_symbol(10'b0011111010);
            send_symbol(10'b1100000101);
        end
        @(posedge clk); #1;
        if (!normal_seen || reversed_seen)
            $fatal(1, "normal order was not classified uniquely");

        @(negedge clk); rst = 1'b1; count = 0;
        repeat (2) @(negedge clk);
        rst = 1'b0;
        repeat (5) begin
            send_symbol(10'b0101111100);
            send_symbol(10'b1010000011);
        end
        @(posedge clk); #1;
        if (normal_seen || !reversed_seen)
            $fatal(1, "reversed order was not classified uniquely");

        $display("PASS: normal and reversed K28.5 orders classified independently");
        $finish;
    end
endmodule
