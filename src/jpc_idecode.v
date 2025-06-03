`include "jpc_config.v"

//
// JPC Instruction Decode Module
//
// Decodes the instruction bits into it's different components. As can be seen,
// it's possible to define direct decoding logic for all components except for immediate.
// The immediate has different locations depending on the instruction format (e.g., R, I, S, B, U, J).
//
// Reference:
// https://github.com/jameslzhu/riscv-card
//

module jpc_idecode(
    input  wire [31:0] instr_I,
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
    output reg         error_O
);

    always @(*) begin
        // Extract fields from the instruction
        opcode_O    = instr_I[6:0];
        rd_O        = instr_I[11:7];
        funct3_O    = instr_I[14:12];
        rs1_O       = instr_I[19:15];
        rs2_O       = instr_I[24:20];
        funct7_O    = instr_I[31:25];
        error_O     = 1'b0;
        ecall_O     = 1'b0;
        ebreak_O    = 1'b0;
        fence_O     = 1'b0;
        fence_i_O   = 1'b0;

        // Generate immediate value based on the instruction type
        case (opcode_O)

        	// I-type (ALU immediate, Load)
            7'b0010011, 7'b0000011:
                imm32_O = {{20{instr_I[31]}}, instr_I[31:20]};

            // B-type (Branch)
            7'b1100011: 
                imm32_O = {{19{instr_I[31]}}, instr_I[31], instr_I[7], instr_I[30:25], instr_I[11:8], 1'b0};

            // S-type (Store)
            7'b0100011: 
                imm32_O = {{20{instr_I[31]}}, instr_I[31:25], instr_I[11:7]};

            // U-type (LUI, AUIPC)
            7'b0110111, 7'b0010111: 
                imm32_O = {12'b0, instr_I[31:12]};

            // J-type (JAL)
            7'b1101111: 
                imm32_O = {{11{instr_I[31]}}, instr_I[31], instr_I[19:12], instr_I[20], instr_I[30:21], 1'b0};

            // I-type (JALR)
            7'b1100111: begin
                rd_O = instr_I[11:7];
                rs1_O = instr_I[19:15];
                imm32_O = {{20{instr_I[31]}}, instr_I[31:20]};
                // Ensure funct3 is valid (should always be 000)
                if (funct3_O != 3'b000) begin
                    error_O = 1'b1;
                end
            end

            // ECALL, EBREAK
            7'b1110011: begin 
                if (instr_I[31:20] == 12'b000000000000) begin
                    // Environment Call
                    ecall_O = 1'b1;
                end else if (instr_I[31:20] == 12'b000000000001) begin
                    // Breakpoint
                    ebreak_O = 1'b1; 
                end else begin
                    // Invalid encoding
                    error_O = 1'b1;
                end
            end

            // FENCE, FENCE.I
            7'b0001111: begin 
                case (funct3_O)
                    // FENCE
                    3'b000: fence_O = 1'b1;  

                    // FENCE.I  
                    3'b001: fence_i_O = 1'b1;

                    default:
                    // Invalid encoding
                    error_O = 1'b1;
                endcase
            end

            default: begin
                // Decode error, invalid instruction
                error_O = 1'b1;
                imm32_O = 32'b0;
            end
        endcase
    end

endmodule
