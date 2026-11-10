# Generic timing constraints. Verify generated-clock object naming in your FPGA tool.
create_clock -name sys_clk -period 20.000 [get_ports {sys_clk}]
create_generated_clock -name pixel_clk -source [get_ports {sys_clk}] -divide_by 2 [get_pins {u_clock|pixel_clk|q}]
# The generated-clock target above is an example, NOT a board/tool verified path.
# Set board-specific pin assignments, button/reset CDC exceptions and VGA output
# delays in your own FPGA project. This file is a starting point, not STA evidence.
