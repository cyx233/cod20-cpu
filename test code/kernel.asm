
kernel.elf:     file format elf32-littleriscv


Disassembly of section .text:

80000000 <INITLOCATE>:
// 监控程序的入口点，.text.init 段放在内存的 0x80000000 位置，是最先执行的代码。
    .p2align 2
    .section .text.init
INITLOCATE:                         // 定位启动程序
    la s10, START
80000000:	00000d17          	auipc	s10,0x0
80000004:	00cd0d13          	addi	s10,s10,12 # 8000000c <START>
    jr s10
80000008:	000d0067          	jr	s10

8000000c <START>:
    .p2align 2

    .global START
START:
    // 清空 BSS
    la s10, _sbss
8000000c:	007f0d17          	auipc	s10,0x7f0
80000010:	ff4d0d13          	addi	s10,s10,-12 # 807f0000 <_sbss>
    la s11, _ebss
80000014:	007f0d97          	auipc	s11,0x7f0
80000018:	104d8d93          	addi	s11,s11,260 # 807f0118 <_ebss>

8000001c <bss_init>:
bss_init:
    beq s10, s11, bss_init_done
8000001c:	01bd0863          	beq	s10,s11,8000002c <bss_init_done>
    sw  zero, 0(s10)
80000020:	000d2023          	sw	zero,0(s10)
    addi s10, s10, 4
80000024:	004d0d13          	addi	s10,s10,4
    j   bss_init
80000028:	ff5ff06f          	j	8000001c <bss_init>

8000002c <bss_init_done>:

bss_init_done:
#ifdef ENABLE_INT
    // 设置异常处理地址寄存器 mtvec
    la s0, EXCEPTION_HANDLER
8000002c:	00000417          	auipc	s0,0x0
80000030:	4d440413          	addi	s0,s0,1236 # 80000500 <EXCEPTION_HANDLER>
    csrw mtvec, s0
80000034:	30541073          	csrw	mtvec,s0
    
    // 判断是否设置成功（mtvec 是 WARL）
    csrr t0, mtvec
80000038:	305022f3          	csrr	t0,mtvec
    beq t0, s0, mtvec_done
8000003c:	00828a63          	beq	t0,s0,80000050 <mtvec_done>
    
    // 不成功，尝试 MODE=VECTORED
    la s0, VECTORED_EXCEPTION_HANDLER
80000040:	00000417          	auipc	s0,0x0
80000044:	6c040413          	addi	s0,s0,1728 # 80000700 <VECTORED_EXCEPTION_HANDLER>
    ori s0, s0, 1
80000048:	00146413          	ori	s0,s0,1
    csrw mtvec, s0
8000004c:	30541073          	csrw	mtvec,s0

80000050 <mtvec_done>:
mtvec_done:
#endif

    la sp, KERNEL_STACK_INIT         // 设置内核栈
80000050:	00800117          	auipc	sp,0x800
80000054:	fb010113          	addi	sp,sp,-80 # 80800000 <KERNEL_STACK_INIT>
    or s0, sp, zero
80000058:	00016433          	or	s0,sp,zero
    li t0, USER_STACK_INIT          // 设置用户栈
8000005c:	800002b7          	lui	t0,0x80000
    // 设置用户态程序的 sp(x2) 和 fp(x8) 寄存器
    la t1, uregs_sp
80000060:	007f0317          	auipc	t1,0x7f0
80000064:	fa430313          	addi	t1,t1,-92 # 807f0004 <uregs_sp>
    STORE t0, 0(t1)
80000068:	00532023          	sw	t0,0(t1)
    la t1, uregs_fp
8000006c:	007f0317          	auipc	t1,0x7f0
80000070:	fb030313          	addi	t1,t1,-80 # 807f001c <uregs_fp>
    STORE t0, 0(t1)
80000074:	00532023          	sw	t0,0(t1)
    li t1, COM_IER_RDI
    sb t1, %lo(COM_IER_OFFSET)(t0)
#endif

    // 清空并留出空间用于存储中断帧
    li t0, TF_SIZE
80000078:	08000293          	li	t0,128
.LC0:
    addi t0, t0, -XLEN
8000007c:	ffc28293          	addi	t0,t0,-4 # 7ffffffc <KERNEL_STACK_INIT+0xff7ffffc>
    addi sp, sp, -XLEN
80000080:	ffc10113          	addi	sp,sp,-4
    STORE zero, 0(sp)
80000084:	00012023          	sw	zero,0(sp)
    bne t0, zero, .LC0
80000088:	fe029ae3          	bnez	t0,8000007c <mtvec_done+0x2c>

    la t0, TCBT               // 载入TCBT地址
8000008c:	007f0297          	auipc	t0,0x7f0
80000090:	07428293          	addi	t0,t0,116 # 807f0100 <TCBT>
    STORE sp, 0(t0)           // thread0(idle)的中断帧地址设置
80000094:	0022a023          	sw	sp,0(t0)

    mv t6, sp                 // t6保存idle中断帧位置
80000098:	00010f93          	mv	t6,sp

    li t0, TF_SIZE
8000009c:	08000293          	li	t0,128
.LC1:
    addi t0, t0, -XLEN              // 滚动计数器
800000a0:	ffc28293          	addi	t0,t0,-4
    addi sp, sp, -XLEN              // 移动栈指针
800000a4:	ffc10113          	addi	sp,sp,-4
    STORE zero, 0(sp)               // 初始化栈空间
800000a8:	00012023          	sw	zero,0(sp)
    bne t0, zero, .LC1              // 初始化循环
800000ac:	fe029ae3          	bnez	t0,800000a0 <mtvec_done+0x50>

    la t0, TCBT                     // 载入TCBT地址
800000b0:	007f0297          	auipc	t0,0x7f0
800000b4:	05028293          	addi	t0,t0,80 # 807f0100 <TCBT>
    STORE sp, XLEN(t0)                    // thread1(shell/user)的中断帧地址设置
800000b8:	0022a223          	sw	sp,4(t0)
    STORE sp, TF_sp(t6)                // 设置idle线程栈指针(调试用?)
800000bc:	002fa223          	sw	sp,4(t6)

    la t2, TCBT + XLEN
800000c0:	007f0397          	auipc	t2,0x7f0
800000c4:	04438393          	addi	t2,t2,68 # 807f0104 <TCBT+0x4>
    LOAD t2, 0(t2)                    // 取得thread1的TCB地址
800000c8:	0003a383          	lw	t2,0(t2)

#ifdef ENABLE_INT
    csrw mscratch, t2              // 设置当前线程为thread1
800000cc:	34039073          	csrw	mscratch,t2
#endif

    la t1, current   
800000d0:	007f0317          	auipc	t1,0x7f0
800000d4:	04030313          	addi	t1,t1,64 # 807f0110 <current>
    sw t2, 0(t1)
800000d8:	00732023          	sw	t2,0(t1)

#ifdef ENABLE_PAGING
#ifdef RV32
    // 一级页表，PAGE_TABLE 为一级页表
    la t0, PAGE_TABLE
800000dc:	00002297          	auipc	t0,0x2
800000e0:	f2428293          	addi	t0,t0,-220 # 80002000 <PAGE_TABLE>
#endif

    // 填写用户代码的页表
    // 需要映射 0x00000000-0x002FF000
    // Sv32 时都在一个页中
    la t1, PAGE_TABLE_USER_CODE
800000e4:	00003317          	auipc	t1,0x3
800000e8:	f1c30313          	addi	t1,t1,-228 # 80003000 <PAGE_TABLE_USER_CODE>
#ifdef RV32
    li t3, 768
800000ec:	30000e13          	li	t3,768
#else
    li t3, 512
#endif
    li t2, 0
800000f0:	00000393          	li	t2,0
.LOOP_USER_CODE:
    li t4, 0x200400fb  // 0x80100000 DAGUX-RV
800000f4:	20040eb7          	lui	t4,0x20040
800000f8:	0fbe8e93          	addi	t4,t4,251 # 200400fb <INITLOCATE-0x5ffbff05>
    slli t5, t2, 10
800000fc:	00a39f13          	slli	t5,t2,0xa
    add t4, t4, t5
80000100:	01ee8eb3          	add	t4,t4,t5
    sw t4, 0(t1)
80000104:	01d32023          	sw	t4,0(t1)
    addi t1, t1, XLEN
80000108:	00430313          	addi	t1,t1,4
    addi t2, t2, 1
8000010c:	00138393          	addi	t2,t2,1
    bne t2, t3, .LOOP_USER_CODE
80000110:	ffc392e3          	bne	t2,t3,800000f4 <mtvec_done+0xa4>

    la t1, PAGE_TABLE_USER_CODE
80000114:	00003317          	auipc	t1,0x3
80000118:	eec30313          	addi	t1,t1,-276 # 80003000 <PAGE_TABLE_USER_CODE>
    srli t1, t1, 2
8000011c:	00235313          	srli	t1,t1,0x2
    ori t1, t1, 0xf1
80000120:	0f136313          	ori	t1,t1,241
    sw t1, 0(t0)
80000124:	0062a023          	sw	t1,0(t0)
    sw t1, 8(t0)
