open_checkpoint {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/vc709_pcs_selftest_direct_build/vc709_pcs_selftest_routed.dcp}

set report_path {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx/vc709_pcs_selftest_inspection.txt}
set fp [open $report_path w]

puts $fp "SELF-TEST CELLS"
foreach c [get_cells -hierarchical -filter {NAME =~ *selftest*}] {
    puts $fp $c
}

puts $fp "\nPACKET MONITOR CELLS"
foreach c [get_cells -hierarchical -filter {NAME =~ *packet_monitor*}] {
    puts $fp $c
}

puts $fp "\nCORE CLOCK NET"
foreach n [get_nets -hierarchical -filter {NAME =~ *coreclk*}] {
    puts $fp "$n loads=[llength [get_pins -quiet -of_objects $n -filter {DIRECTION == IN}]]"
}

puts $fp "\nLED DRIVERS"
foreach p [get_ports {gpio_led[*]}] {
    set n [get_nets -quiet -of_objects $p]
    puts $fp "$p net=$n driver=[get_pins -quiet -leaf -of_objects $n -filter {DIRECTION == OUT}]"
}

puts $fp "\nCLOCKS"
foreach c [get_clocks] {
    puts $fp "$c period=[get_property PERIOD $c]"
}

close $fp
close_project
exit
