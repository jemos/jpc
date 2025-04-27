`timescale 1ns / 1ps

`include "jpc_config.v"

module jpc_pc_tb;

    // Parameters for address width and clock period
    parameter RESET_DURATION = 25;   // Reset duration in ns
    parameter CLK_PERIOD = 10; // Clock period in nanoseconds
    parameter CLK_HPERIOD = 5; // Half-Clock period in nanoseconds
    `include "jpc_time_to_cycles.v"

    // Testbench signals
    reg clk;                      // Clock
    reg rst;                      // Reset
    reg [`JPC_ADDRESS_WIDTH-1:0] next_pc; // Next PC value
    reg pc_enable;                // Enable signal for PC update
    wire [`JPC_ADDRESS_WIDTH-1:0] pc;     // Current PC value

    string assert_msg = "";
    `include "jpc_assert.v"

    // Instantiate the program_counter module
    jpc_pc uut (
        .clk(clk),
        .rst(rst),
        .next_pc_I(next_pc),
        .en_I(pc_enable),
        .pc_O(pc)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_HPERIOD) clk = ~clk; // Clock toggles every half-period

    // Testbench logic with manual assertions
    initial begin
        // Initialize signals
        rst = 1;
        pc_enable = 0;
        next_pc = 0;
        
        // Step 1: Apply reset
        #(RESET_DURATION);  // Wait for reset duration
        rst = 0;
        pc_enable = 1;

        // Manual assertion: Check if PC is reset to 0
        #(1);
        
        // Test 1: Confirm reset was done properly: output pc is cleared.
        assert_msg = $sformatf("PC did not reset correctly (pc=0x%h).", pc);
        jpc_assert("PC001", pc == 0, $time);

        // Step 2: Normal operation - increment PC by 4
        next_pc = pc + 4;
        #(CLK_PERIOD);  // Wait for one clock cycle
        assert_msg = $sformatf("PC increment failed! Expected 4, got %0h", pc);
        jpc_assert("PC002", pc == 4, $time);

        // Step 3: Simulate a branch (jump to 32'h100)
        next_pc = 32'h100;
        #(CLK_PERIOD);
        assert_msg = $sformatf("PC branch failed! Expected 32'h100, got %0h", pc);
        jpc_assert("PC003", pc == 32'h100, $time);

        // Step 4: Stall the PC (disable pc_enable)
        pc_enable = 0;
        next_pc = pc + 4;
        #(2 * CLK_PERIOD);  // Wait for two clock cycles
        assert_msg = $sformatf("PC stall failed! Expected 32'h100, got %0h", pc);
        jpc_assert("PC004", pc == 32'h100, $time);

        // Step 5: Resume normal operation
        pc_enable = 1;
        next_pc = pc + 4;
        #(CLK_PERIOD);
        assert_msg = $sformatf("PC resume failed! Expected 32'h104, got %0h", pc);
        jpc_assert("PC005", pc == 32'h104, $time);

        // End simulation
        $display("jpc_pc: All tests completed");
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time: %0t | Reset: %b | PC Enable: %b | Next PC: %h | Current PC: %h", 
                 $time, rst, pc_enable, next_pc, pc);
    end

    initial begin
        `ifdef VCD_FILE
            $dumpfile(`VCD_FILE);
        `else
            $dumpfile("jpc_pc_tb.vcd");
        `endif
        $dumpvars(0, jpc_pc_tb);
    end

endmodule
