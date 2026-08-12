module top (

    // SERDES quad reference clock pins. For LANE_ID=6 these are connected
    // to the generated MPCS Q1 refclk inputs below.
    input  wire sdq_refclkp_q0_i,
    input  wire sdq_refclkn_q0_i,

    // SFP 1, SERDES lane/channel 0
    input  wire sd0rxp_i,
    input  wire sd0rxn_i,
    output wire sd0txp_o,
    output wire sd0txn_o,
    input  wire sd0_rext_i,
    input  wire sd0_refret_i,

    // SFP 1 module control
    output wire sfp1_tx_disable_o,

    // Low-speed control clock/reset for MPCS/PMA control logic
    input  wire mpcs_clkin_i_0,
    input  wire resetn_i,

    // Bring-up status/debug. Board LEDs are active-high.
    output wire mpcs_ready_o_0, //LED 0
    output wire mpcs_phyrdy_o_0, //LED 1
    output wire mpcs_rxval_o_0, //LED 2
    output wire mpcs_get_lsync_o_0, //LED 3
    output wire mpcs_rx_out_clk_o_0, //LED 4, blinks when RX output clock is running
    output wire mpcs_tx_out_clk_o_0, //LED 5, blinks when TX output clock is running
	
	//switch input
	input wire switch1, 
    input wire switch2,

    //data output
    output reg debug_LED_6,
    output reg debug_LED_7
	
);

    // Reference clock ports
    wire        use_refmux_i;
    wire        diffioclksel_i;
    wire [1:0]  clksel_i;

    assign use_refmux_i    = 1'b0;  // Use the direct SERDES quad reference clock.
    assign diffioclksel_i  = 1'b0;  // Dynamic refclk mux is unused in this wrapper.
    assign clksel_i        = 2'b00; // Dynamic refclk mux is unused in this wrapper.

    // J12/F_SFP1 TX_DISABLE is active-high. Disable during reset, then enable.
    assign sfp1_tx_disable_o = ~resetn_i;

    // JTAG interface
    wire acjtag_mode_i;
    wire acjtag_enable_i_0;
    wire acjtag_acmode_i_0;
    wire acjtag_drive1_i_0;
    wire acjtag_highz_i_0;
    wire acjtagpout_o_0;
    wire acjtagnout_o_0;

    assign acjtag_mode_i      = 1'b0;
    assign acjtag_enable_i_0  = 1'b0;
    assign acjtag_acmode_i_0  = 1'b0;
    assign acjtag_drive1_i_0  = 1'b0;
    assign acjtag_highz_i_0   = 1'b0;

    // LMMI interface is idle because mpcs_1 is generated with fixed settings.
    wire       lmmi_clk_i_0;
    wire       lmmi_resetn_i_0;
    wire       lmmi_request_i_0;
    wire       lmmi_wr_rdn_i_0;
    wire [8:0] lmmi_offset_i_0;
    wire [7:0] lmmi_wdata_i_0;
    wire       lmmi_rdata_valid_o_0;
    wire       lmmi_ready_o_0;
    wire [7:0] lmmi_rdata_o_0;

    assign lmmi_clk_i_0      = mpcs_clkin_i_0;
    assign lmmi_resetn_i_0   = resetn_i;
    assign lmmi_request_i_0  = 1'b0;
    assign lmmi_wr_rdn_i_0   = 1'b0;
    assign lmmi_offset_i_0   = 9'd0;
    assign lmmi_wdata_i_0    = 8'd0;

    // Clock and reset. The PDF recommends releasing PCS resets after calibration/PHY ready.
    wire mpcs_rx_usr_clk_i_0;
    wire mpcs_tx_usr_clk_i_0;
    wire mpcs_rx_out_clk_int_0;
    wire mpcs_tx_out_clk_int_0;
    wire mpcs_tx_pcs_rstn_i_0;
    wire mpcs_rx_pcs_rstn_i_0;
    wire mpcs_perstn_i_0;
    wire mpcs_ready_int_0;
    wire mpcs_phyrdy_int_0;
    wire mpcs_rxval_int_0;
    wire mpcs_get_lsync_int_0;

    assign mpcs_rx_usr_clk_i_0    = mpcs_rx_out_clk_int_0;
    assign mpcs_tx_usr_clk_i_0    = mpcs_tx_out_clk_int_0;
    assign mpcs_perstn_i_0        = resetn_i;
    // Lattice's generated MPCS testbench releases TX PCS reset directly
    // from the external reset; mpcs_ready is status, not a reset qualifier.
    assign mpcs_tx_pcs_rstn_i_0   = resetn_i;
    assign mpcs_rx_pcs_rstn_i_0   = resetn_i & mpcs_phyrdy_int_0;

    // Keep the original output names for LED pins, but show slow clock-alive indicators.
    reg [25:0] mpcs_rx_clk_led_cnt;
    reg [25:0] mpcs_tx_clk_led_cnt;

    always @(posedge mpcs_rx_out_clk_int_0 or negedge resetn_i) begin
        if (!resetn_i)
            mpcs_rx_clk_led_cnt <= 26'd0;
        else if (!mpcs_phyrdy_int_0)
            mpcs_rx_clk_led_cnt <= 26'd0;
        else
            mpcs_rx_clk_led_cnt <= mpcs_rx_clk_led_cnt + 1'b1;
    end

    always @(posedge mpcs_tx_out_clk_int_0 or negedge resetn_i) begin
        if (!resetn_i)
            mpcs_tx_clk_led_cnt <= 26'd0;
        else if (!mpcs_ready_int_0)
            mpcs_tx_clk_led_cnt <= 26'd0;
        else
            mpcs_tx_clk_led_cnt <= mpcs_tx_clk_led_cnt + 1'b1;
    end

    assign mpcs_ready_o_0     = mpcs_ready_int_0;
    assign mpcs_phyrdy_o_0    = mpcs_phyrdy_int_0;
    assign mpcs_rxval_o_0     = mpcs_rxval_int_0;
    assign mpcs_get_lsync_o_0 = mpcs_get_lsync_int_0;
    assign mpcs_rx_out_clk_o_0 = mpcs_rx_clk_led_cnt[25];
    assign mpcs_tx_out_clk_o_0 = mpcs_tx_clk_led_cnt[25];

    // TX/RX FIFO signals.
    wire [79:0] mpcs_tx_ch_din_i_0;
    wire [3:0]  mpcs_tx_fifo_st_o_0;
    wire [79:0] mpcs_rx_ch_dout_o_0;
    wire [3:0]  mpcs_rx_fifo_st_o_0;

    localparam [7:0] XGMII_IDLE  = 8'h07;
    localparam [7:0] XGMII_START = 8'hFB;
    localparam [7:0] XGMII_TERM  = 8'hFD;

    localparam [3:0] TX_IDLE      = 4'd0;
    localparam [3:0] TX_START     = 4'd1;
    localparam [3:0] TX_DATA0     = 4'd2;
    localparam [3:0] TX_DATA1     = 4'd3;
    localparam [3:0] TX_DATA2     = 4'd4;
    localparam [3:0] TX_DATA3     = 4'd5;
    localparam [3:0] TX_DATA4     = 4'd6;
    localparam [3:0] TX_DATA5     = 4'd7;
    localparam [3:0] TX_DATA6     = 4'd8;
    localparam [3:0] TX_DATA7     = 4'd9;
    localparam [3:0] TX_TERMINATE = 4'd10;

    reg [3:0] tx_state;
    reg [15:0] tx_gap_count;
    reg [1:0] switch_meta;
    reg [1:0] switch_tx;
    reg [31:0] tx_sequence;
    reg [63:0] xgmii_txd_0;
    reg [7:0]  xgmii_txc_0;

    always @(posedge mpcs_tx_out_clk_int_0 or negedge resetn_i) begin
        if (!resetn_i) begin
            tx_state    <= TX_IDLE;
            tx_gap_count <= 16'hffff;
            switch_meta <= 2'b00;
            switch_tx   <= 2'b00;
            tx_sequence <= 32'd0;
            xgmii_txd_0 <= {8{XGMII_IDLE}};
            xgmii_txc_0 <= 8'hff;
            debug_LED_6 <= 1'b0;
            debug_LED_7 <= 1'b0;
        end
        else if (!mpcs_ready_int_0) begin
            tx_state    <= TX_IDLE;
            tx_gap_count <= 16'hffff;
            xgmii_txd_0 <= {8{XGMII_IDLE}};
            xgmii_txc_0 <= 8'hff;
            debug_LED_6 <= 1'b0;
            debug_LED_7 <= 1'b0;
        end
        else begin
            switch_meta <= {switch1, switch2};
            switch_tx   <= switch_meta;

            case (tx_state)
                TX_IDLE: begin
                    xgmii_txd_0 <= {8{XGMII_IDLE}};
                    xgmii_txc_0 <= 8'hff;
                    debug_LED_6 <= switch_tx[1];
                    debug_LED_7 <= switch_tx[0];

                    if (tx_gap_count == 16'd0)
                        tx_state <= TX_START;
                    else
                        tx_gap_count <= tx_gap_count - 1'b1;
                end

                TX_START: begin
                    // /S/ on lane 0, six preamble bytes, then the SFD.
                    xgmii_txd_0 <= {8'hd5, {6{8'h55}}, XGMII_START};
                    xgmii_txc_0 <= 8'b0000_0001;
                    tx_state    <= TX_DATA0;
                end

                TX_DATA0: begin
                    xgmii_txd_0 <= 64'h0200_0000_0002_0200;
                    xgmii_txc_0 <= 8'h00;
                    tx_state    <= TX_DATA1;
                end

                TX_DATA1: begin
                    xgmii_txd_0 <= {16'hcafe, tx_sequence, 14'h0, switch_tx};
                    xgmii_txc_0 <= 8'h00;
                    tx_state    <= TX_DATA2;
                end

                TX_DATA2: begin
                    xgmii_txd_0 <= 64'h4c41_5454_4943_4554;
                    xgmii_txc_0 <= 8'h00;
                    tx_state    <= TX_DATA3;
                end

                TX_DATA3: begin
                    xgmii_txd_0 <= 64'h585f_544f_5f56_4337;
                    xgmii_txc_0 <= 8'h00;
                    tx_state    <= TX_DATA4;
                end

                TX_DATA4: begin
                    xgmii_txd_0 <= 64'h3039_5f52_585f_5445;
                    xgmii_txc_0 <= 8'h00;
                    tx_state    <= TX_DATA5;
                end

                TX_DATA5: begin
                    xgmii_txd_0 <= 64'h5354_5f46_5241_4d45;
                    xgmii_txc_0 <= 8'h00;
                    tx_state    <= TX_DATA6;
                end

                TX_DATA6: begin
                    xgmii_txd_0 <= 64'h1122_3344_5566_7788;
                    xgmii_txc_0 <= 8'h00;
                    tx_state    <= TX_DATA7;
                end

                TX_DATA7: begin
                    xgmii_txd_0 <= 64'h99aa_bbcc_ddee_ff00;
                    xgmii_txc_0 <= 8'h00;
                    tx_state    <= TX_TERMINATE;
                end

                TX_TERMINATE: begin
                    xgmii_txd_0  <= {{7{XGMII_IDLE}}, XGMII_TERM};
                    xgmii_txc_0  <= 8'hff;
                    tx_sequence  <= tx_sequence + 1'b1;
                    tx_gap_count <= 16'hffff;
                    tx_state     <= TX_IDLE;
                end

                default: begin
                    tx_state    <= TX_IDLE;
                    xgmii_txd_0 <= {8{XGMII_IDLE}};
                    xgmii_txc_0 <= 8'hff;
                end
            endcase
        end
    end

    // 10GE MPCS input format:
    // [79]    TX FIFO write enable
    // [78:73] Reserved
    // [72]    Force packet bypass. Keep low for normal encoder/scrambler use.
    // [71:64] XGMII control bits, one per byte lane
    // [63:0]  XGMII data bytes. Lane 0 is bits [7:0].
    assign mpcs_tx_ch_din_i_0 = {1'b1, 6'b0, 1'b0, xgmii_txc_0, xgmii_txd_0};

    // Elastic buffer signals
    wire mpcs_ebuf_empty_o_0;
    wire mpcs_ebuf_full_o_0;

    // Word aligner / lane deskew signals
    wire mpcs_anxmit_i_0;
    wire mpcs_walign_en_i_0;
    wire mpcs_rx_get_lalign_o_0;
    wire mpcs_rx_deskew_en_i_0;

    assign mpcs_anxmit_i_0       = 1'b0;
    assign mpcs_walign_en_i_0    = 1'b0;
    assign mpcs_rx_deskew_en_i_0 = 1'b0;

    // PMA control and status signals
    wire [1:0] mpcs_pwrdn_i_0;
    wire       mpcs_txhiz_i_0;
    wire       mpcs_rxidle_o_0;
    wire       mpcs_rxerr_i_0;
    wire       mpcs_fomreq_i_0;
    wire       mpcs_fomack_o_0;
    wire [7:0] mpcs_fomrslt_o_0;
    wire [1:0] mpcs_speed_o_0;
    wire       mpcs_txval_i_0;
    wire       mpcs_rxoob_i_0;
    wire       mpcs_txdeemp_i_0;
    wire [1:0] mpcs_pwrst_o_0;
    wire       mpcs_skipbit_i_0;

    assign mpcs_pwrdn_i_0   = 2'b00;
    assign mpcs_txhiz_i_0   = 1'b0;
    assign mpcs_rxerr_i_0   = 1'b0;
    assign mpcs_fomreq_i_0  = 1'b0;
    // The generated MPCS testbench holds TXVAL asserted in normal operation.
    assign mpcs_txval_i_0   = 1'b1;
    assign mpcs_rxoob_i_0   = 1'b0;
    assign mpcs_txdeemp_i_0 = 1'b0;
    assign mpcs_skipbit_i_0 = 1'b0;

    mpcs_1 mpcs_ex (

        // Reference clock ports
        .use_refmux_i(use_refmux_i),
        .diffioclksel_i(diffioclksel_i),
        .clksel_i(clksel_i),
        .sd_ext_0_refclk_i(1'b0),
        .sd_ext_1_refclk_i(1'b0),
        .pll_0_refclk_i(1'b0),
        .pll_1_refclk_i(1'b0),
        .sd_pll_refclk_i(1'b0),

        // Serial I/O
        .sdq_refclkp_q0_i(1'b0),
        .sdq_refclkn_q0_i(1'b0),
        .sdq_refclkp_q1_i(sdq_refclkp_q0_i),
        .sdq_refclkn_q1_i(sdq_refclkn_q0_i),
        .sd0rxp_i(sd0rxp_i),
        .sd0rxn_i(sd0rxn_i),
        .sd0txp_o(sd0txp_o),
        .sd0txn_o(sd0txn_o),
        .sd0_rext_i(sd0_rext_i),
        .sd0_refret_i(sd0_refret_i),

        // JTAG interface
        .acjtag_mode_i(acjtag_mode_i),
        .acjtag_enable_i_0(acjtag_enable_i_0),
        .acjtag_acmode_i_0(acjtag_acmode_i_0),
        .acjtag_drive1_i_0(acjtag_drive1_i_0),
        .acjtag_highz_i_0(acjtag_highz_i_0),
        .acjtagpout_o_0(acjtagpout_o_0),
        .acjtagnout_o_0(acjtagnout_o_0),

        // LMMI interface
        .lmmi_clk_i_0(lmmi_clk_i_0),
        .lmmi_resetn_i_0(lmmi_resetn_i_0),
        .lmmi_request_i_0(lmmi_request_i_0),
        .lmmi_wr_rdn_i_0(lmmi_wr_rdn_i_0),
        .lmmi_offset_i_0(lmmi_offset_i_0),
        .lmmi_wdata_i_0(lmmi_wdata_i_0),
        .lmmi_rdata_valid_o_0(lmmi_rdata_valid_o_0),
        .lmmi_ready_o_0(lmmi_ready_o_0),
        .lmmi_rdata_o_0(lmmi_rdata_o_0),

        // Clock and reset
        .mpcs_rx_usr_clk_i_0(mpcs_rx_usr_clk_i_0),
        .mpcs_tx_usr_clk_i_0(mpcs_tx_usr_clk_i_0),
        .mpcs_tx_pcs_rstn_i_0(mpcs_tx_pcs_rstn_i_0),
        .mpcs_rx_pcs_rstn_i_0(mpcs_rx_pcs_rstn_i_0),
        .mpcs_rx_out_clk_o_0(mpcs_rx_out_clk_int_0),
        .mpcs_tx_out_clk_o_0(mpcs_tx_out_clk_int_0),
        .mpcs_perstn_i_0(mpcs_perstn_i_0),

        // TX/RX FIFO signals
        .mpcs_tx_ch_din_i_0(mpcs_tx_ch_din_i_0),
        .mpcs_tx_fifo_st_o_0(mpcs_tx_fifo_st_o_0),
        .mpcs_rx_ch_dout_o_0(mpcs_rx_ch_dout_o_0),
        .mpcs_rx_fifo_st_o_0(mpcs_rx_fifo_st_o_0),

        // Elastic buffer signals
        .mpcs_ebuf_empty_o_0(mpcs_ebuf_empty_o_0),
        .mpcs_ebuf_full_o_0(mpcs_ebuf_full_o_0),

        // Word aligner signals
        .mpcs_anxmit_i_0(mpcs_anxmit_i_0),
        .mpcs_walign_en_i_0(mpcs_walign_en_i_0),
        .mpcs_get_lsync_o_0(mpcs_get_lsync_int_0),

        // Lane-to-lane deskew signals
        .mpcs_rx_get_lalign_o_0(mpcs_rx_get_lalign_o_0),
        .mpcs_rx_deskew_en_i_0(mpcs_rx_deskew_en_i_0),

        // PMA control and status signals
        .mpcs_clkin_i_0(mpcs_clkin_i_0),
        .mpcs_pwrdn_i_0(mpcs_pwrdn_i_0),
        .mpcs_txhiz_i_0(mpcs_txhiz_i_0),
        .mpcs_rxidle_o_0(mpcs_rxidle_o_0),
        .mpcs_rxerr_i_0(mpcs_rxerr_i_0),
        .mpcs_fomreq_i_0(mpcs_fomreq_i_0),
        .mpcs_fomack_o_0(mpcs_fomack_o_0),
        .mpcs_fomrslt_o_0(mpcs_fomrslt_o_0),
        .mpcs_speed_o_0(mpcs_speed_o_0),
        .mpcs_txval_i_0(mpcs_txval_i_0),
        .mpcs_phyrdy_o_0(mpcs_phyrdy_int_0),
        .mpcs_ready_o_0(mpcs_ready_int_0),
        .mpcs_rxoob_i_0(mpcs_rxoob_i_0),
        .mpcs_txdeemp_i_0(mpcs_txdeemp_i_0),
        .mpcs_pwrst_o_0(mpcs_pwrst_o_0),
        .mpcs_skipbit_i_0(mpcs_skipbit_i_0),
        .mpcs_rxval_o_0(mpcs_rxval_int_0)
    );

endmodule
