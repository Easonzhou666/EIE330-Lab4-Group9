`timescale 1ns/1ps
`default_nettype none
module font_rom(input wire [7:0] character, input wire [2:0] row,
                output reg [4:0] row_bits);
    reg [34:0] bitmap;
    always @* begin
        case (character)
            8'd77: bitmap = 35'b10001110111010110101100011000110001; // M
            8'd85: bitmap = 35'b10001100011000110001100011000101110; // U
            8'd83: bitmap = 35'b01111100001000001110000010000111110; // S
            8'd84: bitmap = 35'b11111001000010000100001000010000100; // T
            8'd69: bitmap = 35'b11111100001000011110100001000011111; // E
            8'd78: bitmap = 35'b10001110011100110101100111001110001; // N
            8'd68: bitmap = 35'b11110100011000110001100011000111110; // D
            default: bitmap = 35'd0;
        endcase
        case (row)
            3'd0: row_bits = bitmap[34:30];
            3'd1: row_bits = bitmap[29:25];
            3'd2: row_bits = bitmap[24:20];
            3'd3: row_bits = bitmap[19:15];
            3'd4: row_bits = bitmap[14:10];
            3'd5: row_bits = bitmap[9:5];
            3'd6: row_bits = bitmap[4:0];
            default: row_bits = 5'd0;
        endcase
    end
endmodule
`default_nettype wire
