`include "jpc_config.v"

`define JPC_IFETCH_STATE_WIDTH        3
`define JPC_IFETCH_STATE_IDLE         3'b000
`define JPC_IFETCH_STATE_PC_VALID     3'b001
`define JPC_IFETCH_STATE_ADDR_READY   3'b011
`define JPC_IFETCH_STATE_DATA_VALID   3'b010
`define JPC_IFETCH_STATE_INSTR_READY  3'b110

module jpc_ifetch (

    // Clock and reset
    input  wire                          clk,
    input  wire                          rst,

    // Current PC value (comes from an external register)
    input  wire [`JPC_ADDRESS_WIDTH-1:0] pc_I,
    output reg                           pc_ready_O,
    input  wire                          pc_valid_I,

    // Instruction memory read signals (address, read enable, data, and ready signal)
    output reg [`JPC_MEMADDR_WIDTH-1:0]  mem_addr_O,
    output reg                           mem_addr_valid_O,
    input  wire                          mem_addr_ready_I,
    input  wire [`JPC_MEMDATA_WIDTH-1:0] mem_data_I,
    input  wire                          mem_data_valid_I,
    output reg                           mem_data_ready_O,

    // Instruction output
    output reg [`JPC_INSTRUCTION_WIDTH-1:0] instr_O,
    input  wire                             instr_ready_I,
    output reg                              instr_valid_O
);

    // Local register for storing the next_pc
    reg [`JPC_ADDRESS_WIDTH-1:0] next_pc;
    reg [`JPC_ADDRESS_WIDTH-1:0] next_instr;
    reg [`JPC_IFETCH_STATE_WIDTH-1:0] curr_state;

    // Instruction fetch logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin

            // Clear output flow state signals
            mem_addr_valid_O <= 1'b0;
            instr_valid_O <= 1'b0;
            mem_data_ready_O <= 1'b0;
            pc_ready_O <= 1'b0;
            curr_state <= `JPC_IFETCH_STATE_IDLE;

        end
        else begin

            // Default assignment
            mem_addr_valid_O <= mem_addr_valid_O;
            instr_valid_O <= instr_valid_O;
            mem_addr_valid_O <= mem_addr_valid_O;
            pc_ready_O <= pc_ready_O;
            curr_state <= curr_state;

            case (curr_state)
                `JPC_IFETCH_STATE_IDLE: begin
                    // We're ready to receive a PC value
                    pc_ready_O <= 1'b1;
                    mem_addr_valid_O <= 1'b0;
                    instr_valid_O <= 1'b0;
                    mem_data_ready_O <= 1'b0;
                    curr_state <= `JPC_IFETCH_STATE_PC_VALID;
                end
                `JPC_IFETCH_STATE_PC_VALID: begin
                    if (pc_valid_I == 1'b1) begin
                        next_pc <= pc_I;
                        pc_ready_O <= 1'b0;

                        // Skip one state if mem_addr_ready_I is asserted.
                        if (mem_addr_ready_I == 1'b1) begin
                            mem_addr_O <= pc_I;
                            mem_addr_valid_O <= 1'b1;
                            mem_data_ready_O <= 1'b1;
                            curr_state <= `JPC_IFETCH_STATE_DATA_VALID;
                        end else begin
                            curr_state <= `JPC_IFETCH_STATE_ADDR_READY;
                        end
                    end
                end
                `JPC_IFETCH_STATE_ADDR_READY: begin
                    if (mem_addr_ready_I == 1'b1) begin
                        mem_addr_O <= next_pc;
                        mem_addr_valid_O <= 1'b0;
                        mem_data_ready_O <= 1'b1;
                        curr_state <= `JPC_IFETCH_STATE_DATA_VALID;
                    end
                end
                `JPC_IFETCH_STATE_DATA_VALID: begin
                    if (mem_data_valid_I == 1'b1) begin
                        next_instr <= mem_data_I;
                        mem_addr_valid_O <= 1'b0;
                        mem_data_ready_O <= 1'b0;

                        // Skip one state if instr_ready_I is asserted.
                        if (instr_ready_I == 1'b1) begin
                            instr_O <= mem_data_I;
                            instr_valid_O <= 1'b1;
                            curr_state <= `JPC_IFETCH_STATE_IDLE;
                        end else begin
                            curr_state <= `JPC_IFETCH_STATE_INSTR_READY;
                        end
                    end
                end
                `JPC_IFETCH_STATE_INSTR_READY: begin
                    if (instr_ready_I == 1'b1) begin
                        instr_O <= next_instr;
                        instr_valid_O <= 1'b1;
                        curr_state <= `JPC_IFETCH_STATE_IDLE;
                    end
                end
                default: begin
                    mem_addr_valid_O <= 1'b0;
                    instr_valid_O <= 1'b0;
                    mem_addr_valid_O <= 1'b0;
                    pc_ready_O <= 1'b0;
                    curr_state <= `JPC_IFETCH_STATE_IDLE;
                end
            endcase
        end
    end

endmodule
