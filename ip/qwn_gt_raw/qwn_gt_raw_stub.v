// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Thu Aug 13 11:52:27 2026
// Host        : ECE-OP7010PC2 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {c:/Users/Kumar
//               Lab/Desktop/Jasper/xilinx_rx/ip/qwn_gt_raw/qwn_gt_raw_stub.v}
// Design      : qwn_gt_raw
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "qwn_gt_raw,gtwizard_v3_6_15,{protocol_file=Start_from_scratch}" *)
module qwn_gt_raw(sysclk_in, soft_reset_rx_in, 
  dont_reset_on_data_error_in, gt0_tx_fsm_reset_done_out, gt0_rx_fsm_reset_done_out, 
  gt0_data_valid_in, gt0_rx_mmcm_lock_in, gt0_rx_mmcm_reset_out, gt0_drpaddr_in, 
  gt0_drpclk_in, gt0_drpdi_in, gt0_drpdo_out, gt0_drpen_in, gt0_drprdy_out, gt0_drpwe_in, 
  gt0_rxsysclksel_in, gt0_loopback_in, gt0_eyescanreset_in, gt0_rxuserrdy_in, 
  gt0_eyescandataerror_out, gt0_eyescantrigger_in, gt0_rxcdrhold_in, gt0_rxslide_in, 
  gt0_dmonitorout_out, gt0_rxusrclk_in, gt0_rxusrclk2_in, gt0_rxdata_out, gt0_gthrxn_in, 
  gt0_rxphmonitor_out, gt0_rxphslipmonitor_out, gt0_rxbyteisaligned_out, 
  gt0_rxbyterealign_out, gt0_rxcommadet_out, gt0_rxmonitorout_out, gt0_rxmonitorsel_in, 
  gt0_rxoutclk_out, gt0_rxoutclkfabric_out, gt0_gtrxreset_in, gt0_gthrxp_in, 
  gt0_rxresetdone_out, gt0_gttxreset_in, gt0_qplllock_in, gt0_qpllrefclklost_in, 
  gt0_qpllreset_out, gt0_qplloutclk_in, gt0_qplloutrefclk_in)
/* synthesis syn_black_box black_box_pad_pin="soft_reset_rx_in,dont_reset_on_data_error_in,gt0_tx_fsm_reset_done_out,gt0_rx_fsm_reset_done_out,gt0_data_valid_in,gt0_rx_mmcm_lock_in,gt0_rx_mmcm_reset_out,gt0_drpaddr_in[8:0],gt0_drpdi_in[15:0],gt0_drpdo_out[15:0],gt0_drpen_in,gt0_drprdy_out,gt0_drpwe_in,gt0_rxsysclksel_in[1:0],gt0_loopback_in[2:0],gt0_eyescanreset_in,gt0_rxuserrdy_in,gt0_eyescandataerror_out,gt0_eyescantrigger_in,gt0_rxcdrhold_in,gt0_rxslide_in,gt0_dmonitorout_out[14:0],gt0_rxdata_out[63:0],gt0_gthrxn_in,gt0_rxphmonitor_out[4:0],gt0_rxphslipmonitor_out[4:0],gt0_rxbyteisaligned_out,gt0_rxbyterealign_out,gt0_rxcommadet_out,gt0_rxmonitorout_out[6:0],gt0_rxmonitorsel_in[1:0],gt0_rxoutclk_out,gt0_rxoutclkfabric_out,gt0_gtrxreset_in,gt0_gthrxp_in,gt0_rxresetdone_out,gt0_gttxreset_in,gt0_qplllock_in,gt0_qpllrefclklost_in,gt0_qpllreset_out,gt0_qplloutrefclk_in" */
/* synthesis syn_force_seq_prim="sysclk_in" */
/* synthesis syn_force_seq_prim="gt0_drpclk_in" */
/* synthesis syn_force_seq_prim="gt0_rxusrclk_in" */
/* synthesis syn_force_seq_prim="gt0_rxusrclk2_in" */
/* synthesis syn_force_seq_prim="gt0_qplloutclk_in" */;
  input sysclk_in /* synthesis syn_isclock = 1 */;
  input soft_reset_rx_in;
  input dont_reset_on_data_error_in;
  output gt0_tx_fsm_reset_done_out;
  output gt0_rx_fsm_reset_done_out;
  input gt0_data_valid_in;
  input gt0_rx_mmcm_lock_in;
  output gt0_rx_mmcm_reset_out;
  input [8:0]gt0_drpaddr_in;
  input gt0_drpclk_in /* synthesis syn_isclock = 1 */;
  input [15:0]gt0_drpdi_in;
  output [15:0]gt0_drpdo_out;
  input gt0_drpen_in;
  output gt0_drprdy_out;
  input gt0_drpwe_in;
  input [1:0]gt0_rxsysclksel_in;
  input [2:0]gt0_loopback_in;
  input gt0_eyescanreset_in;
  input gt0_rxuserrdy_in;
  output gt0_eyescandataerror_out;
  input gt0_eyescantrigger_in;
  input gt0_rxcdrhold_in;
  input gt0_rxslide_in;
  output [14:0]gt0_dmonitorout_out;
  input gt0_rxusrclk_in /* synthesis syn_isclock = 1 */;
  input gt0_rxusrclk2_in /* synthesis syn_isclock = 1 */;
  output [63:0]gt0_rxdata_out;
  input gt0_gthrxn_in;
  output [4:0]gt0_rxphmonitor_out;
  output [4:0]gt0_rxphslipmonitor_out;
  output gt0_rxbyteisaligned_out;
  output gt0_rxbyterealign_out;
  output gt0_rxcommadet_out;
  output [6:0]gt0_rxmonitorout_out;
  input [1:0]gt0_rxmonitorsel_in;
  output gt0_rxoutclk_out;
  output gt0_rxoutclkfabric_out;
  input gt0_gtrxreset_in;
  input gt0_gthrxp_in;
  output gt0_rxresetdone_out;
  input gt0_gttxreset_in;
  input gt0_qplllock_in;
  input gt0_qpllrefclklost_in;
  output gt0_qpllreset_out;
  input gt0_qplloutclk_in /* synthesis syn_isclock = 1 */;
  input gt0_qplloutrefclk_in;
endmodule
