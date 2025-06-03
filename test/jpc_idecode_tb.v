`timescale 1ns/1ns

`include "jpc_config.v"

// TESTS_EXPECTED:
// TEST:ID001
// TEST:ID002
// TEST:ID003
// TEST:ID004
// TEST:ID005
// TEST:ID006
// TEST:ID007
// TEST:ID008
// TEST:ID009
// TEST:ID010
// TEST:ID011
// TEST:ID012
// TEST:ID013
// TEST:ID014
// TEST:ID015
// TEST:ID016
// TEST:ID017
// TEST:ID018
// TEST:ID019
// TEST:ID020
// TEST:ID021
// TEST:ID022
// TEST:ID023
// TEST:ID024
// TEST:ID025
// TEST:ID026
// TEST:ID027
// TEST:ID028
// TEST:ID029
// TEST:ID030
// TEST:ID031
// TEST:ID032
// TEST:ID033
// TEST:ID034
// TEST:ID035
// TEST:ID036
// TEST:ID037
// TEST:ID038
// TEST:ID039



module jpc_ifetch_tb;

    // Testbench parameters
    parameter CLK_PERIOD = 10; // Clock period in nanoseconds
    parameter CLK_HPERIOD = 5; // Half-Clock period in nanoseconds
    `include "jpc_time_to_cycles.v"

    reg clk;
    reg rst;
    
    reg [`JPC_INSTRUCTION_WIDTH-1:0] instr;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [4:0] rd;
    wire [31:0] imm;
    wire [11:0] imm12;
    wire [12:0] imm13;
    wire [19:0] imm20;
    wire [20:0] imm21;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;
    wire ecall, ebreak, fence, fence_i, error;

    string assert_msg = "";
    `include "jpc_assert.v"

    jpc_idecode uut (
        .instr_I(instr),

        .opcode_O(opcode),
        .funct3_O(funct3),
        .rd_O(rd),
        .imm32_O(imm),
        .rs1_O(rs1),
        .rs2_O(rs2),
        .funct7_O(funct7),

        .ecall_O(ecall),
        .ebreak_O(ebreak),
        .fence_O(fence),
        .fence_i_O(fence_i),
        .error_O(error)
    );
    assign imm12 = imm[11:0];
    assign imm13 = imm[12:0];
    assign imm20 = imm[19:0];
    assign imm21 = imm[20:0];

    // Clock generation
    initial clk = 0;
    always #(CLK_HPERIOD) clk = ~clk; // Clock toggles every half-period

    // Temporary registers for instruction fields
    reg [4:0] irs2;
    reg [4:0] irs1;
    reg [4:0] ird;
    reg [11:0] iimm;
    reg [11:0] iimm12;
    reg [12:0] iimm13;
    reg [19:0] iimm20;
    reg [20:0] iimm21;

    // Test sequence
    initial begin

        $timeformat(-9, 0, "ns", 0);

        // Initialize signals
        rst = 1;
        instr = `JPC_NULL_DATA;
        
        // Keep reset for one clock period
        #(CLK_PERIOD) rst = 0;

        // Check signals at next clock fall
        #(CLK_PERIOD);

        // ------------------------------------------------------------
        // # R-type Instructions
        // ------------------------------------------------------------

        // R-type Instruction: ADD x3, x1, x2
        irs2 = $urandom_range(0, 2**5-1);
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        instr = {7'h00, irs2, irs1, 3'h0, ird, 7'b0110011};
        #10;
        assert_msg = $sformatf("R-type ADD instruction (opcode=%b funct3=%b rd=%b rs1=%b rs2=%b funct7=%b)", opcode, funct3, rd, rs1, rs2, funct7);
        jpc_assert("ID001",
          (opcode == 7'b0110011) && (funct3 == 3'h0) && 
          (rd == ird) && (rs1 == irs1) && (rs2 == irs2) && 
          (funct7 == 7'h00), $time);


        // R-type Instruction: SUB x3, x1, x2
        irs2 = $urandom_range(0, 2**5-1);
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        instr = {7'h20, irs2, irs1, 3'h0, ird, 7'b0110011};
        #10;
        assert_msg = $sformatf("R-type SUB instruction (opcode=%b funct3=%b rd=%b rs1=%b rs2=%b funct7=%b)", opcode, funct3, rd, rs1, rs2, funct7);
        jpc_assert("ID002",
          (opcode == 7'b0110011) && (funct3 == 3'h0) && 
          (rd == ird) && (rs1 == irs1) && (rs2 == irs2) && 
          (funct7 == 7'h20), $time);


        // R-type Instruction: XOR x3, x1, x2
        irs2 = $urandom_range(0, 2**5-1);
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        instr = {7'h00, irs2, irs1, 3'h4, ird, 7'b0110011};
        #10;
        assert_msg = $sformatf("R-type XOR instruction (opcode=%b funct3=%b rd=%b rs1=%b rs2=%b funct7=%b)", opcode, funct3, rd, rs1, rs2, funct7);
        jpc_assert("ID003",
          (opcode == 7'b0110011) && (funct3 == 3'h4) && 
          (rd == ird) && (rs1 == irs1) && (rs2 == irs2) && 
          (funct7 == 7'h00), $time);


        // R-type Instruction: OR x3, x1, x2
        irs2 = $urandom_range(0, 2**5-1);
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        instr = {7'h00, irs2, irs1, 3'h6, ird, 7'b0110011};
        #10;
        assert_msg = $sformatf("R-type OR instruction (opcode=%b funct3=%b rd=%b rs1=%b rs2=%b funct7=%b)", opcode, funct3, rd, rs1, rs2, funct7);
        jpc_assert("ID004",
          (opcode == 7'b0110011) && (funct3 == 3'h6) && 
          (rd == ird) && (rs1 == irs1) && (rs2 == irs2) && 
          (funct7 == 7'h00), $time);

        // R-type Instruction: AND x3, x1, x2
        irs2 = $urandom_range(0, 2**5-1);
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        instr = {7'h00, irs2, irs1, 3'h7, ird, 7'b0110011};
        #10;
        assert_msg = $sformatf("R-type AND instruction (opcode=%b funct3=%b rd=%b rs1=%b rs2=%b funct7=%b)", opcode, funct3, rd, rs1, rs2, funct7);
        jpc_assert("ID005",
          (opcode == 7'b0110011) && (funct3 == 3'h7) && 
          (rd == ird) && (rs1 == irs1) && (rs2 == irs2) && 
          (funct7 == 7'h00), $time);

        // R-type Instruction: SLL x3, x1, x2
        irs2 = $urandom_range(0, 2**5-1);
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        instr = {7'h00, irs2, irs1, 3'h1, ird, 7'b0110011};
        #10;
        assert_msg = $sformatf("R-type SLL instruction (opcode=%b funct3=%b rd=%b rs1=%b rs2=%b funct7=%b)", opcode, funct3, rd, rs1, rs2, funct7);
        jpc_assert("ID006",
          (opcode == 7'b0110011) && (funct3 == 3'h1) && 
          (rd == ird) && (rs1 == irs1) && (rs2 == irs2) && 
          (funct7 == 7'h00), $time);

        // R-type Instruction: SRL x3, x1, x2
        irs2 = $urandom_range(0, 2**5-1);
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        instr = {7'h00, irs2, irs1, 3'h5, ird, 7'b0110011};
        #10;
        assert_msg = $sformatf("R-type SLL instruction (opcode=%b funct3=%b rd=%b rs1=%b rs2=%b funct7=%b)", opcode, funct3, rd, rs1, rs2, funct7);
        jpc_assert("ID007",
          (opcode == 7'b0110011) && (funct3 == 3'h5) && 
          (rd == ird) && (rs1 == irs1) && (rs2 == irs2) && 
          (funct7 == 7'h00), $time);

        // R-type Instruction: SRA x3, x1, x2
        irs2 = $urandom_range(0, 2**5-1);
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        instr = {7'h20, irs2, irs1, 3'h5, ird, 7'b0110011};
        #10;
        assert_msg = $sformatf("R-type SRA instruction (opcode=%b funct3=%b rd=%b rs1=%b rs2=%b funct7=%b)", opcode, funct3, rd, rs1, rs2, funct7);
        jpc_assert("ID008",
          (opcode == 7'b0110011) && (funct3 == 3'h5) && 
          (rd == ird) && (rs1 == irs1) && (rs2 == irs2) && 
          (funct7 == 7'h20), $time);

        // R-type Instruction: SLT x3, x1, x2
        irs2 = $urandom_range(0, 2**5-1);
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        instr = {7'h00, irs2, irs1, 3'h2, ird, 7'b0110011};
        #10;
        assert_msg = $sformatf("R-type SLT instruction (opcode=%b funct3=%b rd=%b rs1=%b rs2=%b funct7=%b)", opcode, funct3, rd, rs1, rs2, funct7);
        jpc_assert("ID009",
          (opcode == 7'b0110011) && (funct3 == 3'h2) && 
          (rd == ird) && (rs1 == irs1) && (rs2 == irs2) && 
          (funct7 == 7'h00), $time);

        // R-type Instruction: SLTU x3, x1, x2
        irs2 = $urandom_range(0, 2**5-1);
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        instr = {7'h00, irs2, irs1, 3'h3, ird, 7'b0110011};
        #10;
        assert_msg = $sformatf("R-type SLTU instruction (opcode=%b funct3=%b rd=%b rs1=%b rs2=%b funct7=%b)", opcode, funct3, rd, rs1, rs2, funct7);
        jpc_assert("ID010",
          (opcode == 7'b0110011) && (funct3 == 3'h3) && 
          (rd == ird) && (rs1 == irs1) && (rs2 == irs2) && 
          (funct7 == 7'h00), $time);


        // ------------------------------------------------------------
        // # I-type Instructions
        // ------------------------------------------------------------


        // I-type Instruction: ADDI rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12, irs1, 3'h0, ird, 7'b0010011};
        #10;
        assert_msg = $sformatf("I-type ADDI instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm12);
        jpc_assert("ID011",
          (opcode == 7'b0010011) && (funct3 == 3'h0) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm12 == iimm12), $time);

        // I-type Instruction: XOR rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12, irs1, 3'h4, ird, 7'b0010011};
        #10;
        assert_msg = $sformatf("I-type XORI instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm12);
        jpc_assert("ID012",
          (opcode == 7'b0010011) && (funct3 == 3'h4) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm12 == iimm12), $time);
        
        // I-type Instruction: OR rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12, irs1, 3'h6, ird, 7'b0010011};
        #10;
        assert_msg = $sformatf("I-type ORI instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm12);
        jpc_assert("ID013",
          (opcode == 7'b0010011) && (funct3 == 3'h6) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm12 == iimm12), $time);
        
        // I-type Instruction: AND rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12, irs1, 3'h7, ird, 7'b0010011};
        #10;
        assert_msg = $sformatf("I-type ANDI instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm12);
        jpc_assert("ID014",
          (opcode == 7'b0010011) && (funct3 == 3'h7) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm12 == iimm12), $time);
        
        // I-type Instruction: SLLI rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm = $urandom_range(0, 2**4-1);
        iimm[11:5] = 7'b0000000;
        instr = {iimm, irs1, 3'h1, ird, 7'b0010011};
        #10;
        assert_msg = $sformatf("I-type SLLI instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm);
        jpc_assert("ID015",
          (opcode == 7'b0010011) && (funct3 == 3'h1) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm == iimm), $time);

        // I-type Instruction: SRLI rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm = $urandom_range(0, 2**4-1);
        iimm[11:5] = 7'b0000000;
        instr = {iimm, irs1, 3'h5, ird, 7'b0010011};
        #10;
        assert_msg = $sformatf("I-type SRLI instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm);
        jpc_assert("ID016",
          (opcode == 7'b0010011) && (funct3 == 3'h5) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm == iimm), $time);

        // I-type Instruction: SRAI rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm = $urandom_range(0, 2**4-1);
        iimm[11:5] = 7'b0100000;
        instr = {iimm, irs1, 3'h5, ird, 7'b0010011};
        #10;
        assert_msg = $sformatf("I-type SRAI instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm);
        jpc_assert("ID017",
          (opcode == 7'b0010011) && (funct3 == 3'h5) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm == iimm), $time);
        
        // I-type Instruction: SLTI rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm = $urandom_range(0, 2**12-1);
        instr = {iimm, irs1, 3'h2, ird, 7'b0010011};
        #10;
        assert_msg = $sformatf("I-type SLTI instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm);
        jpc_assert("ID018",
          (opcode == 7'b0010011) && (funct3 == 3'h2) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm == iimm), $time);

        // I-type Instruction: SLTIU rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12, irs1, 3'h3, ird, 7'b0010011};
        #10;
        assert_msg = $sformatf("I-type SLTIU instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h, irs1=%b, ird=%b, iimm=%h)", opcode, funct3, rd, rs1, imm12, irs1, ird, imm12);
        jpc_assert("ID019", opcode == 7'b0010011, $time);
        jpc_assert("ID019", funct3 == 3'h3, $time);
        jpc_assert("ID019", rd == ird, $time);
        jpc_assert("ID019", rs1 == irs1, $time);
        jpc_assert("ID019", imm12 == iimm12, $time);
        
        // I-type Instruction: JALR rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12, irs1, 3'h0, ird, 7'b1100111};
        #10;
        assert_msg = $sformatf("I-type JALR instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm12);
        jpc_assert("ID020",
          (opcode == 7'b1100111) && (funct3 == 3'h0) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm12 == iimm12), $time);


        // I-type Instruction: LB rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm = $urandom_range(0, 2**12-1);
        instr = {iimm, irs1, 3'h0, ird, 7'b0000011};
        #10;
        assert_msg = $sformatf("I-type LB instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm);
        jpc_assert("ID021",
          (opcode == 7'b0000011) && (funct3 == 3'h0) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm == iimm), $time);
        
        // I-type Instruction: LH rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12, irs1, 3'h1, ird, 7'b0000011};
        #10;
        assert_msg = $sformatf("I-type LH instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm12);
        jpc_assert("ID022",
          (opcode == 7'b0000011) && (funct3 == 3'h1) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm12 == iimm12), $time);

        // I-type Instruction: LW rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12, irs1, 3'h2, ird, 7'b0000011};
        #10;
        assert_msg = $sformatf("I-type LW instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm12);
        jpc_assert("ID023",
          (opcode == 7'b0000011) && (funct3 == 3'h2) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm12 == iimm12), $time);

        // I-type Instruction: LBU rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12, irs1, 3'h4, ird, 7'b0000011};
        #10;
        assert_msg = $sformatf("I-type LBU instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm12);
        jpc_assert("ID024",
          (opcode == 7'b0000011) && (funct3 == 3'h4) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm12 == iimm12), $time);
        
        // I-type Instruction: LHU rd, rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12, irs1, 3'h5, ird, 7'b0000011};
        #10;
        assert_msg = $sformatf("I-type LHU instruction (opcode=%b funct3=%b rd=%b rs1=%b imm=%h)", opcode, funct3, rd, rs1, imm12);
        jpc_assert("ID025",
          (opcode == 7'b0000011) && (funct3 == 3'h5) && 
          (rd == ird) && (rs1 == irs1) && 
          (imm12 == iimm12), $time);

        // I-type Instruction: ECALL
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        iimm12 = 12'h0; // imm12 for ECALL is always 0
        instr = {iimm12, irs1, 3'h0, ird, 7'b1110011};
        #10;
        assert_msg = $sformatf("I-type ECALL instruction (ebreak=%b ecall=%b)", ebreak, ecall);
        jpc_assert("ID026",
          (ecall == 1'b1), $time);
        
        // I-type Instruction: EBREAK
        irs1 = $urandom_range(0, 2**5-1);
        ird = $urandom_range(0, 2**5-1);
        instr = {12'h1, irs1, 3'h0, ird, 7'b1110011};
        #10;
        assert_msg = $sformatf("I-type EBREAK instruction (ebreak=%b ecall=%b)", ebreak, ecall);
        jpc_assert("ID027",
          (ebreak == 1'b1), $time);
        
        // ------------------------------------------------------------
        // # S-type Instructions
        // ------------------------------------------------------------

        // S-type Instruction: SB rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        irs2 = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12[11:5], irs2, irs1, 3'h0, iimm12[4:0] , 7'b0100011};
        #10;
        assert_msg = $sformatf("S-type SB instruction (opcode=%b funct3=%b rs1=%b rs2=%b imm=%h)", opcode, funct3, rs1, rs2, imm12);
        jpc_assert("ID028",
          (opcode == 7'b0100011) && (funct3 == 3'h0) && 
          (rs1 == irs1) && (rs2 == irs2) && 
          (imm12 == iimm12), $time);

        // S-type Instruction: SH rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        irs2 = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12[11:5], irs2, irs1, 3'h1, iimm12[4:0], 7'b0100011};
        #10;
        assert_msg = $sformatf("S-type SH instruction (opcode=%b funct3=%b rs1=%b rs2=%b imm=%h)", opcode, funct3, rs1, rs2, imm12);
        jpc_assert("ID029",
          (opcode == 7'b0100011) && (funct3 == 3'h1) && 
          (rs1 == irs1) && (rs2 == irs2) && 
          (imm12 == iimm12), $time);
        
        // S-type Instruction: SW rs, imm
        irs1 = $urandom_range(0, 2**5-1);
        irs2 = $urandom_range(0, 2**5-1);
        iimm12 = $urandom_range(0, 2**12-1);
        instr = {iimm12[11:5], irs2, irs1, 3'h2, iimm12[4:0], 7'b0100011};
        #10;
        assert_msg = $sformatf("S-type SW instruction (opcode=%b funct3=%b rs1=%b rs2=%b imm=%h)", opcode, funct3, rs1, rs2, imm12);
        jpc_assert("ID030",
          (opcode == 7'b0100011) && (funct3 == 3'h2) && 
          (rs1 == irs1) && (rs2 == irs2) && 
          (imm12 == iimm12), $time);
        

        // ------------------------------------------------------------
        // # B-type Instructions
        // ------------------------------------------------------------


        // B-type Instruction: BEQ rs1, rs2, imm
        irs1 = $urandom_range(0, 2**5-1);
        irs2 = $urandom_range(0, 2**5-1);
        iimm13 = $urandom_range(0, 2**13-1) << 1;
        instr = {iimm13[12], iimm13[10:5], irs2, irs1, 3'h0, iimm13[4:1], iimm13[11], 7'b1100011};
        #10;
        assert_msg = $sformatf("B-type BEQ instruction (opcode=%b funct3=%b rs1=%b rs2=%b imm=%h)", opcode, funct3, rs1, rs2, imm13);
        jpc_assert("ID031",
          (opcode == 7'b1100011) && (funct3 == 3'h0) && 
          (rs1 == irs1) && (rs2 == irs2) && 
          (imm13 == iimm13), $time);
      
        // B-type Instruction: BNE rs1, rs2, imm
        irs1 = $urandom_range(0, 2**5-1);
        irs2 = $urandom_range(0, 2**5-1);
        iimm13 = $urandom_range(0, 2**12-1) << 1;
        instr = {iimm13[12], iimm13[10:5], irs2, irs1, 3'h1, iimm13[4:1], iimm13[11], 7'b1100011};
        #10;
        assert_msg = $sformatf("B-type BNE instruction (opcode=%b funct3=%b rs1=%b rs2=%b imm=%h)", opcode, funct3, rs1, rs2, imm13);
        jpc_assert("ID032",
          (opcode == 7'b1100011) && (funct3 == 3'h1) && 
          (rs1 == irs1) && (rs2 == irs2) && 
          (imm13 == iimm13), $time);
        
        // B-type Instruction: BLT rs1, rs2, imm
        irs1 = $urandom_range(0, 2**5-1);
        irs2 = $urandom_range(0, 2**5-1);
        iimm13 = $urandom_range(0, 2**12-1) << 1;
        instr = {iimm13[12], iimm13[10:5], irs2, irs1, 3'h4, iimm13[4:1], iimm13[11], 7'b1100011};
        #10;
        assert_msg = $sformatf("B-type BLT instr %b -> (opcode=%b funct3=%b rs1=%b rs2=%b imm=%b)", instr, opcode, funct3, rs1, rs2, imm13);
        jpc_assert("ID033",
          (opcode == 7'b1100011) && (funct3 == 3'h4) && 
          (rs1 == irs1) && (rs2 == irs2) && 
          (imm13 == iimm13), $time);
        
        // B-type Instruction: BGE rs1, rs2, imm
        irs1 = $urandom_range(0, 2**5-1);
        irs2 = $urandom_range(0, 2**5-1);
        iimm13 = $urandom_range(0, 2**12-1) << 1;
        instr = {iimm13[12], iimm13[10:5], irs2, irs1, 3'h5, iimm13[4:1], iimm13[11], 7'b1100011};
        #10;
        assert_msg = $sformatf("B-type BGE instruction (opcode=%b funct3=%b rs1=%b rs2=%b imm=%h)", opcode, funct3, rs1, rs2, imm13);
        jpc_assert("ID034",
          (opcode == 7'b1100011) && (funct3 == 3'h5) && 
          (rs1 == irs1) && (rs2 == irs2) && 
          (imm13 == iimm13), $time);
        
        // B-type Instruction: BLTU rs1, rs2, imm
        irs1 = $urandom_range(0, 2**5-1);
        irs2 = $urandom_range(0, 2**5-1);
        iimm13 = $urandom_range(0, 2**12-1) << 1;
        instr = {iimm13[12], iimm13[10:5], irs2, irs1, 3'h6, iimm13[4:1], iimm13[11], 7'b1100011};
        #10;
        assert_msg = $sformatf("B-type BLTU instruction (opcode=%b funct3=%b rs1=%b rs2=%b imm=%h)", opcode, funct3, rs1, rs2, imm13);
        jpc_assert("ID035",
          (opcode == 7'b1100011) && (funct3 == 3'h6) && 
          (rs1 == irs1) && (rs2 == irs2) && 
          (imm13 == iimm13), $time);
        
        // B-type Instruction: BGEU rs1, rs2, imm
        irs1 = $urandom_range(0, 2**5-1);
        irs2 = $urandom_range(0, 2**5-1);
        iimm13 = $urandom_range(0, 2**12-1) << 1;
        instr = {iimm13[12], iimm13[10:5], irs2, irs1, 3'h7, iimm13[4:1], iimm13[11], 7'b1100011};
        #10;
        assert_msg = $sformatf("B-type BGEU instruction (opcode=%b funct3=%b rs1=%b rs2=%b imm=%h)", opcode, funct3, rs1, rs2, imm13);
        jpc_assert("ID036",
          (opcode == 7'b1100011) && (funct3 == 3'h7) && 
          (rs1 == irs1) && (rs2 == irs2) && 
          (imm13 == iimm13), $time);
        

        // ------------------------------------------------------------
        // # U-type Instructions
        // ------------------------------------------------------------


        // U-type Instruction: LUI rd, imm
        ird = $urandom_range(0, 2**5-1);
        iimm20 = $urandom_range(0, 2**20-1);
        instr = {iimm20, ird, 7'b0110111};
        #10;
        assert_msg = $sformatf("U-type LUI instruction (opcode=%b rd=%b imm=%b)", opcode, rd, imm);
        jpc_assert("ID037",
          (opcode == 7'b0110111) && 
          (rd == ird) && 
          (imm == iimm20), $time);
        
        // U-type Instruction: AUIPC rd, imm
        ird = $urandom_range(0, 2**5-1);
        iimm20 = $urandom_range(0, 2**20-1);
        instr = {iimm20, ird, 7'b0010111};
        #10;
        assert_msg = $sformatf("U-type AUIPC instruction (opcode=%b rd=%b imm=%b)", opcode, rd, imm);
        jpc_assert("ID038",
          (opcode == 7'b0010111) && 
          (rd == ird) && 
          (imm == iimm20), $time);
        

        // ------------------------------------------------------------
        // # J-type Instructions
        // ------------------------------------------------------------


        // J-type Instruction: JAL rd, imm
        ird = $urandom_range(0, 2**5-1);
        iimm21 = $urandom_range(0, 2**20-1) << 1;
        instr = {iimm21[20], iimm21[10:1], iimm21[11], iimm21[19:12], ird, 7'b1101111};
        #10;
        assert_msg = $sformatf("J-type JAL instruction (opcode=%b rd=%b imm=%h)", opcode, rd, imm);
        jpc_assert("ID039",
          (opcode == 7'b1101111) && 
          (rd == ird) && 
          (imm21 == iimm21), $time);

        // End of test
        $display("Testbench Completed");
        $finish;
    end

endmodule