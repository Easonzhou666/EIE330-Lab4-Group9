`timescale 1ns/1ps
`default_nettype none
module vga_timing(input wire clk, input wire rst_n,
    output reg [9:0] pixel_x, output reg [9:0] pixel_y,
    output wire hsync, output wire vsync, output wire video_active,
    output wire frame_blank_start);
    // 640 active + 16 front porch + 96 sync + 48 back porch = 800.
    // 480 active + 10 front porch + 2 sync + 33 back porch = 525.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin pixel_x <= 10'd0; pixel_y <= 10'd0; end
        else if (pixel_x == 10'd799) begin
            pixel_x <= 10'd0;
            if (pixel_y == 10'd524) pixel_y <= 10'd0;
            else pixel_y <= pixel_y + 1'b1;
        end else pixel_x <= pixel_x + 1'b1;
    end
    assign hsync = !((pixel_x >= 10'd656) && (pixel_x < 10'd752));
    assign vsync = !((pixel_y >= 10'd490) && (pixel_y < 10'd492));
    assign video_active = (pixel_x < 10'd640) && (pixel_y < 10'd480);
    assign frame_blank_start = (pixel_x == 10'd0) && (pixel_y == 10'd480);
endmodule
`default_nettype wire
