`timescale 1ns/1ps
`default_nettype none
module screen_controller(input wire clk, input wire rst_n,
    input wire click_pulse, input wire frame_blank_start,
    output reg [1:0] requested_state, output reg [1:0] screen_state);
    localparam [1:0] BARS=2'd0, MUST=2'd1, END_SCREEN=2'd2;
    reg [1:0] next_state;
    // Moore FSM: every accepted press advances the requested screen once.
    always @* begin
        next_state = requested_state;
        case (requested_state)
            BARS: if (click_pulse) next_state = MUST;
            MUST: if (click_pulse) next_state = END_SCREEN;
            END_SCREEN: if (click_pulse) next_state = BARS;
            default: next_state = BARS;
        endcase
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            requested_state <= BARS;
            screen_state <= BARS;
        end else begin
            requested_state <= next_state;
            // Commit only during vertical blanking: no mixed-content frame.
            // next_state also handles a click coincident with this boundary.
            if (frame_blank_start) screen_state <= next_state;
        end
    end
endmodule
`default_nettype wire
