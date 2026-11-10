# Verification Record — EIE330 Lab 4

**Source-project verification record date:** November 10, 2026.

This cleaned GitHub package does **not** include historical outputs from `build/`. After running `python3 scripts/run.py`, tool versions are recorded in `build/*_version.log`, overall test results in `build/results.json`, and individual test logs in the corresponding test directories.

Two module-declaration changes were incorporated to help the Simple VGA Simulator discover the top-level module. **The cleaned package must be tested again on the target Ubuntu system; the original verification record is not proof that this repackaged version passes.**

## 1. Verification Matrix

| Requirement / Design Risk | Testbench or Tool | Checks Performed |
| --- | --- | --- |
| 50 MHz input clock and 25 MHz pixel clock | `tb_clock_reset` | 40 ns pixel-clock period; asynchronous reset assertion and two-stage synchronized release |
| Exactly one event per button press | `tb_key_debounce` | Contact bounce during pressing and releasing; long press; another press after release |
| Full-duration debounce timing | `tb_key_real_time` | 500,000 clock cycles and a 19-bit counter; 8 ms of bounce must not trigger a click; the 500,000th stable sample triggers an event; holding the button for another 40 ms must not produce a second event |
| Three-screen cycle and state machine | `tb_screen_controller` | State sequence 0 → 1 → 2 → 0; reset from every state; simultaneous click and frame-boundary events; accumulation of multiple requests |
| Stable, flicker-free screen selection | `tb_screen_controller`, `tb_lab4_top` | Except during reset, the displayed state changes only at the vertical-blanking boundary, never within the active-video region |
| VGA synchronization and active-video window | `tb_vga_timing` | Cycle-by-cycle checks of coordinates, HSYNC, VSYNC, active-video enable, and frame boundaries over two complete frames; 307,200 active pixels per frame |
| All three screen images | `tb_pixel_generator` | All 921,600 active pixels across three screens compared against independent coordinate/font reference functions; blanking regions and invalid states also checked; PNG images exported |
| Full-system integration | `tb_lab4_top` | Three-click screen cycle; bouncing and long presses; reset from each screen; reset while the button is held or during debouncing; another click after release |
| Syntax, design structure, and generic synthesis | Icarus Verilog / Yosys | Icarus `-g2012 -Wall`; Yosys `hierarchy`, `proc`, `opt`, `check -assert`, and `synth -noabc`; target is no compile diagnostics or Yosys warnings |

## 2. Testbench Method and Scope

Each testbench calls `$fatal` when a check fails and prints `PASS` when its checks complete successfully.

For faster stimulus generation, the top-level integration test uses a shortened debounce setting of **8 clock cycles**. Full-duration behavior with the production debounce parameter is checked separately by `tb_key_real_time`.

The VGA timing test retains the full **800 × 525** scan timing. Neither the screen dimensions nor the frame period were reduced for that test.

The independent pixel-reference functions check the image specification selected for **this project**. They do **not** establish that the user's original Lab 3 source modules were reused. The exported PNG files come from a simulated pixel framebuffer, **not** screenshots of the development-board window.

## 3. Simulation Durations and Waveform Data

The source-project record lists these simulation durations:

| Test | Simulated Time |
| --- | ---: |
| `tb_key_real_time` | 128.0016 ms |
| `tb_lab4_top` | 113.28265 ms |
| `tb_vga_timing` | 33.60012 ms |

Waveforms were recorded in short time windows or with selected signals, avoiding millions of unrelated clock-edge transitions.

These durations are **reported from the original project record**, not newly measured for the cleaned repository.

## 4. Verification Not Yet Completed

The following items were not completed or have not been verified for this package:

- Validation of the ModelSim/Questa simulation script.
- ABC technology mapping.
- Place-and-route for the target FPGA device.
- Static timing analysis for the target device.
- Physical-board button operation and VGA measurements.
- A development-board verification video.
- Confirmation of report submission.

The included `constraints/lab4.sdc` is an **example clock-constraint file**. Its device-specific object paths have not been verified.

## 5. Reproducing the Checks

Run these commands from the repository root on the Ubuntu virtual machine:

```bash
python3 scripts/run.py
python3 scripts/run.py --synth
```

Review the terminal output, `build/results.json`, and individual test logs. Do not claim that the cleaned repository passes all tests until those commands have actually completed successfully in the target environment.

For the virtual VGA board, select `RTL/`, choose `lab4_top` as the top module, and map `B2` to `key_in`. Verify the expected **color bars → MUST → END → color bars** cycle and reset behavior in the board window. This visual board check is separate from functional simulation and must be documented independently.

## 6. Tool Limitations

- Icarus Verilog functional simulation does not model actual FPGA propagation delay.
- Yosys generic synthesis is not equivalent to vendor-specific device implementation or timing sign-off.
- The virtual board is not a physical VGA monitor; its buttons do not reproduce mechanical contact bounce. Debouncing must therefore be verified with the simulated bounce test cases.

The verification record should be updated with fresh tool logs, observed results, and board-video evidence before it is used as a final project submission record.
