`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2020 04:32:16 PM
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "alu_header.vh"

module alu_ctrl(
    input wire clk,
    input wire rst,
    input wire[1:0] PCsrc,
    input wire[1:0] ALUsrcA,
    input wire[2:0] ALUsrcB,
    input wire[4:0] ALUop,
    input wire[31:0] data_a0_pc,
    input wire[31:0] data_a1_pcnow,
    input wire[31:0] data_a2_rs1,
    input wire[31:0] data_b0_4,
    input wire[31:0] data_b1_rs2,
    input wire[31:0] data_b2_imm,
    input wire[31:0] data_b3_csr,
    output wire[31:0] alu_result,
    output wire[3:0] alu_flag,
    output wire[31:0] PC_out
);


wire[31:0] data_a;
wire[31:0] data_b;
wire cf,zf,sf,vf;

wire[31:0] result;
reg[31:0] result_out;

assign alu_result = result_out;

assign PC_out = PCsrc==2'h0 ? result_out : 
                PCsrc==2'h1 ? result :
                PCsrc==2'h2 ? data_b3_csr :
                result;

assign data_a = ALUsrcA==2'h0 ? data_a0_pc : 
                ALUsrcA==2'h1 ? data_a1_pcnow : 
                ALUsrcA==2'h2 ? data_a2_rs1 : 
                32'h00000000;

assign data_b = ALUsrcB==3'h0 ? data_b0_4 : 
                ALUsrcB==3'h1 ? data_b1_rs2 :
                ALUsrcB==3'h2 ? data_b2_imm : 
                ALUsrcB==3'h3 ? data_b3_csr : 
                32'h00000000;

always@(posedge clk or posedge rst)begin
    if(rst)begin
        result_out <= 32'h00000000;
    end
    else if(ALUop!=`Nop)begin
        result_out <= result;
    end
end

assign result = ALUop==`Auipc ? (data_a + data_b)&(32'hfffffffe):
                ALUop==`Add ? data_a + data_b:
                ALUop==`Sub ? data_a + ~data_b + 1:
                ALUop==`And ? data_a & data_b:
                ALUop==`Or ? data_a | data_b:
                ALUop==`Xor ? data_a ^ data_b:
                ALUop==`Not ? ~data_a:
                ALUop==`Sll ? data_a << data_b:
                ALUop==`Srl ? data_a >> data_b:
                ALUop==`Sra ? 
                    (data_a[31] ?  (data_a >> data_b)|(33'h100000000-(33'h100000000>>data_b)) :
                                    data_a>>data_b):
                ALUop==`Rol ? (data_a << data_b) | (data_a >> (32 - data_b)):
                ALUop==`Andn ? data_a & (~data_b):
                ALUop==`Min ? 
                    ($signed(data_a) > $signed(data_b) ? data_b : data_a):
                ALUop==`Pack ? ((data_a << 16) >> 16) | (data_b << 16):
                ALUop==`Slt ? 
                    ($signed(data_a) < $signed(data_b) ? 1 : 0):
                ALUop==`Sltu ? 
                    (data_a < data_b ? 1 : 0):
                ALUop==`Beq ? 
                    (data_a == data_b ? 0 : 1):
                ALUop==`Bne ? 
                    (data_a == data_b ? 1 : 0):
                ALUop==`Bge ? 
                    (($signed(data_a) > $signed(data_b))||(data_a == data_b) ? 0 : 1):
                ALUop==`Bgeu ? 
                    ((data_a > data_b)||(data_a == data_b) ? 0 : 1):
                ALUop==`Blt ? 
                    ($signed(data_a) < $signed(data_b) ? 0 : 1):
                ALUop==`Bltu ? 
                    (data_a < data_b ? 0 : 1):
                32'h00000000;

assign cf = (ALUop==`Auipc)&&(({data_a[31],data_b[31],result[31]}==3'b001)||({data_a[31],data_b[31],result[31]}==3'b110)) ? 1'b1:
            (ALUop==`Add)&&(({data_a[31],data_b[31],result[31]}==3'b001)||({data_a[31],data_b[31],result[31]}==3'b110)) ? 1'b1:
            (ALUop==`Sub)&&($signed(data_a) < $signed(data_b)) ? 1'b1:
            1'b0;

assign sf = (ALUop==`Auipc)&&result[31] ? 1'b1:
            ((ALUop==`Add)&&result[31] ? 1'b1:1'b0);

assign vf = (ALUop==`Sub)&&(({data_a[31],data_b[31],result[31]}==3'b011)||({data_a[31],data_b[31],result[31]}==3'b100)) ? 1'b1:
            1'b0;
assign zf = result == 0 ? 1'b1: 1'b0;
assign alu_flag = {cf,zf,sf,vf};

endmodule
