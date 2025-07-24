Instruction Fetch
-----------------

The instruction fetch will use the current Program Counter (PC) value and fetch the instruction from the memory interface.

.. _instruction-fetch-diagram:
.. figure:: _images/JPC_ifetch.png
   :alt: drawing
   :width: 400px
   :align: center

   : Instruction Fetch block diagram.

The Instruction Fetch (:numref:`instruction-fetch-diagram`) has the following groups of signals:

* The program counter input, taken from the program counter block which may have some overriding logic, 
  for jumps, exceptions and similar cases;
* The instruction output that should contain the instruction read from the memory and ready to 
  be consumed by the subsequent block (the Instruction Decoder);
* The memory interface with an address bus and a data bus.

To initialize the instruction fetch the reset (``rst``) should be asserted for one clock cycle. 
This will clear all output valid signals.

The following state diagram (:numref:`instruction-fetch-state-diagram`) describes the Instruction 
Fetch internal flow.

.. _instruction-fetch-state-diagram:
.. figure:: _images/JPC_ifetch_flow.svg
   :alt: drawing
   :width: 400px
   :align: center

   : Instruction Fetch state diagram.

The waveform (:numref:`instruction-fetch-waveform`) for a full instruction fetch assuming the 
memory block takes the minimum possible time from address capture to instruction output availability.

.. _instruction-fetch-waveform:
.. figure:: _images/JPC_ifetch_waveform.svg
   :alt: drawing
   :width: 400px
   :align: center

   : Instruction Fetch waveform.

After reset, the instruction fetch enters an idle state. From that state, it asserts ``pc_ready_O`` to indicate external module that it is ready to receive a new program counter value, and transitions to the next state (*Wait PC Valid*).

In *Wait PC Valid* it waits for ``pc_valid_I`` to be asserted which indicates when there is a valid program counter value at ``pc_I``, ready to be captured by the instruction fetch.

Once ``pc_valid_I`` is asserted, the ``pc_I`` is captured and saved in an internal register, and ``pc_ready_O`` is unasserted to indicate it's no longer accepting new program counter values. It transitions to the next state *Wait Mem Addr Ready*.

In *Wait Mem Addr Ready*, it waits for the memory block to be ready to accept a new address. When ``mem_addr_ready_I`` is asserted it will load ``mem_addr_O`` with ``next_pc`` value, assert ``mem_addr_valid_O`` to inform there is a valid address, and assert ``mem_data_ready`` to inform it's ready to receive new data value. It transitions to *Wait Mem Data Valid* state.

In *Wait Mem Data Valid* state it waits for the memory to send new data. When ``mem_data_valid_I`` is asserted it means we've valid data in ``mem_data_I``. The data is stored in an internal register and ``mem_addr_valid_O`` is unasserted to inform we're no longer providing a valid address to the memory block. The ``mem_data_ready_O`` is also asserted to inform it's no longer accepting new data values. Then transitions to next state *Wait Instruction Ready* where the instruction fetch waits for the external block to be ready to receive a new instruction.

In *Wait Instruction Ready* it waits for ``instr_ready_I`` signal to be asserted which means the external block (i.e., instruction decoder) is ready to accept a new instruction. Once it's asserted, it will load the output ``instr_O`` with the new instruction, and ``instr_valid_O`` is asserted to indicate the external block that the ``instr_O`` has a valid value.

Optimizing Instruction Fetch
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If we look at the waveform in :numref:`instruction-fetch-waveform`, we see it takes 3 clock cycles from capturing a valid PC and capturing the instruction at output. Can we make this instruction fetch faster?

If the ``pc_I`` and ``pc_valid_I`` are directly connected to the ``mem_addr_O`` and ``mem_addr_valid_O`` signals respectively, we could spare one clock cycle because the capture of ``pc_valid_I`` would match the capture of ``mem_addr_valid_O``, assuming ``mem_addr_ready_I`` is asserted. It would require adding combinational logic that is active between clock cycles.

.. code-block:: verilog

    assign mem_addr_valid_O = pc_valid_I && state_wait_pc && mem_addr_ready_I;
    assign mem_addr_O = pc_I;

The same strategy could be employed between the memory address and memory data, and between memory data and instruction ready.

Testbench
^^^^^^^^^

The testbench for the Instruction Fetch block is located in the file ``test/jpc_ifetch_tb.v``. It tests 
the instruction fetch block by simulating various scenarios, including reset conditions, memory read 
attempts, and instruction fetching. For more details about the tests, please refer to the testbench file itself.

To run the testbench, you will need to have a Verilog simulator installed. In context of this project, 
we use Icarus Verilog for simulation. The testbench is designed to be run with the following command:

.. code-block:: none

   $ make run V=test/jpc_pc_tb.v
   iverilog -g2012 -I src -I test/ -DVCD_FILE='"build/test/jpc_pc_tb.vcd"' ... 
   No memory file provided. Using default values.
   VCD info: dumpfile build/test/jpc_pc_tb.vcd opened for output.
   Time: 0 | Reset: 1 | PC Enable: 0 | Next PC: 00000000 | Current PC: 00000000
   Time: 25000 | Reset: 0 | PC Enable: 1 | Next PC: 00000000 | Current PC: 00000000
   [TEST:PC001 PASSED]: PC reset correctly (pc=0x00000000).
   Time: 26000 | Reset: 0 | PC Enable: 1 | Next PC: 00000004 | Current PC: 00000000
   Time: 35000 | Reset: 0 | PC Enable: 1 | Next PC: 00000004 | Current PC: 00000004
   [TEST:PC002 PASSED]: PC incrementing as expected, expected 4, got 4
   Time: 36000 | Reset: 0 | PC Enable: 1 | Next PC: 00000100 | Current PC: 00000004
   Time: 45000 | Reset: 0 | PC Enable: 1 | Next PC: 00000100 | Current PC: 00000100
   [TEST:PC003 PASSED]: PC branch, expected 0x00000100, got 0x00000100
   Time: 46000 | Reset: 0 | PC Enable: 0 | Next PC: 00000104 | Current PC: 00000100
   [TEST:PC004 PASSED]: PC stall, expected 0x00000100, got 0x00000100
   Time: 66000 | Reset: 0 | PC Enable: 1 | Next PC: 00000104 | Current PC: 00000100
   Time: 75000 | Reset: 0 | PC Enable: 1 | Next PC: 00000104 | Current PC: 00000104
   [TEST:PC005 PASSED]: PC resume, expected 0x00000104, got 0x00000104
   jpc_pc: All tests completed
   test/jpc_pc_tb.v:90: $finish called at 76000 (1ps)

With `GTKWave <https://gtkwave.github.io/gtkwave/>`_, we can see a waveform of the signals that resulted from the simulation.
An example is shown in :numref:`instruction-fetch-simulation` below.

.. _instruction-fetch-simulation:
.. figure:: _images/JPC_ifetch_simulation.png
   :alt: Instruction Fetch

   : Instruction Fetch simulation waveform.