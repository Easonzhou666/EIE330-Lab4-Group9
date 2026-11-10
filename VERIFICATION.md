# Verification — lab3-reuse-r1

Local rerun: 10 November 2026, Icarus Verilog 14.0 development build and
Yosys 0.70+360 from OSS CAD Suite. This is functional simulation and generic
synthesis, not target FPGA implementation or a new virtual-board recording.

| Check | Result |
| --- | --- |
| Original vga_pic module-body equality | PASS, after line-ending normalization |
| tb_clock_reset | PASS, divide by two and asynchronous assert / synchronous release |
| tb_key_debounce | PASS, bounce, hold, release, reset-held and interrupted candidate |
| tb_key_real_time | PASS, default 500000 samples / 20 ms and 19-bit count |
| tb_screen_controller | PASS, cycle, reset, frame commit and coincident event |
| tb_vga_timing | PASS, 840000 coordinate samples over two full scans |
| tb_vga_pic | PASS, 307200 original pixels, 8448 white, staging and reset |
| tb_pixel_generator | PASS, 921600 revised pixels, blanking, invalid state and reset |
| tb_lab4_top | PASS, seven clicks/commits, 2832046 external RGB/sync samples |
| Icarus -g2012 -Wall | No compiler diagnostics in the eight tests |
| Yosys hierarchy / proc / opt / check / synth -noabc | PASS, zero warnings |

The full image scoreboard uses division/modulo coordinate calculations while
RTL uses threshold intervals and slices. Bitmap rows are the same declared
specification; appearance is additionally visible in exported PNGs. The top
scoreboard samples coordinates, state and raw sync before each edge, then checks
external RGB and sync after nonblocking assignments. It excludes the edge on
which synchronized reset is first released, since downstream registers still
observe reset on that edge.

Generic synthesis: 1043 primitive cells; 57 async-clear FF, 2 async-set FF,
13 enabled FF (72 stored bits total). The monochrome outputs optimize to one
stored bit each, replicated across 16 RGB bits. No latch or memory cell remains.
These are not Cyclone IV LE counts, fitted utilization, Fmax or STA results.

`verification/` contains rerun logs, result JSON, RTL JSON, output frame PNGs,
short VCD windows and simulator/tool versions. The complete tests regenerate
all build evidence. Supplemental trace benches are visualization captures,
separate from the eight assertion-based tests.

Still required in the target environment: centered full-height bars including
red, both new words, complete BARS/MUST/END/BARS cycle, reset from each screen,
reset while B2 is held, and stable transitions in a replacement recording.
