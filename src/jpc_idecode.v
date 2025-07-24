`include "jpc_config.v"

//
// JPC Instruction Decode Module
//
// Decodes the instruction bits into it's different components.
// It's possible to define direct decoding logic for all components except for immediate.
// The immediate has different locations depending on the instruction format (e.g., R, I, S, B, U, J).
//
// In case of EBREAK and ECALL, the instruction is decoded as a special case. It will
// simply set the ecall_O or ebreak_O output signals to 1, and the rest of the fields will be set to 0.
//
// Reference:
// https://github.com/jameslzhu/riscv-card
//

`define JPC_IDECODE_STATE_WIDTH        3
`define JPC_IDECODE_STATE_IDLE         3'b000
`define JPC_IDECODE_STATE_WAIT_INSTR   3'b001
`define JPC_IDECODE_STATE_WAIT_DECODE  3'b011


module jpc_idecode(
    // Clock and reset
    input  wire        clk,
    input  wire        rst,

    // Inputs
    input  wire [31:0] instr_I,
    input  wire        instr_valid_I,
    input  wire        decode_ready_I,

    // Outputs
    output reg         instr_ready_O,

    output reg  [6:0]  opcode_O,
    output reg  [2:0]  funct3_O,
    output reg  [4:0]  rd_O,
    output reg  [31:0] imm32_O,

    output reg  [4:0]  rs1_O,
    output reg  [4:0]  rs2_O,
    
    output reg  [6:0]  funct7_O,
    
    output reg         ecall_O,
    output reg         ebreak_O,
    output reg         fence_O,
    output reg         fence_i_O,

    // Error output
    output reg         error_O,

    // Valid output signal
    output reg         decode_valid_O
);

    // Internal register to hold the captured instruction
    reg [31:0] instr_reg;
    reg        instr_reg_valid;

    // Internal wires for decoded fields
    reg [6:0]  opcode_dec;
    reg [2:0]  funct3_dec;
    reg [4:0]  rd_dec;
    reg [31:0] imm32_dec;
    reg [4:0]  rs1_dec;
    reg [4:0]  rs2_dec;
    reg [6:0]  funct7_dec;
    reg        ecall_dec;
    reg        ebreak_dec;
    reg        fence_dec;
    reg        fence_i_dec;
    reg        error_dec;

    reg [`JPC_IDECODE_STATE_WIDTH-1:0] curr_state;

    // Instruction ready when not holding a valid instruction
    //assign instr_ready_O = ~instr_reg_valid;

    // Combinational decode logic (from instr_reg)
    always @(*) begin
        // Default values
        opcode_dec    = 7'b0;
        funct3_dec    = 3'b0;
        rd_dec        = 5'b0;
        imm32_dec     = 32'b0;
        rs1_dec       = 5'b0;
        rs2_dec       = 5'b0;
        funct7_dec    = 7'b0;
        ecall_dec     = 1'b0;
        ebreak_dec    = 1'b0;
        fence_dec     = 1'b0;
        fence_i_dec   = 1'b0;
        error_dec     = 1'b0;

        opcode_dec    = instr_reg[6:0];
        rd_dec        = instr_reg[11:7];
        funct3_dec    = instr_reg[14:12];
        rs1_dec       = instr_reg[19:15];
        rs2_dec       = instr_reg[24:20];
        funct7_dec    = instr_reg[31:25];

        case (instr_reg[6:0])
            // I-type (ALU immediate, Load)
            7'b0010011, 7'b0000011:
                imm32_dec = {{20{instr_reg[31]}}, instr_reg[31:20]};

            // B-type (Branch)
            7'b1100011: 
                imm32_dec = {{19{instr_reg[31]}}, instr_reg[31], instr_reg[7], instr_reg[30:25], instr_reg[11:8], 1'b0};

            // S-type (Store)
            7'b0100011: 
                imm32_dec = {{20{instr_reg[31]}}, instr_reg[31:25], instr_reg[11:7]};

            // U-type (LUI, AUIPC)
            7'b0110111, 7'b0010111: 
                imm32_dec = {12'b0, instr_reg[31:12]};

            // J-type (JAL)
            7'b1101111: 
                imm32_dec = {{11{instr_reg[31]}}, instr_reg[31], instr_reg[19:12], instr_reg[20], instr_reg[30:21], 1'b0};

            // I-type (JALR)
            7'b1100111: begin
                rd_dec = instr_reg[11:7];
                rs1_dec = instr_reg[19:15];
                imm32_dec = {{20{instr_reg[31]}}, instr_reg[31:20]};
                // Ensure funct3 is valid (should always be 000)
                if (instr_reg[14:12] != 3'b000) begin
                    error_dec = 1'b1;
                end
            end

            // ECALL, EBREAK
            7'b1110011: begin 
                if (instr_reg[31:20] == 12'b000000000000) begin
                    // Environment Call
                    ecall_dec = 1'b1;
                end else if (instr_reg[31:20] == 12'b000000000001) begin
                    // Breakpoint
                    ebreak_dec = 1'b1; 
                end else begin
                    // Invalid encoding
                    error_dec = 1'b1;
                end
            end

            // FENCE, FENCE.I
            7'b0001111: begin 
                case (instr_reg[14:12])
                    // FENCE
                    3'b000: fence_dec = 1'b1;  

                    // FENCE.I  
                    3'b001: fence_i_dec = 1'b1;

                    default:
                    // Invalid encoding
                    error_dec = 1'b1;
                endcase
            end

            default: begin
                // Decode error, invalid instruction
                error_dec = 1'b1;
                imm32_dec = 32'b0;
            end
        endcase
    end

    // Sequential logic for capturing instruction and outputting decoded fields
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            instr_reg <= 32'b0;
            instr_reg_valid <= 1'b0;
            instr_ready_O <= 1'b1;

            opcode_O <= 7'b0;
            funct3_O <= 3'b0;
            rd_O <= 5'b0;
            imm32_O <= 32'b0;
            rs1_O <= 5'b0;
            rs2_O <= 5'b0;
            funct7_O <= 7'b0;
            ecall_O <= 1'b0;
            ebreak_O <= 1'b0;
            fence_O <= 1'b0;
            fence_i_O <= 1'b0;
            error_O <= 1'b0;
            decode_valid_O <= 1'b0;
            
            curr_state <= `JPC_IDECODE_STATE_IDLE; // Reset to idle state

        end else begin

            // Default assignment
            instr_ready_O <= 1'b0;
            decode_valid_O <= 1'b0;
            opcode_O <= opcode_O;
            funct3_O <= funct3_O;
            rd_O <= rd_O;
            imm32_O <= imm32_O;
            rs1_O <= rs1_O;
            rs2_O <= rs2_O;
            funct7_O <= funct7_O;
            ecall_O <= ecall_O;
            ebreak_O <= ebreak_O;
            fence_O <= fence_O;
            fence_i_O <= fence_i_O;
            error_O <= error_O;
            curr_state <= `JPC_IDECODE_STATE_IDLE;

            case (curr_state)
                `JPC_IDECODE_STATE_IDLE: begin
                    // We're ready to receive a new instruction
                    instr_ready_O <= 1'b1;
                    curr_state <= `JPC_IDECODE_STATE_WAIT_INSTR;
                end
                `JPC_IDECODE_STATE_WAIT_INSTR: begin
                    if (instr_valid_I == 1'b1) begin
                        // Capture the instruction
                        instr_reg <= instr_I;
                        instr_ready_O <= 1'b0;
                        curr_state <= `JPC_IDECODE_STATE_WAIT_DECODE;

                        // Skip one state if decode_ready_I is asserted.
                        if (decode_ready_I == 1'b1) begin
                            // Propagate the decoded values to the output
                            opcode_O   <= opcode_dec;
                            funct3_O   <= funct3_dec;
                            rd_O       <= rd_dec;
                            imm32_O    <= imm32_dec;
                            rs1_O      <= rs1_dec;
                            rs2_O      <= rs2_dec;
                            funct7_O   <= funct7_dec;
                            ecall_O    <= ecall_dec;
                            ebreak_O   <= ebreak_dec;
                            fence_O    <= fence_dec;
                            fence_i_O  <= fence_i_dec;
                            error_O    <= error_dec;

                            decode_valid_O <= 1'b1;

                            // Go back to idle state after decoding
                            curr_state <= `JPC_IDECODE_STATE_IDLE;
                        end else begin
                            curr_state <= `JPC_IDECODE_STATE_WAIT_DECODE;
                        end
                    end else
                    begin
                        // If no instruction is valid, stay in the same state
                        instr_ready_O <= 1'b1;
                        curr_state <= `JPC_IDECODE_STATE_WAIT_INSTR;
                    end
                end
                `JPC_IDECODE_STATE_WAIT_DECODE: begin
                    if (decode_ready_I == 1'b1) begin

                        // Propagate the decoded values to the output
                        opcode_O   <= opcode_dec;
                        funct3_O   <= funct3_dec;
                        rd_O       <= rd_dec;
                        imm32_O    <= imm32_dec;
                        rs1_O      <= rs1_dec;
                        rs2_O      <= rs2_dec;
                        funct7_O   <= funct7_dec;
                        ecall_O    <= ecall_dec;
                        ebreak_O   <= ebreak_dec;
                        fence_O    <= fence_dec;
                        fence_i_O  <= fence_i_dec;
                        error_O    <= error_dec;

                        decode_valid_O <= 1'b1;

                        // Go back to idle state after decoding
                        curr_state <= `JPC_IDECODE_STATE_IDLE;
                    end else
                    begin
                        decode_valid_O <= 1'b0;
                        curr_state <= `JPC_IDECODE_STATE_WAIT_DECODE;
                    end
                end
                default: begin
                    // In case of an unexpected state, reset to idle
                    curr_state <= `JPC_IDECODE_STATE_IDLE;
                end
            endcase
        end
    end
endmodule
