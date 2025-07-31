`include "jpc_config.v"

// TESTS_EXPECTED:
// TEST:RF001
// TEST:RF002
// TEST:RF003
// TEST:RF004

`timescale 1ns/1ns

module jpc_regfile_tb;

    // Testbench parameters
    parameter CLK_PERIOD = 10; // Clock period in nanoseconds
    parameter CLK_HPERIOD = 5; // Half-Clock period in nanoseconds
    `include "jpc_time_to_cycles.v"

    reg clk;
    reg rst;

    // Register file interface signals (port 1 only for simplicity)
    reg                          r1_idx_op_I;
    reg  [4:0]                   r1_idx_I;
    reg  [4:0]                   r1_idx_valid_I;
    wire                         r1_idx_ready_O;

    reg  [4:0]                   r1_rdata_ready_I;
    wire [`JPC_REGDATA_WIDTH-1:0] r1_rdata_O;
    wire                         r1_rdata_valid_O;

    wire [4:0]                   r1_wdata_ready_O;
    reg  [`JPC_REGDATA_WIDTH-1:0] r1_wdata_I;
    reg                          r1_wdata_valid_I;

    // Unused port 2 signals (tie off)
    reg                          r2_idx_op_I = 0;
    reg  [4:0]                   r2_idx_I = 0;
    reg  [4:0]                   r2_idx_valid_I = 0;
    wire                         r2_idx_ready_O;

    reg  [4:0]                   r2_data_ready_I = 0;
    wire [`JPC_REGDATA_WIDTH-1:0] r2_data_O;
    wire                         r2_data_valid_O;

    string assert_msg;
    `include "jpc_assert.v"

    // Instantiate the Register File module
    jpc_regfile uut (
        .clk(clk),
        .rst(rst),

        // Port 1
        .r1_idx_op_I(r1_idx_op_I),
        .r1_idx_I(r1_idx_I),
        .r1_idx_valid_I(r1_idx_valid_I),
        .r1_idx_ready_O(r1_idx_ready_O),
        .r1_rdata_ready_I(r1_rdata_ready_I),
        .r1_rdata_O(r1_rdata_O),
        .r1_rdata_valid_O(r1_rdata_valid_O),
        .r1_wdata_ready_O(r1_wdata_ready_O),
        .r1_wdata_I(r1_wdata_I),
        .r1_wdata_valid_I(r1_wdata_valid_I),

        // Port 2 (unused)
        .r2_idx_op_I(r2_idx_op_I),
        .r2_idx_I(r2_idx_I),
        .r2_idx_valid_I(r2_idx_valid_I),
        .r2_idx_ready_O(r2_idx_ready_O),
        .r2_data_ready_I(r2_data_ready_I),
        .r2_data_O(r2_data_O),
        .r2_data_valid_O(r2_data_valid_O)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_HPERIOD) clk = ~clk; // Clock toggles every half-period

    reg [4:0] rand_reg_idx1;
    reg [`JPC_REGDATA_WIDTH-1:0] rand_reg_val1;
    reg [`JPC_REGDATA_WIDTH-1:0] rand_zero_val;
    reg [4:0] rand_reg_idx2;
    reg [`JPC_REGDATA_WIDTH-1:0] rand_reg_val2;

    // Test sequence
    initial begin

        $timeformat(-9, 0, "ns", 0);

        // Initialize signals
        rst = 1;
        r1_idx_op_I = 0;
        r1_idx_I = 0;
        r1_idx_valid_I = 0;
        r1_rdata_ready_I = 0;
        r1_wdata_I = 0;
        r1_wdata_valid_I = 0;

        // Keep reset for one clock period
        #(CLK_PERIOD) rst = 0;

        // Wait for reset to propagate
        #(CLK_PERIOD);

        // Test 1: Confirm reset was done properly: all outputs cleared, register 0 is zero
        assert_msg = $sformatf("Reset did not clear r1_rdata_valid (r1_rdata_valid_O=%b)", r1_rdata_valid_O);
        jpc_assert("RF001", r1_rdata_valid_O == 0, $time);

        // Test 2: Write to random register, then read it back
        
        rand_reg_idx1 = $urandom_range(1, 31);
        rand_reg_val1 = $urandom_range(0, 32'hFFFFFFFF);

        r1_idx_op_I = 1'b1; // Write
        r1_idx_I = rand_reg_idx1;
        r1_idx_valid_I = 1'b1;
        r1_wdata_I = rand_reg_val1;
        r1_wdata_valid_I = 1'b1;
        #(CLK_PERIOD);

        // Deassert write signals
        r1_idx_op_I = 1'b0;
        r1_idx_valid_I = 0;
        r1_wdata_valid_I = 0;

        // Wait for write to complete
        #(CLK_PERIOD);

        // Test 3: Read from random register
        r1_idx_op_I = 1'b0; // Read
        r1_idx_I = rand_reg_idx1;
        r1_idx_valid_I = 1'b1;
        r1_rdata_ready_I = 1'b1;
        #(CLK_PERIOD);

        // Test 4: Check that the read data is correct
        assert_msg = $sformatf("Incorrect data read from reg %0d (r1_rdata_O=%h, expected=%h)", rand_reg_idx1, r1_rdata_O, rand_reg_val1);
        jpc_assert("RF002", r1_rdata_O == rand_reg_val1, $time);

        // Deassert read signals
        r1_idx_valid_I = 0;
        r1_rdata_ready_I = 0;
        #(CLK_PERIOD);

        // Test 5: Write to register 0 (should remain zero if hardwired)
        rand_zero_val = $urandom_range(0, 32'hFFFFFFFF);

        r1_idx_op_I = 1'b1; // Write
        r1_idx_I = 5'd0;
        r1_idx_valid_I = 1'b1;
        r1_wdata_I = rand_zero_val;
        r1_wdata_valid_I = 1'b1;
        #(CLK_PERIOD);

        r1_idx_valid_I = 0;
        r1_wdata_valid_I = 0;
        #(CLK_PERIOD);

        // Read from register 0
        r1_idx_op_I = 1'b0; // Read
        r1_idx_I = 5'd0;
        r1_idx_valid_I = 1'b1;
        r1_rdata_ready_I = 1'b1;
        #(CLK_PERIOD);

        // Test 6: Check that register 0 is still zero
        assert_msg = $sformatf("Register 0 is not zero (r1_rdata_O=%h)", r1_rdata_O);
        jpc_assert("RF003", r1_rdata_O == 32'h0, $time);

        // Deassert read signals
        r1_idx_valid_I = 0;
        r1_rdata_ready_I = 0;
        #(CLK_PERIOD);

        // Test 7: Write and read another random register
        rand_reg_idx2 = $urandom_range(1, 31);
        // Ensure different index from rand_reg_idx1
        while (rand_reg_idx2 == rand_reg_idx1) rand_reg_idx2 = $urandom_range(1, 31);
        rand_reg_val2 = $urandom_range(0, 32'hFFFFFFFF);

        r1_idx_op_I = 1'b1; // Write
        r1_idx_I = rand_reg_idx2;
        r1_idx_valid_I = 1'b1;
        r1_wdata_I = rand_reg_val2;
        r1_wdata_valid_I = 1'b1;
        #(CLK_PERIOD);

        r1_idx_valid_I = 0;
        r1_wdata_valid_I = 0;
        #(CLK_PERIOD);

        r1_idx_op_I = 1'b0; // Read
        r1_idx_I = rand_reg_idx2;
        r1_idx_valid_I = 1'b1;
        r1_rdata_ready_I = 1'b1;
        #(CLK_PERIOD);

        assert_msg = $sformatf("Incorrect data read from reg %0d (r1_rdata_O=%h, expected=%h)", rand_reg_idx2, r1_rdata_O, rand_reg_val2);
        jpc_assert("RF004", r1_rdata_O == rand_reg_val2, $time);

        // Deassert read signals
        r1_idx_valid_I = 0;
        r1_rdata_ready_I = 0;
        #(CLK_PERIOD);

        $display("jpc_regfile: All tests completed");
        $finish;
    end

    // Add this inside the initial block for signal monitoring
    initial begin
        $monitor("%0t | IDX: %d (op%b v%b r%b) | WDATA: %h (v%b) | RDATA: %h (v%b)", 
                 $time, r1_idx_I, r1_idx_op_I, r1_idx_valid_I, r1_rdata_ready_I,
                 r1_wdata_I, r1_wdata_valid_I, r1_rdata_O, r1_rdata_valid_O);
    end

    initial begin
        `ifdef VCD_FILE
            $dumpfile(`VCD_FILE);
        `else
            $dumpfile("jpc_regfile_tb.vcd");
        `endif
        $dumpvars(0, jpc_regfile_tb);
    end

endmodule
