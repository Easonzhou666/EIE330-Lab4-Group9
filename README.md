# EIE330 Lab 4 Group 9 — Lab 3 reuse revision

Revision: **lab3-reuse-r1**, 10 November 2026. Top module: **lab4_top**.

This package cycles BARS -> MUST -> END -> BARS with a qualified active-low
button. Reset returns to BARS in every state, including during a held press.
It directly reuses Group 9's original Lab 3 `vga_pic` module without changing
its body. MUST uses default parameters; END uses new E/N/D parameters in a
second instance. Both words now have 64x64 character boxes and 32-pixel gaps.

## Files

- `RTL/`: eight Verilog files, all required for the design.
- `sim/`: eight self-checking benches, shared independent pixel reference,
  and two supplemental trace benches. Do not select this as simulator RTL.
- `scripts/run.py`: standard-library Python runner for Icarus and Yosys.
- `scripts/check_reuse.py`: compare the reused module with the original snapshot.
- `scripts/capture_traces.py`: capture short windows for report waveforms.
- `provenance/`: original Lab 3 source as text and exact reuse explanation.
- `constraints/lab4.sdc`: example constraints, not a board-verified pin plan.
- `verification/`: recorded local test/synthesis evidence and expected images.
- `SOURCE_MANIFEST.json`: SHA-256 of this revision's source inputs.
- `UPLOAD_GUIDE_中文.md`: upload and demonstration instructions.

## Compile and test

Install Python 3, Icarus Verilog (`iverilog` and `vvp`), and Yosys; put their
executables on PATH. From the directory containing this README:

```sh
python3 scripts/run.py --synth
python3 scripts/capture_traces.py
```

On Windows use `python` instead of `python3` if applicable. With OSS CAD Suite,
use its provided environment so both `bin` and `lib` are on PATH. No third-party
Python libraries are needed by these commands. The runner rejects compiler
diagnostics and Yosys warnings. Generated results go under `build/`.

## Virtual-board configuration

Load the entire **RTL/** directory and select **lab4_top**. Keep all eight `.v`
files together. Top-level port names and directions are unchanged.

| Simulator connection | RTL port | Meaning |
| --- | --- | --- |
| clk | sys_clk | 50 MHz input |
| reset | sys_rst_n | Active-low reset |
| B2 | key_in | Active-low screen switch |
| h_sync | hsync | Negative horizontal sync |
| v_sync | vsync | Negative vertical sync |
| rgb | rgb[15:0] | RGB565 |

Use the mapping controls provided by your installed simulator; labels can vary.
Press reset once after loading. Release B2 before the first click so the release
can qualify. Both press and release need 20 ms of simulated time. A slow virtual
board can require visibly longer wall-clock holds; wait for settled screens.

## Intended raster and geometry

The 50 MHz clock is divided to 25 MHz. Totals are 800 x 525, active area 640 x 480;
line period 32 us, frame period 16.8 ms (59.524 Hz). Raw HSYNC is low at x=656..751;
raw VSYNC is low at y=490..491. All external sync and RGB paths have matching
one-edge sampling latency, preserving relative phase.

| Screen | Expected appearance |
| --- | --- |
| BARS | Eight 80-pixel stripes: red, yellow, green, cyan, blue, magenta, white, black |
| MUST | Glyph origins x=144,240,336,432; y=208; 8448 white pixels |
| END | Glyph origins x=192,288,384; y=208; 6912 white pixels |

## Key implementation decisions

`screen_controller.v:26` retains the vertical-blanking commit of `next_state`.
`pixel_generator.v` adapts centered coordinates to the archived renderer by
subtracting 96 for MUST and 144 for END. Active guards prevent unsigned wrap.
The original `vga_pic` registers its output, so bars, selector and external sync
are sampled on the same edge. A raw/combinational picture path mixed with a
registered path would require a different comparison cycle.

`font_rom.v` from the earlier revision is removed. Do not retain a duplicate
`vga_pic` declaration by also loading the original `lab3_top.v` into RTL/.

## Verification and remaining evidence

Eight self-checking tests pass locally. Image checking covers 921600 pixels;
the original picture unit checks another 307200; integration checks 2832046
RGB/sync samples. Generic synthesis reports 1043 primitives, 72 FF bits,
zero warnings and no latches. See VERIFICATION.md and verification/.

The earlier Lab 4 video predates this revision. Run and record this package in
the target simulator before claiming its screen alignment or switching is
verified there. No physical-board timing closure is claimed. The supplied Lab 3
archive does not contain a color-bar module; this revision retains the original
Lab 4 palette, and does not claim literal reuse of unavailable bar source.

Repository upload destination: https://github.com/Easonzhou666/EIE330-Lab4-Group9

Original Lab 3: https://github.com/Easonzhou666/--EIE330-Lab3-Group9

Earlier Lab 4 video: https://youtu.be/2VdNohgfJrI?si=VH-0MG7qceL7h6Dc
