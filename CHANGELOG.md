# lab3-reuse-r1

- Add `RTL/vga_pic.v`: unchanged original Lab 3 module body.
- Add `RTL/color_bars.v`: extract the original Lab 4 bar decoder.
- Replace `RTL/pixel_generator.v`: centered adapters, two reused instances,
  new 8x8 E/N/D masks, matched bar and selector registers.
- Update `RTL/lab4_top.v`: clock/reset to renderer and matched sync registers.
- Remove `RTL/font_rom.v`: obsolete 5x7 ROM.
- Keep clock_reset, key_debounce, screen_controller and vga_timing unchanged.
- Update pixel and integration scoreboards; add standalone Lab 3 renderer test.
- Add exact reuse check, trace captures, provenance and source hashes.
- Update README, verification record and matching English report.
