# MIPS-32 Processor Implementation

This project implements a 32-bit MIPS processor using Verilog HDL, along with a
custom assembler written in C++. The processor is designed for simulation and
educational purposes, focusing on understanding pipelined CPU architecture.

## Features
- 32-bit MIPS architecture
- Pipelined design (IF, ID, EX, MEM, WB)
- Supports arithmetic, logical, load/store, branch, and jump instructions
- Hazard handling using stalling and data forwarding
- Custom assembler to convert MIPS assembly to machine code
- Verilog testbench for functional verification

## How to run
- first write assembly code in input.asm
- c++ assembler.cpp
- ./a.exe
- iverilog -o output_file_name.vvp *.v
- vvp ouput_file_name.vvp
- gtkwave M1.vcd