#endif

    // 内核代码段映射
    // 需要映射 0x80000000 和 0x80100000
    la t0, PAGE_TABLE
80000128:	00002297          	auipc	t0,0x2
8000012c:	ed828293          	addi	t0,t0,-296 # 80002000 <PAGE_TABLE>
    la t1, PAGE_TABLE_KERNEL_CODE
80000130:	00004317          	auipc	t1,0x4
80000134:	ed030313          	addi	t1,t1,-304 # 80004000 <PAGE_TABLE_KERNEL_CODE>
    srli t1, t1, 2
80000138:	00235313          	srli	t1,t1,0x2
    ori t1, t1, 0xf1
8000013c:	0f136313          	ori	t1,t1,241
#ifdef RV32
    li t2, 512*4
80000140:	000013b7          	lui	t2,0x1
80000144:	80038393          	addi	t2,t2,-2048 # 800 <INITLOCATE-0x7ffff800>
#else
    li t2, 2*8
#endif
    add t2, t0, t2
80000148:	007283b3          	add	t2,t0,t2
    sw t1, 0(t2)
8000014c:	0063a023          	sw	t1,0(t2)

    // 填写用户数据的页表
    // 需要映射 0x7FC10000-0x7FFFF000
    // Sv32 情况下在一个二级页表内
#ifdef RV32
    la t1, PAGE_TABLE_USER_STACK
80000150:	00005317          	auipc	t1,0x5
80000154:	eb030313          	addi	t1,t1,-336 # 80005000 <PAGE_TABLE_USER_STACK>
    addi t1, t1, 4*16
80000158:	04030313          	addi	t1,t1,64
    li t3, 1024
8000015c:	40000e13          	li	t3,1024
    li t2, 16
80000160:	01000393          	li	t2,16
.LOOP_USER_STACK:
    li t4, 0x200fc0f7  // 0x803F0000 DAGU-WRV
80000164:	200fceb7          	lui	t4,0x200fc
80000168:	0f7e8e93          	addi	t4,t4,247 # 200fc0f7 <INITLOCATE-0x5ff03f09>
    slli t5, t2, 10
8000016c:	00a39f13          	slli	t5,t2,0xa
    add t4, t4, t5
80000170:	01ee8eb3          	add	t4,t4,t5
    sw t4, 0(t1)
80000174:	01d32023          	sw	t4,0(t1)
    addi t1, t1, 4
80000178:	00430313          	addi	t1,t1,4
    addi t2, t2, 1
8000017c:	00138393          	addi	t2,t2,1
    bne t2, t3, .LOOP_USER_STACK
80000180:	ffc392e3          	bne	t2,t3,80000164 <mtvec_done+0x114>

    la t1, PAGE_TABLE_USER_STACK
80000184:	00005317          	auipc	t1,0x5
80000188:	e7c30313          	addi	t1,t1,-388 # 80005000 <PAGE_TABLE_USER_STACK>
    srli t1, t1, 2
8000018c:	00235313          	srli	t1,t1,0x2
    ori t1, t1, 0xf1
80000190:	0f136313          	ori	t1,t1,241
    li t2, 2044
80000194:	7fc00393          	li	t2,2044
    add t2, t0, t2
80000198:	007283b3          	add	t2,t0,t2
    sw t1, 0(t2)
8000019c:	0063a023          	sw	t1,0(t2)
    li t2, 8
    add t2, t0, t2
    sw t1, 0(t2)
#endif

    la t0, PAGE_TABLE
800001a0:	00002297          	auipc	t0,0x2
800001a4:	e6028293          	addi	t0,t0,-416 # 80002000 <PAGE_TABLE>
    srli t0, t0, 12
800001a8:	00c2d293          	srli	t0,t0,0xc
#ifdef RV32
    li t1, SATP_SV32
800001ac:	80000337          	lui	t1,0x80000
#else
    li t1, SATP_SV39
#endif
    or t0, t0, t1
800001b0:	0062e2b3          	or	t0,t0,t1
    csrw satp, t0
800001b4:	18029073          	csrw	satp,t0
    sfence.vma
800001b8:	12000073          	sfence.vma
#endif

    j WELCOME                       // 进入主线程
800001bc:	0040006f          	j	800001c0 <WELCOME>

800001c0 <WELCOME>:

WELCOME:
    la s1, monitor_version          // 装入启动信息
800001c0:	00001497          	auipc	s1,0x1
800001c4:	fac48493          	addi	s1,s1,-84 # 8000116c <monitor_version>
    lb a0, 0(s1)
800001c8:	00048503          	lb	a0,0(s1)
.Loop0:
    addi s1, s1, 0x1
800001cc:	00148493          	addi	s1,s1,1
    jal WRITE_SERIAL                // 调用串口写函数
800001d0:	6c8000ef          	jal	ra,80000898 <WRITE_SERIAL>
    lb a0, 0(s1)
800001d4:	00048503          	lb	a0,0(s1)
    bne a0, zero, .Loop0            // 打印循环至0结束符
800001d8:	fe051ae3          	bnez	a0,800001cc <WELCOME+0xc>

    j SHELL                         // 开始交互
800001dc:	0340006f          	j	80000210 <SHELL>

800001e0 <IDLELOOP>:

IDLELOOP:
    nop
800001e0:	00000013          	nop
    nop
800001e4:	00000013          	nop
    nop
800001e8:	00000013          	nop
    nop
800001ec:	00000013          	nop
    nop
800001f0:	00000013          	nop
    nop
800001f4:	00000013          	nop
    nop
800001f8:	00000013          	nop
    nop
800001fc:	00000013          	nop
    nop
80000200:	00000013          	nop
    nop
80000204:	00000013          	nop
    j IDLELOOP
80000208:	fd9ff06f          	j	800001e0 <IDLELOOP>
    nop
8000020c:	00000013          	nop

80000210 <SHELL>:
     * 
     *  用户空间寄存器：x1-x31依次保存在0x807F0000连续124字节
     *  用户程序入口临时存储：0x807F0000
     */
SHELL:
    jal READ_SERIAL                  // 读操作符
80000210:	70c000ef          	jal	ra,8000091c <READ_SERIAL>
    
    ori t0, zero, 'R'
80000214:	05206293          	ori	t0,zero,82
    beq a0, t0, .OP_R
80000218:	08550a63          	beq	a0,t0,800002ac <.OP_R>
    ori t0, zero, 'D'
8000021c:	04406293          	ori	t0,zero,68
    beq a0, t0, .OP_D
80000220:	0c550463          	beq	a0,t0,800002e8 <.OP_D>
    ori t0, zero, 'A'
80000224:	04106293          	ori	t0,zero,65
    beq a0, t0, .OP_A
80000228:	10550063          	beq	a0,t0,80000328 <.OP_A>
    ori t0, zero, 'G'
8000022c:	04706293          	ori	t0,zero,71
    beq a0, t0, .OP_G
80000230:	12550e63          	beq	a0,t0,8000036c <.OP_G>
    ori t0, zero, 'T'
80000234:	05406293          	ori	t0,zero,84
    beq a0, t0, .OP_T
80000238:	02550863          	beq	a0,t0,80000268 <.OP_T>
    ori t0, zero, 'E'
8000023c:	04506293          	ori	t0,zero,69
    beq a0, t0, .OP_E
80000240:	00550863          	beq	a0,t0,80000250 <.OP_E>

    li a0, XLEN                     // 错误的操作符，输出 XLEN，用于区分 RV32 和 RV64
80000244:	00400513          	li	a0,4
    jal WRITE_SERIAL                 // 把 XLEN 写给 term
80000248:	650000ef          	jal	ra,80000898 <WRITE_SERIAL>
    j .DONE                         
8000024c:	2ac0006f          	j	800004f8 <.DONE>

80000250 <.OP_E>:

.OP_E:
    li s0, 30
80000250:	01e00413          	li	s0,30
    li a0, 0x4F
80000254:	04f00513          	li	a0,79
    ecall
80000258:	00000073          	ecall
    li a0, 0x4B
8000025c:	04b00513          	li	a0,75
    ecall
80000260:	00000073          	ecall
    j .DONE    
80000264:	2940006f          	j	800004f8 <.DONE>

80000268 <.OP_T>:

.OP_T:                              // 操作 - 打印页表
    addi sp, sp, -3*XLEN
80000268:	ff410113          	addi	sp,sp,-12
    STORE s1, 0(sp)
8000026c:	00912023          	sw	s1,0(sp)
    STORE s2, XLEN(sp)
80000270:	01212223          	sw	s2,4(sp)

#ifdef ENABLE_PAGING
    csrr s1, satp
80000274:	180024f3          	csrr	s1,satp
    slli s1, s1, 12
80000278:	00c49493          	slli	s1,s1,0xc
#else
    li s1, -1
#endif
    STORE s1, 2*XLEN(sp)
8000027c:	00912423          	sw	s1,8(sp)
    addi s1, sp, 2*XLEN
80000280:	00810493          	addi	s1,sp,8
    li s2, XLEN
80000284:	00400913          	li	s2,4
.LC0:
    lb a0, 0(s1)           // 读取字节
