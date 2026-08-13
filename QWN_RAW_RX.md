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
This remains a controlled idle-pattern checkpoint before packet framing.

## Hardware

1. Keep the two short SMA clock cables installed: VC709 J31/J32 to J25/J26.
2. Use the 10-Gb/s LR SFP module in VC709 cage P3/SFP1.
3. Connect Lattice J12 TX to VC709 P3/SFP1 RX.
4. Program `qwn_raw_rx.bit` on the VC709 and the raw K28.5 TX bitstream on the
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
| 5 | SFP reports optical signal (no LOS) |
| 6 | Reversed K28.5 found and 10-bit symbol alignment locked |
| 7 | Eight consecutive symbols decoded as K28.5 (`K=1`, byte `0xBC`) |

With the current alternating K28.5 transmitter, both LEDs 6 and 7 should turn
on. LED 7 is sticky until CPU reset. Resetting with the optical cable removed
must leave LED 7 off; reconnecting must make it qualify again.

## Rebuild

The generator and build scripts intentionally use the authoritative local
`CPCC_QWN/clock_test_ex` sources rather than the old Ethernet receiver:

1. Run `generate_qwn_gt.tcl` in Vivado batch mode if the `qwn_gt_raw` IP must
   be regenerated.
2. Run `build_qwn_raw_rx.tcl` to synthesize, implement, report, and export the
   bitstream.

Current signoff: routed DRC has 0 violations; setup WNS is +0.454 ns and hold
WHS is +0.108 ns. All ten possible symbol starting offsets align and decode
K28.5 as `K=1`, byte `0xBC`, without code errors in XSim.
