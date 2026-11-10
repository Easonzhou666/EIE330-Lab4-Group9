# EIE330 Lab 4 — VGA Screen Controller Using a Finite-State Machine

This project implements a three-screen VGA controller for **EIE330 FPGA-based System Design, Lab 4**. A push button advances the display through **color bars → MUST → END → color bars**, while an active-low reset returns the display to color bars from any state.

The design uses a Moore finite-state machine (FSM), button synchronization and debouncing, VGA timing generation, a small character ROM, and RGB565 pixel generation. The top-level Verilog module is `lab4_top`.

> **Project note:** This standalone implementation is based on the Lab 4 requirements; it does not incorporate the author's original Lab 3 source modules. The `lab4_top.v` and `key_debounce.v` declarations in this package were adjusted for compatibility with the Simple VGA Simulator's module discovery. The cleaned package has not yet been re-tested on the target Ubuntu installation. Run the included tests before relying on its results.

## 1. Project Structure

```text
RTL/
  lab4_top.v             Top-level module and module interconnections
  clock_reset.v          50 MHz to 25 MHz pixel clock; reset handling
  key_debounce.v         Input synchronizer, counter-based debounce, click pulse
  screen_controller.v    Three-state Moore FSM and frame-safe screen selection
  vga_timing.v           VGA scan counters, sync signals, and active-video region
  font_rom.v             5x7 glyph patterns for M, U, S, T, E, N, and D
  pixel_generator.v      RGB565 color bars and centered white text
sim/
  tb_*.v                 Seven self-checking testbenches
  waves.gtkw             Optional GTKWave signal configuration
  run_modelsim.do        Alternative ModelSim/Questa script (not verified here)
scripts/
  run.py                 Compile and run tests; generate PNGs; optional synthesis
  vcd2csv.py             Export selected VCD time windows to CSV
constraints/
  lab4.sdc               Example timing constraints; adapt to the target board
README.md                Project overview and instructions
VERIFICATION.md          Test coverage, evidence, and known limitations
.gitignore               Excludes generated simulation and synthesis files
```

The `build/` directory is automatically created when the tests run. Generated executables, logs, waveforms, images, and synthesis outputs are not included in the GitHub upload.

## 2. Requirements and Screen Sequence

- **Reset / initial state:** vertical color bars.
- **First valid button press:** centered white **MUST** on a black background.
- **Second valid button press:** centered white **END** on a black background.
- **Third valid button press:** return to color bars; the sequence repeats.
- **Debouncing:** one physical press produces one state transition, even if the button is held or its contacts bounce.
- **Reset at any time:** return to color bars, including during a held button press.
- **Display mode:** 640 × 480, approximately 60 Hz, using 16-bit RGB565 output.

The FSM has three encoded states:

| Encoding | State | Display |
| --- | --- | --- |
| `2'b00` | `BARS` | Vertical color bars |
| `2'b01` | `MUST` | White text “MUST” on black |
| `2'b10` | `END` | White text “END” on black |

A debounced `click_pulse` updates `requested_state`. To avoid visible switching within a frame, `screen_state` is updated at the beginning of vertical blanking. Reset clears both state registers immediately.

## 3. Top-Level Interface

| Port | Direction | Description |
| --- | --- | --- |
| `sys_clk` | Input | 50 MHz system clock |
| `sys_rst_n` | Input | Active-low reset |
| `key_in` | Input | Active-low screen-switching button |
| `hsync` | Output | Active-low horizontal sync |
| `vsync` | Output | Active-low vertical sync |
| `rgb[15:0]` | Output | RGB565 video: R[15:11], G[10:5], B[4:0] |

For the Simple VGA Simulator, select the directory containing all seven `RTL/*.v` files and choose **`lab4_top`** as the top module. The intended signal mapping is:

| Simulator connection | Design port |
| --- | --- |
| `clk` | `sys_clk` |
| `reset` | `sys_rst_n` |
| `B2` | `key_in` |
| `h_sync` | `hsync` |
| `v_sync` | `vsync` |
| `rgb` | `rgb` |

Other buttons and LEDs may remain unconnected. After starting the simulator, use reset to return to color bars and press/release B2 to cycle between screens. This simulator run must be checked on the target Ubuntu system; successful compilation alone does not demonstrate correct on-screen behavior.

## 4. VGA Timing and Button Debouncing

