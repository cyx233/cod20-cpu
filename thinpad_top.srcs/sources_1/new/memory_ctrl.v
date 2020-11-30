`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2020 05:22:01 PM
// Design Name: 
// Module Name: memory_ctrl
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
`include "exception_header.vh"

module memory_ctrl(
    input wire clk_uart,
    input wire clk_cpu,
    input wire rst_cpu,
    input wire PCWrite,
    input wire IorD,
    input wire PCnow_Write,
    input wire MemWrite,
    input wire MemRead,
    input wire IRWrite,
    input wire sfence_vma,
    input wire[2:0] MemType,
    input wire[31:0] satp_in,
    input wire[1:0] privilege,

    input wire[31:0] PC_in,
    input wire[31:0] alu_result_in,
    input wire[31:0] data_to_write_in,

    inout wire[31:0] base_ram_data,
    output wire[19:0] base_ram_addr,
    output wire[3:0] base_ram_be_n,
    output wire base_ram_ce_n,
    output wire base_ram_oe_n,
    output wire base_ram_we_n,

    inout wire[31:0] ext_ram_data,
    output wire[19:0] ext_ram_addr,
    output wire[3:0] ext_ram_be_n,
    output wire ext_ram_ce_n,
    output wire ext_ram_oe_n,
    output wire ext_ram_we_n,

    output wire uart_rdn,         //读串口信号，低有效
    output wire uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志

    output wire[31:0] PC_out,
    output wire[31:0] PC_now_out,
    output wire[31:0] IR_out,
    output wire[31:0] DR_out,
    output wire uart_busy,
    output wire uart_work_init, 
    output wire uart_done,
    output wire address_done,
    output wire load_access_fault,
    output wire store_access_fault,
    output wire instr_access_fault,
    output wire[31:0] address
);


wire base_en,ext_en,uart_en;
wire oe_ram_n,oe_uart_n;
wire we_ram_n,we_uart_n;

reg[31:0] PC_reg;
reg[31:0] PC_now_reg;
reg[31:0] IR_reg;
reg[31:0] DR_reg;
reg[1:0] state;
reg[31:0] pte1;
reg[31:0] pte2;
reg[43:0] tlb_reg[63:0];


wire[31:0] ram_data_out;
wire[31:0] uart_data_out;
wire[1:0] byte_offset;
wire page_en;
wire[21:0] satp_ppn;
wire[31:0] address_origrin;
wire[31:0] address_vpn1;
wire[31:0] address_vpn2;
wire[11:0] address_offset;
wire[2:0] ram_MemType;
wire tlb_hit;

assign IR_out = IR_reg;
assign DR_out = DR_reg;
assign PC_out = PC_reg;
assign PC_now_out = PC_now_reg;
assign oe_ram_n = ~MemRead;
assign we_ram_n = ~MemWrite;
assign oe_uart_n = ~MemRead;
assign we_uart_n = ~MemWrite;

