`include "jpc_config.v"

module jpc_ifetch_tb;

    // Testbench parameters
    parameter CLK_PERIOD = 10; // Clock period in nanoseconds

    reg clk;
    reg rst;
    reg stall_I;
    reg flush_I;
    reg branch_taken_I;
    reg [`JPC_ADDRESS_WIDTH-1:0] branch_addr_I;
    reg trap_taken_I;
    reg [`JPC_ADDRESS_WIDTH-1:0] trap_address_I;
    wire [`JPC_ADDRESS_WIDTH-1:0] pc_O;
    wire [`JPC_ADDRESS_WIDTH-1:0] next_pc_I;
    wire [`JPC_ADDRESS_WIDTH-1:0] mem_addr_O;
    wire [31:0] mem_data_I;
    wire [31:0] instr_O;

    // Instantiate jpc_pc
    jpc_pc pc_module (
        .clk(clk),
        .rst(rst),
        .next_pc_I(next_pc_I),
        .en_I(!stall_I), // Enable PC update only if not stalled
        .pc_O(pc_O)
    );

    // Instantiate the IFetch module
    jpc_ifetch uut (
        .clk(clk),
        .rst(rst),
        .stall_I(stall_I),
        .flush_I(flush_I),
        .branch_taken_I(branch_taken_I),
        .branch_addr_I(branch_addr_I),
        .trap_taken_I(trap_taken_I),
        .trap_address_I(trap_address_I),
        .pc_I(pc_O),
        .next_pc_O(next_pc_I),
        .mem_addr_O(mem_addr_O),
        .mem_data_I(mem_data_I),
        .instr_O(instr_O)
    );

    // Instantiate the BRAM module
    jpc_32bram #(
        .DEPTH(256)
    ) instruction_bram (
        .clk(clk),
        .addr(mem_addr_O),
        .din(32'b0), // No writing in this testbench
        .we(1'b0),   // No writing in this testbench
        .dout(mem_data_I)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk; // Clock toggles every half-period

    // Test sequence
    initial begin
        // Initialize signals
        rst = 1;
        stall_I = 0;
        flush_I = 0;
        branch_taken_I = 0;
        branch_addr_I = 0;
        trap_taken_I = 0;
        trap_address_I = 0;

        #(CLK_PERIOD) rst = 0; // Release reset

        // Test 1: Sequential PC increment
        if (pc_O != 0) $error("Test 1 failed: PC did not reset to 0");
        #(CLK_PERIOD);
        if (pc_O != `JPC_INSTRUCTION_WIDTH) $error("Test 1 failed: PC did not increment correctly");
        #(CLK_PERIOD);

        // Test 2: Branch taken
        branch_taken_I = 1;
        branch_addr_I = 32'h10;
        #(CLK_PERIOD);
        branch_taken_I = 0; // Clear branch
        if (pc_O != 32'h10) $error("Test 2 failed: PC did not branch correctly");
        #(CLK_PERIOD);

        // Test 3: Trap handling
        trap_taken_I = 1;
        trap_address_I = 32'h20;
        #(CLK_PERIOD);
        trap_taken_I = 0; // Clear trap
        if (pc_O != 32'h20) $error("Test 3 failed: PC did not handle trap correctly");
        #(CLK_PERIOD);

        // Test 4: Flush
        flush_I = 1;
        #(CLK_PERIOD);
        if (instr_O != 32'b0) $error("Test 4 failed: Flush did not clear instruction");
        if (pc_O != 32'h24) $error("Test 4 failed: PC updated (%h) during flush", pc_O);
        flush_I = 0;

        // Test 5: Stall
        stall_I = 1;
        #(CLK_PERIOD);
        if (pc_O != 32'h24) $error("Test 5 failed: PC updated (%h) during stall", pc_O);
        stall_I = 0;
        #(CLK_PERIOD);

        $display("jpc_ifetch: All tests completed");
        $finish;
    end

    // Add this inside the initial block for signal monitoring
    initial begin
        $monitor("Time: %0t | PC: %h | Instr: %h | Branch Taken: %b | Trap Taken: %b | Stall: %b | Flush: %b", 
                 $time, pc_O, instr_O, branch_taken_I, trap_taken_I, stall_I, flush_I);
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
