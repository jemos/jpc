`timescale 1ns / 1ps



module jpc_pc_tb;

    // Testbench signals
    reg clk;                      // Clock
    reg rst;                      // Reset
    reg [31:0] next_pc;           // Next PC value
    reg pc_enable;                // Enable signal for PC update
    wire [31:0] pc;               // Current PC value

    // Instantiate the program_counter module
    jpc_pc uut (
        .clk(clk),
        .rst(rst),
        .next_pc_I(next_pc),
        .pc_enable_I(pc_enable),
        .pc_O(pc)
    );

    // Clock generation (50 MHz = 20 ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 10 ns high, 10 ns low
    end

    // Testbench logic
    initial begin
        // Initialize signals
        rst = 1;
        pc_enable = 0;
        next_pc = 32'b0;

        // Step 1: Apply reset
        #25; // Wait for some cycles
        rst = 0;
        pc_enable = 1;

        // Step 2: Normal operation - increment PC by 4
        next_pc = pc + 4;
        #20; // Wait for one clock cycle
        next_pc = pc + 4;
        #20;

        // Step 3: Simulate a branch (jump to 32'h100)
        next_pc = 32'h100;
        #20;

        // Step 4: Stall the PC (disable pc_enable)
        pc_enable = 0;
        #40;

        // Step 5: Resume normal operation
        pc_enable = 1;
        next_pc = pc + 4;
        #20;

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
