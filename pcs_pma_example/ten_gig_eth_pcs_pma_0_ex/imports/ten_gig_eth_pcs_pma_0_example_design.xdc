## (c) Copyright 2009 - 2014 Advanced Micro Devices, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Advanced Micro Devices, Inc. and is protected under U.S. and 
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Advanced Micro Devices, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Advanced Micro Devices shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Advanced Micro Devices had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Advanced Micro Devices products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Advanced Micro Devices products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.

create_clock -period 10.000 [get_ports {dclk}]


create_generated_clock -name ddrclock -divide_by 1 -invert -source [get_pins *rx_clk_ddr/C] [get_ports xgmii_rx_clk]
set_output_delay -max 0.750 -clock [get_clocks ddrclock] [get_ports * -filter {NAME =~ *xgmii_rxd*}]
set_output_delay -min -0.700 -clock [get_clocks ddrclock] [get_ports * -filter {NAME =~ *xgmii_rxd*}]
set_output_delay -max 0.750 -clock [get_clocks ddrclock] [get_ports * -filter {NAME =~ *xgmii_rxc*}]
set_output_delay -min -0.700 -clock [get_clocks ddrclock] [get_ports * -filter {NAME =~ *xgmii_rxc*}]


## Sample constraint for GT location
#set_property LOC GTHE2_CHANNEL_X1Y21 [get_cells ten_gig_eth_pcs_pma_core_i/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gth_10gbaser_i/gthe2_i]
#set_property LOC GTHE2_COMMON_X1Y5 [get_cells ten_gig_eth_pcs_pma_core_i/inst/ten_gig_eth_pcs_pma_gt_common_block/gthe2_common_0_i]

set_property IOSTANDARD HSTL_I [get_ports {xgmii_txc[*]}]
set_property IOSTANDARD HSTL_I [get_ports {xgmii_txd[*]}]

set_property IOSTANDARD HSTL_I [get_ports {xgmii_rxc[*]}]
set_property IOSTANDARD HSTL_I [get_ports {xgmii_rxd[*]}]

set_property IOB TRUE [get_cells {xgmii_rxc_reg[*]}]
set_property IOB TRUE [get_cells {xgmii_rxd_reg[*]}]

set_property IOSTANDARD HSTL_I [get_ports xgmii_rx_clk]



 
create_waiver -quiet -type CDC -id {CDC-10} -user "ten_gig_eth_pcs_pma" -tags "11999" -desc "Control register o/p expected to be static during MAC operations and thus a false path for all practical purposes and thus can be ignored."\
-from [get_pins -of [get_cells -hier -filter {name =~ */*clk*sync_i/data_out_reg*}] -filter {name =~ *C}]\
-to [get_pins -of [get_cells -hier -filter {name =~ */coreclk_rxusrclk2_resets_resyncs_i/resynch[*].synch_inst/d1_reg*}] -filter {name =~ *D}]

