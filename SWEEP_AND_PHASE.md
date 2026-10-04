# Updated testbench: 1 kHz to 10 MHz, plus phase shifting

Run from the extracted project directory:

```sh
make test
# Generate a GTKWave-compatible VCD:
vvp results/dds_sim +vcd
# Open it:
gtkwave results/dds.vcd
```

`tb/dds_tb.v` is now the default updated testbench. The original testbench is preserved as `tb/dds_regression_tb.v`; run it with `make regression`. No DUT changes were required.

## Frequency tests

The 1 kHz input is FCW 42950 (hex 0000a7c6). The 10 MHz endpoint is FCW 429496730 (hex 1999999a). Clock is 100 MHz throughout.

1. Hold 1 kHz for 500000 measurement samples (5 ms, about five periods). Check output zero crossings and compare every cycle to the independent reference.
2. Check 10 kHz and all six original test frequencies.
3. Apply a staircase without reset: 1 kHz -> 10 kHz -> 100 kHz -> 1 MHz -> 5 MHz -> 10 MHz. Each immediate update preserves accumulator phase.
4. Apply the smooth ramp command to the advanced core: 1 kHz -> 10 MHz. The baseline receives the same endpoint command and immediately changes to 10 MHz, while the advanced core gradually approaches it.

Smooth frequency step is 4295 FCW units per enabled edge, about 100.00076 Hz per sample. The 9999 kHz excursion takes 99990 enabled edges, about 0.9999 ms. The final step clamps exactly to the target FCW. The test explicitly verifies monotonic movement, step size, endpoint, timeout, phase continuity and output samples. Quantized tuning endpoints are approximately 1000.00761 Hz and 10000000.00931 Hz.

`results/sweep.csv` contains both outputs and the advanced post-edge FCW. Its FCW column is the current control state, not a latency-aligned label for the output on that same row: accepted samples take three subsequent enabled edges to reach the outputs, and use pre-edge controls. The cycle-by-cycle reference accounts for this timing correctly. Do not run the coherent single-tone SFDR utility on this chirp file.

## Phase tests

After the sweep, both cores use a fixed 1 MHz tuning word to make shifts easy to inspect. Test these offsets:

| Degrees | Offset hex |
|---:|---|
| 0 | 00000000 |
| 45 | 20000000 |
| 90 | 40000000 |
| 180 | 80000000 |
| 270 | c0000000 |
| 350 | f8e38e39 |
| 10 | 071c71c7 |

First both cores change offsets immediately. Next the baseline still changes immediately while the advanced core uses shortest-path circular slew. Advanced phase step is 0x00100000, or 0.087890625 degrees per enabled edge. Commands are held for 4096 cycles, longer than the maximum 2048-edge shortest-path transition. The 350 -> 10 degree change crosses zero in the positive direction, rather than going backward through 340 degrees.

`results/phase_shift.csv` exports requested phase, post-edge actual offsets, and both pairs of waveforms. As with frequency CSV, post-edge controls and pipeline outputs have different timing; the independent checker handles that delay. Smooth phase changes temporarily affect instantaneous frequency while the offset moves. Neither mode overwrites accumulator phase.

## GTKWave signals

Expand dds_tb and add:

* test_stage: 1 frequency measurements, 2 staircase, 3 smooth sweep, 4 immediate phase shifts, 5 smooth phase shifts, 6 original regression checks.
* phase_degrees: requested phase during stages 4 and 5.
* fcw_in, frequency_slew_enable, phase_slew_enable.
* dut.active_fcw, advanced.active_fcw.
* dut.phase_offset, advanced.phase_offset.
* s/c: baseline sine/cosine; as/ac: advanced sine/cosine.
* v/av: output-valid signals.

Set waveform samples to signed decimal, then Analog -> Interpolated. Display control words in hexadecimal or unsigned decimal. Zoom into stages 3, 4 and 5: a full 1 kHz-to-10 MHz record contains too many high-frequency periods to distinguish at full zoom. VCD dumping is optional and can produce a large file because the simulation checks more than 900000 clock cycles.

The original reset/stall/random tests and the coherent SFDR capture still run after the new tests. `results/sweep_verification.log` is the updated full-run report; `results/verification.log` preserves the earlier regression report. The general README's original verification counts describe that earlier run; see the updated log for the new run.

Updated run result: PASS for both cores; 1007146 clock cycles and 1004493 checked output samples per core. The smooth frequency ramp completed in 99990 enabled edges. All fourteen directed phase commands reached their requested offsets.
