
`timescale 1ns / 1ps

module jpc_pc (
    input   wire                          clk,       // Clock signal
    input   wire                          rst,       // Reset signal
    input   wire [`JPC_ADDRESS_WIDTH-1:0] next_pc_I, // Next PC value (from branch/jump logic)
    input   wire                          en_I,      // Control signal to enable PC update
    output  reg [`JPC_ADDRESS_WIDTH-1:0]  pc_O       // Current PC value
);

    // Internal signal for handling endianness conversion
    wire [`JPC_ADDRESS_WIDTH-1:0] adjusted_next_pc;

    // Handle endianness
    generate
        if (`JPC_ENDIANNESS == "BIG") begin
            assign adjusted_next_pc = {next_pc_I[7:0], next_pc_I[15:8], next_pc_I[23:16], next_pc_I[31:24]};
        end else begin
            assign adjusted_next_pc = next_pc_I; // LITTLE endian (default)
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_O <= {`JPC_ADDRESS_WIDTH{1'b0}};  // Reset PC to 0
        end else if (en_I) begin
            pc_O <= adjusted_next_pc;   // Update PC with the adjusted value
        end
    end

endmodule