80000288:	00048503          	lb	a0,0(s1)
    addi s2, s2, -1                 // 滚动计数器
8000028c:	fff90913          	addi	s2,s2,-1
    jal WRITE_SERIAL                 // 写入串口
80000290:	608000ef          	jal	ra,80000898 <WRITE_SERIAL>
    addi s1, s1, 0x1                // 移动打印指针
80000294:	00148493          	addi	s1,s1,1
    bne s2, zero, .LC0              // 打印循环
80000298:	fe0918e3          	bnez	s2,80000288 <.OP_T+0x20>

    LOAD s1, 0x0(sp)
8000029c:	00012483          	lw	s1,0(sp)
    LOAD s2, XLEN(sp)
800002a0:	00412903          	lw	s2,4(sp)
    addi sp, sp, 3*XLEN
800002a4:	00c10113          	addi	sp,sp,12

    j .DONE
800002a8:	2500006f          	j	800004f8 <.DONE>

800002ac <.OP_R>:

.OP_R:                              // 操作 - 打印用户空间寄存器
    addi sp, sp, -2*XLEN                 // 保存s1,s2
800002ac:	ff810113          	addi	sp,sp,-8
    STORE s1, 0(sp)
800002b0:	00912023          	sw	s1,0(sp)
    STORE s2, XLEN(sp)
800002b4:	01212223          	sw	s2,4(sp)

    la s1, uregs
800002b8:	007f0497          	auipc	s1,0x7f0
800002bc:	d4848493          	addi	s1,s1,-696 # 807f0000 <_sbss>
    ori s2, zero, 31*XLEN               // 计数器，打印 31 个寄存器
800002c0:	07c06913          	ori	s2,zero,124
.LC1:
    lb a0, 0(s1)           // 读取字节
800002c4:	00048503          	lb	a0,0(s1)
    addi s2, s2, -1                 // 滚动计数器
800002c8:	fff90913          	addi	s2,s2,-1
    jal WRITE_SERIAL                 // 写入串口
800002cc:	5cc000ef          	jal	ra,80000898 <WRITE_SERIAL>
    addi s1, s1, 0x1                // 移动打印指针
800002d0:	00148493          	addi	s1,s1,1
    bne s2, zero, .LC1              // 打印循环
800002d4:	fe0918e3          	bnez	s2,800002c4 <.OP_R+0x18>

    LOAD s1, 0(sp)                    // 恢复s1,s2
800002d8:	00012483          	lw	s1,0(sp)
    LOAD s2, XLEN(sp)
800002dc:	00412903          	lw	s2,4(sp)
    addi sp, sp, 2*XLEN
800002e0:	00810113          	addi	sp,sp,8
    j .DONE
800002e4:	2140006f          	j	800004f8 <.DONE>

800002e8 <.OP_D>:

.OP_D:                              // 操作 - 打印内存num字节
    addi sp, sp, -2*XLEN                 // 保存s1,s2
800002e8:	ff810113          	addi	sp,sp,-8
    STORE s1, 0(sp)
800002ec:	00912023          	sw	s1,0(sp)
    STORE s2, XLEN(sp)
800002f0:	01212223          	sw	s2,4(sp)

    jal READ_SERIAL_XLEN
800002f4:	6c4000ef          	jal	ra,800009b8 <READ_SERIAL_XLEN>
    or s1, a0, zero                 // 获得addr
800002f8:	000564b3          	or	s1,a0,zero
    jal READ_SERIAL_XLEN
800002fc:	6bc000ef          	jal	ra,800009b8 <READ_SERIAL_XLEN>
    or s2, a0, zero                 // 获得num
80000300:	00056933          	or	s2,a0,zero

.LC2:
    lb a0, 0(s1)                    // 读取字节
80000304:	00048503          	lb	a0,0(s1)
    addi s2, s2, -1                 // 滚动计数器
80000308:	fff90913          	addi	s2,s2,-1
    jal WRITE_SERIAL                 // 写入串口
8000030c:	58c000ef          	jal	ra,80000898 <WRITE_SERIAL>
    addi s1, s1, 0x1                // 移动打印指针
80000310:	00148493          	addi	s1,s1,1
    bne s2, zero, .LC2              // 打印循环
80000314:	fe0918e3          	bnez	s2,80000304 <.OP_D+0x1c>

    LOAD s1, 0(sp)                    // 恢复s1,s2
80000318:	00012483          	lw	s1,0(sp)
    LOAD s2, XLEN(sp)
8000031c:	00412903          	lw	s2,4(sp)
    addi sp, sp, 2*XLEN
80000320:	00810113          	addi	sp,sp,8
    j .DONE
80000324:	1d40006f          	j	800004f8 <.DONE>

80000328 <.OP_A>:

.OP_A:                              // 操作 - 写入内存num字节，num为4的倍数
    addi sp, sp, -2*XLEN                 // 保存s1,s2
80000328:	ff810113          	addi	sp,sp,-8
    STORE s1, 0(sp)
8000032c:	00912023          	sw	s1,0(sp)
    STORE s2, 4(sp)
80000330:	01212223          	sw	s2,4(sp)

    jal READ_SERIAL_XLEN
80000334:	684000ef          	jal	ra,800009b8 <READ_SERIAL_XLEN>
    or s1, a0, zero                 // 获得addr
80000338:	000564b3          	or	s1,a0,zero
    jal READ_SERIAL_XLEN
8000033c:	67c000ef          	jal	ra,800009b8 <READ_SERIAL_XLEN>
    or s2, a0, zero                 // 获得num
80000340:	00056933          	or	s2,a0,zero
    srl s2, s2, 2                   // num除4，获得字数
80000344:	00295913          	srli	s2,s2,0x2
.LC3:                               // 每次写入一字
    jal READ_SERIAL_WORD              // 从串口读入一字
80000348:	5f0000ef          	jal	ra,80000938 <READ_SERIAL_WORD>
    sw a0, 0(s1)                    // 写内存一字
8000034c:	00a4a023          	sw	a0,0(s1)
    addi s2, s2, -1                 // 滚动计数器
80000350:	fff90913          	addi	s2,s2,-1
    addi s1, s1, 4                  // 移动写指针
80000354:	00448493          	addi	s1,s1,4
    bne s2, zero, .LC3              // 写循环
80000358:	fe0918e3          	bnez	s2,80000348 <.OP_A+0x20>

#ifdef ENABLE_FENCEI
    fence.i                         // 有 Cache 时让写入的代码生效
#endif

    LOAD s1, 0(sp)                    // 恢复s1,s2
8000035c:	00012483          	lw	s1,0(sp)
    LOAD s2, XLEN(sp)
80000360:	00412903          	lw	s2,4(sp)
    addi sp, sp, 2*XLEN
80000364:	00810113          	addi	sp,sp,8
    j .DONE
80000368:	1900006f          	j	800004f8 <.DONE>

8000036c <.OP_G>:

.OP_G:
    jal READ_SERIAL_XLEN            // 获取addr
8000036c:	64c000ef          	jal	ra,800009b8 <READ_SERIAL_XLEN>
    mv s10, a0                      // 保存到 s10
80000370:	00050d13          	mv	s10,a0

80000374 <TEST>:
TEST:
    ori a0, zero, TIMERSET          // 写TIMERSET(0x06)信号
80000374:	00606513          	ori	a0,zero,6
    jal WRITE_SERIAL                 // 告诉终端用户程序开始运行
80000378:	520000ef          	jal	ra,80000898 <WRITE_SERIAL>

#ifdef ENABLE_INT
    csrw mepc, s10                // 用户程序入口写入EPC
8000037c:	341d1073          	csrw	mepc,s10
    li a0, MSTATUS_MPP_MASK
80000380:	00002537          	lui	a0,0x2
80000384:	80050513          	addi	a0,a0,-2048 # 1800 <INITLOCATE-0x7fffe800>
    csrc mstatus, a0     // 设置 MPP=0 ，对应 U-mode
80000388:	30053073          	csrc	mstatus,a0
#endif

    la ra, uregs              // 定位用户空间寄存器备份地址
8000038c:	007f0097          	auipc	ra,0x7f0
80000390:	c7408093          	addi	ra,ra,-908 # 807f0000 <_sbss>
    STORE sp, TF_ksp(ra)           // 保存栈指针
80000394:	0820a023          	sw	sp,128(ra)

    // LOAD x1,  TF_ra(ra)
    LOAD sp, TF_sp(ra)
80000398:	0040a103          	lw	sp,4(ra)
    LOAD gp, TF_gp(ra)
8000039c:	0080a183          	lw	gp,8(ra)
    LOAD tp, TF_tp(ra)
800003a0:	00c0a203          	lw	tp,12(ra)
    LOAD t0, TF_t0(ra)
800003a4:	0100a283          	lw	t0,16(ra)
    LOAD t1, TF_t1(ra)
800003a8:	0140a303          	lw	t1,20(ra)
    LOAD t2, TF_t2(ra)
800003ac:	0180a383          	lw	t2,24(ra)
    LOAD s0, TF_s0(ra)
800003b0:	01c0a403          	lw	s0,28(ra)
    LOAD s1, TF_s1(ra)
800003b4:	0200a483          	lw	s1,32(ra)
    LOAD a0, TF_a0(ra)
