`timescale 1ns/1ps
`default_nettype none
// 50 MHz -> 25 MHz. Use a dedicated clock route or PLL for a physical FPGA.
module clock_reset(input wire sys_clk, input wire sys_rst_n,
                   output reg pixel_clk, output wire pixel_rst_n);
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_pipe;
    always @(posedge sys_clk or negedge sys_rst_n)
        if (!sys_rst_n) pixel_clk <= 1'b0;
        else pixel_clk <= ~pixel_clk;
    // Asynchronous assertion, synchronous release in the pixel-clock domain.
    always @(posedge pixel_clk or negedge sys_rst_n)
        if (!sys_rst_n) reset_pipe <= 2'b00;
        else reset_pipe <= {reset_pipe[0], 1'b1};
    assign pixel_rst_n = reset_pipe[1];
endmodule
`default_nettype wire
