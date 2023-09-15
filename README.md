# ENCS4370-Computer-Architecture-Project-2

## Objectives:
This project aims to design and verify a basic RISC processor using Verilog. The processor is defined by the following specifications:

  ### Processor Specifications:

    1) Instruction size: 32 bits
    2) 32-bit general-purpose registers (R0 to R31)
    3) Special purpose register for the program counter (PC)
    4) Control stack to save return addresses
    5) Stack pointer (SP) to point to the top of the control stack (initialized to zero)
    6) Four instruction types: R-type, I-type, J-type, and S-type
    7) ALU with a "zero" signal indicating if the last operation result is zero
    8) Separate data and instruction memories
