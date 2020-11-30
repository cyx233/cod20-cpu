`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2020 10:41:00 AM
// Design Name: 
// Module Name: _base_ram_ctrl
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

`include "memory_header.vh"

module ram_ctrl(
    input wire oen,
    input wire wen,
    input wire base_en,
    input wire ext_en,
    input wire[31:0] data_in,
    input wire[31:0] addr_in,
    input wire[2:0] MemType,

    output wire[31:0] data_out,

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n       //ExtRAM写使能，低有效
);


reg data_z;
wire[1:0] offset;

assign base_ram_data = data_z? 32'bz : data_in;
assign ext_ram_data = data_z? 32'bz : data_in;
assign data_out = base_en ? base_ram_data:
                 (ext_en ? ext_ram_data : 32'bz);

assign base_ram_addr = addr_in[21:2];
assign ext_ram_addr = addr_in[21:2];
assign offset = addr_in[1:0];

reg[3:0] base_ram_be_n_flag;
reg base_ram_oe_n_flag;
reg base_ram_we_n_flag;
reg[3:0] ext_ram_be_n_flag;
reg ext_ram_oe_n_flag;
reg ext_ram_we_n_flag;

assign base_ram_be_n = base_ram_be_n_flag;
assign base_ram_oe_n = base_ram_oe_n_flag;
assign base_ram_we_n = base_ram_we_n_flag;

assign ext_ram_be_n = ext_ram_be_n_flag;
assign ext_ram_oe_n = ext_ram_oe_n_flag;
assign ext_ram_we_n = ext_ram_we_n_flag;


assign base_ram_ce_n = ~base_en;
assign ext_ram_ce_n = ~ext_en;


always @* begin
    base_ram_be_n_flag = 4'b1111;
    ext_ram_be_n_flag = 4'b1111;
    case(MemType)
        `Byte,`UByte:begin
            base_ram_be_n_flag[offset] = 1'b0;
            ext_ram_be_n_flag[offset] = 1'b0;
        end
        `HWord,`UHWord:begin
            if(offset[1])begin
                base_ram_be_n_flag = 4'b0011;
                ext_ram_be_n_flag = 4'b0011;
            end
            else begin
                base_ram_be_n_flag = 4'b1100;
                ext_ram_be_n_flag = 4'b1100;
            end
        end
        `Word:begin
            base_ram_be_n_flag = 4'b0000;
            ext_ram_be_n_flag = 4'b0000;
        end
    endcase
    data_z = 1'b1;
    base_ram_oe_n_flag = 1'b1;
    ext_ram_oe_n_flag = 1'b1;
    base_ram_we_n_flag = 1'b1;
    ext_ram_we_n_flag = 1'b1;
    if(~oen)begin
        data_z = 1'b1;
        base_ram_oe_n_flag = 1'b0;
        ext_ram_oe_n_flag = 1'b0;
    end
    if(~wen)begin
        data_z = 1'b0;
        base_ram_we_n_flag = 1'b0;
        ext_ram_we_n_flag = 1'b0;
    end
end
endmodule