800003b8:	0240a503          	lw	a0,36(ra)
    LOAD a1, TF_a1(ra)
800003bc:	0280a583          	lw	a1,40(ra)
    LOAD a2, TF_a2(ra)
800003c0:	02c0a603          	lw	a2,44(ra)
    LOAD a3, TF_a3(ra)
800003c4:	0300a683          	lw	a3,48(ra)
    LOAD a4, TF_a4(ra)
800003c8:	0340a703          	lw	a4,52(ra)
    LOAD a5, TF_a5(ra)
800003cc:	0380a783          	lw	a5,56(ra)
    LOAD a6, TF_a6(ra)
800003d0:	03c0a803          	lw	a6,60(ra)
    LOAD a7, TF_a7(ra)
800003d4:	0400a883          	lw	a7,64(ra)
    LOAD s2, TF_s2(ra)
800003d8:	0440a903          	lw	s2,68(ra)
    LOAD s3, TF_s3(ra)
800003dc:	0480a983          	lw	s3,72(ra)
    LOAD s4, TF_s4(ra)
800003e0:	04c0aa03          	lw	s4,76(ra)
    LOAD s5, TF_s5(ra)
800003e4:	0500aa83          	lw	s5,80(ra)
    LOAD s6, TF_s6(ra)
800003e8:	0540ab03          	lw	s6,84(ra)
    LOAD s7, TF_s7(ra)
800003ec:	0580ab83          	lw	s7,88(ra)
    LOAD s8, TF_s8(ra)
800003f0:	05c0ac03          	lw	s8,92(ra)
    LOAD s9, TF_s9(ra)
800003f4:	0600ac83          	lw	s9,96(ra)
    // LOAD s10, TF_s10(ra)
    LOAD s11, TF_s11(ra)
800003f8:	0680ad83          	lw	s11,104(ra)
    LOAD t3, TF_t3(ra)
800003fc:	06c0ae03          	lw	t3,108(ra)
    LOAD t4, TF_t4(ra)
80000400:	0700ae83          	lw	t4,112(ra)
    LOAD t5, TF_t5(ra)
80000404:	0740af03          	lw	t5,116(ra)
    LOAD t6, TF_t6(ra)
80000408:	0780af83          	lw	t6,120(ra)

8000040c <.ENTER_UESR>:

.ENTER_UESR:
#ifdef ENABLE_INT
    la ra, .USERRET_USER                // ra写入返回地址
8000040c:	00000097          	auipc	ra,0x0
80000410:	00c08093          	addi	ra,ra,12 # 80000418 <.USERRET_USER>
    mret                                // 进入用户程序
80000414:	30200073          	mret

80000418 <.USERRET_USER>:
    jr s10
#endif

#ifdef ENABLE_INT
.USERRET_USER:
    ebreak
80000418:	00100073          	ebreak

8000041c <USERRET_MACHINE>:

    .global USERRET_MACHINE
USERRET_MACHINE:
    la s1, uregs
8000041c:	007f0497          	auipc	s1,0x7f0
80000420:	be448493          	addi	s1,s1,-1052 # 807f0000 <_sbss>
    li s2, TF_SIZE                  // 计数器
80000424:	08000913          	li	s2,128
.LC4:
    lw a0, 0(sp)
80000428:	00012503          	lw	a0,0(sp)
    sw a0, 0(s1)
8000042c:	00a4a023          	sw	a0,0(s1)
    addi s2, s2, -4                 // 滚动计数器
80000430:	ffc90913          	addi	s2,s2,-4
    addi s1, s1, 0x4
80000434:	00448493          	addi	s1,s1,4
    addi sp, sp, 0x4
80000438:	00410113          	addi	sp,sp,4
    bne s2, zero, .LC4
8000043c:	fe0916e3          	bnez	s2,80000428 <USERRET_MACHINE+0xc>

    la s1, uregs
80000440:	007f0497          	auipc	s1,0x7f0
80000444:	bc048493          	addi	s1,s1,-1088 # 807f0000 <_sbss>
    LOAD sp, TF_ksp(s1)             // 重新获得当前监控程序栈顶指针
80000448:	0804a103          	lw	sp,128(s1)

    ori a0, zero, TIMETOKEN         // 发送TIMETOKEN(0x07)信号
8000044c:	00706513          	ori	a0,zero,7
    jal WRITE_SERIAL                // 告诉终端用户程序结束运行
80000450:	448000ef          	jal	ra,80000898 <WRITE_SERIAL>

    j .DONE
80000454:	0a40006f          	j	800004f8 <.DONE>

80000458 <.USERRET2>:
#endif

.USERRET2:
    la ra, uregs              // 定位用户空间寄存器备份地址
80000458:	007f0097          	auipc	ra,0x7f0
8000045c:	ba808093          	addi	ra,ra,-1112 # 807f0000 <_sbss>

    //STORE ra, TF_ra(ra)
    STORE sp, TF_sp(ra)
80000460:	0020a223          	sw	sp,4(ra)
    STORE gp, TF_gp(ra)
80000464:	0030a423          	sw	gp,8(ra)
    STORE tp, TF_tp(ra)
80000468:	0040a623          	sw	tp,12(ra)
    STORE t0, TF_t0(ra)
8000046c:	0050a823          	sw	t0,16(ra)
    STORE t1, TF_t1(ra)
80000470:	0060aa23          	sw	t1,20(ra)
    STORE t2, TF_t2(ra)
80000474:	0070ac23          	sw	t2,24(ra)
    STORE s0, TF_s0(ra)
80000478:	0080ae23          	sw	s0,28(ra)
    STORE s1, TF_s1(ra)
8000047c:	0290a023          	sw	s1,32(ra)
    STORE a0, TF_a0(ra)
80000480:	02a0a223          	sw	a0,36(ra)
    STORE a1, TF_a1(ra)
80000484:	02b0a423          	sw	a1,40(ra)
    STORE a2, TF_a2(ra)
80000488:	02c0a623          	sw	a2,44(ra)
    STORE a3, TF_a3(ra)
8000048c:	02d0a823          	sw	a3,48(ra)
    STORE a4, TF_a4(ra)
80000490:	02e0aa23          	sw	a4,52(ra)
    STORE a5, TF_a5(ra)
80000494:	02f0ac23          	sw	a5,56(ra)
    STORE a6, TF_a6(ra)
80000498:	0300ae23          	sw	a6,60(ra)
    STORE a7, TF_a7(ra)
8000049c:	0510a023          	sw	a7,64(ra)
    STORE s2, TF_s2(ra)
800004a0:	0520a223          	sw	s2,68(ra)
    STORE s3, TF_s3(ra)
800004a4:	0530a423          	sw	s3,72(ra)
    STORE s4, TF_s4(ra)
800004a8:	0540a623          	sw	s4,76(ra)
    STORE s5, TF_s5(ra)
800004ac:	0550a823          	sw	s5,80(ra)
    STORE s6, TF_s6(ra)
800004b0:	0560aa23          	sw	s6,84(ra)
    STORE s7, TF_s7(ra)
800004b4:	0570ac23          	sw	s7,88(ra)
    STORE s8, TF_s8(ra)
800004b8:	0580ae23          	sw	s8,92(ra)
    STORE s9, TF_s9(ra)
800004bc:	0790a023          	sw	s9,96(ra)
    STORE s10, TF_s10(ra)
800004c0:	07a0a223          	sw	s10,100(ra)
    STORE s11, TF_s11(ra)
800004c4:	07b0a423          	sw	s11,104(ra)
    STORE t3, TF_t3(ra)
800004c8:	07c0a623          	sw	t3,108(ra)
    STORE t4, TF_t4(ra)
800004cc:	07d0a823          	sw	t4,112(ra)
    STORE t5, TF_t5(ra)
800004d0:	07e0aa23          	sw	t5,116(ra)
    STORE t6, TF_t6(ra)
800004d4:	07f0ac23          	sw	t6,120(ra)

    LOAD sp, TF_ksp(ra)             // 重新获得当前监控程序栈顶指针
800004d8:	0800a103          	lw	sp,128(ra)
    mv a0, ra
800004dc:	00008513          	mv	a0,ra
    la ra, .USERRET2
800004e0:	00000097          	auipc	ra,0x0
800004e4:	f7808093          	addi	ra,ra,-136 # 80000458 <.USERRET2>
    STORE ra, TF_ra(a0)
800004e8:	00152023          	sw	ra,0(a0)

    ori a0, zero, TIMETOKEN         // 发送TIMETOKEN(0x07)信号
800004ec:	00706513          	ori	a0,zero,7
    jal WRITE_SERIAL                // 告诉终端用户程序结束运行
800004f0:	3a8000ef          	jal	ra,80000898 <WRITE_SERIAL>

    j .DONE
800004f4:	0040006f          	j	800004f8 <.DONE>

800004f8 <.DONE>:

.DONE:
    j SHELL                         // 交互循环
800004f8:	d19ff06f          	j	80000210 <SHELL>
800004fc:	0000                	unimp
	...

80000500 <EXCEPTION_HANDLER>:
    .text
    .global EXCEPTION_HANDLER

