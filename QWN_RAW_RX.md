# QWN raw oversampling receiver — first hardware checkpoint

This project receives the Lattice test stream without Ethernet PCS processing.
The VC709 GTH runs at 10.0 Gb/s and exposes a raw 64-bit word at 156.25 MHz.
Because the Lattice payload changes at 1.25 Gb/s, each payload bit appears as
eight raw samples. The proven `rx_oversample_cdr_64` block from
`CPCC_QWN/clock_test_ex` chooses the center sample and reconstructs up to eight
payload bits per fabric cycle.

The receiver searches for the reversed K28.5 forms observed from the Lattice
serializer, establishes the 10-bit boundary, reverses each complete symbol,
and feeds the normalized word to the original `clock_test_ex` 8b/10b decoder.
The receiver now validates the original QWN burst header and runs the original
integrity-gated coarse payload-start timer through the laser-off interval.
GT RXCDRHOLD and the physical OSERDES/ODELAY marker output remain deliberately
disabled so this build is the no-hold coarse-gate baseline.

## Hardware

1. Keep the two short SMA clock cables installed: VC709 J31/J32 to J25/J26.
2. Use the 10-Gb/s LR SFP module in VC709 cage P3/SFP1.
3. Connect Lattice J12 TX to VC709 P3/SFP1 RX.
4. Program `qwn_raw_rx.bit` on the VC709 and the QWN burst TX bitstream on the
   Lattice board.

The Xilinx design is receive-only and holds `SFP1_TX_DISABLE` high.

## Active-high LED meanings

| LED | Meaning |
| --- | --- |
| 0 | Stable 100-MHz management clock locked |
| 1 | GTH QPLL locked to the 156.25-MHz reference |
| 2 | GTH RX startup and reset completed |
| 3 | Recovered 156.25-MHz clock heartbeat |
| 4 | SFP module present |
| 5 | Sticky: SFP reported at least one physical LOS/dark event since reset |
| 6 | A valid post-LOS header was seen and correctly timed gates keep firing |
| 7 | Valid QWN headers continue arriving (expires after ~0.42 ms) |

With the original-format burst transmitter, LEDs 5-7 should all turn on shortly
after reset. Together they prove physical dark was observed, a valid header was
then recovered, and headers keep arriving. LED 7's ~0.42-ms timeout is fewer
than three 151.76-us burst periods, so a single old header cannot leave a
permanent success indication. LED 6 also has a ~0.42-ms gate watchdog, so it
cannot remain on from one historical marker. Holding the transmitter in reset
must make LEDs 6-7 expire; releasing it must restore them without resetting
this receiver. The gate uses the original `rx_gate` integrity policy and counts
through dark with GT RXCDRHOLD still disabled for this baseline.

## Rebuild

The generator and build scripts intentionally use the authoritative local
`CPCC_QWN/clock_test_ex` sources rather than the old Ethernet receiver:

1. Run `generate_qwn_gt.tcl` in Vivado batch mode if the `qwn_gt_raw` IP must
   be regenerated.
2. Run `build_qwn_raw_rx.tcl` to synthesize, implement, report, and export the
   bitstream.

Current signoff: routed DRC has 0 violations; setup WNS is +0.363 ns and hold
WHS is +0.108 ns. XSim verifies all ten symbol offsets, exact original burst
contents, repeated post-dark header validation, a gate exactly 2202 recovered
cycles after FID, and no gate for discarded or missing headers.