The 50 MHz system clock is divided by two to obtain a **25 MHz pixel clock** (40 ns per pixel).

| Parameter | Horizontal (pixels) | Vertical (lines) |
| --- | ---: | ---: |
| Active area | 640 | 480 |
| Front porch | 16 | 10 |
| Sync pulse | 96 | 2 |
| Back porch | 48 | 33 |
| Total | 800 | 525 |

A full line lasts **32 μs** and a full frame lasts **16.8 ms**, giving approximately **59.52 frames/s**. This is a 25 MHz approximation of the 640 × 480 @ 60 Hz timing; compatibility with physical monitors is not established by functional simulation alone.

The default debounce setting is `DEBOUNCE_CYCLES = 500000`. At 25 MHz, this corresponds to **20 ms** of stable button input. The implementation uses a 19-bit counter, input synchronization, and press-event detection. A stable release is required before another press is accepted, including after reset.

## 5. Screen Layout

The visible area uses coordinates `x = 0..639`, `y = 0..479`.

**Color bars:** Eight full-height bars, 80 pixels wide each:

| X coordinates | Color | RGB565 |
| --- | --- | --- |
| 0–79 | Red | `F800` |
| 80–159 | Yellow | `FFE0` |
| 160–239 | Green | `07E0` |
| 240–319 | Cyan | `07FF` |
| 320–399 | Blue | `001F` |
| 400–479 | Magenta | `F81F` |
| 480–559 | White | `FFFF` |
| 560–639 | Black | `0000` |

**Text screens:** The design scales a 5 × 7 bitmap font by 8, producing 40 × 56-pixel characters with an 8-pixel gap. All text is white (`FFFF`) on black (`0000`) and vertically centered at `y = 212..267`.

- `MUST`: character boxes at x = 228–267, 276–315, 324–363, and 372–411.
- `END`: character boxes at x = 252–291, 300–339, and 348–387.

Pixels outside the active-video area are black.

## 6. Running Functional Simulation

### Requirements

- Ubuntu/Linux with Python 3
- Icarus Verilog (`iverilog` and `vvp`)
- Optional: GTKWave for debugging
- Optional: Yosys for generic synthesis checks

From the **repository root directory**, run all seven automated tests:

```bash
python3 scripts/run.py
```

Run a specific test:

```bash
python3 scripts/run.py --test tb_lab4_top
python3 scripts/run.py --test tb_key_real_time
```

Run the tests and the generic Yosys synthesis check:

```bash
python3 scripts/run.py --synth
```

On success, the script prints a `PASS` message for each test and stores its results in `build/results.json`. Detailed logs and VCD waveforms are created under `build/tb_*/`.

The seven testbenches cover clock/reset behavior, short-window debouncing, real-time debouncing, FSM transitions, VGA timing, pixel content, and top-level integration. Some tests use a shortened debounce parameter to reduce simulation time; `tb_key_real_time` verifies the default 500,000-cycle debounce interval separately.

After `tb_pixel_generator` completes successfully, the generated screen images can be viewed using:

```bash
xdg-open build/tb_pixel_generator/bars.png
xdg-open build/tb_pixel_generator/must.png
xdg-open build/tb_pixel_generator/end.png
```

These images are generated from the RTL simulation. They are **not** screenshots of the virtual development board.

### Waveform inspection (optional)

```bash
gtkwave build/tb_lab4_top/lab4_top.vcd
```

A waveform excerpt can be exported as CSV using `scripts/vcd2csv.py`. For the lab report, waveform plots should be generated from simulation data rather than copied as GTKWave screenshots, as required by the lab instructions.

## 7. Synthesis, Verification, and Limitations

The optional Yosys flow performs generic synthesis using `synth -noabc` and writes files such as `build/rtl.json`, `build/synth.json`, and `build/yosys.log`. It does **not** provide target-device placement/routing, physical timing closure, or confirmed resource usage on a particular FPGA.

The included `constraints/lab4.sdc` is an example and must be checked against the actual board and synthesis toolchain. No FPGA model, pin assignment, board recording, or hardware timing analysis is supplied in this repository.

See [`VERIFICATION.md`](VERIFICATION.md) for the test-to-requirement mapping and details of checks that still require user confirmation. Before submitting the lab, verify the code in Ubuntu, demonstrate the complete screen cycle and reset behavior in the board window, and provide the required recorded video and report evidence. Document any AI-assisted contributions according to the course policy.
