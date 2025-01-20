

module jpc_32bram #(
    parameter DEPTH = 256 // Default depth
)(
    input wire                          clk,  // Clock
    input wire [`JPC_ADDRESS_WIDTH-1:0] addr, // Address input
    input wire [`JPC_ADDRESS_WIDTH-1:0] din,  // Data input
    input wire                          we,   // Write enable
    output reg [`JPC_ADDRESS_WIDTH-1:0] dout  // Data output
);

    // Memory array (DEPTH x JPC_ADDRESS_WIDTH)
    reg [`JPC_ADDRESS_WIDTH-1:0] mem [0:DEPTH-1];

    // Read from memory file (if defined)
    initial begin
        `ifdef JPC_IMEM_FILE
            $readmemh(`JPC_IMEM_FILE, mem); // Read .mem file in hexadecimal format
        `else
            $display("No memory file provided. Using default values.");
        `endif
    end

    // Synchronous read/write logic
    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= din; // Write data
        end
        dout <= mem[addr]; // Read data
    end

endmodule
