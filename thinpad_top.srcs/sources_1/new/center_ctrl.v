`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2020 08:38:15 PM
// Design Name: 
// Module Name: center_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision: // Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "center_header.vh"
`include "register_header.vh"
`include "alu_header.vh"
`include "memory_header.vh"
`include "exception_header.vh"

module center_ctrl(
    input wire[31:0] address,
    input wire[31:0] IR_in,
    input wire[3:0] alu_flag,
    input wire[3:0] state,
    input wire[1:0] privilege,
    input wire address_done,
    input wire load_access_fault,
    input wire store_access_fault,
    input wire instr_access_fault,

    // Memory Control
    output wire PCWrite,
    output wire IorD,
    output wire PCnowWrite,
    output wire MemWrite,
    output wire MemRead,
    output wire[2:0] MemType,
    output wire IRWrite,
    output wire sfence_vma,

    //Register heap Control
    output wire[1:0] RDsrc,
    output wire[2:0] ImmSE,
    output wire RegWrite,
    output wire CsrWrite,
    output wire[31:0] Expt_code,

    //ALU Control
    output wire[1:0] ALUsrcA,
    output wire[2:0] ALUsrcB,
    output wire[4:0] ALUop,
    output wire[1:0] PCsrc
);

wire[6:0] op;
wire[2:0] func3;
wire[6:0] func7;
wire[11:0] csr_id;
assign op = IR_in[6:0];
assign func3 = IR_in[14:12];
assign func7 = IR_in[31:25];
assign csr_id = IR_in[31:20];

wire cf,zf,sv,vf;
assign {cf,zf,sf,vf} = alu_flag;

// Memory Control
assign PCWrite = Expt_code != `No_Exception ? 1'b1 : 
                 state == `STATE_FETCH ? (
                    address_done ? 1'b1 :
                    1'b0) : 
                 state == `STATE_BRANCH ? (
                    op == `EXPT ? 1'b1 :
                    op == `JAL ? 1'b1 :
                    zf ? 1'b1 :
                    1'b0) :
                 state == `STATE_ALU_WRITE_BACK ? (
                    op == `JALR ? 1'b1 : 
                    1'b0) : 
                 1'b0;

assign IorD = state == `STATE_MEM_READ ? 1'b1 :
              state == `STATE_MEM_WRITE ? 1'b1 : 1'b0;

assign PCnowWrite = PCWrite;

assign IRWrite = state == `STATE_FETCH ? (
                            address_done ? 1'b1:
                            1'b0): 
                           1'b0;

assign MemRead = load_access_fault == 1'b1 ? 1'b0:
                 state == `STATE_FETCH ? 1'b1 : 
                 state == `STATE_MEM_READ ? 1'b1 :
                 state == `STATE_MEM_WRITE ?(
                    address_done ? 1'b0:
                    1'b1): 
                 1'b0;
                

assign MemWrite = store_access_fault == 1'b1 ? 1'b0:
                  state == `STATE_MEM_WRITE ? (
                    address_done ? 1'b1:
                    1'b0): 
                  1'b0;

assign MemType = (state == `STATE_MEM_READ)||(state == `STATE_MEM_WRITE) ? (
                    func3 == 3'b000 ? `Byte : 
                    func3 == 3'b001 ? `HWord :
                    func3 == 3'b100 ? `UByte :
                    func3 == 3'b101 ? `UHWord : `Word) : `Word;

assign sfence_vma = (state==`STATE_DECODE) && (op == `EXPT) && 
                    ({func7,func3}==10'b0001001000) ? 1'b1:1'b0;

// Register Heap Control
assign RDsrc = state == `STATE_BRANCH ? (
                    op == `JAL ? 2'h2 : 2'h0): 
               state == `STATE_EXECUTE ? (
                    op == `EXPT ? 2'h3 : 2'h0):
               state == `STATE_ALU_WRITE_BACK ? (
                    op == `JALR ? 2'h2 : 2'h1):
               2'h0;

assign ImmSE = op == `S_INSTR ? `S_Imm :
               op == `B_INSTR ? `B_Imm : 
               (op == `LUI)||(op == `AUIPC) ? `U_Imm : 
               op == `JAL ? `JAL_Imm :
               op == `JALR ? `JALR_Imm :
               `I_Imm;

