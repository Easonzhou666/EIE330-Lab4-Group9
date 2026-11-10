`timescale 1ns/1ps
`default_nettype none
module pixel_generator(input wire clk, input wire rst_n,
    input wire [9:0] pixel_x, input wire [9:0] pixel_y,
    input wire video_active, input wire [1:0] screen_state,
    output reg [15:0] rgb);
    // The archived vga_pic uses origins 48,144,240,336 and registered RGB.
    // Translate its input, preserving the original module and all MUST masks.
    // MUST: origins 144,240,336,432; END: 192,288,384; y=208..271.
    // All glyph boxes are 64x64 with 32-pixel gaps; MSB is the left column.
    wire must_active = video_active && pixel_x >= 10'd96;
    wire end_active = video_active && pixel_x >= 10'd144;
    wire [9:0] must_x = must_active ? pixel_x - 10'd96 : 10'd0;
    wire [9:0] end_x = end_active ? pixel_x - 10'd144 : 10'd0;
    wire [15:0] must_rgb, end_rgb, bars_rgb;
    reg [15:0] bars_q;
    reg [1:0] state_q;
    // Literal source reuse: this instance uses every original parameter default.
    vga_pic u_must(.vga_clk(clk), .sys_rst_n(rst_n), .active(must_active),
        .pix_x(must_x), .pix_y(pixel_y), .pix_data(must_rgb));
    // Same Lab 3 renderer, new row constants: slots M/U/S become E/N/D.
    // The fourth slot is blank. No new font address convention is introduced.
    vga_pic #(
        .M0(8'hFF), .M1(8'hC0), .M2(8'hC0), .M3(8'hFC),
        .M4(8'hC0), .M5(8'hC0), .M6(8'hC0), .M7(8'hFF),
        .U0(8'hC3), .U1(8'hE3), .U2(8'hF3), .U3(8'hDB),
        .U4(8'hCF), .U5(8'hC7), .U6(8'hC3), .U7(8'hC3),
        .S0(8'hFC), .S1(8'hC6), .S2(8'hC3), .S3(8'hC3),
        .S4(8'hC3), .S5(8'hC3), .S6(8'hC6), .S7(8'hFC),
        .T0(8'h00), .T1(8'h00), .T2(8'h00), .T3(8'h00),
        .T4(8'h00), .T5(8'h00), .T6(8'h00), .T7(8'h00)
    ) u_end(.vga_clk(clk), .sys_rst_n(rst_n), .active(end_active),
        .pix_x(end_x), .pix_y(pixel_y), .pix_data(end_rgb));
    color_bars u_bars(.pixel_x(pixel_x), .video_active(video_active),
        .rgb(bars_rgb));
    // Match the one-edge latency of both vga_pic instances.
    // Register the selector too: every mux input describes the same sample.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin bars_q <= 16'h0000; state_q <= 2'd0; end
        else begin bars_q <= bars_rgb; state_q <= screen_state; end
    end
    always @* begin
        case (state_q)
            2'd0: rgb = bars_q;
            2'd1: rgb = must_rgb;
            2'd2: rgb = end_rgb;
            default: rgb = 16'h0000;
        endcase
    end
endmodule
`default_nettype wire
