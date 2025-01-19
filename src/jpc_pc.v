
`timescale 1ns / 1ps

module jpc_pc (
    input wire clk,                // Clock signal
    input wire rst,                // Reset signal
    input wire [31:0] next_pc_I,     // Next PC value (from branch/jump logic)
    input wire pc_enable_I,          // Control signal to enable PC update
    output reg [31:0] pc_O           // Current PC value
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_O <= 32'b0;           // Reset PC to 0
        end else if (pc_enable_I) begin
            pc_O <= next_pc_I;         // Update PC with the next value
        end
    end

endmodule
