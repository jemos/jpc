Processor Architecture
======================

The JemosLite RV32I has the architecture shown in the following diagram.

.. image:: _images/JPC_Architecture.png
   :alt: Processor architecture diagram.
   :align: center

This processor is designed to be simple and educational, focusing on the basic components of a RISC-like 
architecture. It includes:

* A Program Counter (PC) to keep track of the current instruction address.
* An Instruction Fetch unit to retrieve instructions from memory.
* An Instruction Decoder to decode the fetched instructions into control signals.
* An Execution Unit to perform arithmetic and logical operations.
* A Register File to store operands and results.
* An Arithmetic Logic Unit (ALU) to perform operations on the data.

Each of these components communicates through a :ref:`handshake mechanism <basic-handshake-section>`, which allows for flexible timing 
and data transfer. The architecture is designed to be modular, allowing for easy expansion and modification.

In the following sections, we will explore the details of each component, including their functionality, 
signal interfaces, and how they interact with each other.

.. toctree::
   :maxdepth: 2

   basic_handshake_mechanism
   instruction_fetch
   instruction_decoder
   execution_unit
   arithmetic_logic_unit
   register_file
   memory_interface

