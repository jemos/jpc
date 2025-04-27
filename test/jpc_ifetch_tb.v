`include "jpc_config.v"

// TESTS_EXPECTED:
// TEST:IF001
// TEST:IF002
// TEST:IF003
// TEST:IF004
// TEST:IF005
// TEST:IF006

`timescale 1ns/1ns

module jpc_ifetch_tb;

    // Testbench parameters
    parameter CLK_PERIOD = 10; // Clock period in nanoseconds
    parameter CLK_HPERIOD = 5; // Half-Clock period in nanoseconds
    `include "jpc_time_to_cycles.v"

    reg clk;
    reg rst;
    
    // PC signals
    reg [`JPC_ADDRESS_WIDTH-1:0] pc;
    reg pc_valid;
    reg pc_ready;

    // Memory signals
    wire [`JPC_ADDRESS_WIDTH-1:0] mem_addr;
    wire mem_addr_valid;
    reg mem_addr_ready;
    wire [`JPC_MEMDATA_WIDTH-1:0] mem_data;
    reg mem_data_valid = 1'b0;
    wire mem_data_ready;

    // Instruction signals
    wire [`JPC_INSTRUCTION_WIDTH-1:0] instr;
    wire instr_valid;
    reg instr_ready;

    string assert_msg;
    `include "jpc_assert.v"
    
    // Instantiate the Instruction Fetch module
    reg mem_valid;
    jpc_ifetch uut (
        .clk(clk),
        .rst(rst),

        // Program Counter signals
        .pc_I(pc),
        .pc_valid_I(pc_valid),
        .pc_ready_O(pc_ready),

        // Instruction signals
        .instr_O(instr),
        .instr_valid_O(instr_valid),
        .instr_ready_I(instr_ready),

        // Memory interface
        .mem_addr_O(mem_addr),
        .mem_addr_valid_O(mem_addr_valid),
        .mem_addr_ready_I(mem_addr_ready),
        .mem_data_I(mem_data),
        .mem_data_valid_I(mem_data_valid),
        .mem_data_ready_O(mem_data_ready)
    );

    // Instantiate the BRAM module
    jpc_32bram #(
        .DEPTH(256)
    ) instruction_bram (
        .clk(clk),
        .addr(mem_addr),
        .din(32'b0), // No writing in this testbench
        .we(1'b0),   // No writing in this testbench
        .dout(mem_data)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_HPERIOD) clk = ~clk; // Clock toggles every half-period

    // Test sequence
    initial begin

        $timeformat(-9, 0, "ns", 0);

        // Initialize signals
        rst = 1;
        pc = `JPC_NULL_ADDRESS;
        pc_valid = 1'b0;
        instr_ready = 1'b0;
        mem_addr_ready = 1'b0; // tell dut mem addr not ready

        // Keep reset for one clock period
        #(CLK_PERIOD) rst = 0;

        // Check signals at next clock fall
        #(CLK_PERIOD);
        
        // Test 1: Confirm reset was done properly: output instr_valid is cleared.
        assert_msg = $sformatf("Reset did not clear instr_valid (instr_valid=%b)", instr_valid);
        jpc_assert("IF001", instr_valid == 0, $time);

        // Test 2: DUT is not attempting to read memory
        assert_msg = $sformatf("Trying to read memory after reset (mem_addr_valid=%b, mem_data_ready=%b).", mem_addr_valid, mem_data_ready);
        jpc_assert("IF002", mem_addr_valid == 0 && mem_data_ready == 0, $time);

        // Test 3: Check if it's ready to receive a PC
        assert_msg = $sformatf("Not ready to receive PC (pc_ready=%b).", pc_ready);
        jpc_assert("IF003", pc_ready == 1'b1, $time);

        // Pass a null program counter and assert memory address ready.
        pc = `JPC_NULL_ADDRESS;
        pc_valid = 1'b1;
        mem_addr_ready = 1'b1;
        instr_ready = 1'b1;

        // Let it capture the new program counter
        #(CLK_PERIOD);

        // Clear PC valid right after.
        pc_valid = 1'b0;

        // Test 4: Check that it will load an address to the memory interface
        assert_msg = $sformatf("Not loading memory address (mem_addr_valid=%b)", mem_addr_valid);
        jpc_assert("IF004", mem_addr_valid == 1'b1, $time);

        // Wait for memory read at minimum, one cycle.
        mem_data_valid = 1'b0;
        #(CLK_PERIOD);
        mem_data_valid = 1'b1;
        #(CLK_PERIOD);

        // Test 5: Check that the instruction was fetched
        assert_msg = $sformatf("Not fetched the instruction (instr_valid=%b)", instr_valid);
        jpc_assert("IF005", instr_valid == 1'b1, $time);

        // Test 6: Check that the right instruction is at instr_O
        assert_msg = $sformatf("Incorrect instruction fetched (instr=%h)", instr);
        jpc_assert("IF006", instr == 32'hDEADBEEF, $time);

        #(CLK_PERIOD); #(CLK_PERIOD);
        $display("jpc_ifetch: All tests completed");
        $finish;
    end

    // Add this inside the initial block for signal monitoring
    initial begin
        $monitor("%0t | PC: %h (v%b r%b) | INSTR: %h (v%b r%b)", 
                 $time, pc, pc_valid, pc_ready, instr, instr_valid, instr_ready);
    end


    initial begin
        `ifdef VCD_FILE
            $dumpfile(`VCD_FILE);
        `else
            $dumpfile("jpc_ifetch_tb.vcd");
        `endif
        $dumpvars(0, jpc_ifetch_tb);
    end

endmodule
