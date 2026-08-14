`timescale 1ns/1ps
`default_nettype none

// Human-visible proof of the burst link's two essential physical events:
// the SFP receiver reports loss of light, then a checksum-valid QWN header
// arrives after light returns. LOS is asynchronous to the recovered clock.
module qwn_burst_diagnostics #(
    parameter [15:0] HEADER_HOLD_CYCLES = 16'hFFFF
)(
    input  wire clk,
    input  wire rst,
    input  wire sfp_los_async,
    input  wire header_valid,
    input  wire gate_pulse,
    output reg  los_seen,
    output reg  header_after_los,
    output wire header_recent,
    output wire gate_recent
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] los_sync;
    reg waiting_for_header;
    reg [15:0] header_hold;
    reg [15:0] gate_hold;

    assign header_recent = (header_hold != 16'd0);
    assign gate_recent = (gate_hold != 16'd0);

    always @(posedge clk) begin
        if (rst)
            los_sync <= 2'b00;
        else
            los_sync <= {los_sync[0], sfp_los_async};
    end

    always @(posedge clk) begin
        if (rst) begin
            los_seen <= 1'b0;
            header_after_los <= 1'b0;
            waiting_for_header <= 1'b0;
            header_hold <= 16'd0;
            gate_hold <= 16'd0;
        end else begin
            if (los_sync[1]) begin
                los_seen <= 1'b1;
                waiting_for_header <= 1'b1;
            end

            if (header_valid) begin
                header_hold <= HEADER_HOLD_CYCLES;
                if (waiting_for_header) begin
                    header_after_los <= 1'b1;
                    waiting_for_header <= 1'b0;
                end
            end else if (header_hold != 16'd0) begin
                header_hold <= header_hold - 1'b1;
            end

            if (gate_pulse)
                gate_hold <= HEADER_HOLD_CYCLES;
            else if (gate_hold != 16'd0)
                gate_hold <= gate_hold - 1'b1;
        end
    end
endmodule

`default_nettype wire
