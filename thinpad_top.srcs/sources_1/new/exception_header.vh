`ifndef EXCEPTION_HEADER_VH
`define EXCEPTION_HEADER_VH

`define MTVEC      3'h0 
`define MSCRATCH   3'h1 
`define MEPC       3'h2 
`define MCAUSE     3'h3 
`define MSTATUS    3'h4 
`define MTVAL      3'h5
`define SATP       3'h6 

`define Direct   2'b00
`define Vectored 2'b01

`define U_Mode 2'b00
`define S_Mode 2'b01
`define M_Mode 2'b11

`define S_Software_Intrpt 32'h80000001
`define M_Software_Intrpt 32'h80000003
`define S_Timer_Intrpt    32'h80000005
`define M_Timer_Intrpt    32'h80000007
`define S_EXT_Intrpt      32'h80000009
`define M_EXT_Intrpt      32'h8000000b

`define Instr_Addr_Misaligned 32'h00000000  
`define Instr_Access_Fault    32'h00000001
`define Illegal_Instr         32'h00000002
`define Breakpoint            32'h00000003
`define Load_Addr_Misaligned  32'h00000004
`define Load_Access_Fault     32'h00000005
`define Store_Addr_Misaligned 32'h00000006
`define Store_Access_Fault    32'h00000007
`define Environment_Call_U    32'h00000008
`define Environment_Call_S    32'h00000009
`define Environment_Call_M    32'h0000000b
`define Instr_Page_Fault      32'h0000000c
`define Load_Page_Fault       32'h0000000d
`define Store_Page_Fault      32'h0000000f

`define Nesting_Exception     32'h0000001e
`define No_Exception          32'h0000001f

`endif
