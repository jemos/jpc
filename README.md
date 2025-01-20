# Jemos Processor Core

Just a very simple processor I'm building for learning purposes, based on RISC-V 32bit.

# Architecture

TBD

# Testing

In this section I leave some information on how to test the core modules.

## Test Program Counter


To test the program counter, run the following command. Assuming `gmake` is gnumake.


	$ gmake test V=test/jpc_pc_tb.v

This will generate the test binary and execute it. The output should show the current
time and signal variations.

To see the same information in a waveform, we can use the `wave` target of the Makefile.

	$ gmake wave V=test/jpc_pc_tb.v 

