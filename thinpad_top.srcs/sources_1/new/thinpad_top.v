`default_nettype none
`include "center_header.vh"
`include "exception_header.vh"

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //CPLD串口控制器信号
    output wire uart_rdn,         //读串口信号，低有效
    output wire uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志

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
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB数据线与网络控制器的dm9k_sd[7:0]共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);


reg[3:0] state;
wire clk_cpu;

wire PCWrite,IorD,PCnow_Write,MemWrite,MemRead,uart_done,uart_busy,uart_work_init,address_done,
    load_access_fault,store_access_fault,instr_access_fault,sfence_vma;
wire IRWrite,RegWrite,CsrWrite;
wire[1:0] privilege;
wire[1:0] PCsrc,RDsrc,ALUsrcA;
wire[2:0] ImmSE,MemType,ALUsrcB;
wire[4:0] ALUop;

wire[31:0] Expt_code;
wire[31:0] PCwire,PCnow,IRget,DRget,address;
wire[31:0] RegDataA,RegDataB,ImmGen,csr_out,satp;

wire[3:0] ALUflag;
wire[31:0] PCalu,ALUout;

// PLL分频示例
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // 外部时钟输入
  // Clock out ports
  .clk_out1(clk_10M), // 时钟输出1，频率在IP配置界面中设置
  .clk_out2(clk_20M), // 时钟输出2，频率在IP配置界面中设置
  // Status and control signals
  .reset(reset_btn), // PLL复位输入
  .locked(locked)    // PLL锁定指示输出，"1"表示时钟稳定，
                     // 后级电路复位信号应当由它生成（见下）
 );

reg reset_of_clk;
// 异步复位，同步释放，将locked信号转为后级电路的复位reset_of_clk10M
always@(posedge clk_20M or negedge locked) begin
    if(~locked) reset_of_clk <= 1'b1;
    else        reset_of_clk <= 1'b0;
end

assign clk_cpu = clk_20M;

center_ctrl _center_ctrl(
    .address(address),
    .IR_in(IRget),
    .alu_flag(ALUflag),
    .state(state),
    .privilege(privilege),
    .address_done(address_done),
    .load_access_fault(load_access_fault),
    .store_access_fault(store_access_fault),
    .instr_access_fault(instr_access_fault),

    .PCWrite(PCWrite),
    .IorD(IorD),
    .PCnowWrite(PCnow_Write),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .MemType(MemType),
    .IRWrite(IRWrite),
    .sfence_vma(sfence_vma),

    .RDsrc(RDsrc),
    .ImmSE(ImmSE),
    .RegWrite(RegWrite),
    .CsrWrite(CsrWrite),
    .Expt_code(Expt_code),

    .ALUsrcA(ALUsrcA),
    .ALUsrcB(ALUsrcB),
    .ALUop(ALUop),
    .PCsrc(PCsrc)
);

memory_ctrl _memory_ctrl(
    .clk_uart(clk_cpu),
    .clk_cpu(clk_cpu),
    .rst_cpu(reset_of_clk),
    .PCWrite(PCWrite),
    .IorD(IorD),
    .PCnow_Write(PCnow_Write),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .IRWrite(IRWrite),
    .MemType(MemType),
    .satp_in(satp),
    .privilege(privilege),
    .sfence_vma(sfence_vma),

    .PC_in(PCalu),
    .alu_result_in(ALUout),
    .data_to_write_in(RegDataB),

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
    .ext_ram_we_n(ext_ram_we_n),

    .uart_rdn(uart_rdn),              
    .uart_wrn(uart_wrn),              
    .uart_dataready(uart_dataready),  
    .uart_tbre(uart_tbre),            
    .uart_tsre(uart_tsre),            

    .PC_out(PCwire),
    .PC_now_out(PCnow),
    .IR_out(IRget),
    .DR_out(DRget),
    .uart_busy(uart_busy),
    .uart_work_init(uart_work_init), 
    .uart_done(uart_done),
    .address(address),
    .load_access_fault(load_access_fault),
    .store_access_fault(store_access_fault),
    .instr_access_fault(instr_access_fault),
    .address_done(address_done)
); 

register_heap_ctrl _register_heap_ctrl(
    .clk(clk_cpu),
    .rst(reset_of_clk),
    .RDsrc(RDsrc),
    .ImmSE(ImmSE),
    .RegWrite(RegWrite),

    .IR_in(IRget),
    .DR_in(DRget),
    .alu_result(ALUout),
    .PC_in(PCwire),
    .PC_now_in(PCnow),

    .Imm_out(ImmGen),
    .data_a_out(RegDataA),
    .data_b_out(RegDataB),

    .CsrWrite(CsrWrite),
    .Expt_code(Expt_code),

    .csr_out(csr_out),
    .privilege(privilege),
    .satp_out(satp)
);

alu_ctrl _alu_ctrl(
    .clk(clk_cpu),
    .rst(reset_of_clk),
    .ALUsrcA(ALUsrcA),
    .ALUsrcB(ALUsrcB),
    .PCsrc(PCsrc),
    .ALUop(ALUop),
    .data_a0_pc(PCwire),
    .data_a1_pcnow(PCnow),
    .data_a2_rs1(RegDataA),
    .data_b0_4(32'h0004),
    .data_b1_rs2(RegDataB),
    .data_b2_imm(ImmGen),
    .data_b3_csr(csr_out),
    .alu_result(ALUout),
    .alu_flag(ALUflag),
    .PC_out(PCalu)
);

wire[6:0] op;
wire[2:0] func3;
wire[6:0] func7;
assign op = IRget[6:0];
assign func3 = IRget[14:12];
assign func7 = IRget[31:25];

always @(posedge clk_cpu or posedge reset_of_clk) begin
    if(reset_of_clk || (Expt_code!=`No_Exception))begin
        state <= `STATE_FETCH;
    end
    else begin
        case(state)
            `STATE_FETCH:begin
                if(address_done)begin
                    state <= `STATE_DECODE;
                end
            end
            `STATE_DECODE:begin
                case(op)
                    `I_LOAD,`S_INSTR:begin
                        state <= `STATE_MEM_ADR;
                    end
                    `R_INSTR,`I_LOGIC,`JALR,`LUI,`AUIPC:begin
                        state <= `STATE_EXECUTE;
                    end
                    `B_INSTR,`JAL:begin
                        state <= `STATE_BRANCH;
                    end
                    `EXPT:begin
                        if(func3==3'b000)begin
                            if(func7==7'b0001001)begin //sfence
                                state <= `STATE_FETCH;
                            end
                            else begin
                                state <= `STATE_BRANCH;
                            end
                        end
                        else begin
                            state <= `STATE_EXECUTE;
                        end
                    end
                endcase
            end
            `STATE_MEM_ADR:begin
                case(op)
                    `I_LOAD:begin
                        state <= `STATE_MEM_READ;
                    end
                    `S_INSTR:begin
                        state <= `STATE_MEM_WRITE;
                    end
                endcase
            end
            `STATE_EXECUTE:begin
                state <= `STATE_ALU_WRITE_BACK;
            end
            `STATE_BRANCH:begin
                state <= `STATE_FETCH;
            end
            `STATE_MEM_WRITE:begin
                if(~uart_work_init && ((~uart_busy)||uart_done) && address_done)begin
                    state <= `STATE_FETCH;
                end
            end
            `STATE_MEM_READ:begin
                if(~uart_work_init && ((~uart_busy)||uart_done) && address_done)begin
                    state <= `STATE_MEM_WRITE_BACK;
                end
            end
            `STATE_MEM_WRITE_BACK:begin
                state <= `STATE_FETCH;
            end
            `STATE_ALU_WRITE_BACK:begin
                state <= `STATE_FETCH;
            end
        endcase
    end
end
endmodule
