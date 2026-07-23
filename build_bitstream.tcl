open_project xilinx_rx.xpr

set xdc_file {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/xilinx_rx.srcs/constrs_1/new/vc709.xdc}
if {[llength [get_files -quiet [list $xdc_file]]] == 0} {
    add_files -fileset constrs_1 [list $xdc_file]
}
set_property used_in_synthesis true [get_files [list $xdc_file]]
set_property used_in_implementation true [get_files [list $xdc_file]]

reset_run synth_1
launch_runs synth_1 -jobs 16
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] ne "synth_design Complete!"} {
    error "Synthesis did not complete: [get_property STATUS [get_runs synth_1]]"
}

reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 16
wait_on_run impl_1

set run_status [get_property STATUS [get_runs impl_1]]
puts "FINAL_IMPL_STATUS=$run_status"
if {$run_status ne "write_bitstream Complete!"} {
    error "Implementation/bitstream run did not complete: $run_status"
}

open_run impl_1
report_timing_summary -file final_timing_summary.rpt
report_drc -file final_drc.rpt
close_project
exit
