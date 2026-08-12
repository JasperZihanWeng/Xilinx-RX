set workspace_dir {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx}
set build_dir "$workspace_dir/vc709_pma_selftest_build"

set_param general.maxThreads 1
create_project vc709_pma_selftest $build_dir -part xc7vx690tffg1761-2 -force
add_files [list "$workspace_dir/xilinx_rx.srcs/sources_1/new/top.v"]
add_files [list "$workspace_dir/xilinx_rx.srcs/sources_1/ip/ten_gig_eth_pcs_pma_0/ten_gig_eth_pcs_pma_0.xci"]
add_files -fileset constrs_1 [list "$workspace_dir/xilinx_rx.srcs/constrs_1/new/vc709.xdc"]

set_property top top [current_fileset]
set_property generic {PCS_LOOPBACK_TEST=0 PMA_LOOPBACK_TEST=1} [current_fileset]
update_compile_order -fileset sources_1

synth_design -top top -part xc7vx690tffg1761-2
write_checkpoint -force "$build_dir/vc709_pma_selftest_synth.dcp"
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force "$build_dir/vc709_pma_selftest_routed.dcp"

report_timing_summary -file "$workspace_dir/vc709_pma_selftest_timing.rpt"
report_drc -file "$workspace_dir/vc709_pma_selftest_drc.rpt"
write_bitstream -force "$workspace_dir/vc709_pma_selftest.bit"
close_project
exit
