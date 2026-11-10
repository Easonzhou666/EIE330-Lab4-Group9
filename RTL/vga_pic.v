`timescale 1ns/1ps
// Unmodified module body from Group 9 Lab 3 revision f473cda.
// See provenance/LAB3_REUSE.md; adapters belong in pixel_generator.v.
module vga_pic(
    input wire vga_clk, input wire sys_rst_n, input wire active,
    input wire [9:0] pix_x, pix_y,
    output reg [15:0] pix_data
);
    parameter [7:0] M0=8'hC3, M1=8'hE7, M2=8'hFF, M3=8'hDB,
                    M4=8'hC3, M5=8'hC3, M6=8'hC3, M7=8'hC3;
    parameter [7:0] U0=8'hC3, U1=8'hC3, U2=8'hC3, U3=8'hC3,
                    U4=8'hC3, U5=8'hC3, U6=8'h66, U7=8'h3C;
    parameter [7:0] S0=8'h7E, S1=8'hC3, S2=8'hC0, S3=8'h7E,
                    S4=8'h03, S5=8'h03, S6=8'hC3, S7=8'h7E;
    parameter [7:0] T0=8'hFF, T1=8'hFF, T2=8'h18, T3=8'h18,
                    T4=8'h18, T5=8'h18, T6=8'h18, T7=8'h18;
    reg inside_box;
    reg [1:0] char_id;
    reg [9:0] local_x;
    wire [2:0] char_y = (pix_y - 10'd208) >> 3;
    wire [2:0] char_x = local_x[5:3];
    reg [7:0] bitmap_row;
    always @* begin
        inside_box=0; char_id=0; local_x=0;
        if (active && pix_y >= 208 && pix_y < 272) begin
            if (pix_x >= 48 && pix_x < 112) begin
                inside_box=1; char_id=0; local_x=pix_x-10'd48;
            end else if (pix_x >= 144 && pix_x < 208) begin
                inside_box=1; char_id=1; local_x=pix_x-10'd144;
            end else if (pix_x >= 240 && pix_x < 304) begin
                inside_box=1; char_id=2; local_x=pix_x-10'd240;
            end else if (pix_x >= 336 && pix_x < 400) begin
                inside_box=1; char_id=3; local_x=pix_x-10'd336;
            end
        end
        bitmap_row=0;
        case ({char_id,char_y})
            0:bitmap_row=M0; 1:bitmap_row=M1; 2:bitmap_row=M2; 3:bitmap_row=M3;
            4:bitmap_row=M4; 5:bitmap_row=M5; 6:bitmap_row=M6; 7:bitmap_row=M7;
            8:bitmap_row=U0; 9:bitmap_row=U1; 10:bitmap_row=U2; 11:bitmap_row=U3;
            12:bitmap_row=U4; 13:bitmap_row=U5; 14:bitmap_row=U6; 15:bitmap_row=U7;
            16:bitmap_row=S0; 17:bitmap_row=S1; 18:bitmap_row=S2; 19:bitmap_row=S3;
            20:bitmap_row=S4; 21:bitmap_row=S5; 22:bitmap_row=S6; 23:bitmap_row=S7;
            24:bitmap_row=T0; 25:bitmap_row=T1; 26:bitmap_row=T2; 27:bitmap_row=T3;
            28:bitmap_row=T4; 29:bitmap_row=T5; 30:bitmap_row=T6; 31:bitmap_row=T7;
            default:bitmap_row=0;
        endcase
    end
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) pix_data <= 16'h0000;
        else pix_data <= (inside_box && bitmap_row[3'd7-char_x]) ? 16'hFFFF : 16'h0000;
    end
endmodule
