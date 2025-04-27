
`include "jpc_config.v"

// A helper function to convert $time to clock cycles
function integer time_to_cycles;
    input [63:0] current_time;
    begin
        // integer divide current time by the clock period
        time_to_cycles = current_time / CLK_PERIOD;
    end
endfunction
