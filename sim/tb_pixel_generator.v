`timescale 1ns/1ps
module tb_pixel_generator;
    reg clk=0, rst_n=1;
    always #5 clk=~clk;
    reg [9:0] pixel_x=0,pixel_y=0;
    reg video_active=0;
    reg [1:0] screen_state=0;
    wire [15:0] rgb;
    integer s,x,y,j,fd,r,g,b,white_count;
    reg [15:0] expected;
    pixel_generator dut(.*);
    `include "golden_pixels.vh"
    initial begin
        $dumpfile("pixel_generator.vcd"); $dumpvars(0,tb_pixel_generator); $dumpoff;
        #1; rst_n=0; #1; rst_n=1; video_active=1; @(negedge clk);
        for(s=0;s<3;s=s+1) begin
            screen_state=s[1:0]; white_count=0;
            case(s)
                0:fd=$fopen("bars.ppm","wb");
                1:fd=$fopen("must.ppm","wb");
                2:fd=$fopen("end.ppm","wb");
            endcase
            if(!fd) $fatal(1,"cannot create framebuffer");
            $fwrite(fd,"P6\n640 480\n255\n");
            for(y=0;y<480;y=y+1) for(x=0;x<640;x=x+1) begin
                pixel_x=x[9:0]; pixel_y=y[9:0]; @(posedge clk); #1;
                expected=golden_pixel(s,x,y);
                if(rgb!==expected) $fatal(1,"pixel state=%0d x=%0d y=%0d actual=%h expected=%h",s,x,y,rgb,expected);
                if(rgb==16'hFFFF) white_count=white_count+1;
                r=(rgb[15:11]*255)/31; g=(rgb[10:5]*255)/63; b=(rgb[4:0]*255)/31;
                $fwrite(fd,"%c%c%c",r[7:0],g[7:0],b[7:0]);
                @(negedge clk);
            end
            $fclose(fd);
            $display("Screen %0d: 307200 pixels matched; white pixels=%0d",s,white_count);
            // Blanking must override even white text and colored bars.
            video_active=0; pixel_x=192; pixel_y=208; @(posedge clk); #1;
            if(rgb!==0) $fatal(1,"blanking nonblack");
            @(negedge clk); video_active=1;
        end
        $dumpon; screen_state=1; pixel_y=208;
        for(j=136;j<216;j=j+1) begin pixel_x=j[9:0]; @(posedge clk); #1; @(negedge clk); end
        screen_state=3; @(posedge clk); #1; if(rgb!==0) $fatal(1,"illegal state not black");
        @(negedge clk); screen_state=1; pixel_x=144; pixel_y=208;
        @(posedge clk); #1; if(rgb!==16'hFFFF) $fatal(1,"reset setup not white");
        #1; rst_n=0; #1; if(rgb!==0) $fatal(1,"asynchronous RGB reset failed");
        $display("PASS tb_pixel_generator: all 921600 active pixels, 3 screens, blanking, illegal state");
        $finish;
    end
endmodule
