`timescale 1ns/1ps
`default_nettype none

module qwn_raw_rx_top (
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
    input  wire sfp1_tx_fault,
    input  wire sfp1_mod_abs,
    input  wire sfp1_los,
    output wire sfp1_tx_disable,
    output wire sfp1_rs0,
    output wire sfp1_rs1,
    output wire [7:0] gpio_led
);
    wire reset_button = cpu_reset_n; // VC709 SW8 is high while pressed.
    wire sysclk_200;
    wire stable_clk;
    wire stable_locked;
    wire si570_clock;
    wire gt_refclk;

    IBUFDS sysclk_input (.I(sysclk_p), .IB(sysclk_n), .O(sysclk_200));
    qwn_stable_clock stable_clock_i (
        .clk_200(sysclk_200), .reset(reset_button),
        .clk_100(stable_clk), .locked(stable_locked)
    );

    // Preserve the proven VC709 clock cabling: Si570 -> J31/J32 -> J25/J26.
    IBUFDS si570_input (.I(user_clock_p), .IB(user_clock_n), .O(si570_clock));
    OBUFDS si570_output (.I(si570_clock), .O(ref_clk_sma_p), .OB(ref_clk_sma_n));
    IBUFDS_GTE2 gt_refclk_input (
        .I(gt_refclk_p), .IB(gt_refclk_n), .CEB(1'b0),
        .O(gt_refclk), .ODIV2()
    );

    assign sfp1_tx_disable = 1'b1; // This checkpoint is intentionally RX-only.
    assign sfp1_rs0 = 1'b1;
    assign sfp1_rs1 = 1'b0;

    wire qpll_lock;
    wire qpll_refclk_lost;
    wire qpll_outclk;
    wire qpll_outrefclk;
    wire qpll_reset;

    // This generated common block is taken directly from clock_test_ex.  Its
    // QPLL x64 setting converts the 156.25-MHz reference to the 10-Gb/s rate.
    clock_test_common #(
        .WRAPPER_SIM_GTRESET_SPEEDUP("TRUE"),
        .SIM_QPLLREFCLK_SEL(3'b010)
    ) qpll_i (
        .DRPADDR_COMMON_IN(8'd0), .DRPCLK_COMMON_IN(stable_clk),
        .DRPDI_COMMON_IN(16'd0), .DRPDO_COMMON_OUT(),
        .DRPEN_COMMON_IN(1'b0), .DRPRDY_COMMON_OUT(), .DRPWE_COMMON_IN(1'b0),
        .GTGREFCLK_IN(1'b0), .GTNORTHREFCLK0_IN(1'b0),
        .GTNORTHREFCLK1_IN(1'b0), .GTSOUTHREFCLK0_IN(1'b0),
        .GTSOUTHREFCLK1_IN(1'b0), .QPLLREFCLKSEL_IN(3'b010),
        .GTREFCLK0_IN(1'b0), .GTREFCLK1_IN(gt_refclk),
        .QPLLLOCK_OUT(qpll_lock), .QPLLLOCKDETCLK_IN(stable_clk),
        .QPLLOUTCLK_OUT(qpll_outclk), .QPLLOUTREFCLK_OUT(qpll_outrefclk),
        .QPLLREFCLKLOST_OUT(qpll_refclk_lost), .QPLLRESET_IN(qpll_reset)
    );

    wire rxoutclk;
    wire rxusrclk;
    wire rxusrclk2;
    wire rx_mmcm_lock;
    wire rx_mmcm_reset;
    qwn_rx_clocking rx_clock_i (
        .rxoutclk(rxoutclk), .reset(rx_mmcm_reset),
        .rxusrclk(rxusrclk), .rxusrclk2(rxusrclk2), .locked(rx_mmcm_lock)
    );

    wire [63:0] raw_samples;
    wire rx_fsm_done;
    wire rx_reset_done;
    wire unused_tx_fsm_done;
    qwn_gt_raw raw_gt_i (
        .sysclk_in(stable_clk),
        .soft_reset_rx_in(reset_button | ~stable_locked),
        .dont_reset_on_data_error_in(1'b1),
        .gt0_tx_fsm_reset_done_out(unused_tx_fsm_done),
        .gt0_rx_fsm_reset_done_out(rx_fsm_done),
        .gt0_data_valid_in(1'b1),
        .gt0_rx_mmcm_lock_in(rx_mmcm_lock),
        .gt0_rx_mmcm_reset_out(rx_mmcm_reset),
        .gt0_drpaddr_in(9'd0), .gt0_drpclk_in(stable_clk),
        .gt0_drpdi_in(16'd0), .gt0_drpdo_out(),
        .gt0_drpen_in(1'b0), .gt0_drprdy_out(), .gt0_drpwe_in(1'b0),
        .gt0_rxsysclksel_in(2'b11), .gt0_loopback_in(3'b000),
        .gt0_eyescanreset_in(1'b0), .gt0_rxuserrdy_in(1'b1),
        .gt0_eyescandataerror_out(), .gt0_eyescantrigger_in(1'b0),
        .gt0_rxcdrhold_in(1'b0), .gt0_rxslide_in(1'b0),
        .gt0_dmonitorout_out(),
        .gt0_rxusrclk_in(rxusrclk), .gt0_rxusrclk2_in(rxusrclk2),
        .gt0_rxdata_out(raw_samples),
        .gt0_gthrxn_in(sfp_rx_n), .gt0_gthrxp_in(sfp_rx_p),
        .gt0_rxphmonitor_out(), .gt0_rxphslipmonitor_out(),
        .gt0_rxbyteisaligned_out(), .gt0_rxbyterealign_out(),
        .gt0_rxcommadet_out(), .gt0_rxmonitorout_out(),
        .gt0_rxmonitorsel_in(2'b00), .gt0_rxoutclk_out(rxoutclk),
        .gt0_rxoutclkfabric_out(), .gt0_gtrxreset_in(1'b0),
        .gt0_rxresetdone_out(rx_reset_done), .gt0_gttxreset_in(1'b0),
        .gt0_qplllock_in(qpll_lock),
        .gt0_qpllrefclklost_in(qpll_refclk_lost),
        .gt0_qpllreset_out(qpll_reset),
        .gt0_qplloutclk_in(qpll_outclk),
        .gt0_qplloutrefclk_in(qpll_outrefclk)
    );

    // Bring the GT reset result safely into the recovered-clock domain.
    (* ASYNC_REG = "TRUE" *) reg [1:0] rx_ready_sync = 2'b00;
    always @(posedge rxusrclk2)
        rx_ready_sync <= {rx_ready_sync[0], rx_fsm_done & rx_reset_done};
    wire datapath_reset = ~rx_ready_sync[1];

    wire [7:0] recovered_bits;
    wire [3:0] recovered_count;
    wire [3:0] recovered_phase;
    rx_oversample_cdr_64 #(.OS(8)) fabric_cdr_i (
        .clk(rxusrclk2), .rst(datapath_reset), .word_i(raw_samples),
        .rbits_o(recovered_bits), .rcnt_o(recovered_count),
        .reph_o(recovered_phase)
    );

    wire [7:0] decoded_byte;
    wire decoded_k;
    wire decoded_valid;
    wire decoded_error;
    wire comma_locked;
    wire k285_healthy;
    qwn_symbol_decoder symbol_decoder_i (
        .clk(rxusrclk2), .rst(datapath_reset),
        .recovered_bits(recovered_bits), .recovered_count(recovered_count),
        .byte_o(decoded_byte), .k_o(decoded_k),
        .byte_valid(decoded_valid), .code_err(decoded_error),
        .comma_locked(comma_locked), .k285_healthy(k285_healthy)
    );

    reg [25:0] rx_heartbeat = 26'd0;
    always @(posedge rxusrclk2)
        if (datapath_reset) rx_heartbeat <= 26'd0;
        else rx_heartbeat <= rx_heartbeat + 1'b1;

    // DS2..DS9 are active-high. The physical-link indicators are unchanged;
    // LEDs 6/7 now prove symbol alignment and actual 8b/10b decoding.
    assign gpio_led[0] = stable_locked;
    assign gpio_led[1] = qpll_lock;
    assign gpio_led[2] = rx_fsm_done & rx_reset_done;
    assign gpio_led[3] = rx_heartbeat[25];
    assign gpio_led[4] = ~sfp1_mod_abs;
    assign gpio_led[5] = ~sfp1_los;
    assign gpio_led[6] = comma_locked;
    assign gpio_led[7] = k285_healthy;

    wire _unused = &{1'b0, sfp1_tx_fault, recovered_phase,
                     decoded_byte, decoded_k, decoded_valid, decoded_error};
endmodule

`default_nettype wire
