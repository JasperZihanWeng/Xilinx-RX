`timescale 1ns/1ps
`default_nettype none

// Recreate the receive clocks used by clock_test_ex.  At a 10 Gb/s line
// rate with a 64-bit raw interface, RXOUTCLKPMA is 312.5 MHz.  The MMCM
// produces the 312.5 MHz RXUSRCLK and 156.25 MHz RXUSRCLK2 required by GTH.
module qwn_rx_clocking (
    input  wire rxoutclk,
    input  wire reset,
    output wire rxusrclk,
    output wire rxusrclk2,
    output wire locked
);
    wire clkfb;
    wire clkfb_unbuffered;
    wire rxusrclk_unbuffered;
    wire rxusrclk2_unbuffered;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(3.200),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(2.000),
        .CLKOUT0_DIVIDE_F(2.000),
        .CLKOUT1_DIVIDE(4),
        .STARTUP_WAIT("FALSE")
    ) rx_mmcm (
        .CLKIN1(rxoutclk),
        .RST(reset),
        .PWRDWN(1'b0),
        .CLKFBIN(clkfb),
        .CLKFBOUT(clkfb_unbuffered),
        .CLKFBOUTB(),
        .CLKOUT0(rxusrclk_unbuffered),
        .CLKOUT0B(),
        .CLKOUT1(rxusrclk2_unbuffered),
        .CLKOUT1B(),
        .CLKOUT2(), .CLKOUT2B(), .CLKOUT3(), .CLKOUT3B(),
        .CLKOUT4(), .CLKOUT5(), .CLKOUT6(),
        .LOCKED(locked)
    );

    BUFG rx_feedback_buffer (.I(clkfb_unbuffered), .O(clkfb));
    BUFG rxusrclk_buffer     (.I(rxusrclk_unbuffered), .O(rxusrclk));
    BUFG rxusrclk2_buffer    (.I(rxusrclk2_unbuffered), .O(rxusrclk2));
endmodule

module qwn_stable_clock (
    input  wire clk_200,
    input  wire reset,
    output wire clk_100,
    output wire locked
);
    wire clkfb;
    wire clkfb_unbuffered;
    wire clk_100_unbuffered;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(5.000),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(5.000),
        .CLKOUT0_DIVIDE_F(10.000),
        .STARTUP_WAIT("FALSE")
    ) stable_mmcm (
        .CLKIN1(clk_200), .RST(reset), .PWRDWN(1'b0),
        .CLKFBIN(clkfb), .CLKFBOUT(clkfb_unbuffered), .CLKFBOUTB(),
        .CLKOUT0(clk_100_unbuffered), .CLKOUT0B(),
        .CLKOUT1(), .CLKOUT1B(), .CLKOUT2(), .CLKOUT2B(),
        .CLKOUT3(), .CLKOUT3B(), .CLKOUT4(), .CLKOUT5(), .CLKOUT6(),
        .LOCKED(locked)
    );

    BUFG stable_feedback_buffer (.I(clkfb_unbuffered), .O(clkfb));
    BUFG stable_output_buffer   (.I(clk_100_unbuffered), .O(clk_100));
endmodule

`default_nettype wire