assign RegWrite = state == `STATE_ALU_WRITE_BACK ? (
                    op == `EXPT ? 1'b0 : 1'b1) :
                  state == `STATE_MEM_WRITE_BACK ? 1'b1 :
                  state == `STATE_EXECUTE ? (
                    op == `EXPT ? 1'b1 : 1'b0) :
                  state == `STATE_BRANCH ? (
                    op == `JAL ? 1'b1 : 1'b0) :
                  1'b0;

assign CsrWrite = state == `STATE_ALU_WRITE_BACK ? (
                    op == `EXPT ? 1'b1:
                    1'b0):
                  1'b0;

assign Expt_code = state == `STATE_FETCH ? (
                        address[1:0]!=2'b00 ? `Instr_Addr_Misaligned:
                        `No_Exception):
                    state == `STATE_DECODE ? (
                        instr_access_fault==1'b1 ? `Instr_Access_Fault :
                        op == `EXPT ? (
                            {func3,func7}==10'h000 ? (// ebreak ecall 
                                privilege == `U_Mode ? ( 
                                    csr_id == 12'h001 ? `Breakpoint : 
                                    csr_id == 12'h000 ? `Environment_Call_U : 
                                    `Illegal_Instr): 
                                `Nesting_Exception): 
                            privilege == `U_Mode ? `Illegal_Instr: // sfence.vma mret csrrc csrrs csrrw 
                            `No_Exception): 
                        (op!=`R_INSTR)&&(op!=`I_LOGIC)&&(op!=`I_LOAD)&&(op!=`S_INSTR)&&(op!=`B_INSTR)&&
                        (op!=`LUI)&&(op!=`AUIPC)&&(op!=`JAL)&&(op!=`JALR)&&(op!=`EXPT) ? `Illegal_Instr:
                        `No_Exception): 
                    state == `STATE_MEM_READ ? (
                        load_access_fault==1'b1 ? `Load_Access_Fault :
                        MemType == `Word ? (
                            address[1:0]!=2'b00 ? `Load_Addr_Misaligned:
                            `No_Exception):
                        (MemType==`HWord) || (MemType==`HWord) ? (
                            address[0]!=1'b0 ? `Load_Addr_Misaligned:
                            `No_Exception):
                        `No_Exception):
                    state == `STATE_MEM_WRITE ? (
                        store_access_fault==1'b1 ? `Store_Access_Fault :
                        MemType == `Word ? (
                            address[1:0]!=2'b00 ? `Store_Addr_Misaligned:
                            `No_Exception):
                        (MemType==`HWord) || (MemType==`HWord) ? (
                            address[0]!=1'b0 ? `Store_Addr_Misaligned:
                            `No_Exception):
                        `No_Exception):
                    `No_Exception;

// ALU Control
assign ALUsrcA = state == `STATE_FETCH ? 2'h0 :
                 state == `STATE_DECODE ? (
                    op == `B_INSTR ? 2'h1 : 
                    2'h0):
                 state == `STATE_BRANCH ? (
                    op == `JAL ? 2'h1 : 2'h2):
                 state == `STATE_EXECUTE ? (
                    op == `LUI ? 2'h3 : 
                    op == `AUIPC ? 2'h1 : 2'h2):
                 2'h2;
                    
assign ALUsrcB = state == `STATE_FETCH ? 3'h0 : 
                 state == `STATE_DECODE ? (
                    op == `B_INSTR ? 3'h2 : 
                    3'h0):
                 state == `STATE_BRANCH ? (
                    op == `JAL ? 3'h2 : 3'h1):
                 state == `STATE_EXECUTE ? (
                    op == `R_INSTR ? 3'h1:
                    op == `EXPT ? (
                        func3 == 3'b001 ? 3'h4: 
                        3'h3): 
                    3'h2):
                 3'h2;

assign ALUop =  state == `STATE_FETCH  ? `Add :
                state == `STATE_DECODE ? (
                    op == `B_INSTR ? `Add : 
                    `Nop):
                state == `STATE_BRANCH ? (
                    op == `JAL ? `Add : 
                   (func3 == 3'b000 ? `Beq :
                    func3 == 3'b001 ? `Bne :
                    func3 == 3'b100 ? `Blt :
                    func3 == 3'b101 ? `Bge :
                    func3 == 3'b110 ? `Bltu : 
                    `Bgeu)
                ) :
                state == `STATE_MEM_ADR ? `Add :
                state == `STATE_EXECUTE ?(
                    op == `R_INSTR ? 
                        (func3 == 3'b000 ? (
                            func7 == 7'b0000000 ? `Add :
                            func7 == 7'b0100000 ? `Sub : 
                            `Nop) :
                        func3 == 3'b001 ? `Sll :
                        func3 == 3'b010 ? `Slt :
                        func3 == 3'b011 ? `Sltu :
                        func3 == 3'b100 ? (
                            func7 == 7'b0000000 ? `Xor : 
                            func7 == 7'b0000101 ? `Min : 
                            func7 == 7'b0000100 ? `Pack : 
                            `Nop ):
                        func3 == 3'b101 ? (
                            func7 == 7'b0000000 ? `Srl :
                            func7 == 7'b0100000 ? `Sra : 
                            `Nop) :
                        func3 == 3'b110 ? `Or :
                        func3 == 3'b111 ? (
                            func7 == 7'b0000000 ? `And : 
                            func7 == 7'b0100000 ? `Andn : 
                            `Nop) :
                        `Nop) :
                    op == `I_LOGIC ? (
                        func3 == 3'b000 ? `Add :
                        func3 == 3'b001 ? `Sll :
                        func3 == 3'b010 ? `Slt :
                        func3 == 3'b011 ? `Sltu :
                        func3 == 3'b100 ? `Xor:
                        func3 == 3'b101 ? (
                            func7 == 7'b0000000 ? `Srl :
                            func7 == 7'b0100000 ? `Sra : 
                            `Nop) :
                        func3 == 3'b110 ? `Or :
                        func3 == 3'b111 ? `And : 
                        `Nop) :
                    op == `I_LOAD ? `Add :
                    op == `LUI    ? `Add :
                    op == `AUIPC  ? `Auipc :
                    op == `JALR   ? `Add : 
                    op == `EXPT ? (
                        func3 == 3'b011 ? `Andn :
                        func3 == 3'b010 ? `Or :
                        func3 == 3'b001 ? `Add :
                        `Nop) :
                    `Nop):
                `Nop;

assign PCsrc = Expt_code != `No_Exception ? 2'h2 :
               state == `STATE_BRANCH ? (
                  op == `JAL ? 2'h1 : 
                  op == `EXPT ? 2'h2 : 
                  2'h0):
               state == `STATE_ALU_WRITE_BACK ? (
                  op == `JALR ? 2'h0 : 
                  2'h1):
               2'h1;

endmodule
