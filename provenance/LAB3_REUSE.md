# Lab 3 reuse record

Original: https://github.com/Easonzhou666/--EIE330-Lab3-Group9/blob/f473cda29fbb629c7e9b2654096946d7ca76ebd4/RTL/lab3_top.v

`RTL/vga_pic.v` preserves the original `module vga_pic` through `endmodule` text
exactly after line-ending normalization. The source snapshot is retained as `.txt`
to avoid duplicate module declarations. MUST uses the original parameter values.
END instantiates the same renderer with new 8x8 E/N/D masks and a zero fourth slot.
Adapters translate horizontal coordinates by 96 (MUST) and 144 (END) so the new
words are centered. RGB, selector and sync have matching one-edge latency.

The supplied Lab 3 archive has no color-bar module. `color_bars.v` is extracted
from Lab 4 revision d271178fa023bb92d1dd37e078200c50bc86423f, not represented as
recovered Lab 3 source. Literal reuse of a prior Lab 3 bars module remains
unverified. No automatic compensation for the old video offset is applied.
