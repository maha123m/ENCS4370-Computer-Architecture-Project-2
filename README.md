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
    
  ### Instruction Types and Formats:

   #### Common Fields:
      1) 2-bit instruction type (00: R-Type, 01: J-Type, 10: I-Type, 11: S-Type)
      2) 5-bit function code
      3) Stop bit (marks the end of a function code block)  
  
   
   #### Instruction Formats:

   #####  R-Type (Register Type) Format:
      1) 5-bit Rs1 (first source register)
      2) 5-bit Rd (destination register)
      3) 5-bit Rs2 (second source register)
      4) 9-bit unused
   ##### I-Type (Immediate Type) Format:
5-bit Rs1 (first source register)
5-bit Rd (destination register)
14-bit immediate (unsigned for logic instructions, signed otherwise)
J-Type (Jump Type) Format:
24-bit signed immediate (jump offset)
S-Type (Shift Type) Format:
5-bit Rs1 (first source register)
5-bit Rd (destination register)
5-bit Rs2 (second source register) for variable shift amounts
5-bit SA (constant shift amount)
4-bit unused
Instructions' Encoding:

A subset of instructions is implemented, including AND, ADD, SUB, CMP, ANDI, ADDI, LW, SW, BEQ, J, JAL, SLL, SLR, SLLV, and SLRV.
RTL Design Options:

Three design options: Single cycle processor (80% grade), Multi-cycle processor (100% grade), and 5-stage pipelined processor (up to 120% with a bonus).
Verification:

Verification is performed by creating a testbench for the RTL design.
Various code sequences in the given ISA are executed to demonstrate correct functionality.
Project Report:

Design and Implementation:

Detailed data path description, component explanation, and design choices rationale.
Block diagrams of component circuits and the overall data path.
Clear description of control logic and control signals.
Control signal values and logic equations for each instruction.
Proper attribution of any non-original design elements.
Simulation and Testing:

Thorough simulation of the processor.
Description of test programs, including inputs and expected outputs.
Listing of tested instructions with results.
Presentation of simulator snapshots showing test program execution.
This project involves designing, implementing, and verifying a RISC processor in Verilog, emphasizing correct functionality, comprehensive testing, and clear documentation.
