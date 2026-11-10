`timescale 1ns/1ps
`default_nettype none
module key_debounce(input wire clk, input wire rst_n, input wire key_in,
  output reg key_level, output reg click_pulse);
    parameter integer DEBOUNCE_CYCLES = 500000;
    localparam integer COUNT_WIDTH = (DEBOUNCE_CYCLES <= 1) ? 1 : $clog2(DEBOUNCE_CYCLES);
    localparam [COUNT_WIDTH-1:0] LAST_COUNT = DEBOUNCE_CYCLES-1;
    (* ASYNC_REG = "TRUE" *) reg key_meta, key_sync;
    reg [COUNT_WIDTH-1:0] stable_count;
    reg armed;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Start 'pressed and unarmed': a stable release is required after reset.
            key_meta <= 1'b0;
            key_sync <= 1'b0;
            key_level <= 1'b0;
            stable_count <= {COUNT_WIDTH{1'b0}};
            click_pulse <= 1'b0;
            armed <= 1'b0;
        end else begin
            key_meta <= key_in;
            key_sync <= key_meta;
            click_pulse <= 1'b0;
            if (key_sync == key_level) begin
                stable_count <= {COUNT_WIDTH{1'b0}};
            end else if (stable_count == LAST_COUNT) begin
                stable_count <= {COUNT_WIDTH{1'b0}};
                key_level <= key_sync;
                if (key_sync) armed <= 1'b1;
                else begin
                    click_pulse <= armed;
                    armed <= 1'b0;
                end
            end else stable_count <= stable_count + 1'b1;
        end
    end
endmodule
`default_nettype wire