assign page_en = satp_in[31] && (privilege == `U_Mode) ? 1'b1:1'b0;
assign satp_ppn = satp_in[21:0];

assign address_origrin = IorD==1'b0 ? PC_reg : alu_result_in;
assign address_vpn1 = {satp_ppn[19:0],address_origrin[31:22],2'b00};
assign address_vpn2 = {pte1[29:10],address_origrin[21:12],2'b00};
assign address_offset = address_origrin[11:0];

assign tlb_hit = tlb_reg[address_origrin[31:26]][43]==1'b1 ? (
                    tlb_reg[address_origrin[31:26]][39:20]==address_origrin[31:12] ? 1'b1: 
                    1'b0):
                 1'b0;

assign address = page_en==1'b1 ? (
                    address_origrin==32'h10000000 ? address_origrin : 
                    address_origrin==32'h10000005 ? address_origrin : 
                    tlb_hit == 1'b1 ? {tlb_reg[address_origrin[31:26]][19:0],address_offset[11:0]}:
                    state == `STATE_LOAD_VPN1 ? address_vpn1 :
                    state == `STATE_LOAD_VPN2 ? address_vpn2 :
                    {pte2[29:10],address_offset[11:0]}):
                 address_origrin;

assign byte_offset = IorD==1'b0 ? PC_reg[1:0] : alu_result_in[1:0];


assign load_access_fault = page_en==1'b1 ? (
                            (tlb_hit==1'b1)&&(tlb_reg[address_origrin[31:26]][42]==1'b0) ? 1'b1:
                            (state==`STATE_LOAD_PPN)&&(pte2[1]==1'b0) ? 1'b1:
                            1'b0):
                           1'b0;

assign store_access_fault = page_en==1'b1 ? (
                                (tlb_hit==1'b1)&&(tlb_reg[address_origrin[31:26]][41]==1'b0) ? 1'b1:
                                (state==`STATE_LOAD_PPN)&&(pte2[2]==1'b0) ? 1'b1:
                                1'b0):
                            1'b0;

assign instr_access_fault = page_en==1'b1 ? (
                                (tlb_hit==1'b1)&&(tlb_reg[address_origrin[31:26]][40]==1'b0) ? 1'b1:
                                (state==`STATE_LOAD_PPN)&&(pte2[3]==1'b0) ? 1'b1:
                                1'b0):
                            1'b0;

assign ram_MemType = address_done==1'b1 ? `Word : MemType;

ram_ctrl _ram_ctrl(
    .oen(oe_ram_n),
    .wen(we_ram_n),
    .base_en(base_en),
    .ext_en(ext_en),
    .data_in(data_to_write_in),
    .addr_in(address),
    .MemType(ram_MemType),
    
    .data_out(ram_data_out),

    .base_ram_data(base_ram_data),
    .base_ram_addr(base_ram_addr),
    .base_ram_be_n(base_ram_be_n),
    .base_ram_ce_n(base_ram_ce_n),
    .base_ram_oe_n(base_ram_oe_n),
    .base_ram_we_n(base_ram_we_n),

    .ext_ram_data(ext_ram_data),
    .ext_ram_addr(ext_ram_addr),
    .ext_ram_be_n(ext_ram_be_n),
    .ext_ram_ce_n(ext_ram_ce_n),
    .ext_ram_oe_n(ext_ram_oe_n),
    .ext_ram_we_n(ext_ram_we_n)
);

uart_io _uart_io(
    .clk(clk_uart),
    .rst(rst_cpu),
    .uart_en(uart_en),
    .oen(oe_uart_n),
    .wen(we_uart_n),
    .data_in(data_to_write_in),
    .data_out(uart_data_out),
    .busy(uart_busy),
    .done(uart_done),
    .ready_to_work(uart_work_init),
    
    .base_ram_data_wire(base_ram_data),
    
    .uart_rdn(uart_rdn),
    .uart_wrn(uart_wrn),
    .uart_dataready(uart_dataready),
    .uart_tbre(uart_tbre),
    .uart_tsre(uart_tsre)
);

wire[31:0] select_data_out;
wire[31:0] sign;
wire[31:0] sign_ext_result;

assign base_en = (address[31:24]==8'h80) && (address[23:22]==2'b00) ? 1'b1 : 1'b0;
assign ext_en = (address[31:24]==8'h80) && (address[23:22]==2'b01) ? 1'b1 : 1'b0;
assign uart_en = address==32'h10000000 ? 1'b1 : 1'b0;

assign address_done = page_en == 1'b1 ? (
                        tlb_hit==1'b1 ? 1'b1:
                        state == `STATE_LOAD_PPN ? 1'b1:
                        (~base_en)&&(~ext_en) ? 1'b1:
                        1'b0):
                      1'b1;

assign select_data_out = address==32'h10000000 ? uart_data_out :
                         address==32'h10000005 ? {16'h0000,2'b00,~uart_busy,1'b0,3'b000,uart_dataready,8'h00} :
                         address[31:24]==8'h80 ? ram_data_out : 32'h00000000;

assign sign = (MemType == `Byte) && select_data_out[byte_offset*8+7] ? 32'hffffffff :
             (MemType == `HWord) && byte_offset[byte_offset*16+15] ? 32'hffffffff:32'h00000000;

assign sign_ext_result = (MemType==`Byte)||(MemType==`UByte) ?
                            (byte_offset==0 ? {sign[23:0],select_data_out[7:0]} :
                            byte_offset==1 ? {sign[23:0],select_data_out[15:8]} :
                            byte_offset==2 ? {sign[23:0],select_data_out[23:16]} :
                            {sign[23:0],select_data_out[31:24]}) :
                         (MemType==`HWord)||(MemType==`UHWord) ?
                            (byte_offset[1] ? {sign[15:0],select_data_out[31:16]} :
                            {sign[15:0],select_data_out[15:0]}) :
                         select_data_out;

integer i;
always @(posedge clk_cpu or posedge rst_cpu) begin
    if(rst_cpu)begin
        for(i=0; i<64; i=i+1)begin
            tlb_reg[i] <= 41'h00000000000;
        end
        PC_reg <= 32'h80000000;
        PC_now_reg <= 32'h80000000;
        IR_reg <= 32'h00000000;
        DR_reg <= 32'h00000000;
        pte1 <= 32'h00000000;
        pte2 <= 32'h00000000;
        state <= `STATE_LOAD_VPN1;
    end
    else begin
        if(PCWrite)begin
            PC_reg <= PC_in;
        end
        if(PCnow_Write)begin
            PC_now_reg <= PC_reg;
        end
        if(IRWrite)begin
            IR_reg <= sign_ext_result; 
        end
        if(sfence_vma)begin
            state <= `STATE_LOAD_VPN1;
            for(i=0; i<64; i=i+1)begin
                tlb_reg[i] <= 41'h00000000000;
            end
        end
        else if((page_en==1) && (MemWrite||MemRead) && (base_en||ext_en) && (tlb_hit==1'b0))begin
            case(state)
                `STATE_LOAD_VPN1:begin
                    pte1 <= ram_data_out;
                    state<=`STATE_LOAD_VPN2;
                end
                `STATE_LOAD_VPN2:begin
                    pte2 <= ram_data_out;
                    state<=`STATE_LOAD_PPN;
                end
                `STATE_LOAD_PPN:begin
                    tlb_reg[address_origrin[31:26]] <= {1'b1,pte2[1],pte2[2],pte2[3],address_origrin[31:12],address[31:12]};
                    DR_reg <= sign_ext_result;
                    state<=`STATE_LOAD_VPN1;
                end
            endcase
        end
        else begin
            state <= `STATE_LOAD_VPN1;
            DR_reg <= sign_ext_result;
        end
    end
end

endmodule
