`timescale 1ns/1ps
module tb_vga_timing;
    reg clk=0, rst_n=1;
    wire [9:0] pixel_x,pixel_y;
    wire hsync,vsync,video_active,frame_blank_start;
    integer n,x,y,active_count=0,hs_count=0,vs_count=0,blank_count=0;
    vga_timing dut(.*);
    always #20 clk=~clk;
    initial begin
        $dumpfile("vga_timing.vcd"); $dumpvars(0,tb_vga_timing); $dumpoff;
        #1; rst_n=0; repeat(3) @(negedge clk); rst_n=1;
        for(n=0;n<840000;n=n+1) begin
            x=n%800; y=(n/800)%525;
            #1;
            if (pixel_x!==x[9:0] || pixel_y!==y[9:0]) $fatal(1,"coordinate %0d",n);
            if (hsync !== !(x>=656 && x<752)) $fatal(1,"hsync %0d",n);
            if (vsync !== !(y>=490 && y<492)) $fatal(1,"vsync %0d",n);
            if (video_active !== (x<640 && y<480)) $fatal(1,"active %0d",n);
            if (frame_blank_start !== (x==0 && y==480)) $fatal(1,"blank %0d",n);
            if(n<420000) begin
                if(video_active) active_count=active_count+1;
                if(!hsync) hs_count=hs_count+1;
                if(!vsync) vs_count=vs_count+1;
                if(frame_blank_start) blank_count=blank_count+1;
            end
            // Three short windows: one line, vsync, and frame wrap.
            if(n==0 || n==391990 || n==419990) $dumpon;
            if(n==805 || n==393610 || n==420010) $dumpoff;
            @(negedge clk);
        end
        if(active_count!=307200 || hs_count!=50400 || vs_count!=1600 || blank_count!=1)
            $fatal(1,"frame totals wrong");
        $display("PASS tb_vga_timing: two full frames, 800x525, active=307200, hsync=96/line, vsync=2 lines");
        $finish;
    end
    initial begin #40000000; $fatal(1,"timeout"); end
endmodule