#ifdef ENABLE_INT
EXCEPTION_HANDLER:
    csrrw sp, mscratch, sp          // 交换 mscratch 和 sp ，保存上下文
80000500:	34011173          	csrrw	sp,mscratch,sp

    STORE ra, TF_ra(sp)
80000504:	00112023          	sw	ra,0(sp)
    csrrw ra, mscratch, sp          // 读出原来的 sp
80000508:	340110f3          	csrrw	ra,mscratch,sp
    STORE ra, TF_sp(sp)
8000050c:	00112223          	sw	ra,4(sp)
    STORE gp, TF_gp(sp)
80000510:	00312423          	sw	gp,8(sp)
    STORE tp, TF_tp(sp)
80000514:	00412623          	sw	tp,12(sp)
    STORE t0, TF_t0(sp)
80000518:	00512823          	sw	t0,16(sp)
    STORE t1, TF_t1(sp)
8000051c:	00612a23          	sw	t1,20(sp)
    STORE t2, TF_t2(sp)
80000520:	00712c23          	sw	t2,24(sp)
    STORE s0, TF_s0(sp)
80000524:	00812e23          	sw	s0,28(sp)
    STORE s1, TF_s1(sp)
80000528:	02912023          	sw	s1,32(sp)
    STORE a0, TF_a0(sp)
8000052c:	02a12223          	sw	a0,36(sp)
    STORE a1, TF_a1(sp)
80000530:	02b12423          	sw	a1,40(sp)
    STORE a2, TF_a2(sp)
80000534:	02c12623          	sw	a2,44(sp)
    STORE a3, TF_a3(sp)
80000538:	02d12823          	sw	a3,48(sp)
    STORE a4, TF_a4(sp)
8000053c:	02e12a23          	sw	a4,52(sp)
    STORE a5, TF_a5(sp)
80000540:	02f12c23          	sw	a5,56(sp)
    STORE a6, TF_a6(sp)
80000544:	03012e23          	sw	a6,60(sp)
    STORE a7, TF_a7(sp)
80000548:	05112023          	sw	a7,64(sp)
    STORE s2, TF_s2(sp)
8000054c:	05212223          	sw	s2,68(sp)
    STORE s3, TF_s3(sp)
80000550:	05312423          	sw	s3,72(sp)
    STORE s4, TF_s4(sp)
80000554:	05412623          	sw	s4,76(sp)
    STORE s5, TF_s5(sp)
80000558:	05512823          	sw	s5,80(sp)
    STORE s6, TF_s6(sp)
8000055c:	05612a23          	sw	s6,84(sp)
    STORE s7, TF_s7(sp)
80000560:	05712c23          	sw	s7,88(sp)
    STORE s8, TF_s8(sp)
80000564:	05812e23          	sw	s8,92(sp)
    STORE s9, TF_s9(sp)
80000568:	07912023          	sw	s9,96(sp)
    STORE s10, TF_s10(sp)
8000056c:	07a12223          	sw	s10,100(sp)
    STORE s11, TF_s11(sp)
80000570:	07b12423          	sw	s11,104(sp)
    STORE t3, TF_t3(sp)
80000574:	07c12623          	sw	t3,108(sp)
    STORE t4, TF_t4(sp)
80000578:	07d12823          	sw	t4,112(sp)
    STORE t5, TF_t5(sp)
8000057c:	07e12a23          	sw	t5,116(sp)
    STORE t6, TF_t6(sp)
80000580:	07f12c23          	sw	t6,120(sp)
    csrr t0, mepc
80000584:	341022f3          	csrr	t0,mepc
    STORE t0, TF_epc(sp)
80000588:	06512e23          	sw	t0,124(sp)

    csrr t0, mcause
8000058c:	342022f3          	csrr	t0,mcause
    li t1, EX_INT_FLAG
80000590:	80000337          	lui	t1,0x80000
    and t1, t0, t1
80000594:	0062f333          	and	t1,t0,t1
    bne t1, zero, .HANDLE_INT
80000598:	04031263          	bnez	t1,800005dc <.HANDLE_INT>
    li t1, EX_ECALL_U
8000059c:	00800313          	li	t1,8
    beq t1, t0, .HANDLE_ECALL
800005a0:	00530863          	beq	t1,t0,800005b0 <.HANDLE_ECALL>
    li t1, EX_BREAK
800005a4:	00300313          	li	t1,3
    beq t1, t0, .HANDLE_BREAK
800005a8:	02530863          	beq	t1,t0,800005d8 <.HANDLE_BREAK>

    j FATAL
800005ac:	2540006f          	j	80000800 <FATAL>

800005b0 <.HANDLE_ECALL>:

.HANDLE_ECALL:
    LOAD t0, TF_epc(sp)
800005b0:	07c12283          	lw	t0,124(sp)
    addi t0, t0, 0x4
800005b4:	00428293          	addi	t0,t0,4
    STORE t0, TF_epc(sp)
800005b8:	06512e23          	sw	t0,124(sp)

    LOAD t0, TF_s0(sp)
800005bc:	01c12283          	lw	t0,28(sp)
    li t1, SYS_putc
800005c0:	01e00313          	li	t1,30
    beq t0, t1, .HANDLE_ECALL_PUTC
800005c4:	00628463          	beq	t0,t1,800005cc <.HANDLE_ECALL_PUTC>

    // 忽略其他系统调用
    j CONTEXT_SWITCH
800005c8:	0180006f          	j	800005e0 <CONTEXT_SWITCH>

800005cc <.HANDLE_ECALL_PUTC>:

.HANDLE_ECALL_PUTC:
    LOAD a0, TF_a0(sp)
800005cc:	02412503          	lw	a0,36(sp)
    jal WRITE_SERIAL
800005d0:	2c8000ef          	jal	ra,80000898 <WRITE_SERIAL>
    j CONTEXT_SWITCH
800005d4:	00c0006f          	j	800005e0 <CONTEXT_SWITCH>

800005d8 <.HANDLE_BREAK>:

.HANDLE_BREAK:
    j USERRET_MACHINE
800005d8:	e45ff06f          	j	8000041c <USERRET_MACHINE>

800005dc <.HANDLE_INT>:

.HANDLE_INT:
    // 暂未实现
    j FATAL
800005dc:	2240006f          	j	80000800 <FATAL>

800005e0 <CONTEXT_SWITCH>:


CONTEXT_SWITCH:
    LOAD t0, TF_epc(sp)
800005e0:	07c12283          	lw	t0,124(sp)
    csrw mepc, t0
800005e4:	34129073          	csrw	mepc,t0

    LOAD ra, TF_ra(sp)
800005e8:	00012083          	lw	ra,0(sp)
    LOAD gp, TF_gp(sp)
800005ec:	00812183          	lw	gp,8(sp)
    LOAD tp, TF_tp(sp)
800005f0:	00c12203          	lw	tp,12(sp)
    LOAD t0, TF_t0(sp)
800005f4:	01012283          	lw	t0,16(sp)
    LOAD t1, TF_t1(sp)
800005f8:	01412303          	lw	t1,20(sp)
    LOAD t2, TF_t2(sp)
800005fc:	01812383          	lw	t2,24(sp)
    LOAD s0, TF_s0(sp)
80000600:	01c12403          	lw	s0,28(sp)
    LOAD s1, TF_s1(sp)
80000604:	02012483          	lw	s1,32(sp)
    LOAD a0, TF_a0(sp)
80000608:	02412503          	lw	a0,36(sp)
    LOAD a1, TF_a1(sp)
8000060c:	02812583          	lw	a1,40(sp)
    LOAD a2, TF_a2(sp)
80000610:	02c12603          	lw	a2,44(sp)
    LOAD a3, TF_a3(sp)
80000614:	03012683          	lw	a3,48(sp)
    LOAD a4, TF_a4(sp)
80000618:	03412703          	lw	a4,52(sp)
    LOAD a5, TF_a5(sp)
8000061c:	03812783          	lw	a5,56(sp)
    LOAD a6, TF_a6(sp)
80000620:	03c12803          	lw	a6,60(sp)
    LOAD a7, TF_a7(sp)
80000624:	04012883          	lw	a7,64(sp)
    LOAD s2, TF_s2(sp)
80000628:	04412903          	lw	s2,68(sp)
    LOAD s3, TF_s3(sp)
8000062c:	04812983          	lw	s3,72(sp)
    LOAD s4, TF_s4(sp)
80000630:	04c12a03          	lw	s4,76(sp)
    LOAD s5, TF_s5(sp)
80000634:	05012a83          	lw	s5,80(sp)
    LOAD s6, TF_s6(sp)
80000638:	05412b03          	lw	s6,84(sp)
    LOAD s7, TF_s7(sp)
8000063c:	05812b83          	lw	s7,88(sp)
    LOAD s8, TF_s8(sp)
80000640:	05c12c03          	lw	s8,92(sp)
    LOAD s9, TF_s9(sp)
80000644:	06012c83          	lw	s9,96(sp)
    LOAD s10, TF_s10(sp)
80000648:	06412d03          	lw	s10,100(sp)
    LOAD s11, TF_s11(sp)
