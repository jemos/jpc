`timescale 1ns / 1ps

`include "jpc_config.v"

module jpc_pc_tb;

    // Parameters for address width and clock period
    parameter JPC_ADDRESS_WIDTH = `ifdef JPC_ADDRESS_WIDTH `JPC_ADDRESS_WIDTH `else 32 `endif;
    parameter JPC_CLOCK_PERIOD = 20;  // Clock period in ns
    parameter RESET_DURATION = 25;   // Reset duration in ns

    // Testbench signals
    reg clk;                      // Clock
    reg rst;                      // Reset
    reg [JPC_ADDRESS_WIDTH-1:0] next_pc; // Next PC value
    reg pc_enable;                // Enable signal for PC update
    wire [JPC_ADDRESS_WIDTH-1:0] pc;     // Current PC value

    // Instantiate the program_counter module
    jpc_pc uut (
        .clk(clk),
        .rst(rst),
        .next_pc_I(next_pc),
        .pc_enable_I(pc_enable),
        .pc_O(pc)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(JPC_CLOCK_PERIOD / 2) clk = ~clk;  // Generate a clock with a period defined by JPC_CLOCK_PERIOD
    end

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
        if (pc !== 0) $error("Assertion failed: PC did not reset correctly!");

        // Step 2: Normal operation - increment PC by 4
        next_pc = pc + 4;
        #(JPC_CLOCK_PERIOD);  // Wait for one clock cycle
        if (pc !== 4) $error("Assertion failed: PC increment failed! Expected 4, got %0h", pc);

        // Step 3: Simulate a branch (jump to 32'h100)
        next_pc = 32'h100;
        #(JPC_CLOCK_PERIOD);
        if (pc !== 32'h100) $error("Assertion failed: PC branch failed! Expected 32'h100, got %0h", pc);

        // Step 4: Stall the PC (disable pc_enable)
        pc_enable = 0;
        next_pc = pc + 4;
        #(2 * JPC_CLOCK_PERIOD);  // Wait for two clock cycles
        if (pc !== 32'h100) $error("Assertion failed: PC stall failed! Expected 32'h100, got %0h", pc);

        // Step 5: Resume normal operation
        pc_enable = 1;
        next_pc = pc + 4;
        #(JPC_CLOCK_PERIOD);
        if (pc !== 32'h104) $error("Assertion failed: PC resume failed! Expected 32'h104, got %0h", pc);

        // End simulation
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
