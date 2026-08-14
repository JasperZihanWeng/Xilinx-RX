`timescale 1ns/1ps

module tb_qwn_burst_diagnostics;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg sfp_los_async = 1'b0;
    reg header_valid = 1'b0;
    reg gate_pulse = 1'b0;
    wire los_seen;
    wire header_after_los;
    wire header_recent;
    wire gate_recent;

    always #3.2 clk = ~clk;

    qwn_burst_diagnostics #(.HEADER_HOLD_CYCLES(16'd10)) dut (
        .clk(clk), .rst(rst), .sfp_los_async(sfp_los_async),
        .header_valid(header_valid), .gate_pulse(gate_pulse),
        .los_seen(los_seen),
        .header_after_los(header_after_los),
        .header_recent(header_recent), .gate_recent(gate_recent)
    );

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;

        // A header before any dark interval may set "recent," but must not
        // claim recovery after LOS.
        @(negedge clk); header_valid = 1'b1;
        @(negedge clk); header_valid = 1'b0;
        @(negedge clk);
        if (!header_recent || gate_recent || los_seen || header_after_los)
            $fatal(1, "pre-LOS header diagnostic mismatch");

        repeat (11) @(negedge clk);
        if (header_recent)
            $fatal(1, "header-recent watchdog did not expire");

        // LOS must survive the two-flop synchronizer and latch permanently.
        sfp_los_async = 1'b1;
        repeat (4) @(negedge clk);
        sfp_los_async = 1'b0;
        repeat (3) @(negedge clk);
        if (!los_seen || header_after_los)
            $fatal(1, "LOS event was not latched correctly");

        // The first later valid header proves post-dark recovery.
        header_valid = 1'b1;
        @(negedge clk); header_valid = 1'b0;
        gate_pulse = 1'b1;
        @(negedge clk); gate_pulse = 1'b0;
        @(negedge clk);
        if (!los_seen || !header_after_los || !header_recent || !gate_recent)
            $fatal(1, "post-LOS header recovery was not latched");

        rst = 1'b1;
        repeat (2) @(negedge clk);
        if (los_seen || header_after_los || header_recent || gate_recent)
            $fatal(1, "reset did not clear burst diagnostics");

        $display("PASS: LOS, post-LOS header recovery, and recent-header timeout");
        $finish;
    end
endmodule
