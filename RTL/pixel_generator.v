`timescale 1ns/1ps
`default_nettype none
module pixel_generator(input wire [9:0] pixel_x, input wire [9:0] pixel_y,
    input wire video_active, input wire [1:0] screen_state,
    output reg [15:0] rgb);
    // 5x7 font, 8x scale: glyph 40x56; gap 8; group vertically centered.
    // MUST: x=228,276,324,372; END: x=252,300,348; y=212..267.
    reg [7:0] character;
    reg [9:0] local_x, local_y;
    reg [2:0] font_row, font_col;
    reg in_glyph;
    wire [4:0] row_bits;
    font_rom u_font(.character(character), .row(font_row), .row_bits(row_bits));
    always @* begin
        character = 8'd0;
        local_x = 10'd0;
        local_y = 10'd0;
        font_row = 3'd0;
        font_col = 3'd0;
        in_glyph = 1'b0;
        if (pixel_y >= 10'd212 && pixel_y < 10'd268) begin
            local_y = pixel_y - 10'd212;
            if (screen_state == 2'd1) begin
                if (pixel_x >= 228 && pixel_x < 268) begin character=8'd77; local_x=pixel_x-10'd228; in_glyph=1'b1; end
                else if (pixel_x >= 276 && pixel_x < 316) begin character=8'd85; local_x=pixel_x-10'd276; in_glyph=1'b1; end
                else if (pixel_x >= 324 && pixel_x < 364) begin character=8'd83; local_x=pixel_x-10'd324; in_glyph=1'b1; end
                else if (pixel_x >= 372 && pixel_x < 412) begin character=8'd84; local_x=pixel_x-10'd372; in_glyph=1'b1; end
            end else if (screen_state == 2'd2) begin
                if (pixel_x >= 252 && pixel_x < 292) begin character=8'd69; local_x=pixel_x-10'd252; in_glyph=1'b1; end
                else if (pixel_x >= 300 && pixel_x < 340) begin character=8'd78; local_x=pixel_x-10'd300; in_glyph=1'b1; end
                else if (pixel_x >= 348 && pixel_x < 388) begin character=8'd68; local_x=pixel_x-10'd348; in_glyph=1'b1; end
            end
            font_row = local_y[5:3];
            font_col = local_x[5:3];
        end
    end
    always @* begin
        rgb = 16'h0000;
        if (video_active) begin
            if (screen_state == 2'd0) begin
                if (pixel_x < 80) rgb=16'hF800;       // red
                else if (pixel_x < 160) rgb=16'hFFE0; // yellow
                else if (pixel_x < 240) rgb=16'h07E0; // green
                else if (pixel_x < 320) rgb=16'h07FF; // cyan
                else if (pixel_x < 400) rgb=16'h001F; // blue
                else if (pixel_x < 480) rgb=16'hF81F; // magenta
                else if (pixel_x < 560) rgb=16'hFFFF; // white
                else rgb=16'h0000;                  // black
            end else if (in_glyph && font_col < 3'd5) begin
                if (row_bits[4-font_col]) rgb=16'hFFFF;
            end
        end
    end
endmodule
`default_nettype wire
