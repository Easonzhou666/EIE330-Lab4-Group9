`timescale 1ns/1ps
module tb_vga_pic;
    reg vga_clk=0,sys_rst_n=1,active=1;
    reg [9:0] pix_x=0,pix_y=0;
    wire [15:0] pix_data;
    integer x,y,count=0;
    reg [15:0] old_value;
    `include "golden_pixels.vh"
    vga_pic dut(.*);
    always #5 vga_clk=~vga_clk;
    initial begin
        $dumpfile("vga_pic.vcd"); $dumpvars(0,tb_vga_pic); $dumpoff;
        #1; sys_rst_n=0; #1; sys_rst_n=1;
        for(y=0;y<480;y=y+1) for(x=0;x<640;x=x+1) begin
            @(negedge vga_clk); old_value=pix_data; pix_x=x; pix_y=y;
            #1; if(pix_data!==old_value) $fatal(1,"unexpected combinational output");
            @(posedge vga_clk); #1;
            if(pix_data!==golden_pixel(1,x+96,y)) $fatal(1,"original MUST mismatch %0d %0d",x,y);
            if(pix_data==16'hFFFF) count=count+1;
        end
        if(count!=8448) $fatal(1,"MUST lit-cell population changed");
        @(negedge vga_clk); $dumpon; pix_x=48;pix_y=208;
        @(posedge vga_clk); #1; if(pix_data!==16'hFFFF) $fatal(1,"white origin");
        @(negedge vga_clk); active=0;
        @(posedge vga_clk); #1; if(pix_data!==0) $fatal(1,"inactive not black");
        @(negedge vga_clk); active=1;
        @(posedge vga_clk); #1; sys_rst_n=0; #1;
        if(pix_data!==0) $fatal(1,"async reset");
        $display("PASS tb_vga_pic: original module, 307200 coordinates, 8448 white, registered output, blanking, async reset");
        $finish;
    end
endmodule
