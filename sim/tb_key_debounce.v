`timescale 1ns/1ps
module tb_key_debounce;
    reg clk=0, rst_n=1, key_in=1;
    wire key_level, click_pulse;
    integer pulses=0;
    key_debounce #(.DEBOUNCE_CYCLES(8)) dut(.*);
    always #20 clk=~clk;
    always @(posedge clk) if (rst_n && click_pulse) pulses=pulses+1;
    task cycles(input integer n); begin repeat(n) @(negedge clk); end endtask
    task expect_count(input integer expected); begin
        if (pulses !== expected) $fatal(1,"pulses=%0d expected=%0d",pulses,expected);
    end endtask
    initial begin
        $dumpfile("key_debounce.vcd"); $dumpvars(0,tb_key_debounce);
        #1; rst_n=0; cycles(3); rst_n=1; cycles(16);
        expect_count(0); // Power-up released: arm, no click.
        key_in=0; cycles(3); key_in=1; cycles(3);
        key_in=0; cycles(4); key_in=1; cycles(4);
        expect_count(0); // Every pre-press bounce is too short.
        key_in=0; cycles(16); expect_count(1);
        cycles(100); expect_count(1); // Long hold cannot repeat.
        key_in=1; cycles(3); key_in=0; cycles(3);
        key_in=1; cycles(16); expect_count(1); // Release bounce.
        key_in=0; cycles(16); expect_count(2);
        rst_n=0; cycles(3); rst_n=1; cycles(40);
        expect_count(2); // Reset while held: no phantom new press.
        key_in=1; cycles(16); key_in=0; cycles(16); expect_count(3);
        key_in=1; cycles(16); key_in=0; cycles(5);
        rst_n=0; cycles(3); rst_n=1; cycles(30); expect_count(3);
        $display("PASS tb_key_debounce: bounce, long hold, reset-held, mid-debounce reset");
        $finish;
    end
    initial begin #100000; $fatal(1,"timeout"); end
endmodule
