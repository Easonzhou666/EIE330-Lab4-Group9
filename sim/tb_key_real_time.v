`timescale 1ns/1ps
module tb_key_real_time;
    reg clk=0, rst_n=1, key_in=1;
    wire key_level, click_pulse;
    integer pulses=0, i;
    key_debounce dut(.*); // Production value: 500000 clocks = 20 ms.
    always #20 clk=~clk;
    always @(posedge clk) if (rst_n && click_pulse) pulses=pulses+1;
    task cycles(input integer n); begin repeat(n) @(negedge clk); end endtask
    initial begin
        $dumpfile("key_real_time.vcd"); $dumpvars(0,tb_key_real_time); $dumpoff;
        #1; rst_n=0; cycles(3); rst_n=1; cycles(500010);
        if (!key_level) $fatal(1,"did not arm after 20 ms stable release");
        // 8 ms mechanical bounce, shorter than the 20 ms qualification time.
        for (i=0;i<4;i=i+1) begin key_in=0; cycles(25000); key_in=1; cycles(25000); end
        if (pulses!=0) $fatal(1,"bounce produced a click");
        key_in=0; cycles(499980); $dumpon;
        cycles(21);
        if (pulses!=0 || dut.stable_count!=499999)
            $fatal(1,"count before qualification incorrect: %0d",dut.stable_count);
        cycles(1);
        if (!click_pulse || key_level) $fatal(1,"500000th sample did not qualify press");
        cycles(5); $dumpoff;
        cycles(1000000); // 40 ms held AFTER qualification.
        if (pulses!=1) $fatal(1,"long hold repeated");
        key_in=1; cycles(500010); key_in=0; cycles(500010);
        if (pulses!=2) $fatal(1,"second physical press lost");
        $display("PASS tb_key_real_time: 20 ms / 500000 clocks, 8 ms bounce, 60 ms hold, second click");
        $finish;
    end
    initial begin #200000000; $fatal(1,"timeout"); end
endmodule