8000064c:	06812d83          	lw	s11,104(sp)
    LOAD t3, TF_t3(sp)
80000650:	06c12e03          	lw	t3,108(sp)
    LOAD t4, TF_t4(sp)
80000654:	07012e83          	lw	t4,112(sp)
    LOAD t5, TF_t5(sp)
80000658:	07412f03          	lw	t5,116(sp)
    LOAD t6, TF_t6(sp)
8000065c:	07812f83          	lw	t6,120(sp)
    
    csrw mscratch, sp
80000660:	34011073          	csrw	mscratch,sp
    LOAD sp, TF_sp(sp)
80000664:	00412103          	lw	sp,4(sp)

    mret
80000668:	30200073          	mret
8000066c:	00000013          	nop
80000670:	00000013          	nop
80000674:	00000013          	nop
80000678:	00000013          	nop
8000067c:	00000013          	nop
80000680:	00000013          	nop
80000684:	00000013          	nop
80000688:	00000013          	nop
8000068c:	00000013          	nop
80000690:	00000013          	nop
80000694:	00000013          	nop
80000698:	00000013          	nop
8000069c:	00000013          	nop
800006a0:	00000013          	nop
800006a4:	00000013          	nop
800006a8:	00000013          	nop
800006ac:	00000013          	nop
800006b0:	00000013          	nop
800006b4:	00000013          	nop
800006b8:	00000013          	nop
800006bc:	00000013          	nop
800006c0:	00000013          	nop
800006c4:	00000013          	nop
800006c8:	00000013          	nop
800006cc:	00000013          	nop
800006d0:	00000013          	nop
800006d4:	00000013          	nop
800006d8:	00000013          	nop
800006dc:	00000013          	nop
800006e0:	00000013          	nop
800006e4:	00000013          	nop
800006e8:	00000013          	nop
800006ec:	00000013          	nop
800006f0:	00000013          	nop
800006f4:	00000013          	nop
800006f8:	00000013          	nop
800006fc:	00000013          	nop

80000700 <VECTORED_EXCEPTION_HANDLER>:
    .balign 256
    .global VECTORED_EXCEPTION_HANDLER
VECTORED_EXCEPTION_HANDLER:
    .rept 64
    j EXCEPTION_HANDLER
    .endr
80000700:	e01ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000704:	dfdff06f          	j	80000500 <EXCEPTION_HANDLER>
80000708:	df9ff06f          	j	80000500 <EXCEPTION_HANDLER>
8000070c:	df5ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000710:	df1ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000714:	dedff06f          	j	80000500 <EXCEPTION_HANDLER>
80000718:	de9ff06f          	j	80000500 <EXCEPTION_HANDLER>
8000071c:	de5ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000720:	de1ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000724:	dddff06f          	j	80000500 <EXCEPTION_HANDLER>
80000728:	dd9ff06f          	j	80000500 <EXCEPTION_HANDLER>
8000072c:	dd5ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000730:	dd1ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000734:	dcdff06f          	j	80000500 <EXCEPTION_HANDLER>
80000738:	dc9ff06f          	j	80000500 <EXCEPTION_HANDLER>
8000073c:	dc5ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000740:	dc1ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000744:	dbdff06f          	j	80000500 <EXCEPTION_HANDLER>
80000748:	db9ff06f          	j	80000500 <EXCEPTION_HANDLER>
8000074c:	db5ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000750:	db1ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000754:	dadff06f          	j	80000500 <EXCEPTION_HANDLER>
80000758:	da9ff06f          	j	80000500 <EXCEPTION_HANDLER>
8000075c:	da5ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000760:	da1ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000764:	d9dff06f          	j	80000500 <EXCEPTION_HANDLER>
80000768:	d99ff06f          	j	80000500 <EXCEPTION_HANDLER>
8000076c:	d95ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000770:	d91ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000774:	d8dff06f          	j	80000500 <EXCEPTION_HANDLER>
80000778:	d89ff06f          	j	80000500 <EXCEPTION_HANDLER>
8000077c:	d85ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000780:	d81ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000784:	d7dff06f          	j	80000500 <EXCEPTION_HANDLER>
80000788:	d79ff06f          	j	80000500 <EXCEPTION_HANDLER>
8000078c:	d75ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000790:	d71ff06f          	j	80000500 <EXCEPTION_HANDLER>
80000794:	d6dff06f          	j	80000500 <EXCEPTION_HANDLER>
80000798:	d69ff06f          	j	80000500 <EXCEPTION_HANDLER>
8000079c:	d65ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007a0:	d61ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007a4:	d5dff06f          	j	80000500 <EXCEPTION_HANDLER>
800007a8:	d59ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007ac:	d55ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007b0:	d51ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007b4:	d4dff06f          	j	80000500 <EXCEPTION_HANDLER>
800007b8:	d49ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007bc:	d45ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007c0:	d41ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007c4:	d3dff06f          	j	80000500 <EXCEPTION_HANDLER>
800007c8:	d39ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007cc:	d35ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007d0:	d31ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007d4:	d2dff06f          	j	80000500 <EXCEPTION_HANDLER>
800007d8:	d29ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007dc:	d25ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007e0:	d21ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007e4:	d1dff06f          	j	80000500 <EXCEPTION_HANDLER>
800007e8:	d19ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007ec:	d15ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007f0:	d11ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007f4:	d0dff06f          	j	80000500 <EXCEPTION_HANDLER>
800007f8:	d09ff06f          	j	80000500 <EXCEPTION_HANDLER>
800007fc:	d05ff06f          	j	80000500 <EXCEPTION_HANDLER>

80000800 <FATAL>:
EXCEPTION_HANDLER:
    j HALT
#endif

FATAL:                              // 严重问题，重启
    ori a0, zero, 0x80              // 错误信号
80000800:	08006513          	ori	a0,zero,128
    jal WRITE_SERIAL                // 发送
80000804:	094000ef          	jal	ra,80000898 <WRITE_SERIAL>

#ifdef ENABLE_INT
    csrrs a0, mepc, zero
80000808:	34102573          	csrr	a0,mepc
    jal WRITE_SERIAL_XLEN
8000080c:	0f8000ef          	jal	ra,80000904 <WRITE_SERIAL_XLEN>
    csrrs a0, mcause, zero
80000810:	34202573          	csrr	a0,mcause
    jal WRITE_SERIAL_XLEN
80000814:	0f0000ef          	jal	ra,80000904 <WRITE_SERIAL_XLEN>
    csrrs a0, mtval, zero
80000818:	34302573          	csrr	a0,mtval
    jal WRITE_SERIAL_XLEN
8000081c:	0e8000ef          	jal	ra,80000904 <WRITE_SERIAL_XLEN>
    jal WRITE_SERIAL_XLEN
    jal WRITE_SERIAL_XLEN
    jal WRITE_SERIAL_XLEN
#endif

    la a0, START                    // 重启地址
80000820:	fffff517          	auipc	a0,0xfffff
80000824:	7ec50513          	addi	a0,a0,2028 # 8000000c <START>
    jr a0
80000828:	00050067          	jr	a0
	...

80000898 <WRITE_SERIAL>:
    .global READ_SERIAL
    .global READ_SERIAL_WORD
    .global READ_SERIAL_XLEN

WRITE_SERIAL:                       // 写串口：将a0的低八位写入串口
    li t0, COM1
80000898:	100002b7          	lui	t0,0x10000

8000089c <.TESTW>:
.TESTW:
    lb t1, %lo(COM_LSR_OFFSET)(t0)  // 查看串口状态
8000089c:	00528303          	lb	t1,5(t0) # 10000005 <INITLOCATE-0x6ffffffb>
    andi t1, t1, COM_LSR_THRE       // 截取写状态位
800008a0:	02037313          	andi	t1,t1,32
    bne t1, zero, .WSERIAL          // 状态位非零可写进入写
800008a4:	00031463          	bnez	t1,800008ac <.WSERIAL>
    j .TESTW                        // 检测验证，忙等待
800008a8:	ff5ff06f          	j	8000089c <.TESTW>

800008ac <.WSERIAL>:
.WSERIAL:
    sb a0, %lo(COM_THR_OFFSET)(t0)  // 写入寄存器a0中的值
800008ac:	00a28023          	sb	a0,0(t0)
    jr ra
800008b0:	00008067          	ret

800008b4 <WRITE_SERIAL_WORD>:

WRITE_SERIAL_WORD:
    addi sp, sp, -2*XLEN
800008b4:	ff810113          	addi	sp,sp,-8
    STORE ra, 0x0(sp)
800008b8:	00112023          	sw	ra,0(sp)
    STORE s0, XLEN(sp)
800008bc:	00812223          	sw	s0,4(sp)

    mv s0, a0
800008c0:	00050413          	mv	s0,a0

    andi a0, a0, 0xFF
800008c4:	0ff57513          	andi	a0,a0,255
    jal WRITE_SERIAL
800008c8:	fd1ff0ef          	jal	ra,80000898 <WRITE_SERIAL>
    srli a0, s0, 8
800008cc:	00845513          	srli	a0,s0,0x8

    andi a0, a0, 0xFF
800008d0:	0ff57513          	andi	a0,a0,255
    jal WRITE_SERIAL
800008d4:	fc5ff0ef          	jal	ra,80000898 <WRITE_SERIAL>
    srli a0, s0, 16
