`ifndef CENTER_HEADER_VH
`define CENTER_HEADER_VH

`define STATE_FETCH          4'b0000
`define STATE_DECODE         4'b0001
`define STATE_MEM_ADR        4'b0010
`define STATE_MEM_READ       4'b0011
`define STATE_MEM_WRITE_BACK 4'b0100
`define STATE_MEM_WRITE      4'b0101
`define STATE_EXECUTE        4'b0110
`define STATE_ALU_WRITE_BACK 4'b0111
`define STATE_BRANCH         4'b1000

`define R_INSTR 7'b0110011
`define I_LOGIC 7'b0010011
`define I_LOAD  7'b0000011
`define S_INSTR 7'b0100011
`define B_INSTR 7'b1100011
`define LUI     7'b0110111
`define AUIPC   7'b0010111
`define JAL     7'b1101111
`define JALR    7'b1100111
`define EXPT    7'b1110011 //异常指令ecall，csr指令

`endif
