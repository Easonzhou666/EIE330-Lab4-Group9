function [7:0] golden_row(input integer ch, input integer row);
    reg [63:0] rows;
    begin
        case(ch)
            77: rows=64'hC3E7FFDBC3C3C3C3;
            85: rows=64'hC3C3C3C3C3C3663C;
            83: rows=64'h7EC3C07E0303C37E;
            84: rows=64'hFFFF181818181818;
            69: rows=64'hFFC0C0FCC0C0C0FF;
            78: rows=64'hC3E3F3DBCFC7C3C3;
            68: rows=64'hFCC6C3C3C3C3C6FC;
            default: rows=0;
        endcase
        golden_row=(rows >> ((7-row)*8)) & 255;
    end
endfunction
function [15:0] golden_pixel(input integer state,input integer xx,input integer yy);
    integer start,idx,cx,ch;
    reg [7:0] bits;
    begin
        golden_pixel=0;
        if(xx>=0 && xx<640 && yy>=0 && yy<480) begin
            if(state==0) begin
                case(xx/80)
                    0:golden_pixel=16'hF800; 1:golden_pixel=16'hFFE0;
                    2:golden_pixel=16'h07E0; 3:golden_pixel=16'h07FF;
                    4:golden_pixel=16'h001F; 5:golden_pixel=16'hF81F;
                    6:golden_pixel=16'hFFFF; 7:golden_pixel=0;
                endcase
            end else if((state==1 || state==2) && yy>=208 && yy<272) begin
                start=(state==1)?144:192;
                if(xx>=start && xx<640-start) begin
                    idx=(xx-start)/96; cx=(xx-start)%96; ch=0;
                    if(state==1) case(idx) 0:ch=77; 1:ch=85; 2:ch=83; 3:ch=84; endcase
                    else case(idx) 0:ch=69; 1:ch=78; 2:ch=68; endcase
                    bits=golden_row(ch,(yy-208)/8);
                    if(cx<64 && bits[7-cx/8]) golden_pixel=16'hFFFF;
                end
            end
        end
    end
endfunction
