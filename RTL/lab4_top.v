`timescale 1ns/1ps
`default_nettype none
module lab4_top(
    input wire sys_clk, input wire sys_rst_n, input wire key_in,
    output reg hsync, output reg vsync, output wire [15:0] rgb);
    parameter integer DEBOUNCE_CYCLES = 500000;
    wire pixel_clk, pixel_rst_n;
    wire key_level, click_pulse;
    wire [1:0] requested_state, screen_state;
    wire [9:0] pixel_x, pixel_y;
    wire video_active, frame_blank_start;
    wire hsync_raw, vsync_raw;
    clock_reset u_clock(.sys_clk(sys_clk), .sys_rst_n(sys_rst_n),
        .pixel_clk(pixel_clk), .pixel_rst_n(pixel_rst_n));
    key_debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_key(
        .clk(pixel_clk), .rst_n(pixel_rst_n), .key_in(key_in),
        .key_level(key_level), .click_pulse(click_pulse));
    screen_controller u_screen(.clk(pixel_clk), .rst_n(pixel_rst_n),
        .click_pulse(click_pulse), .frame_blank_start(frame_blank_start),
        .requested_state(requested_state), .screen_state(screen_state));
    vga_timing u_timing(.clk(pixel_clk), .rst_n(pixel_rst_n),
        .pixel_x(pixel_x), .pixel_y(pixel_y), .hsync(hsync_raw), .vsync(vsync_raw),
        .video_active(video_active), .frame_blank_start(frame_blank_start));
    pixel_generator u_pixels(.clk(pixel_clk), .rst_n(pixel_rst_n),
        .pixel_x(pixel_x), .pixel_y(pixel_y),
        .video_active(video_active), .screen_state(screen_state), .rgb(rgb));
    // RGB is registered inside the picture paths: delay sync by the same edge.
    // A one-edge matched pipeline preserves porch lengths and image position.
    always @(posedge pixel_clk or negedge pixel_rst_n) begin
        if (!pixel_rst_n) begin hsync <= 1'b1; vsync <= 1'b1; end
        else begin hsync <= hsync_raw; vsync <= vsync_raw; end
    end
endmodule
`default_nettype wire
