`timescale 1ns/1ps
// Supplemental VCD capture; the self-checking integration bench verifies pixels.
module trace_output;
    reg sys_clk=0, sys_rst_n=1, key_in=1;
    wire hsync,vsync;
    wire [15:0] rgb;
    lab4_top #(.DEBOUNCE_CYCLES(8)) dut(.*);
    always #10 sys_clk=~sys_clk;
    task cycles(input integer n); repeat(n) @(negedge dut.pixel_clk); endtask
    initial begin
        $dumpfile("output_pipeline.vcd");
        $dumpvars(0,dut.pixel_clk,dut.pixel_x,dut.pixel_y,dut.video_active,
            dut.hsync_raw,hsync,rgb,dut.screen_state,dut.u_pixels.state_q);
        $dumpoff;
        #1; sys_rst_n=0; #99; sys_rst_n=1;
        cycles(20); key_in=0; cycles(18); key_in=1;
        wait(dut.pixel_y==0 && dut.pixel_x==76); $dumpon; cycles(12); $dumpoff;
        wait(dut.pixel_y==0 && dut.pixel_x==652); $dumpon; cycles(12); $dumpoff;
        wait(dut.screen_state==1);
        wait(dut.pixel_y==208 && dut.pixel_x==140); $dumpon; cycles(12);
        $display("PASS trace_output: three short matched-pipeline capture windows");
        $finish;
    end
    initial begin #40000000; $fatal(1,"trace timeout"); end
endmodule
