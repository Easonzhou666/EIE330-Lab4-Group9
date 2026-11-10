# Run from the project root in ModelSim / Questa.
# Unit tests must be run first; scripts/run.py runs all tests automatically.
file mkdir build
cd build
if {![file exists work]} {vlib work}
vmap lab4work [file normalize work]
vlog -work lab4work -sv ../RTL/*.v ../sim/*.v
foreach bench {tb_clock_reset tb_key_debounce tb_key_real_time tb_screen_controller tb_vga_timing tb_pixel_generator tb_lab4_top} {
    file mkdir $bench
    cd $bench
    vsim -c -onfinish stop lab4work.$bench
    run -all
    quit -sim
    cd ..
}
cd ..
