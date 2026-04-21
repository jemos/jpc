`include "jpc_config.v"

//
// JPC Register File Module
//
// This module implements a register file for the JPC architecture. It supports reading and writing
// to registers, as well as handling special cases like EBREAK and ECALL.
//
// It is a register file that allows two simultaneous operations which can be read or write.
//
// Reference:
// https://github.com/jameslzhu/riscv-card
//

`define JPC_REGFILE_STATE_WIDTH        3
`define JPC_REGFILE_STATE_IDLE         3'b000
`define JPC_REGFILE_STATE_WAIT_IDX     3'b001
`define JPC_REGFILE_STATE_READ         3'b010
`define JPC_REGFILE_STATE_WRITE        3'b011

module jpc_regfile (
    // Clock and reset
    input  wire                          clk,
    input  wire                          rst,

    // Register operation interface 1
    input  wire                          r1_idx_op_I,
    input  wire [4:0]                    r1_idx_I,
    input  wire                          r1_idx_valid_I,
    output wire                          r1_idx_ready_O,

    input  wire [4:0]                    r1_rdata_ready_I,
    output wire [`JPC_REGDATA_WIDTH-1:0] r1_rdata_O,
    output wire                          r1_rdata_valid_O,

    output wire                          r1_wdata_ready_O,
    input  wire [`JPC_REGDATA_WIDTH-1:0] r1_wdata_I,
    input  wire                          r1_wdata_valid_I,

    // Register operation interface 2
    input  wire                          r2_idx_op_I,
    input  wire [4:0]                    r2_idx_I,
    input  wire [4:0]                    r2_idx_valid_I,
    output wire                          r2_idx_ready_O,

    input  wire [4:0]                    r2_data_ready_I,
    output wire [`JPC_REGDATA_WIDTH-1:0] r2_data_O,
    output wire                          r2_data_valid_O
);

    // Register file: 32 registers, width from config
    reg [`JPC_REGDATA_WIDTH-1:0] regs[31:0];

    // State machine for port 1
    reg [`JPC_REGFILE_STATE_WIDTH-1:0] r1_state;

    // Port 1 signals
    reg r1_idx_ready;
    reg [`JPC_REGDATA_WIDTH-1:0] r1_rdata;
    reg r1_rdata_valid;
    reg r1_wdata_ready;

    // Assign outputs
    assign r1_idx_ready_O   = r1_idx_ready;
    assign r1_rdata_O       = r1_rdata;
    assign r1_rdata_valid_O = r1_rdata_valid;
    assign r1_wdata_ready_O = r1_wdata_ready;

    // Reset and register logic
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= {`JPC_REGDATA_WIDTH{1'b0}};
            end

            r1_idx_ready   <= 1'b1;
            r1_rdata       <= {`JPC_REGDATA_WIDTH{1'b0}};
            r1_rdata_valid <= 1'b0;
            r1_wdata_ready <= 1'b1;

            r1_state <= `JPC_REGFILE_STATE_IDLE;
            
        end else
        begin
            
            case (r1_state)
            `JPC_REGFILE_STATE_IDLE: begin
                // Default state, ready to accept new operations
                r1_idx_ready   <= 1'b1;
                r1_rdata       <= {`JPC_REGDATA_WIDTH{1'b0}};
                r1_rdata_valid <= 1'b0;
                r1_wdata_ready <= 1'b1;

                r1_state <= `JPC_REGFILE_STATE_WAIT_IDX;
            end
            `JPC_REGFILE_STATE_WAIT_IDX: begin

                if ( r1_idx_valid_I ) begin

                    r1_idx_ready   <= 1'b0; // Not ready to accept new index

                    // Read operation
                    if ( r1_idx_op_I == 1'b0 ) begin

                        // If the rdata is ready, we can return the data immediately
                        if ( r1_rdata_ready_I ) begin
                            r1_rdata       <= regs[r1_idx_I];
                            r1_rdata_valid <= 1'b1;
                            r1_state <= `JPC_REGFILE_STATE_IDLE;
                        end else begin
                            r1_rdata       <= r1_rdata;
                            r1_rdata_valid <= 1'b0;
                            r1_state <= `JPC_REGFILE_STATE_READ;
                        end

                    // Write operation
                    end else if ( r1_idx_op_I == 1'b1 ) begin

                        // If the wdata is valid, we can write the data immediately
                        if ( r1_wdata_valid_I ) begin
                            if ( r1_idx_I != 5'd0 ) begin
                                regs[r1_idx_I] <= r1_wdata_I;
                            end
                            r1_state <= `JPC_REGFILE_STATE_IDLE;
                        end else begin
                            r1_state <= `JPC_REGFILE_STATE_WRITE;
                        end

                    end

                end else begin
                    // No valid idx/op yet, stay in wait state
                    r1_state <= `JPC_REGFILE_STATE_WAIT_IDX;
                end
            end
            `JPC_REGFILE_STATE_READ: begin
                // Waiting for read data to be ready
                if (r1_rdata_ready_I) begin
                    r1_rdata       <= regs[r1_idx_I];
                    r1_rdata_valid <= 1'b1;
                    r1_state       <= `JPC_REGFILE_STATE_IDLE;
                end else begin
                    r1_rdata_valid <= 1'b0;
                    r1_state       <= `JPC_REGFILE_STATE_READ;
                end
            end
            `JPC_REGFILE_STATE_WRITE: begin
                // Waiting for write data to be valid
                if (r1_wdata_valid_I) begin
                    regs[r1_idx_I] <= r1_wdata_I;
                    r1_state       <= `JPC_REGFILE_STATE_IDLE;
                end else begin
                    r1_state       <= `JPC_REGFILE_STATE_WRITE;
                end
            end
            default: begin
                // Fallback to idle state
                r1_state <= `JPC_REGFILE_STATE_IDLE;
            end
            endcase
        end
    end

endmodule