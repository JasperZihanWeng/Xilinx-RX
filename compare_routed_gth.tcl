proc dump_design {dcp tag} {
    open_checkpoint $dcp
    set out [open "gth_compare_${tag}.txt" w]
    puts $out "DESIGN=$tag"
    foreach c [get_cells -hierarchical -filter {REF_NAME == GTHE2_CHANNEL && LOC == GTHE2_CHANNEL_X1Y12}] {
        puts $out "CHANNEL=[get_property NAME $c] LOC=[get_property LOC $c]"
        report_property -file "gth_${tag}_channel.txt" $c
    }
    foreach c [get_cells -hierarchical -filter {REF_NAME == GTHE2_COMMON}] {
        puts $out "COMMON=[get_property NAME $c] LOC=[get_property LOC $c]"
        report_property -file "gth_${tag}_common.txt" $c
    }
    close $out
    close_design
}

dump_design {C:/Users/Kumar Lab/Desktop/Jasper/clock_test_ex/clock_test_ex.runs/impl_1/clock_test_exdes_routed.dcp} clock_test
dump_design {C:/Users/Kumar Lab/Desktop/Gamze/QWN_FPGA_4SFP_1G/gth_sfp_ex.runs/impl_1/gth_sfp_exdes_routed.dcp} qwn
dump_design {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/xilinx_rx.runs/impl_1/top_routed.dcp} xilinx_rx
exit
