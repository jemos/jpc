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
    input  wire [31:0] instr_I,  // 32-bit instruction
    output reg  [4:0]  rs1_O,          // Source register 1
    output reg  [4:0]  rs2_O,          // Source register 2
    output reg  [4:0]  rd_O,           // Destination register
    output reg  [6:0]  opcode_O,       // Opcode
    output reg  [2:0]  funct3_O,       // funct3 field
    output reg  [6:0]  funct7_O,       // funct7 field
    output reg  [31:0] imm_O,          // Immediate value (sign-extended)
    output reg         ecall_O,
    output reg         ebreak_O,
    output reg         fence_O,
    output reg         fence_i_O,
    output reg         error_O         // Instruction decoder error
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
        case (opcode)

        	// I-type (ALU immediate, Load)
            7'b0010011, 7'b0000011:
                imm_O = {{20{instr_I[31]}}, instr_I[31:20]};

            // B-type (Branch)
            7'b1100011: 
                imm_O = {{19{instr_I[31]}}, instr_I[31], instr_I[7], instr_I[30:25], instr_I[11:8], 1'b0};

            // S-type (Store)
            7'b0100011: 
                imm_O = {{20{instr_I[31]}}, instr_I[31:25], instr_I[11:7]};

            // U-type (LUI, AUIPC)
            7'b0110111, 7'b0010111: 
                imm_O = {instr_I[31:12], 12'b0};

            // J-type (JAL)
            7'b1101111: 
                imm_O = {{11{instr_I[31]}}, instr_I[31], instr_I[19:12], instr_I[20], instr_I[30:21], 1'b0};

            // I-type (JALR)
            7'b1100111: begin // JALR
                rd = instruction[11:7];
                rs1 = instruction[19:15];
                imm = {{20{instruction[31]}}, instruction[31:20]};
                // Ensure funct3 is valid (should always be 000)
                if (funct3 != 3'b000)
                    error_O = 1'b1;

            // ECALL, EBREAK
            7'b1110011: begin 
                if (instruction[31:20] == 12'b000000000000) begin
                    ecall = 1'b1; // Environment Call
                end else if (instruction[31:20] == 12'b000000000001) begin
                    ebreak = 1'b1; // Breakpoint
                end else begin
                    error_O = 1'b1; // Invalid encoding
                end
            end

            // FENCE, FENCE.I
            7'b0001111: begin 
                case (funct3)
                    3'b000: fence = 1'b1;    // FENCE
                    3'b001: fence_i = 1'b1; // FENCE.I
                    default: error_O = 1'b1;
                endcase
            end
            default:
                // Decode error, invalid instruction
                error_O = 1'b1;
                imm = 32'b0;
        endcase
    end

endmodule
