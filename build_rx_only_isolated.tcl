set build_dir {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/rx_only_build}
create_project rx_only_build $build_dir -part xc7vx690tffg1761-2 -force
add_files [list {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/xilinx_rx.srcs/sources_1/new/top.v}]
add_files [list {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/xilinx_rx.srcs/sources_1/ip/ten_gig_eth_pcs_pma_0/ten_gig_eth_pcs_pma_0.xci}]
add_files -fileset constrs_1 [list {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/xilinx_rx.srcs/constrs_1/new/vc709.xdc}]
set_property top top [current_fileset]
update_compile_order -fileset sources_1

launch_runs synth_1 -jobs 16
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] ne "synth_design Complete!"} {
    error "RX-only synthesis failed: [get_property STATUS [get_runs synth_1]]"
}

launch_runs impl_1 -to_step write_bitstream -jobs 16
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] ne "write_bitstream Complete!"} {
    error "RX-only implementation failed: [get_property STATUS [get_runs impl_1]]"
}

open_run impl_1
report_timing_summary -file {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/rx_only_timing_summary.rpt}
report_drc -file {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/rx_only_drc.rpt}
file copy -force "$build_dir/rx_only_build.runs/impl_1/top.bit" {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/rx_only_top.bit}
close_project
exit
