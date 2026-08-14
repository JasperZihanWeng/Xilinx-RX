`timescale 1ns/1ps

module tb_qwn_rx_gate;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg fid_pulse = 1'b0;
    reg hdr_valid = 1'b0;
    reg hdr_discard = 1'b0;
    reg [23:0] gate_delay = 24'd2202;
    wire gate;
    wire [7:0] gate_fine;
    wire [2:0] gate_inst;
    wire gate_veto;
    wire [2:0] gate_ui;
    wire armed;

    integer cycle = 0;
    integer fid_cycle;
    integer gate_cycle;
    integer gate_count = 0;

    always #3.2 clk = ~clk;
    always @(posedge clk) begin
        if (rst)
            cycle <= 0;
        else begin
            cycle <= cycle + 1;
            if (gate) begin
                gate_cycle <= cycle;
                gate_count <= gate_count + 1;
            end
        end
    end

    rx_gate #(.CAL_OFFSET(16'sd0)) dut (
        .clk(clk), .rst(rst), .bv(1'b0),
        .eph_inst_i(3'd2), .eph_filt_i(7'd32),
        .fid_pulse(fid_pulse), .hdr_valid_i(hdr_valid),
        .hdr_discard_i(hdr_discard), .gate_delay_i(gate_delay),
        .ui_offset_i(3'd5), .gate_o(gate), .gate_fine_o(gate_fine),
        .gate_inst_o(gate_inst), .veto_o(gate_veto),
        .gate_ui_o(gate_ui), .armed_o(armed)
    );

    task reset_dut;
        begin
            rst = 1'b1;
            fid_pulse = 1'b0;
            hdr_valid = 1'b0;
            hdr_discard = 1'b0;
            repeat (3) @(negedge clk);
            rst = 1'b0;
            @(negedge clk);
        end
    endtask

    task send_fid;
        begin
            fid_pulse = 1'b1;
            @(negedge clk);
            fid_pulse = 1'b0;
            fid_cycle = cycle;
        end
    endtask

    initial begin
        // Valid header: count free-runs with bv=0 and fires once. The
        // CAL_OFFSET=0 is the coarse-gate baseline. Physical marker-path
        // compensation is added only when that output path is instantiated.
        reset_dut();
        gate_count = 0;
        send_fid();
        repeat (9) @(negedge clk);
        hdr_valid = 1'b1;
        @(negedge clk); hdr_valid = 1'b0;
        // A later false FID in dark must not restart a validated countdown.
        repeat (20) @(negedge clk);
        fid_pulse = 1'b1;
        @(negedge clk); fid_pulse = 1'b0;
        wait (gate_count == 1);
        @(negedge clk);
        if ((gate_cycle - fid_cycle) != 2202)
            $fatal(1, "gate delay mismatch: got %0d expected 2202",
                   gate_cycle - fid_cycle);
        if (gate_fine != 8'd32 || gate_inst != 3'd2 || gate_ui != 3'd5)
            $fatal(1, "committed phase/UI outputs mismatch");
        if (gate_veto || armed)
            $fatal(1, "unexpected veto or armed state after gate");
        repeat (4) @(negedge clk);
        if (gate_count != 1)
            $fatal(1, "valid header produced multiple gates");

        // Explicit discard must cancel the pending gate.
        reset_dut();
        gate_delay = 24'd32;
        gate_count = 0;
        send_fid();
        repeat (5) @(negedge clk);
        hdr_discard = 1'b1;
        @(negedge clk); hdr_discard = 1'b0;
        repeat (40) @(negedge clk);
        if (gate_count != 0 || armed)
            $fatal(1, "discarded header produced or retained a gate");

        // Missing validation reaches the target but must never fire.
        reset_dut();
        gate_count = 0;
        send_fid();
        repeat (40) @(negedge clk);
        if (gate_count != 0 || armed)
            $fatal(1, "missing header produced or retained a gate");

        $display("PASS: exact gate delay, dark counting, discard, and missing-header safety");
        $finish;
    end
endmodule
