`ifndef ALU_HEADER_VH
`define ALU_HEADER_VH

`define Add   5'b00001
`define Sub   5'b00010
`define And   5'b00011
`define Or    5'b00100
`define Xor   5'b00101
`define Not   5'b00110
`define Sll   5'b00111
`define Srl   5'b01000
`define Sra   5'b01001
`define Rol   5'b01010
`define Andn  5'b01011
`define Min   5'b01100
`define Pack  5'b01101
`define Slt   5'b01110
`define Sltu  5'b01111
`define Beq   5'b10000
`define Bne   5'b10001
`define Bge   5'b10010
`define Bgeu  5'b10011
`define Blt   5'b10100
`define Bltu  5'b10101
`define Auipc 5'b10110
`define Nop   5'b10111
`endif