800008d8:	01045513          	srli	a0,s0,0x10

    andi a0, a0, 0xFF
800008dc:	0ff57513          	andi	a0,a0,255
    jal WRITE_SERIAL
800008e0:	fb9ff0ef          	jal	ra,80000898 <WRITE_SERIAL>
    srli a0, s0, 24
800008e4:	01845513          	srli	a0,s0,0x18

    andi a0, a0, 0xFF
800008e8:	0ff57513          	andi	a0,a0,255
    jal WRITE_SERIAL
800008ec:	fadff0ef          	jal	ra,80000898 <WRITE_SERIAL>
    mv a0, s0
800008f0:	00040513          	mv	a0,s0

    LOAD ra, 0x0(sp)
800008f4:	00012083          	lw	ra,0(sp)
    LOAD s0, XLEN(sp)
800008f8:	00412403          	lw	s0,4(sp)
    addi sp, sp, 2*XLEN
800008fc:	00810113          	addi	sp,sp,8

    jr ra
80000900:	00008067          	ret

80000904 <WRITE_SERIAL_XLEN>:

WRITE_SERIAL_XLEN:
    addi sp, sp, -XLEN
80000904:	ffc10113          	addi	sp,sp,-4
    STORE ra, 0x0(sp)
80000908:	00112023          	sw	ra,0(sp)

    jal WRITE_SERIAL_WORD
8000090c:	fa9ff0ef          	jal	ra,800008b4 <WRITE_SERIAL_WORD>
#ifdef RV64
    srli a0, a0, 32
    jal WRITE_SERIAL_WORD
#endif
    LOAD ra, 0x0(sp)
80000910:	00012083          	lw	ra,0(sp)
    addi sp, sp, XLEN
80000914:	00410113          	addi	sp,sp,4

    jr ra
80000918:	00008067          	ret

8000091c <READ_SERIAL>:

READ_SERIAL:                        // 读串口：将读到的数据写入a0低八位
    li t0, COM1
8000091c:	100002b7          	lui	t0,0x10000

80000920 <.TESTR>:
.TESTR:
    lb t1, %lo(COM_LSR_OFFSET)(t0)
80000920:	00528303          	lb	t1,5(t0) # 10000005 <INITLOCATE-0x6ffffffb>
    andi t1, t1, COM_LSR_DR         // 截取读状态位
80000924:	00137313          	andi	t1,t1,1
    bne t1, zero, .RSERIAL          // 状态位非零可读进入读
80000928:	00031463          	bnez	t1,80000930 <.RSERIAL>
#ifdef ENABLE_INT
    ori v0, zero, SYS_wait          // 取得wait调用号
    syscall SYSCALL_BASE            // 睡眠等待
#endif
*/
    j .TESTR                        // 检测验证
8000092c:	ff5ff06f          	j	80000920 <.TESTR>

80000930 <.RSERIAL>:
.RSERIAL:
    lb a0, %lo(COM_RBR_OFFSET)(t0)
80000930:	00028503          	lb	a0,0(t0)
    jr ra
80000934:	00008067          	ret

80000938 <READ_SERIAL_WORD>:

READ_SERIAL_WORD:
    addi sp, sp, -5*XLEN             // 保存ra,s0-3
80000938:	fec10113          	addi	sp,sp,-20
    STORE ra, 0x0(sp)
8000093c:	00112023          	sw	ra,0(sp)
    STORE s0, XLEN(sp)
80000940:	00812223          	sw	s0,4(sp)
    STORE s1, 2*XLEN(sp)
80000944:	00912423          	sw	s1,8(sp)
    STORE s2, 3*XLEN(sp)
80000948:	01212623          	sw	s2,12(sp)
    STORE s3, 4*XLEN(sp)
8000094c:	01312823          	sw	s3,16(sp)

    jal READ_SERIAL                 // 读串口获得八个比特
80000950:	fcdff0ef          	jal	ra,8000091c <READ_SERIAL>
    or s0, zero, a0                 // 结果存入s0
80000954:	00a06433          	or	s0,zero,a0
    jal READ_SERIAL                 // 读串口获得八个比特
80000958:	fc5ff0ef          	jal	ra,8000091c <READ_SERIAL>
    or s1, zero, a0                 // 结果存入s1
8000095c:	00a064b3          	or	s1,zero,a0
    jal READ_SERIAL                 // 读串口获得八个比特
80000960:	fbdff0ef          	jal	ra,8000091c <READ_SERIAL>
    or s2, zero, a0                 // 结果存入s2
80000964:	00a06933          	or	s2,zero,a0
    jal READ_SERIAL                 // 读串口获得八个比特
80000968:	fb5ff0ef          	jal	ra,8000091c <READ_SERIAL>
    or s3, zero, a0                 // 结果存入s3
8000096c:	00a069b3          	or	s3,zero,a0

    andi s0, s0, 0x00FF             // 截取低八位
80000970:	0ff47413          	andi	s0,s0,255
    andi s1, s1, 0x00FF
80000974:	0ff4f493          	andi	s1,s1,255
    andi s2, s2, 0x00FF
80000978:	0ff97913          	andi	s2,s2,255
    andi s3, s3, 0x00FF
8000097c:	0ff9f993          	andi	s3,s3,255
    or a0, zero, s3                 // 存高八位
80000980:	01306533          	or	a0,zero,s3
    sll a0, a0, 8                   // 左移
80000984:	00851513          	slli	a0,a0,0x8
    or a0, a0, s2                   // 存八位
80000988:	01256533          	or	a0,a0,s2
    sll a0, a0, 8                   // 左移
8000098c:	00851513          	slli	a0,a0,0x8
    or a0, a0, s1                   // 存八位
80000990:	00956533          	or	a0,a0,s1
    sll a0, a0, 8                   // 左移
80000994:	00851513          	slli	a0,a0,0x8
    or a0, a0, s0                   // 存低八位
80000998:	00856533          	or	a0,a0,s0

    LOAD ra, 0x0(sp)                // 恢复ra,s0
8000099c:	00012083          	lw	ra,0(sp)
    LOAD s0, XLEN(sp)
800009a0:	00412403          	lw	s0,4(sp)
    LOAD s1, 2*XLEN(sp)
800009a4:	00812483          	lw	s1,8(sp)
    LOAD s2, 3*XLEN(sp)
800009a8:	00c12903          	lw	s2,12(sp)
    LOAD s3, 4*XLEN(sp)
800009ac:	01012983          	lw	s3,16(sp)
    addi sp, sp, 5*XLEN
800009b0:	01410113          	addi	sp,sp,20
    jr ra
800009b4:	00008067          	ret

800009b8 <READ_SERIAL_XLEN>:

READ_SERIAL_XLEN:
    addi sp, sp, -2*XLEN             // 保存ra,s0-3
800009b8:	ff810113          	addi	sp,sp,-8
    STORE ra, 0x0(sp)
800009bc:	00112023          	sw	ra,0(sp)
    STORE s0, XLEN(sp)
800009c0:	00812223          	sw	s0,4(sp)

    jal READ_SERIAL_WORD
800009c4:	f75ff0ef          	jal	ra,80000938 <READ_SERIAL_WORD>
    mv s0, a0
800009c8:	00050413          	mv	s0,a0
#ifdef RV64
    jal READ_SERIAL_WORD
    sll a0, a0, 32
    add s0, s0, a0
#endif
    mv a0, s0
800009cc:	00040513          	mv	a0,s0
    LOAD ra, 0x0(sp)                // 恢复ra,s0
800009d0:	00012083          	lw	ra,0(sp)
    LOAD s0, XLEN(sp)
800009d4:	00412403          	lw	s0,4(sp)
    addi sp, sp, 2*XLEN
800009d8:	00810113          	addi	sp,sp,8
    jr ra
800009dc:	00008067          	ret
	...

80001000 <UTEST_SIMPLE>:
    //.set noat
    .section .text.utest
    .p2align 2

UTEST_SIMPLE:
    addi t5, t5, 0x1
80001000:	001f0f13          	addi	t5,t5,1
    jr ra
80001004:	00008067          	ret

80001008 <UTEST_1PTB>:
     *  这段程序一般没有数据冲突和结构冲突，可作为性能标定。
     *  若执行延迟槽，执行这段程序需至少384M指令，384M/time可算得频率。
     *  不执行延迟槽，执行这段程序需至少320M指令，320M/time可算得频率。
     */
UTEST_1PTB:
    li t0, TESTLOOP64         // 装入64M
80001008:	040002b7          	lui	t0,0x4000
.LC0:
    addi t0, t0, -1                // 滚动计数器
8000100c:	fff28293          	addi	t0,t0,-1 # 3ffffff <INITLOCATE-0x7c000001>
    ori t1, zero, 0
80001010:	00006313          	ori	t1,zero,0
    ori t2, zero, 1
80001014:	00106393          	ori	t2,zero,1
    ori t3, zero, 2
80001018:	00206e13          	ori	t3,zero,2
    bne t0, zero, .LC0
8000101c:	fe0298e3          	bnez	t0,8000100c <UTEST_1PTB+0x4>
    jr ra
