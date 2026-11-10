`timescale 1ns/1ps
module tb_pixel_generator;
    reg [9:0] pixel_x=0,pixel_y=0;
    reg video_active=1;
    reg [1:0] screen_state=0;
    wire [15:0] rgb;
    integer s,x,y,j,fd,r,g,b,white_count;
    reg [15:0] expected;
    pixel_generator dut(.*);
    function [4:0] expected_row(input integer ch,input integer row);
        reg [34:0] map;
        begin
            case(ch)
                77: map=35'b10001110111010110101100011000110001;
                85: map=35'b10001100011000110001100011000101110;
                83: map=35'b01111100001000001110000010000111110;
                84: map=35'b11111001000010000100001000010000100;
                69: map=35'b11111100001000011110100001000011111;
                78: map=35'b10001110011100110101100111001110001;
                68: map=35'b11110100011000110001100011000111110;
                default: map=0;
            endcase
            expected_row=(map >> ((6-row)*5)) & 31;
        end
    endfunction
    function [15:0] expected_pixel(input integer state,input integer xx,input integer yy);
        integer start,idx,cx,ch;
        reg [4:0] bits;
        begin
            expected_pixel=16'h0000;
            if(state==0) begin
                case(xx/80)
                    0:expected_pixel=16'hF800; 1:expected_pixel=16'hFFE0;
                    2:expected_pixel=16'h07E0; 3:expected_pixel=16'h07FF;
                    4:expected_pixel=16'h001F; 5:expected_pixel=16'hF81F;
                    6:expected_pixel=16'hFFFF; 7:expected_pixel=16'h0000;
                endcase
            end else if(yy>=212 && yy<268) begin
                start=(state==1)?228:252;
                if(xx>=start && xx<640-start) begin
                    idx=(xx-start)/48; cx=(xx-start)%48; ch=0;
                    if(state==1) case(idx) 0:ch=77; 1:ch=85; 2:ch=83; 3:ch=84; endcase
                    else case(idx) 0:ch=69; 1:ch=78; 2:ch=68; endcase
                    bits=expected_row(ch,(yy-212)/8);
                    if(cx<40 && bits[4-cx/8]) expected_pixel=16'hFFFF;
                end
            end
        end
    endfunction
    initial begin
        $dumpfile("pixel_generator.vcd"); $dumpvars(0,tb_pixel_generator); $dumpoff;
        #1; video_active=0; #1; video_active=1;
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
                pixel_x=x[9:0]; pixel_y=y[9:0]; #1;
                expected=expected_pixel(s,x,y);
                if(rgb!==expected) $fatal(1,"pixel state=%0d x=%0d y=%0d actual=%h expected=%h",s,x,y,rgb,expected);
                if(rgb==16'hFFFF) white_count=white_count+1;
                r=(rgb[15:11]*255)/31; g=(rgb[10:5]*255)/63; b=(rgb[4:0]*255)/31;
                $fwrite(fd,"%c%c%c",r[7:0],g[7:0],b[7:0]);
            end
            $fclose(fd);
            $display("Screen %0d: 307200 pixels matched; white pixels=%0d",s,white_count);
            // Blanking must override even white text and colored bars.
            video_active=0; pixel_x=252; pixel_y=212; #1;
            if(rgb!==0) $fatal(1,"blanking nonblack");
            video_active=1;
        end
        $dumpon; screen_state=1; pixel_y=212;
        for(j=220;j<420;j=j+1) begin pixel_x=j[9:0]; #1; end
        screen_state=3; #1; if(rgb!==0) $fatal(1,"illegal state not black");
        $display("PASS tb_pixel_generator: all 921600 active pixels, 3 screens, blanking, illegal state");
        $finish;
    end
endmodule
