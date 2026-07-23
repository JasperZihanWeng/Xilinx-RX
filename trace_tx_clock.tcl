open_checkpoint {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/xilinx_rx.runs/impl_1/top_routed.dcp}
set out [open {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/tx_clock_trace.txt} w]
puts $out "CLOCKS"
foreach c [get_clocks] {
    puts $out "[get_property NAME $c] PERIOD=[get_property PERIOD $c]"
}
puts $out "TX_COUNT_CELLS"
foreach c [get_cells -hierarchical -filter {NAME =~ *tx_packet_count* || NAME =~ *packet_count_reg*}] {
    puts $out "[get_property NAME $c] REF=[get_property REF_NAME $c] LOC=[get_property LOC $c]"
    foreach p [get_pins -of_objects $c -filter {REF_PIN_NAME == C}] {
        puts $out "  CLOCK_PIN=[get_property NAME $p] NET=[get_property NAME [get_nets -of_objects $p]] CLOCK=[get_property NAME [get_clocks -of_objects $p]]"
    }
}
puts $out "CORECLK_NETS"
foreach n [get_nets -hierarchical -filter {NAME =~ *coreclk*}] {
    puts $out "[get_property NAME $n] DRIVER=[get_property NAME [get_pins -leaf -of_objects $n -filter {DIRECTION == OUT}]] LOADS=[llength [get_pins -leaf -of_objects $n -filter {DIRECTION == IN}]]"
}
close $out
exit
