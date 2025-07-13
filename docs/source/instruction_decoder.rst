Instruction Decoder
-------------------

The instruction decoder is a sequential block that decomposes the instruction bits into the different fields that can be more easily processed by the execution unit. I chosen to do it sequential to support handshake-based inputs and outputs.

The following diagram (:numref:`instruction-decoder-state-diagram`) illustrates the inputs and outputs of the instruction decoder block.

.. _instruction-decoder-state-diagram:
.. figure:: _images/JPC_idecode-3.svg
   :alt: JPC Instruction Decoder block diagram.
   :width: 400px
   :align: center

   Instruction Decoder block diagram.

With the ready and valid signals, there is control flow of the information and we can easily stall the information transfer.

.. _instruction-decoder-flow:
.. figure:: _images/JPC_idecode_flow.svg
   :alt: JPC Instruction Decoder flow diagram.
   :width: 400px
   :align: center

   Instruction Decoder flow diagram.

Testbench
^^^^^^^^^

The testbench for the Instruction Decoder block is located in the file ``test/jpc_idecoder_tb.v``. It tests
the instruction decoder by simulating various scenarios, including reset conditions, instruction decoding, 
and output validation. For more details about the tests, please refer to the testbench file itself.

To run the testbench, you will need to have a Verilog simulator installed. In context of this project, 
I have we used `Icarus Verilog <https://steveicarus.github.io/iverilog/>`_ for simulation. The testbench 
is designed to be run with the following command:

.. code-block:: none

   $ make run V=test/jpc_idecode_tb.v
   No memory file provided. Using default values.
   [TEST:ID000 PASSED]: Confirm reset was done properly: all outputs are cleared (opcode=0000000 ...)
   [TEST:ID001 PASSED]: R-type ADD instruction (opcode=0110011 funct3=000 rd=00000 rs1=01000 rs2=10010 funct7=0000000)
   [TEST:ID002 PASSED]: R-type SUB instruction (opcode=0110011 funct3=000 rd=11000 rs1=10000 rs2=00110 funct7=0100000)
   [TEST:ID003 PASSED]: R-type XOR instruction (opcode=0110011 funct3=100 rd=10000 rs1=00001 rs2=00110 funct7=0000000)
   [TEST:ID004 PASSED]: R-type OR instruction (opcode=0110011 funct3=110 rd=10011 rs1=10111 rs2=10000 funct7=0000000)
   [TEST:ID005 PASSED]: R-type AND instruction (opcode=0110011 funct3=111 rd=11111 rs1=11000 rs2=11110 funct7=0000000)
   [TEST:ID006 PASSED]: R-type SLL instruction (opcode=0110011 funct3=001 rd=01010 rs1=01100 rs2=01100 funct7=0000000)
   [TEST:ID007 PASSED]: R-type SLL instruction (opcode=0110011 funct3=101 rd=00001 rs1=00111 rs2=11110 funct7=0000000)
   [TEST:ID008 PASSED]: R-type SRA instruction (opcode=0110011 funct3=101 rd=01100 rs1=11111 rs2=11000 funct7=0100000)
   [TEST:ID009 PASSED]: R-type SLT instruction (opcode=0110011 funct3=010 rd=10101 rs1=01100 rs2=01110 funct7=0000000)
   [TEST:ID010 PASSED]: R-type SLTU instruction (opcode=0110011 funct3=011 rd=00110 rs1=00010 rs2=01011 funct7=0000000)
   ...
   Testbench Completed
   test//jpc_idecode_tb.v:703: $finish called at 1175000 (1ps)

