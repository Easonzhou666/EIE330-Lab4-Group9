`timescale 1ns/1ps
`default_nettype none
// Extracted from the original Lab 4 decoder, not claimed as a Lab 3 module.
module color_bars(input wire [9:0] pixel_x, input wire video_active,
                  output reg [15:0] rgb);
    always @* begin
        rgb = 16'h0000;
        if (video_active) begin
            if (pixel_x < 80) rgb=16'hF800;
            else if (pixel_x < 160) rgb=16'hFFE0;
            else if (pixel_x < 240) rgb=16'h07E0;
            else if (pixel_x < 320) rgb=16'h07FF;
            else if (pixel_x < 400) rgb=16'h001F;
            else if (pixel_x < 480) rgb=16'hF81F;
            else if (pixel_x < 560) rgb=16'hFFFF;
        end
    end
endmodule
`default_nettype wire
