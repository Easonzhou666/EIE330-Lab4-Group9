`timescale 1ns/1ps
module tb_clock_reset;
    reg sys_clk=0,sys_rst_n=1;
    wire pixel_clk,pixel_rst_n;
    integer edges=0;
    time previous_edge=0;
    clock_reset dut(.*);
    always #10 sys_clk=~sys_clk;
    always @(posedge pixel_clk) begin
        if(sys_rst_n) begin
            if(edges>0 && $time-previous_edge!=40) $fatal(1,"pixel period is not 40 ns");
            previous_edge=$time; edges=edges+1;
        end
    end
    initial begin
        $dumpfile("clock_reset.vcd"); $dumpvars(0,tb_clock_reset);
        #1; sys_rst_n=0; #42; sys_rst_n=1;
        @(posedge pixel_clk); #1; if(pixel_rst_n!==0) $fatal(1,"release too early");
        @(posedge pixel_clk); #1; if(pixel_rst_n!==1) $fatal(1,"release not synchronized");
        repeat(20) @(negedge sys_clk);
        #3; sys_rst_n=0; #1;
        if(pixel_clk!==0 || pixel_rst_n!==0) $fatal(1,"asynchronous reset failed");
        edges=0; #13; sys_rst_n=1; repeat(10) @(negedge sys_clk);
        $display("PASS tb_clock_reset: 50->25 MHz, asynchronous assertion, two-edge synchronous release");
        $finish;
    end
endmodule
