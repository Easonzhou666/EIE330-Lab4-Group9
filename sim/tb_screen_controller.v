`timescale 1ns/1ps
module tb_screen_controller;
    reg clk=0, rst_n=1, click_pulse=0, frame_blank_start=0;
    wire [1:0] requested_state, screen_state;
    integer s;
    screen_controller dut(.*);
    always #20 clk=~clk;
    task tick; begin @(posedge clk); #1; @(negedge clk); end endtask
    task check(input integer a,input integer b); begin
        if (requested_state!==a[1:0] || screen_state!==b[1:0])
            $fatal(1,"FSM actual=%0d/%0d expected=%0d/%0d",requested_state,screen_state,a,b);
    end endtask
    initial begin
        $dumpfile("screen_controller.vcd"); $dumpvars(0,tb_screen_controller);
        #1; rst_n=0; tick; rst_n=1; tick; check(0,0);
        for(s=1;s<=3;s=s+1) begin
            click_pulse=1; tick; click_pulse=0; check(s%3,(s-1)%3);
            repeat(4) tick; check(s%3,(s-1)%3); // Visible state must wait for blanking.
            frame_blank_start=1; tick; frame_blank_start=0; check(s%3,s%3);
        end
        // Click and commit on same edge.
        click_pulse=1; frame_blank_start=1; tick;
        click_pulse=0; frame_blank_start=0; check(1,1);
        // Reset from all three states, including an asserted click.
        for(s=0;s<3;s=s+1) begin
            rst_n=0; #1; check(0,0); tick; rst_n=1; tick;
            repeat(s) begin click_pulse=1; frame_blank_start=1; tick; click_pulse=0; frame_blank_start=0; tick; end
            check(s,s); click_pulse=1; rst_n=0; #1; check(0,0);
            tick; click_pulse=0; rst_n=1; tick;
        end
        // Multiple requests before one frame are accumulated modulo three.
        repeat(2) begin click_pulse=1; tick; click_pulse=0; tick; end
        check(2,0); frame_blank_start=1; tick; frame_blank_start=0; check(2,2);
        $display("PASS tb_screen_controller: cycle, frame commit, coincident click, reset all states, queued clicks");
        $finish;
    end
    initial begin #100000; $fatal(1,"timeout"); end
endmodule