80001020:	00008067          	ret

80001024 <UTEST_2DCT>:
     *  这段程序含有大量数据冲突，可测试数据冲突对效率的影响。
     *  执行延迟槽，执行这段程序需至少192M指令。
     *  不执行延迟槽，执行这段程序需至少176M指令。
     */
UTEST_2DCT:
    lui t0, %hi(TESTLOOP16)         // 装入16M
80001024:	010002b7          	lui	t0,0x1000
    ori t1, zero, 1
80001028:	00106313          	ori	t1,zero,1
    ori t2, zero, 2
8000102c:	00206393          	ori	t2,zero,2
    ori t3, zero, 3
80001030:	00306e13          	ori	t3,zero,3
.LC1:
    xor t2, t2, t1                  // 交换t1,t2
80001034:	0063c3b3          	xor	t2,t2,t1
    xor t1, t1, t2
80001038:	00734333          	xor	t1,t1,t2
    xor t2, t2, t1
8000103c:	0063c3b3          	xor	t2,t2,t1
    xor t3, t3, t2                  // 交换t2,t3
80001040:	007e4e33          	xor	t3,t3,t2
    xor t2, t2, t3
80001044:	01c3c3b3          	xor	t2,t2,t3
    xor t3, t3, t2
80001048:	007e4e33          	xor	t3,t3,t2
    xor t1, t1, t3                  // 交换t3,t1
8000104c:	01c34333          	xor	t1,t1,t3
    xor t3, t3, t1
80001050:	006e4e33          	xor	t3,t3,t1
    xor t1, t1, t3
80001054:	01c34333          	xor	t1,t1,t3
    addi t0, t0, -1
80001058:	fff28293          	addi	t0,t0,-1 # ffffff <INITLOCATE-0x7f000001>
    bne t0, zero, .LC1
8000105c:	fc029ce3          	bnez	t0,80001034 <UTEST_2DCT+0x10>
    jr ra
80001060:	00008067          	ret

80001064 <UTEST_3CCT>:
     *  这段程序有大量控制冲突。
     *  无延迟槽执行需要至少256M指令；
     *  有延迟槽需要224M指令。
     */
UTEST_3CCT:
    lui t0, %hi(TESTLOOP64)         // 装入64M
80001064:	040002b7          	lui	t0,0x4000
.LC2_0:
    bne t0, zero, .LC2_1
80001068:	00029463          	bnez	t0,80001070 <UTEST_3CCT+0xc>
    jr ra
8000106c:	00008067          	ret
.LC2_1:
    j .LC2_2
80001070:	0040006f          	j	80001074 <UTEST_3CCT+0x10>
.LC2_2:
    addi t0, t0, -1
80001074:	fff28293          	addi	t0,t0,-1 # 3ffffff <INITLOCATE-0x7c000001>
    j .LC2_0
80001078:	ff1ff06f          	j	80001068 <UTEST_3CCT+0x4>
    addi t0, t0, -1
8000107c:	fff28293          	addi	t0,t0,-1

80001080 <UTEST_4MDCT>:
     *  这段程序反复对内存进行有数据冲突的读写。
     *  不执行延迟槽需要至少192M指令。
     *  执行延迟槽，需要至少224M指令。
     */
UTEST_4MDCT:
    lui t0, %hi(TESTLOOP32)          // 装入32M
80001080:	020002b7          	lui	t0,0x2000
    addi sp, sp, -4
80001084:	ffc10113          	addi	sp,sp,-4
.LC3:
    sw t0, 0(sp)
80001088:	00512023          	sw	t0,0(sp)
    lw t1, 0(sp)
8000108c:	00012303          	lw	t1,0(sp)
    addi t1, t1, -1
80001090:	fff30313          	addi	t1,t1,-1 # 7fffffff <KERNEL_STACK_INIT+0xff7fffff>
    sw t1, 0(sp)
80001094:	00612023          	sw	t1,0(sp)
    lw t0, 0(sp)
80001098:	00012283          	lw	t0,0(sp)
    bne t0, zero, .LC3
8000109c:	fe0296e3          	bnez	t0,80001088 <UTEST_4MDCT+0x8>
    addi sp, sp, 4
800010a0:	00410113          	addi	sp,sp,4
    jr ra
800010a4:	00008067          	ret

800010a8 <UTEST_PUTC>:

#ifdef ENABLE_INT
UTEST_PUTC:
    li s0, SYS_putc
800010a8:	01e00413          	li	s0,30
    li a0, 0x4F              // 'O'
800010ac:	04f00513          	li	a0,79
    ecall
800010b0:	00000073          	ecall
    li a0, 0x4B              // 'K'
800010b4:	04b00513          	li	a0,75
    ecall
800010b8:	00000073          	ecall
    jr ra
800010bc:	00008067          	ret

800010c0 <UTEST_CRYPTONIGHT>:
#endif

UTEST_CRYPTONIGHT:
    li a0, 0x80400000 // base addr
800010c0:	80400537          	lui	a0,0x80400
    li a1, 0x200000 // 2M bytes
800010c4:	002005b7          	lui	a1,0x200
    li a3, 524288 // number of iterations
800010c8:	000806b7          	lui	a3,0x80
    li a4, 0x1FFFFC // 2M mask
800010cc:	00200737          	lui	a4,0x200
800010d0:	ffc70713          	addi	a4,a4,-4 # 1ffffc <INITLOCATE-0x7fe00004>
    add a1, a1, a0 // end addr
800010d4:	00a585b3          	add	a1,a1,a0
    li s0, 1 // rand number
800010d8:	00100413          	li	s0,1

    mv a2, a0
800010dc:	00050613          	mv	a2,a0

800010e0 <.INIT_LOOP>:
.INIT_LOOP:
    sw s0, 0(a2)
800010e0:	00862023          	sw	s0,0(a2)

    // xorshift lfsr
    slli s1, s0, 13
800010e4:	00d41493          	slli	s1,s0,0xd
    xor s0, s0, s1
800010e8:	00944433          	xor	s0,s0,s1
    srli s1, s0, 17
800010ec:	01145493          	srli	s1,s0,0x11
    xor s0, s0, s1
800010f0:	00944433          	xor	s0,s0,s1
    slli s1, s0, 5
800010f4:	00541493          	slli	s1,s0,0x5
    xor s0, s0, s1
800010f8:	00944433          	xor	s0,s0,s1

    addi a2, a2, 4
800010fc:	00460613          	addi	a2,a2,4
    bne a2, a1, .INIT_LOOP
80001100:	feb610e3          	bne	a2,a1,800010e0 <.INIT_LOOP>

    li a2, 0
80001104:	00000613          	li	a2,0
    li t0, 0
80001108:	00000293          	li	t0,0

8000110c <.MAIN_LOOP>:
.MAIN_LOOP:
    // calculate a valid addr from rand number
    and t0, s0, a4
8000110c:	00e472b3          	and	t0,s0,a4
    add t0, a0, t0
80001110:	005502b3          	add	t0,a0,t0
    // read from it
    lw t0, 0(t0)
80001114:	0002a283          	lw	t0,0(t0) # 2000000 <INITLOCATE-0x7e000000>
    // xor with last iteration's t0
    xor t0, t0, t1
80001118:	0062c2b3          	xor	t0,t0,t1
    // xor rand number with current t0
    xor s0, s0, t0
8000111c:	00544433          	xor	s0,s0,t0

    // get new rand number from xorshift lfsr
    slli s1, s0, 13
80001120:	00d41493          	slli	s1,s0,0xd
    xor s0, s0, s1
80001124:	00944433          	xor	s0,s0,s1
    srli s1, s0, 17
80001128:	01145493          	srli	s1,s0,0x11
    xor s0, s0, s1
8000112c:	00944433          	xor	s0,s0,s1
    slli s1, s0, 5
80001130:	00541493          	slli	s1,s0,0x5
    xor s0, s0, s1
80001134:	00944433          	xor	s0,s0,s1

    // calculate a valid addr from new rand number
    and t1, s0, a4
80001138:	00e47333          	and	t1,s0,a4
    add t1, a0, t1
8000113c:	00650333          	add	t1,a0,t1
    // write t0 to this addr
    sw t0, 0(t1)
80001140:	00532023          	sw	t0,0(t1)
    // save t0 for next iteration
    mv t1, t0
80001144:	00028313          	mv	t1,t0

    // get new rand number from xorshift lfsr
    slli s1, s0, 13
80001148:	00d41493          	slli	s1,s0,0xd
    xor s0, s0, s1
8000114c:	00944433          	xor	s0,s0,s1
    srli s1, s0, 17
80001150:	01145493          	srli	s1,s0,0x11
    xor s0, s0, s1
80001154:	00944433          	xor	s0,s0,s1
    slli s1, s0, 5
80001158:	00541493          	slli	s1,s0,0x5
    xor s0, s0, s1
8000115c:	00944433          	xor	s0,s0,s1

    add a2, a2, 1
80001160:	00160613          	addi	a2,a2,1
    bne a2, a3, .MAIN_LOOP
80001164:	fad614e3          	bne	a2,a3,8000110c <.MAIN_LOOP>

    jr ra
80001168:	00008067          	ret
