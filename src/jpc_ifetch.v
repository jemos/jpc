`include "jpc_config.v"

module jpc_ifetch (
    input  wire                          clk,            // Clock signal
    input  wire                          rst,            // Reset signal
    input  wire                          stall_I,        // Stall signal
    input  wire                          flush_I,        // Flush signal
    input  wire                          branch_taken_I, // Branch signal
    input  wire [`JPC_ADDRESS_WIDTH-1:0] branch_addr_I,  // Branch target address
    input  wire                          trap_taken_I,   // Exception/interrupt signal
    input  wire [`JPC_ADDRESS_WIDTH-1:0] trap_address_I, // Address of exception/interrupt handler
    input  wire [`JPC_ADDRESS_WIDTH-1:0] pc_I,           // Current program counter
    output wire [`JPC_ADDRESS_WIDTH-1:0] next_pc_O,      // Next program counter
    output wire [`JPC_ADDRESS_WIDTH-1:0] mem_addr_O,     // Address to fetch from memory
    input  wire [31:0]                   mem_data_I,     // Instruction fetched from memory
    output reg  [31:0]                   instr_O         // Instruction to decode
);

    // Next PC calculation
    assign mem_addr_O = pc_I;
    assign next_pc_O = stall_I ? pc_I :
                       flush_I ? pc_I :
                       trap_taken_I ? trap_address_I : 
                       branch_taken_I ? branch_addr_I : 
                       pc_I + `JPC_INSTRUCTION_WIDTH;

    // Fetch instruction logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            instr_O <= 32'b0;                 // Reset instruction
        end else if (flush_I) begin
            instr_O <= 32'b0;                 // Clear instruction on flush
        end else if (!stall_I) begin
            instr_O <= mem_data_I;            // Fetch new instruction
        end
    end

endmodule
