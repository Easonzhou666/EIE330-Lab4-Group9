`timescale 1ns/1ps
module trace_lab4;
    reg sys_clk=0, sys_rst_n=1, key_in=1;
    wire hsync, vsync;
    wire [15:0] rgb;
    lab4_top #(.DEBOUNCE_CYCLES(8)) dut(.*);
    always #10 sys_clk=~sys_clk;
    task cycles(input integer n);
        repeat(n) @(negedge dut.pixel_clk);
    endtask
    initial begin
        $dumpfile("trace_lab4.vcd");
        $dumpvars(0,key_in,dut.pixel_clk,dut.click_pulse,dut.requested_state,
            dut.screen_state,dut.frame_blank_start,dut.video_active,
            dut.pixel_x,dut.pixel_y,rgb);
        #1 sys_rst_n=0;
        #99 sys_rst_n=1;
        cycles(20);
        key_in=0;
        cycles(18);
        key_in=1;
        cycles(18);
        $dumpoff;
        wait(dut.pixel_y==479 && dut.pixel_x==790);
        $dumpon;
        cycles(22);
        $finish;
    end
    initial begin
        #17000000;
        $fatal(1,"timed out");
    end
endmodule
