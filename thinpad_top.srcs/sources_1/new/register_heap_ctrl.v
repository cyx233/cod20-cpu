`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2020 07:49:07 PM
// Design Name: 
// Module Name: register_heap_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "register_header.vh"
`include "exception_header.vh"

module register_heap_ctrl(
    input wire clk,
    input wire rst,
    input wire[1:0] RDsrc,
    input wire[2:0] ImmSE,
    input wire RegWrite,

    input wire[31:0] IR_in,
    input wire[31:0] DR_in,
    input wire[31:0] alu_result,
    input wire[31:0] PC_in,
    input wire[31:0] PC_now_in,

    output wire[31:0] Imm_out,
    output wire[31:0] data_a_out,
    output wire[31:0] data_b_out,

    input wire CsrWrite,
    input wire[31:0] Expt_code,

    output wire[1:0] privilege, 
    output wire[31:0] csr_out,
    output wire[31:0] satp_out
);

reg[31:0] data_a,data_b,csr;
wire[31:0] data_in;
wire[4:0] rs1,rs2,rd;
wire[2:0] func3;
wire[6:0] func7;
wire[11:0] csr_code;
wire[2:0] csr_id;
wire[31:0] rs1_val,rs2_val,csr_val;
wire[19:0] sign;

reg[31:0] reg_heap[31:0], reg_csr[6:0];
reg[1:0] privilege_reg;

assign data_in = RDsrc==2'b00 ? DR_in:
                 RDsrc==2'b01 ? alu_result:
                 RDsrc==2'b10 ? PC_in:
                 RDsrc==2'b11 ? csr_out:
                 32'h00000000;

assign sign = IR_in[31]==0? 20'h00000:20'hfffff;
assign csr_code = IR_in[31:20];
assign rs1 = IR_in[19:15];
assign rs2 = IR_in[24:20];
assign func3 = IR_in[14:12];
assign func7 = IR_in[31:25];
assign rd = IR_in[11:7];
assign data_a_out = data_a;
assign data_b_out = data_b;

wire ExptJump,ExptRet;

assign ExptJump = Expt_code != `No_Exception ? 1'b1:1'b0;
assign ExptRet = IR_in == 32'h30200073 ? 1'b1:1'b0;

assign csr_out = ExptJump ? reg_csr[`MTVEC]: 
                 ExptRet ? reg_csr[`MEPC]: 
                 csr;
assign satp_out = reg_csr[`SATP];
assign privilege = privilege_reg;

assign rs1_val = reg_heap[rs1];
assign rs2_val = reg_heap[rs2];
assign csr_val = reg_csr[csr_id];

assign csr_id = csr_code == 12'h305 ? `MTVEC :
                csr_code == 12'h340 ? `MSCRATCH :
                csr_code == 12'h341 ? `MEPC :
                csr_code == 12'h342 ? `MCAUSE :
                csr_code == 12'h300 ? `MSTATUS :
                csr_code == 12'h343 ? `MTVAL :
                csr_code == 12'h180 ? `SATP :
                `MTVEC;

assign Imm_out = (ImmSE==`I_Imm)||(ImmSE==`JALR_Imm)?{sign[19:0],IR_in[31:20]}:
                 (ImmSE==`S_Imm?{sign[19:0],IR_in[31:25],IR_in[11:7]}:
                 (ImmSE==`B_Imm?{sign[18:0],IR_in[31],IR_in[7],IR_in[30:25],IR_in[11:8],1'b0}:
                 (ImmSE==`U_Imm?{IR_in[31:12],12'h000}:
                 (ImmSE==`JAL_Imm?{sign[10:0],IR_in[31],IR_in[19:12],IR_in[20],IR_in[30:21],1'b0}:
                 32'h0000000))));


integer i;
always @(posedge clk or posedge rst) begin
    if(rst)begin
        for(i=0; i<32; i=i+1)begin
            reg_heap[i] <= 32'h00000000;
        end
        reg_csr[`MTVEC] <= 32'h00000000;
        reg_csr[`MSCRATCH] <= 32'h00000000;
        reg_csr[`MEPC] <= 32'h00000000;
        reg_csr[`MCAUSE] <= 32'h00000000;
        reg_csr[`MSTATUS] <= 32'h00000000;
        reg_csr[`MTVAL] <= 32'h00000000;
        reg_csr[`SATP] <= 32'h00000000;
        privilege_reg <= `M_Mode;
        csr <= 32'h00000000;
        data_a <= 32'h00000000;
        data_b <= 32'h00000000;
    end
    else begin
        data_a <= rs1_val;
        data_b <= rs2_val;
        csr <= csr_val;
        if(RegWrite && (rd!=0))begin
            reg_heap[rd] <= data_in;
        end
        if(CsrWrite)begin
            reg_csr[csr_id] <= data_in;
        end
        if(ExptJump)begin
            reg_csr[`MCAUSE] <= Expt_code;
            reg_csr[`MEPC] <= PC_now_in;
            reg_csr[`MTVAL] <= IR_in;
            privilege_reg <= `M_Mode;
        end
        if(ExptRet && ~ExptJump)begin
            privilege_reg <= `U_Mode;
        end
    end
end



endmodule
