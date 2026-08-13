set repo_dir {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx}
set ref_dir  {C:/Users/Kumar Lab/Desktop/Jasper/CPCC_QWN/clock_test_ex.srcs/sources_1}
set build_dir [file join $repo_dir qwn_raw_rx_build]

create_project qwn_raw_rx $build_dir -part xc7vx690tffg1761-2 -force
set_property target_language Verilog [current_project]

add_files [glob [file join $repo_dir source *.v]]
add_files [list [file join $ref_dir new rx_oversample_cdr_64.v]]
add_files [list [file join $ref_dir new dec_8b10b.v]]
add_files [list [file join $ref_dir imports example_design support clock_test_common.v]]
read_ip [list [file join $repo_dir ip qwn_gt_raw qwn_gt_raw.xci]]
add_files -fileset constrs_1 [list [file join $repo_dir constraints qwn_raw_rx_vc709.xdc]]

set_property top qwn_raw_rx_top [current_fileset]
update_compile_order -fileset sources_1
generate_target all [get_ips qwn_gt_raw]

launch_runs synth_1 -jobs 8
wait_on_run synth_1
if {![string match "synth_design Complete*" [get_property STATUS [get_runs synth_1]]]} {
    error "Synthesis failed: [get_property STATUS [get_runs synth_1]]"
}

open_run synth_1
report_drc -file [file join $repo_dir qwn_raw_rx_synth_drc.rpt]
close_design

launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
if {![string match "write_bitstream Complete*" [get_property STATUS [get_runs impl_1]]]} {
    error "Implementation failed: [get_property STATUS [get_runs impl_1]]"
}

open_run impl_1
report_timing_summary -file [file join $repo_dir qwn_raw_rx_timing.rpt]
report_drc -file [file join $repo_dir qwn_raw_rx_drc.rpt]
write_bitstream -force [file join $repo_dir qwn_raw_rx.bit]
close_project
exit
