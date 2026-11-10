`timescale 1ns/1ps
module tb_lab4_top;
    reg sys_clk=0,sys_rst_n=1,key_in=1;
    wire hsync,vsync;
    wire [15:0] rgb;
    integer clicks=0,changes=0;
    reg [1:0] old_screen=0;
    reg boundary_previous=0;
    lab4_top #(.DEBOUNCE_CYCLES(8)) dut(.*);
    always #10 sys_clk=~sys_clk;
    always @(posedge dut.pixel_clk) begin
        if(dut.pixel_rst_n && dut.click_pulse) clicks=clicks+1;
        boundary_previous=dut.frame_blank_start;
        #1;
        if(!dut.pixel_rst_n) old_screen=0;
        else if(dut.screen_state!=old_screen) begin
            if(!boundary_previous || dut.video_active) $fatal(1,"screen changed outside vblank");
            changes=changes+1; old_screen=dut.screen_state;
        end
        if(dut.pixel_rst_n && !dut.video_active && rgb!==0) $fatal(1,"RGB not black during blanking");
    end
    task cycles(input integer n); begin repeat(n) @(negedge dut.pixel_clk); end endtask
    task clean_click; begin key_in=0; cycles(18); key_in=1; cycles(18); end endtask
    task expect_request(input integer s); begin
        if(dut.requested_state!==s[1:0]) $fatal(1,"requested=%0d expected=%0d",dut.requested_state,s);
    end endtask
    task wait_screen(input integer s); begin
        wait(dut.screen_state==s[1:0]); cycles(2);
    end endtask
    task reset_now; begin
        sys_rst_n=0; #1;
        if(dut.screen_state!==0 || dut.requested_state!==0) $fatal(1,"reset did not select bars");
        #99; sys_rst_n=1; cycles(20);
    end endtask
    initial begin
        $dumpfile("lab4_top.vcd");
        // State/count evidence without recording the free-running clocks or every pixel.
        $dumpvars(0,sys_rst_n,key_in,hsync,vsync,dut.click_pulse,dut.key_level,
            dut.u_key.stable_count,dut.u_key.armed,dut.requested_state,dut.screen_state);
        #1; sys_rst_n=0; #99; sys_rst_n=1; cycles(20);
        expect_request(0);
        // Three clean clicks: BARS -> MUST -> END -> BARS.
        clean_click; expect_request(1); wait_screen(1);
        clean_click; expect_request(2); wait_screen(2);
        clean_click; expect_request(0); wait_screen(0);
        if(clicks!=3) $fatal(1,"clean cycle click count");
        // Bouncing press and release, then long hold.
        key_in=0; cycles(3); key_in=1; cycles(3);
        key_in=0; cycles(4); key_in=1; cycles(4);
        key_in=0; cycles(20); expect_request(1);
        cycles(1000); if(clicks!=4) $fatal(1,"bounce/hold repeated");
        wait_screen(1); // Reset from MUST while held.
        reset_now; expect_request(0); cycles(100); if(clicks!=4) $fatal(1,"phantom held-reset click");
        key_in=1; cycles(20);
        clean_click; wait_screen(1); clean_click; wait_screen(2);
        reset_now; expect_request(0); // Reset from END.
        reset_now; expect_request(0); // Reset from BARS.
        key_in=0; cycles(4); reset_now; expect_request(0); // Reset mid-debounce.
        cycles(40); if(clicks!=6) $fatal(1,"mid-click reset created event");
        key_in=1; cycles(20); clean_click; wait_screen(1);
        if(clicks!=7 || changes!=7) $fatal(1,"integration totals clicks=%0d commits=%0d",clicks,changes);
        $display("PASS tb_lab4_top: complete cycle, bounce, long press, reset every screen/held/mid-click, vblank switching");
        $finish;
    end
    initial begin #180000000; $fatal(1,"top-level timeout"); end
endmodule
