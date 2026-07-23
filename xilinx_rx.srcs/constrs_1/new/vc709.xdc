# VC709 board constraints for top.v.
# Sources: UG887 v1.6, Tables 1-8, 1-9, 1-13, and 1-19.

set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

# U51 onboard 200 MHz system clock (UG887 p.29).
set_property PACKAGE_PIN H19 [get_ports sysclk_p]
set_property PACKAGE_PIN G18 [get_ports sysclk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {sysclk_p sysclk_n}]
create_clock -period 5.000 -name sysclk_200 [get_ports sysclk_p]

# U34 onboard Si570, 156.25 MHz after power-up (UG887 pp.29-30).
set_property PACKAGE_PIN AK34 [get_ports user_clock_p]
set_property PACKAGE_PIN AL34 [get_ports user_clock_n]
set_property IOSTANDARD LVDS [get_ports {user_clock_p user_clock_n}]
create_clock -period 6.400 -name si570_156m25 [get_ports user_clock_p]

# Forward the Si570 to user SMA J31/J32 (UG887 pp.29,31).
set_property PACKAGE_PIN AJ32 [get_ports ref_clk_sma_p]
set_property PACKAGE_PIN AK32 [get_ports ref_clk_sma_n]
set_property IOSTANDARD LVDS [get_ports {ref_clk_sma_p ref_clk_sma_n}]

# Quad 113 MGTREFCLK1 at GTH SMA J25/J26 (UG887 pp.29,32).
set_property PACKAGE_PIN AK8 [get_ports gt_refclk_p]
set_property PACKAGE_PIN AK7 [get_ports gt_refclk_n]
# The PCS/PMA IP supplies the 6.400 ns reference-clock timing constraint.

# SW8 CPU_RESET is pulled high and low while pressed (UG887 pp.50,52).
set_property PACKAGE_PIN AV40 [get_ports cpu_reset_n]
set_property IOSTANDARD LVCMOS18 [get_ports cpu_reset_n]

# Eight active-high GPIO user LEDs, UG887 Table 1-19, printed p.51.
# gpio_led[0:7] drive DS2 through DS9 respectively.
set_property PACKAGE_PIN AM39 [get_ports {gpio_led[0]}]
set_property PACKAGE_PIN AN39 [get_ports {gpio_led[1]}]
set_property PACKAGE_PIN AR37 [get_ports {gpio_led[2]}]
set_property PACKAGE_PIN AT37 [get_ports {gpio_led[3]}]
set_property PACKAGE_PIN AR35 [get_ports {gpio_led[4]}]
set_property PACKAGE_PIN AP41 [get_ports {gpio_led[5]}]
set_property PACKAGE_PIN AP42 [get_ports {gpio_led[6]}]
set_property PACKAGE_PIN AU39 [get_ports {gpio_led[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {gpio_led[*]}]

# SFP+ Module 1/P3 is GTHE2_CHANNEL_X1Y12 (UG887 pp.36,44).
# Dedicated serial pins select the required GT channel for the PCS/PMA IP.
set_property PACKAGE_PIN AP4 [get_ports sfp_tx_p]
set_property PACKAGE_PIN AP3 [get_ports sfp_tx_n]
set_property PACKAGE_PIN AN6 [get_ports sfp_rx_p]
set_property PACKAGE_PIN AN5 [get_ports sfp_rx_n]

# SFP1 module control/status through the onboard level translator
# (UG887 Table 1-14, printed p.45). TX_DISABLE is active high; LOS,
# MOD_ABS, and TX_FAULT are also active high.
set_property PACKAGE_PIN AB41 [get_ports sfp1_tx_disable]
set_property PACKAGE_PIN Y38  [get_ports sfp1_tx_fault]
set_property PACKAGE_PIN AB42 [get_ports sfp1_mod_abs]
set_property PACKAGE_PIN Y39  [get_ports sfp1_los]
set_property PACKAGE_PIN W40  [get_ports sfp1_rs0]
set_property PACKAGE_PIN Y40  [get_ports sfp1_rs1]
set_property IOSTANDARD LVCMOS18 [get_ports {sfp1_tx_disable sfp1_tx_fault sfp1_mod_abs sfp1_los sfp1_rs0 sfp1_rs1}]

# Explicit hard-block placement. The package pins above and these LOCs describe
# the same dedicated SFP1 lane and its Quad 113 reference-clock input.
set_property LOC GTHE2_CHANNEL_X1Y12 \
    [get_cells -hierarchical -filter {REF_NAME == GTHE2_CHANNEL}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks sysclk_200] \
    -group [get_clocks -include_generated_clocks si570_156m25]
