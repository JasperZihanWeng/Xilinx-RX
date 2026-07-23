`timescale 1ns / 1ps
`default_nettype none

module top (
    input  wire sysclk_p,
    input  wire sysclk_n,
    input  wire cpu_reset_n,

    input  wire user_clock_p,
    input  wire user_clock_n,
    output wire ref_clk_sma_p,
    output wire ref_clk_sma_n,

    input  wire gt_refclk_p,
    input  wire gt_refclk_n,
    input  wire sfp_rx_p,
    input  wire sfp_rx_n,
    output wire sfp_tx_p,
    output wire sfp_tx_n,

    input  wire sfp1_tx_fault,
    input  wire sfp1_mod_abs,
    input  wire sfp1_los,
    output wire sfp1_tx_disable,
    output wire sfp1_rs0,
    output wire sfp1_rs1,

    output wire [7:0] gpio_led
);

    wire sysclk_200;
    wire dclk_100;
    wire dclk_locked;
    wire reset_button = ~cpu_reset_n;
    wire pcs_reset = reset_button | ~dclk_locked;
    wire si570_forward;

    // The same VC709 clock arrangement used by clock_test_ex: forward the
    // onboard 156.25 MHz Si570 to J31/J32, then use the installed SMA cables
    // to feed J25/J26 (the GTH reference-clock input).
    IBUFDS system_clock_input (
        .I(sysclk_p),
        .IB(sysclk_n),
        .O(sysclk_200)
    );

    stable_clock_100 system_clock_divider (
        .clk_200_in(sysclk_200),
        .reset(reset_button),
        .clk_100_out(dclk_100),
        .locked(dclk_locked)
    );

    IBUFDS si570_input (
        .I(user_clock_p),
        .IB(user_clock_n),
        .O(si570_forward)
    );

    OBUFDS si570_sma_output (
        .I(si570_forward),
        .O(ref_clk_sma_p),
        .OB(ref_clk_sma_n)
    );

    // The PCS/PMA presents decoded 10G Ethernet as 64-bit XGMII. These nets
    // stay in fabric; MARK_DEBUG keeps them available for a later ILA pass.
    (* mark_debug = "true" *) wire [63:0] xgmii_rxd;
    (* mark_debug = "true" *) wire [7:0]  xgmii_rxc;
    (* mark_debug = "true" *) wire [7:0]  core_status;
    (* mark_debug = "true" *) wire [447:0] status_vector;
    (* mark_debug = "true" *) wire         pcs_resetdone;
    (* mark_debug = "true" *) wire         qpll_locked;
    wire coreclk;
    (* mark_debug = "true" *) wire core_tx_disable;
    (* mark_debug = "true" *) wire core_gttxreset;
    (* mark_debug = "true" *) wire core_gtrxreset;
    (* mark_debug = "true" *) wire core_txuserrdy;
    (* mark_debug = "true" *) wire core_reset_counter_done;

    // The SFP+ cage has a separate, active-high laser-disable input.  UG887
    // Table 1-14 routes it to AB41; leaving this pin unconstrained can keep the
    // module transmitter off. For optical bring-up, explicitly enable TX once
    // the clocks are stable, independently of the PCS-requested disable, and
    // select the high-rate operating mode on both SFP rate-select pins.
    assign sfp1_tx_disable = pcs_reset;
    assign sfp1_rs0 = 1'b1;
    // VC709 guidance requires RS1 low (receiver rate select grounded).
    assign sfp1_rs1 = 1'b0;

    // Periodic XGMII test frames make an optical TX-to-RX loopback visible on
    // the packet LEDs without requiring the Lattice board.
    wire [63:0] xgmii_txd;
    wire [7:0]  xgmii_txc;
    (* mark_debug = "true" *) wire [31:0] tx_packet_count;

    xgmii_test_transmitter test_transmitter (
        .clk(coreclk),
        .reset(~pcs_resetdone),
        .xgmii_txd(xgmii_txd),
        .xgmii_txc(xgmii_txc),
        .packet_count(tx_packet_count)
    );

    // The configuration-vector default (all zero) enables normal operation:
    // no reset, loopback, test pattern, or global transmit disable.
    wire [535:0] configuration_vector = 536'b0;

    // Loop the core's PCS-requested DRP transaction into its internal GTH.
    wire        drp_req;
    wire        drp_den;
    wire        drp_dwe;
    wire [15:0] drp_daddr;
    wire [15:0] drp_di;
    wire        drp_drdy;
    wire [15:0] drp_drpdo;

    ten_gig_eth_pcs_pma_0 pcs_pma (
        .dclk(dclk_100),
        .refclk_p(gt_refclk_p),
        .refclk_n(gt_refclk_n),
        .reset(pcs_reset),
        .sim_speedup_control(1'b0),

        .txp(sfp_tx_p),
        .txn(sfp_tx_n),
        .rxp(sfp_rx_p),
        .rxn(sfp_rx_n),

        .xgmii_txd(xgmii_txd),
        .xgmii_txc(xgmii_txc),
        .xgmii_rxd(xgmii_rxd),
        .xgmii_rxc(xgmii_rxc),

        .configuration_vector(configuration_vector),
        .status_vector(status_vector),
        .core_status(core_status),
        .pma_pmd_type(3'b110),       // 10GBASE-LR optical PMD indication
        // Do not gate GTH initialization with optical LOS. The generated core
        // otherwise holds RX in reset while no light is present, making its
        // combined resetdone_out stay low and obscuring TX-only bring-up.
        .signal_detect(1'b1),
        .tx_fault(sfp1_tx_fault),
        .tx_disable(core_tx_disable),

        .drp_req(drp_req),
        .drp_gnt(drp_req),
        .drp_den_o(drp_den),
        .drp_dwe_o(drp_dwe),
        .drp_daddr_o(drp_daddr),
        .drp_di_o(drp_di),
        .drp_drdy_o(drp_drdy),
        .drp_drpdo_o(drp_drpdo),
        .drp_den_i(drp_den),
        .drp_dwe_i(drp_dwe),
        .drp_daddr_i(drp_daddr),
        .drp_di_i(drp_di),
        .drp_drdy_i(drp_drdy),
        .drp_drpdo_i(drp_drpdo),

        .coreclk_out(coreclk),
        .qplllock_out(qpll_locked),
        .resetdone_out(pcs_resetdone),
        .rxrecclk_out(),
        .qplloutclk_out(),
        .qplloutrefclk_out(),
        .txusrclk_out(),
        .txusrclk2_out(),
        .areset_datapathclk_out(),
        .gttxreset_out(core_gttxreset),
        .gtrxreset_out(core_gtrxreset),
        .txuserrdy_out(core_txuserrdy),
        .reset_counter_done_out(core_reset_counter_done)
    );

    (* mark_debug = "true" *) wire        rx_in_frame;
    (* mark_debug = "true" *) wire        packet_seen;
    (* mark_debug = "true" *) wire        packet_error;
    (* mark_debug = "true" *) wire        packet_led;
    (* mark_debug = "true" *) wire [31:0] rx_packet_count;

    xgmii_packet_monitor packet_monitor (
        .clk(coreclk),
        .reset(pcs_reset),
        .xgmii_rxd(xgmii_rxd),
        .xgmii_rxc(xgmii_rxc),
        .block_lock(core_status[0]),
        .in_frame(rx_in_frame),
        .packet_seen(packet_seen),
        .packet_error(packet_error),
        .packet_led(packet_led),
        .packet_count(rx_packet_count)
    );

    // Independent core-clock heartbeat. This does not depend on the XGMII
    // transmitter state machine, so it distinguishes a stopped core clock
    // from a transmitter that is still held in reset or not advancing.
    reg [25:0] coreclk_heartbeat = 26'd0;
    always @(posedge coreclk or negedge pcs_resetdone) begin
        if (!pcs_resetdone)
            coreclk_heartbeat <= 26'd0;
        else
            coreclk_heartbeat <= coreclk_heartbeat + 1'b1;
    end

    // UG887 Table 1-19 defines these LEDs as active-high.
    //   DS2: QPLL locked              DS6: packet received since reset
    //   DS3: PCS/GTH reset complete   DS7: SFP1 module installed
    //   DS4: TX frame-count toggle    DS8: SFP1 receiver loss of signal
    //   DS5: raw coreclk heartbeat    DS9: SFP1 transmitter fault
    assign gpio_led[0] = qpll_locked;
    assign gpio_led[1] = pcs_resetdone;
    assign gpio_led[2] = tx_packet_count[0];
    assign gpio_led[3] = coreclk_heartbeat[25];
    assign gpio_led[4] = core_tx_disable;
    assign gpio_led[5] = ~sfp1_mod_abs;
    assign gpio_led[6] = sfp1_los;
    assign gpio_led[7] = sfp1_tx_fault;

endmodule


module xgmii_test_transmitter (
    input  wire        clk,
    input  wire        reset,
    output reg  [63:0] xgmii_txd,
    output reg  [7:0]  xgmii_txc,
    output reg  [31:0] packet_count
);
    localparam [63:0] XGMII_IDLES = 64'h0707_0707_0707_0707;
    localparam [25:0] INTER_PACKET_DELAY = 26'd39_062_499; // about 250 ms

    localparam [3:0] TX_WAIT = 4'd0;
    localparam [3:0] TX_START = 4'd1;
    localparam [3:0] TX_DATA0 = 4'd2;
    localparam [3:0] TX_DATA1 = 4'd3;
    localparam [3:0] TX_DATA2 = 4'd4;
    localparam [3:0] TX_DATA3 = 4'd5;
    localparam [3:0] TX_DATA4 = 4'd6;
    localparam [3:0] TX_DATA5 = 4'd7;
    localparam [3:0] TX_DATA6 = 4'd8;
    localparam [3:0] TX_DATA7 = 4'd9;
    localparam [3:0] TX_TERM = 4'd10;

    reg [3:0] state;
    reg [25:0] delay_counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= TX_WAIT;
            delay_counter <= 26'd0;
            packet_count  <= 32'd0;
            xgmii_txd     <= XGMII_IDLES;
            xgmii_txc     <= 8'hff;
        end else begin
            case (state)
                TX_WAIT: begin
                    xgmii_txd <= XGMII_IDLES;
                    xgmii_txc <= 8'hff;
                    if (delay_counter == INTER_PACKET_DELAY) begin
                        delay_counter <= 26'd0;
                        state <= TX_START;
                    end else begin
                        delay_counter <= delay_counter + 1'b1;
                    end
                end

                // Lane 0 is /S/; lanes 1-6 are preamble; lane 7 is SFD.
                TX_START: begin
                    xgmii_txd <= {8'hd5, {6{8'h55}}, 8'hfb};
                    xgmii_txc <= 8'b0000_0001;
                    state <= TX_DATA0;
                end

                // Recognizable test content. CAFE and the packet sequence are
                // intentionally included for easy ILA inspection.
                TX_DATA0: begin
                    xgmii_txd <= 64'h0200_0000_0002_0200;
                    xgmii_txc <= 8'h00;
                    state <= TX_DATA1;
                end
                TX_DATA1: begin
                    xgmii_txd <= {16'hcafe, packet_count, 16'h88b5};
                    xgmii_txc <= 8'h00;
                    state <= TX_DATA2;
                end
                TX_DATA2: begin
                    xgmii_txd <= 64'h4c4f_4f50_4241_434b;
                    xgmii_txc <= 8'h00;
                    state <= TX_DATA3;
                end
                TX_DATA3: begin
                    xgmii_txd <= 64'h5643_3730_395f_5445;
                    xgmii_txc <= 8'h00;
                    state <= TX_DATA4;
                end
                TX_DATA4: begin
                    xgmii_txd <= 64'h5354_5f46_5241_4d45;
                    xgmii_txc <= 8'h00;
                    state <= TX_DATA5;
                end
                TX_DATA5: begin
                    xgmii_txd <= 64'h1122_3344_5566_7788;
                    xgmii_txc <= 8'h00;
                    state <= TX_DATA6;
                end
                TX_DATA6: begin
                    xgmii_txd <= 64'h99aa_bbcc_ddee_ff00;
                    xgmii_txc <= 8'h00;
                    state <= TX_DATA7;
                end
                TX_DATA7: begin
                    xgmii_txd <= 64'h0123_4567_89ab_cdef;
                    xgmii_txc <= 8'h00;
                    state <= TX_TERM;
                end

                TX_TERM: begin
                    xgmii_txd    <= 64'h0707_0707_0707_07fd;
                    xgmii_txc    <= 8'hff;
                    packet_count <= packet_count + 1'b1;
                    state        <= TX_WAIT;
                end

                default: begin
                    state     <= TX_WAIT;
                    xgmii_txd <= XGMII_IDLES;
                    xgmii_txc <= 8'hff;
                end
            endcase
        end
    end
endmodule


module xgmii_packet_monitor (
    input  wire        clk,
    input  wire        reset,
    input  wire [63:0] xgmii_rxd,
    input  wire [7:0]  xgmii_rxc,
    input  wire        block_lock,
    output reg         in_frame,
    output reg         packet_seen,
    output reg         packet_error,
    output wire        packet_led,
    output reg  [31:0] packet_count
);
    // At 156.25 MHz this holds DS5 on for approximately 100 ms after every
    // completed frame, making even an isolated packet visible to the eye.
    localparam [23:0] PACKET_LED_HOLD = 24'd15_625_000;

    integer lane;
    reg start_seen_this_cycle;
    reg terminate_seen_this_cycle;
    reg [23:0] packet_led_counter;

    always @* begin
        start_seen_this_cycle = 1'b0;
        terminate_seen_this_cycle = 1'b0;
        for (lane = 0; lane < 8; lane = lane + 1) begin
            if (xgmii_rxc[lane] && xgmii_rxd[lane*8 +: 8] == 8'hfb)
                start_seen_this_cycle = 1'b1;     // XGMII /S/
            if (xgmii_rxc[lane] && xgmii_rxd[lane*8 +: 8] == 8'hfd)
                terminate_seen_this_cycle = 1'b1; // XGMII /T/
        end
    end

    assign packet_led = (packet_led_counter != 24'd0);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            in_frame          <= 1'b0;
            packet_seen       <= 1'b0;
            packet_error      <= 1'b0;
            packet_count      <= 32'd0;
            packet_led_counter <= 24'd0;
        end else if (!block_lock) begin
            in_frame <= 1'b0;
            if (packet_led_counter != 24'd0)
                packet_led_counter <= packet_led_counter - 1'b1;
        end else begin
            if (packet_led_counter != 24'd0)
                packet_led_counter <= packet_led_counter - 1'b1;

            if (start_seen_this_cycle) begin
                if (in_frame)
                    packet_error <= 1'b1;
                in_frame <= 1'b1;
            end

            if (terminate_seen_this_cycle) begin
                if (in_frame) begin
                    in_frame           <= 1'b0;
                    packet_seen        <= 1'b1;
                    packet_count       <= packet_count + 1'b1;
                    packet_led_counter <= PACKET_LED_HOLD;
                end else begin
                    packet_error <= 1'b1;
                end
            end
        end
    end
endmodule


module stable_clock_100 (
    input  wire clk_200_in,
    input  wire reset,
    output wire clk_100_out,
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
    ) mmcm (
        .CLKIN1(clk_200_in),
        .RST(reset),
        .PWRDWN(1'b0),
        .CLKFBIN(clkfb),
        .CLKFBOUT(clkfb_unbuffered),
        .CLKFBOUTB(),
        .CLKOUT0(clk_100_unbuffered),
        .CLKOUT0B(),
        .CLKOUT1(), .CLKOUT1B(), .CLKOUT2(), .CLKOUT2B(),
        .CLKOUT3(), .CLKOUT3B(), .CLKOUT4(), .CLKOUT5(), .CLKOUT6(),
        .LOCKED(locked)
    );

    BUFG feedback_buffer (.I(clkfb_unbuffered), .O(clkfb));
    BUFG output_buffer   (.I(clk_100_unbuffered), .O(clk_100_out));
endmodule

`default_nettype wire
