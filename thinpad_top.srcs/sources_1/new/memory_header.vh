`ifndef MEMORY_HEADER_VH
`define MEMORY_HEADER_VH

`define Byte    3'b000
`define HWord   3'b001
`define Word    3'b010
`define UByte   3'b011
`define UHWord  3'b100

`define STATE_LOAD_VPN1   2'h0
`define STATE_LOAD_VPN2   2'h1
`define STATE_LOAD_PPN    2'h2
`define STATE_DONE        2'h2

`endif
