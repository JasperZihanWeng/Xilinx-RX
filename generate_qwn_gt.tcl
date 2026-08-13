# Generate a one-lane raw GTH receiver using the proven clock_test_ex settings.
# The reference IP remains read-only; this script clones only its GT0 channel
# profile and enables the VC709 SFP1 physical channel (GTHE2 X1Y12).

set repo_dir {C:/Users/Kumar Lab/Desktop/Jasper/xilinx_rx}
set work_dir [file join $repo_dir .gt_ip_work]
set ip_dir   [file join $repo_dir ip]
set ref_xci  {C:/Users/Kumar Lab/Desktop/Jasper/CPCC_QWN/clock_test_ex.srcs/sources_1/ip/clock_test/clock_test.xci}

file mkdir $work_dir
file mkdir $ip_dir
create_project qwn_gt_config $work_dir -part xc7vx690tffg1761-2 -force

read_ip [list $ref_xci]
set ref_ip [get_ips clock_test]

# Capture the reference's common and first-logical-channel configuration.
set clone_properties {}
foreach property_name [list_property $ref_ip] {
    if {[regexp {^CONFIG\.(identical_val_|gt_val_|gt0_val_)} $property_name]} {
        # Single-channel Wizard configurations only expose automatic phase
        # alignment. The four-channel reference used manual bypass alignment;
        # leave these two derived selectors at their one-lane defaults while
        # retaining RXBUF_EN=FALSE and TXBUF_EN=FALSE.
        if {$property_name ni {
            CONFIG.gt0_val_rx_buffer_bypass_mode
            CONFIG.gt0_val_tx_buffer_bypass_mode
        }} {
            lappend clone_properties $property_name [get_property $property_name $ref_ip]
        }
    }
}

create_ip -name gtwizard -vendor xilinx.com -library ip -version 3.6 \
    -module_name qwn_gt_raw -dir $ip_dir
set target_ip [get_ips qwn_gt_raw]

# Apply interdependent Wizard settings atomically. Keep only the board's SFP1
# channel and its Quad-113 REFCLK1 input.
for {set lane 0} {$lane < 48} {incr lane} {
    lappend clone_properties CONFIG.gt${lane}_val false
}
lappend clone_properties CONFIG.gt12_val true
lappend clone_properties CONFIG.gt12_val_tx_refclk REFCLK1_Q3
lappend clone_properties CONFIG.gt12_val_rx_refclk REFCLK1_Q3
# The original experiment also transmitted at 1.25 Gb/s. This checkpoint is
# deliberately RX-only, so remove that unused channel and its clock/reset FSM.
lappend clone_properties CONFIG.identical_val_no_tx true
lappend clone_properties CONFIG.gt0_val_no_tx true
set_property -dict $clone_properties $target_ip

generate_target all $target_ip
export_ip_user_files -of_objects $target_ip -no_script -sync -force -quiet

puts "Applied the reference GT0 profile and selected physical channel X1Y12."
puts "Generated [get_property IP_FILE $target_ip]"
close_project
exit
