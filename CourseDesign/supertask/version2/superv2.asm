; ==========================================
; superv2.asm
; 编译方法：nasm superv2.asm -o superv2.com
; 实现功能：  支持简易PCB（名字，pid，静态优先级，动态优先级），即支持多个简易进程，LDT，TSS，页目录，页表无需手动编写。
; 			使用段页式地址映射，之前一版共用页目录与页表。
;			此版本为每个简易进程创建页目录和页表，但为了简化，页目录和页表均直接将线性地址直接映射为物理地址。
; ==========================================

%include	"pm.inc"	; 常量, 宏, 以及一些说明

%define SetNumberOfProcess 5	

%assign 		PhysicalAddress 	200000h
%assign			num					1
%rep			SetNumberOfProcess
PageDirBase%[num]	equ	PhysicalAddress	; 页目录开始地址:	2M
%assign 		PhysicalAddress 	PhysicalAddress + 01000H
PageTblBase%[num]	equ	PhysicalAddress	; 页表开始地址:		2M +  4K
%assign 		PhysicalAddress 	PhysicalAddress + 0F000H
%assign			num					num + 1
%endrep

ProcPagingDemo		equ	301000h
LinearAddrDemo		equ	401000h

%assign 		PhysicalAddress 	401000h
%assign			num					1
%rep			SetNumberOfProcess
ProcTask%[num]		equ	PhysicalAddress
%assign			num					num + 1
%assign 		PhysicalAddress 	PhysicalAddress + 100000H
%endrep

org	0100h
jmp	LABEL_BEGIN

[SECTION .gdt]
; GDT
;                                         段基址,       段界限     , 属性
LABEL_GDT:			Descriptor	       0,                 0, 0				; 空描述符
LABEL_DESC_NORMAL:	Descriptor	       0,            0ffffh, DA_DRW			; Normal 描述符
LABEL_DESC_FLAT_C:	Descriptor         0,           0fffffh, DA_CR | DA_32 | DA_LIMIT_4K; 0 ~ 4G
LABEL_DESC_FLAT_RW:	Descriptor         0,           0fffffh, DA_DRW | DA_LIMIT_4K	; 0 ~ 4G
LABEL_DESC_CODE32:	Descriptor	       0,  SegCode32Len - 1, DA_CR | DA_32	; 非一致代码段, 32
LABEL_DESC_CODE16:	Descriptor	       0,            0ffffh, DA_C			; 非一致代码段, 16
LABEL_DESC_DATA:	Descriptor	       0,		DataLen - 1, DA_DRW				; Data
LABEL_DESC_STACK:	Descriptor	       0,        TopOfStack, DA_DRWA | DA_32; Stack, 32 位

%assign 		num 	1
%rep			SetNumberOfProcess
LABEL_DESC_STACK%[num]:	Descriptor	   0,  TopOfStack%[num], DA_DRWA | DA_32; Stack, 32 位
LABEL_DESC_LDT%[num]:	Descriptor	   0,  LDT%[num]Len - 1, DA_LDT			; LDT
LABEL_DESC_TSS%[num]:	Descriptor	   0,  TSSLen%[num] - 1, DA_386TSS		; TSSs
%assign 		num 	num + 1
%endrep

LABEL_DESC_VIDEO:	Descriptor	 0B8000h,            0ffffh, DA_DRW			; 显存首地址
; GDT 结束

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1		; GDT界限
			dd	0				; GDT基地址

; GDT 选择子
SelectorNormal		equ	LABEL_DESC_NORMAL	- LABEL_GDT
SelectorFlatC		equ	LABEL_DESC_FLAT_C	- LABEL_GDT
SelectorFlatRW		equ	LABEL_DESC_FLAT_RW	- LABEL_GDT
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorCode16		equ	LABEL_DESC_CODE16	- LABEL_GDT
SelectorData		equ	LABEL_DESC_DATA		- LABEL_GDT
SelectorStack		equ	LABEL_DESC_STACK	- LABEL_GDT

%assign 		num 	1
%rep			SetNumberOfProcess
SelectorStack%[num]		equ	LABEL_DESC_STACK%[num]		- LABEL_GDT
SelectorLDT%[num]		equ LABEL_DESC_LDT%[num]		- LABEL_GDT
SelectorTSS%[num]		equ LABEL_DESC_TSS%[num]		- LABEL_GDT
%assign 		num 	num + 1
%endrep

SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT
; END of [SECTION .gdt]

%macro PCBlock 4
	db	%1				;进程名，不能超过10个字符
	%strlen charcnt %1
	%rep	10 - charcnt
	db	0
	%endrep
	dw	%2				;pid
	dw	%3				;当前进程持有的时间片
	dw	%4				;静态优先级
%endmacro ; 共 16 字节

[SECTION .data1]	 ; 数据段
ALIGN	32
[BITS	32]
LABEL_DATA:
; 实模式下使用这些符号
; 字符串
_szPMMessage:		db	"In Protect Mode now. ^-^", 0Ah, 0Ah, 0	; 进入保护模式后显示此字符串
_szMemChkTitle:		db	"BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0	; 进入保护模式后显示此字符串
_szRAMSize:			db	"RAM size:", 0
_szReturn:			db	0Ah, 0
; 变量
_wSPValueInRealMode:dw	0
_dwMCRNumber:		dd	0	; Memory Check Result
_dwDispPos:			dd	(80 * 6 + 0) * 2	; 屏幕第 6 行, 第 0 列。
_dwMemSize:			dd	0
_ARDStruct:			; Address Range Descriptor Structure
_dwBaseAddrLow:		dd	0
_dwBaseAddrHigh:	dd	0
_dwLengthLow:		dd	0
_dwLengthHigh:		dd	0
_dwType:			dd	0
_PageTableNumber:	dd	0
_SavedIDTR:			dd	0	; 用于保存 IDTR
					dd	0
_SavedIMREG:		db	0	; 中断屏蔽寄存器值
_MemChkBuf:	times	256	db	0
_NumberOfProcess:	dd	SetNumberOfProcess
_nowProcess:		dd	0
_PCB:				PCBlock	"VERY.exe",		1,		0,		010H
					PCBlock	"LOVE.exe",		2,		0,		0AH
					PCBlock	"HUST.exe",		3,		0,		08H
					PCBlock	"MRSU.exe",		4,		0,		06H
					PCBlock	"1010.exe",		4,		0,		012H
_TSSArray:	
%assign 		num 	1
%rep			SetNumberOfProcess
	dd				0
	dw				SelectorTSS%[num]
	dw				0
%assign 		num 	num + 1
%endrep		



; 保护模式下使用这些符号
szPMMessage		equ	_szPMMessage	- $$
szMemChkTitle	equ	_szMemChkTitle	- $$
szRAMSize		equ	_szRAMSize	- $$
szReturn		equ	_szReturn	- $$
dwDispPos		equ	_dwDispPos	- $$
dwMemSize		equ	_dwMemSize	- $$
dwMCRNumber		equ	_dwMCRNumber	- $$
ARDStruct		equ	_ARDStruct	- $$
dwBaseAddrLow	equ	_dwBaseAddrLow	- $$
dwBaseAddrHigh	equ	_dwBaseAddrHigh	- $$
dwLengthLow		equ	_dwLengthLow	- $$
dwLengthHigh	equ	_dwLengthHigh	- $$
dwType			equ	_dwType		- $$
MemChkBuf		equ	_MemChkBuf	- $$
PageTableNumber	equ	_PageTableNumber- $$
SavedIDTR		equ	_SavedIDTR	- $$
SavedIMREG		equ	_SavedIMREG	- $$
NumberOfProcess	equ _NumberOfProcess - $$
nowProcess 		equ _nowProcess - $$
PCB 			equ _PCB - $$
TSSArray 		equ _TSSArray - $$
DataLen			equ	$ - LABEL_DATA
; END of [SECTION .data1]


; 全局堆栈段
[SECTION .gs]
ALIGN	32
[BITS	32]
LABEL_STACK:
	times 512 db 0
TopOfStack	equ	$ - LABEL_STACK - 1
; END of [SECTION .gs]

%assign 		num 	1
%rep			SetNumberOfProcess
[SECTION .gs%[num]]
ALIGN	32
[BITS	32]
LABEL_STACK%[num]:
	times 512 db 0
TopOfStack%[num]	equ	$ - LABEL_STACK%[num] - 1
; END of [SECTION .gs%[num]]
%assign 		num 	num + 1
%endrep

; IDT
[SECTION .idt]
ALIGN	32
[BITS	32]
LABEL_IDT:
; 门                                目标选择子,            偏移, DCount, 属性
%rep 32
			Gate	SelectorCode32, SpuriousHandler,      0, DA_386IGate
%endrep
.020h:		Gate	SelectorCode32,    ClockHandler,      0, DA_386IGate
%rep 95
			Gate	SelectorCode32, SpuriousHandler,      0, DA_386IGate
%endrep
.080h:		Gate	SelectorCode32,  UserIntHandler,      0, DA_386IGate

IdtLen		equ	$ - LABEL_IDT
IdtPtr		dw	IdtLen - 1	; 段界限
			dd	0		; 基地址
; END of [SECTION .idt]

[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	mov	[LABEL_GO_BACK_TO_REAL+3], ax
	mov	[_wSPValueInRealMode], sp

	; 得到内存数
	mov	ebx, 0
	mov	di, _MemChkBuf
.loop:
	mov	eax, 0E820h
	mov	ecx, 20
	mov	edx, 0534D4150h
	int	15h
	jc	LABEL_MEM_CHK_FAIL
	add	di, 20
	inc	dword [_dwMCRNumber]
	cmp	ebx, 0
	jne	.loop
	jmp	LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
	mov	dword [_dwMCRNumber], 0
LABEL_MEM_CHK_OK:

	; 初始化 16 位代码段描述符
	mov	ax, cs
	movzx	eax, ax
	shl	eax, 4
	add	eax, LABEL_SEG_CODE16
	mov	word [LABEL_DESC_CODE16 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE16 + 4], al
	mov	byte [LABEL_DESC_CODE16 + 7], ah

	; 初始化 32 位代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

	; 初始化数据段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_DATA
	mov	word [LABEL_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_DATA + 4], al
	mov	byte [LABEL_DESC_DATA + 7], ah

	; 初始化堆栈段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK
	mov	word [LABEL_DESC_STACK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK + 4], al
	mov	byte [LABEL_DESC_STACK + 7], ah

	; 初始化每一个进程
%assign 		num 	1
%rep			SetNumberOfProcess
	; 初始化内核堆栈段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK%[num]
	mov	word [LABEL_DESC_STACK%[num] + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK%[num] + 4], al
	mov	byte [LABEL_DESC_STACK%[num] + 7], ah

	; 初始化 LDT 在 GDT 中的描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_LDT%[num]
	mov	word [LABEL_DESC_LDT%[num] + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_LDT%[num] + 4], al
	mov	byte [LABEL_DESC_LDT%[num] + 7], ah

	; 初始化 TSS 描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_TSS%[num]
	mov	word [LABEL_DESC_TSS%[num] + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_TSS%[num] + 4], al
	mov	byte [LABEL_DESC_TSS%[num] + 7], ah

	; 初始化 LDT 中的描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_Task%[num]
	mov	word [LABEL_LDT%[num]_DESC_TASK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_LDT%[num]_DESC_TASK + 4], al
	mov	byte [LABEL_LDT%[num]_DESC_TASK + 7], ah

	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_Data%[num]
	mov	word [LABEL_LDT%[num]_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_LDT%[num]_DESC_DATA + 4], al
	mov	byte [LABEL_LDT%[num]_DESC_DATA + 7], ah

	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, Local_LABEL_STACK%[num]
	mov	word [LABEL_LDT%[num]_DESC_STACK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_LDT%[num]_DESC_STACK + 4], al
	mov	byte [LABEL_LDT%[num]_DESC_STACK + 7], ah
%assign 		num 	num + 1
%endrep

	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址

	; 为加载 IDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_IDT		; eax <- idt 基地址
	mov	dword [IdtPtr + 2], eax	; [IdtPtr + 2] <- idt 基地址

	; 保存 IDTR
	sidt	[_SavedIDTR]

	; 保存中断屏蔽寄存器(IMREG)值
	in	al, 21h
	mov	[_SavedIMREG], al

	; 加载 GDTR
	lgdt	[GdtPtr]

	; 加载 IDTR
	lidt	[IdtPtr]

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 准备切换到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 真正进入保护模式
	jmp	dword SelectorCode32:0	; 执行这一句会把 SelectorCode32 装入 cs, 并跳转到 Code32Selector:0  处

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LABEL_REAL_ENTRY:		; 从保护模式跳回到实模式就到了这里
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, [_wSPValueInRealMode]

	lidt	[_SavedIDTR]	; 恢复 IDTR 的原值

	mov	al, [_SavedIMREG]	; ┓恢复中断屏蔽寄存器(IMREG)的原值
	out	21h, al				; ┛

	in	al, 92h			; ┓
	and	al, 11111101b	; ┣ 关闭 A20 地址线
	out	92h, al			; ┛

	sti			; 开中断

	mov	ax, 4c00h	; ┓
	int	21h			; ┛回到 DOS
; END of [SECTION .s16]


[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]

LABEL_SEG_CODE32:
	mov	ax, SelectorData
	mov	ds, ax			; 数据段选择子
	mov	es, ax
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子

	mov	ax, SelectorStack
	mov	ss, ax			; 堆栈段选择子

	mov	esp, TopOfStack

	call	Init8259A

	; 下面显示一个字符串
	push	szPMMessage
	call	DispStr
	add	esp, 4

	push	szMemChkTitle
	call	DispStr
	add	esp, 4

	call	DispMemSize		; 显示内存信息

	call	StartPage		; 开启分页机制
	

	mov 	ax, SelectorLDT1
	lldt 	ax
	jmp 	SelectorLDT1Task:0

	call	SetRealmode8259A

	; 到此停止
	jmp	SelectorCode16:0


; Init8259A ---------------------------------------------------------------------------------------------
Init8259A:
	mov	al, 011h
	out	020h, al	; 主8259, ICW1.
	call	io_delay

	out	0A0h, al	; 从8259, ICW1.
	call	io_delay

	mov	al, 020h	; IRQ0 对应中断向量 0x20
	out	021h, al	; 主8259, ICW2.
	call	io_delay

	mov	al, 028h	; IRQ8 对应中断向量 0x28
	out	0A1h, al	; 从8259, ICW2.
	call	io_delay

	mov	al, 004h	; IR2 对应从8259
	out	021h, al	; 主8259, ICW3.
	call	io_delay

	mov	al, 002h	; 对应主8259的 IR2
	out	0A1h, al	; 从8259, ICW3.
	call	io_delay

	mov	al, 001h
	out	021h, al	; 主8259, ICW4.
	call	io_delay

	out	0A1h, al	; 从8259, ICW4.
	call	io_delay

	mov	al, 11111110b	; 仅仅开启定时器中断
	out	021h, al	; 主8259, OCW1.
	call	io_delay

	mov	al, 11111111b	; 屏蔽从8259所有中断
	out	0A1h, al	; 从8259, OCW1.
	call	io_delay

	ret
; Init8259A ---------------------------------------------------------------------------------------------


; SetRealmode8259A ---------------------------------------------------------------------------------------------
SetRealmode8259A:
	mov	ax, SelectorData
	mov	fs, ax

	mov	al, 017h
	out	020h, al	; 主8259, ICW1.
	call	io_delay

	mov	al, 008h	; IRQ0 对应中断向量 0x8
	out	021h, al	; 主8259, ICW2.
	call	io_delay

	mov	al, 001h
	out	021h, al	; 主8259, ICW4.
	call	io_delay

	mov	al, [fs:SavedIMREG]	; ┓恢复中断屏蔽寄存器(IMREG)的原值
	out	021h, al			; ┛
	call	io_delay

	ret
; SetRealmode8259A ---------------------------------------------------------------------------------------------

io_delay:
	nop
	nop
	nop
	nop
	ret

; int handler ---------------------------------------------------------------
_ClockHandler:
ClockHandler	equ	_ClockHandler - $$
    mov	al, 20h
	out	20h, al				; 发送 EOI

	mov ax, SelectorData
	mov ds, ax
	mov es, ax

	mov	ah, 0Fh			; 0000: 黑底    1111: 白字
	mov	al, '1'
    add eax, dword [ds:nowProcess]
	mov	[gs:((80 * 0 + 0) * 2)], ax	; 屏幕第 0 行, 第 0 列。

	mov esi, dword [ds:nowProcess]
	shl esi, 4
	add	esi, 0Ch			; 得到	word [ds:PCB+esi]中存放的当前进程的counter
	cmp word [ds:PCB+esi], 0
	jz findtorun
	dec word [ds:PCB+esi]
	iretd
findtorun:
	mov ecx, dword [ds: NumberOfProcess]
	xor esi, esi
	add	esi, 0Ch
CheckZeros:
	cmp word [ds:PCB+esi] , 0
	jne notAllZeros
	add esi, 010h
	dec ecx
	cmp ecx, 0
	jnz CheckZeros
	
	jmp allZeros
notAllZeros:
	xor bx, bx ; bx存放当前counter最大的进程号
	xor dx, dx ; dx存放当前遍历的进程号
	xor esi, esi
	add esi, 0ch
	xor edi, edi
	add edi, 0ch
	mov ecx, dword [ds: NumberOfProcess]
findMaxcountPro:
	mov ax, word [ds:PCB+esi] 
	cmp word [ds:PCB+edi], ax
	ja getnewmax
	jmp nextmaxloop
getnewmax: 
	mov bx, dx
	mov esi, edi
nextmaxloop:
	inc dx
	add edi, 10h
	dec ecx
	cmp ecx, 0
	jnz findMaxcountPro
	xor eax, eax
	mov ax, bx
	mov dword [ds:nowProcess], eax
	jmp continueThisProcess
allZeros:
	xor esi, esi
	add esi, 0ch
	mov ecx, dword [ds:NumberOfProcess]
copypri:
	mov bx, word [ds:PCB + esi + 2]
	mov word [ds:PCB + esi], bx
	add esi, 10h
	dec ecx
	cmp ecx, 0
	jnz copypri
	jmp notAllZeros

continueThisProcess:
	mov esi, dword [ds:nowProcess]
	shl esi, 4
	add esi, 0Ch
	dec word [ds:PCB+esi]

	mov ebx, dword [ds:nowProcess]
	shl ebx, 3
	jmp far [es:ebx + TSSArray]
	iretd

_UserIntHandler:
UserIntHandler	equ	_UserIntHandler - $$
	mov	ah, 0Ch				; 0000: 黑底    1100: 红字
	mov	al, 'I'
	mov	[gs:((80 * 0 + 80) * 2)], ax	; 屏幕第 0 行, 第 70 列。
	iretd

_SpuriousHandler:
SpuriousHandler	equ	_SpuriousHandler - $$
	mov	ah, 0Ch				; 0000: 黑底    1100: 红字
	mov	al, '!'
	mov	[gs:((80 * 0 + 70) * 2)], ax	; 屏幕第 0 行, 第 75 列。
	jmp	$
	iretd
; ---------------------------------------------------------------------------

; 启动分页机制 --------------------------------------------------------------
SetupPaging:
	; 根据内存大小计算应初始化多少PDE以及多少页表
	xor	edx, edx
	mov	eax, [dwMemSize]
	mov	ebx, 400000h	; 400000h = 4M = 4096 * 1024, 一个页表对应的内存大小
	div	ebx
	mov	ecx, eax	; 此时 ecx 为页表的个数，也即 PDE 应该的个数
	test	edx, edx
	jz	.no_remainder
	inc	ecx		; 如果余数不为 0 就需增加一个页表
.no_remainder:
	mov	[PageTableNumber], ecx	; 暂存页表个数

	; 初始化页表与页目录
	; 为简化处理, 所有线性地址对应相等的物理地址. 并且不考虑内存空洞.
%assign 		num 	1
%rep			SetNumberOfProcess
	; 首先初始化页目录
	mov	ax, SelectorFlatRW
	mov	es, ax
	mov	edi, PageDirBase%[num]	; 此段首地址为 PageDirBase
	xor	eax, eax
	mov	eax, PageTblBase%[num] | PG_P  | PG_USU | PG_RWW
LocalTable1%[num]:
	stosd
	add	eax, 4096		; 为了简化, 所有页表在内存中是连续的.
	loop	LocalTable1%[num]

	; 再初始化所有页表
	mov	eax, [PageTableNumber]	; 页表个数
	mov	ebx, 1024		; 每个页表 1024 个 PTE
	mul	ebx
	mov	ecx, eax		; PTE个数 = 页表个数 * 1024
	mov	edi, PageTblBase%[num]	; 此段首地址为 PageTblBase
	xor	eax, eax
	mov	eax, PG_P  | PG_USU | PG_RWW
LocalTable2%[num]:
	stosd
	add	eax, 4096		; 每一页指向 4K 的空间
	loop	LocalTable2%[num]

	; 在此假设内存是大于 8M 的
	mov	eax, LinearAddrDemo
	shr	eax, 22
	mov	ebx, 4096
	mul	ebx
	mov	ecx, eax
	mov	eax, LinearAddrDemo
	shr	eax, 12
	and	eax, 03FFh	; 1111111111b (10 bits)
	mov	ebx, 4
	mul	ebx
	add	eax, ecx
	add	eax, PageTblBase%[num]
	mov	dword [es:eax], ProcTask%[num] | PG_P | PG_USU | PG_RWW
%assign 		num 	num + 1
%endrep

    

	mov	eax, PageDirBase1
	mov	cr3, eax
	mov	eax, cr0
	or	eax, 80000000h
	mov	cr0, eax
	jmp	short .3
.3:
	nop

	ret
; 分页机制启动完毕 ----------------------------------------------------------

; 测试分页机制 --------------------------------------------------------------
StartPage:
	mov	ax, cs
	mov	ds, ax
	mov	ax, SelectorFlatRW
	mov	es, ax

%assign 		num 	1
%rep			SetNumberOfProcess
	push	LenTask%[num]
	push	OffsetTask%[num]
	push	ProcTask%[num]
	call	MemCpy
	add	esp, 12
%assign 		num 	num + 1
%endrep	

	push	LenPagingDemoAll
	push	OffsetPagingDemoProc
	push	ProcPagingDemo
	call	MemCpy
	add	esp, 12

	mov	ax, SelectorData
	mov	ds, ax			; 数据段选择子
	mov	es, ax

	call	SetupPaging		; 启动分页

	ret
; ---------------------------------------------------------------------------


; PagingDemoProc ------------------------------------------------------------
PagingDemoProc:
OffsetPagingDemoProc	equ	PagingDemoProc - $$
	mov		eax, LinearAddrDemo
	call	eax
	retf
; ---------------------------------------------------------------------------
LenPagingDemoAll	equ	$ - PagingDemoProc
; ---------------------------------------------------------------------------


; task1 -----------------------------------------------------------------------
task1:
OffsetTask1	equ	task1 - $$
looptask1:
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'V'
	mov	[gs:((80 * 17 + 0) * 2)], ax	; 屏幕第 17 行, 第 0 列。
	mov	al, 'E'
	mov	[gs:((80 * 17 + 1) * 2)], ax	; 屏幕第 17 行, 第 1 列。
	mov	al, 'R'
	mov	[gs:((80 * 17 + 2) * 2)], ax	; 屏幕第 17 行, 第 2 列。
	mov	al, 'Y'
	mov	[gs:((80 * 17 + 3) * 2)], ax	; 屏幕第 17 行, 第 3 列。
	jmp looptask1
	ret
LenTask1	equ	$ - task1
; ---------------------------------------------------------------------------


; task2 -----------------------------------------------------------------------
task2:
OffsetTask2	equ	task2 - $$
looptask2:
	mov	ah, 0Fh			; 0000: 黑底    1111: 白字
	mov	al, 'L'
	mov	[gs:((80 * 17 + 0) * 2)], ax	; 屏幕第 17 行, 第 0 列。
	mov	al, 'O'
	mov	[gs:((80 * 17 + 1) * 2)], ax	; 屏幕第 17 行, 第 1 列。
	mov	al, 'V'
	mov	[gs:((80 * 17 + 2) * 2)], ax	; 屏幕第 17 行, 第 2 列。
	mov	al, 'E'
	mov	[gs:((80 * 17 + 3) * 2)], ax	; 屏幕第 17 行, 第 3 列。
	jmp looptask2
	ret
LenTask2	equ	$ - task2
; ---------------------------------------------------------------------------


; task3 -----------------------------------------------------------------------
task3:
OffsetTask3	equ	task3 - $$
looptask3:
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'H'
	mov	[gs:((80 * 17 + 0) * 2)], ax	; 屏幕第 17 行, 第 0 列。
	mov	al, 'U'
	mov	[gs:((80 * 17 + 1) * 2)], ax	; 屏幕第 17 行, 第 1 列。
	mov	al, 'S'
	mov	[gs:((80 * 17 + 2) * 2)], ax	; 屏幕第 17 行, 第 2 列。
	mov	al, 'T'
	mov	[gs:((80 * 17 + 3) * 2)], ax	; 屏幕第 17 行, 第 3 列。
	jmp looptask3
	ret
LenTask3	equ	$ - task3
; ---------------------------------------------------------------------------


; task4 -----------------------------------------------------------------------
task4:
OffsetTask4	equ	task4 - $$
looptask4:
	mov	ah, 0Fh			; 0000: 黑底    1111: 白字
	mov	al, 'M'
	mov	[gs:((80 * 17 + 0) * 2)], ax	; 屏幕第 17 行, 第 0 列。
	mov	al, 'R'
	mov	[gs:((80 * 17 + 1) * 2)], ax	; 屏幕第 17 行, 第 1 列。
	mov	al, 'S'
	mov	[gs:((80 * 17 + 2) * 2)], ax	; 屏幕第 17 行, 第 2 列。
	mov	al, 'U'
	mov	[gs:((80 * 17 + 3) * 2)], ax	; 屏幕第 17 行, 第 3 列。
	jmp looptask4
	ret
LenTask4	equ	$ - task4
; ---------------------------------------------------------------------------

; task5 -----------------------------------------------------------------------
task5:
OffsetTask5	equ	task5 - $$
looptask5:
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, '-'
	mov	[gs:((80 * 17 + 0) * 2)], ax	; 屏幕第 17 行, 第 0 列。
	mov	al, 'H'
	mov	[gs:((80 * 17 + 1) * 2)], ax	; 屏幕第 17 行, 第 1 列。
	mov	al, 'H'
	mov	[gs:((80 * 17 + 2) * 2)], ax	; 屏幕第 17 行, 第 2 列。
	mov	al, 'F'
	mov	[gs:((80 * 17 + 3) * 2)], ax	; 屏幕第 17 行, 第 3 列。
	jmp looptask5
	ret
LenTask5	equ	$ - task5
; ---------------------------------------------------------------------------

; 显示内存信息 --------------------------------------------------------------
DispMemSize:
	push	esi
	push	edi
	push	ecx

	mov	esi, MemChkBuf
	mov	ecx, [dwMCRNumber]	;for(int i=0;i<[MCRNumber];i++) // 每次得到一个ARDS(Address Range Descriptor Structure)结构
.loop:						;{
	mov	edx, 5				;	for(int j=0;j<5;j++)	// 每次得到一个ARDS中的成员，共5个成员
	mov	edi, ARDStruct		;	{			// 依次显示：BaseAddrLow，BaseAddrHigh，LengthLow，LengthHigh，Type
.1:							;
	push	dword [esi]		;
	call	DispInt			;		DispInt(MemChkBuf[j*4]); // 显示一个成员
	pop	eax					;
	stosd					;		ARDStruct[j*4] = MemChkBuf[j*4];
	add	esi, 4				;
	dec	edx					;
	cmp	edx, 0				;
	jnz	.1					;	}
	call	DispReturn		;	printf("\n");
	cmp	dword [dwType], 1	;	if(Type == AddressRangeMemory) // AddressRangeMemory : 1, AddressRangeReserved : 2
	jne	.2					;	{
	mov	eax, [dwBaseAddrLow];
	add	eax, [dwLengthLow]	;
	cmp	eax, [dwMemSize]	;		if(BaseAddrLow + LengthLow > MemSize)
	jb	.2					;
	mov	[dwMemSize], eax	;			MemSize = BaseAddrLow + LengthLow;
.2:							;	}
	loop	.loop			;}
							;
	call	DispReturn		;printf("\n");
	push	szRAMSize		;
	call	DispStr			;printf("RAM size:");
	add	esp, 4				;
							;
	push	dword [dwMemSize];
	call	DispInt			;DispInt(MemSize);
	add	esp, 4				;

	pop	ecx
	pop	edi
	pop	esi
	ret
; ---------------------------------------------------------------------------

%include	"lib.inc"	; 库函数

SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]


; 16 位代码段. 由 32 位代码段跳入, 跳出后到实模式
[SECTION .s16code]
ALIGN	32
[BITS	16]
LABEL_SEG_CODE16:
	; 跳回实模式:
	mov	ax, SelectorNormal
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax

	mov	eax, cr0
	and	al, 11111110b
	mov	cr0, eax

LABEL_GO_BACK_TO_REAL:
	jmp	0:LABEL_REAL_ENTRY	; 段地址会在程序开始处被设置成正确的值

Code16Len	equ	$ - LABEL_SEG_CODE16
; END of [SECTION .s16code]


%assign			num					1
%rep			SetNumberOfProcess
; TSS ---------------------------------------------------------------------------------------------
;初始化任务状态堆栈段(TSS)
[SECTION .tss]         ;求得各段的大小
ALIGN	32              ;align是一个让数据对齐的宏。通常align的对象是1、4、8等。这里的align 32是没有意义的，因为本来就是只有32b的地址总线宽度。
[BITS	32]             ;32位模式的机器运行
LABEL_TSS%[num]:              ;定义LABEL_TSS
		DD	0			; Back
		DD	TopOfStack%[num]	; 0 级堆栈   //内层ring0级堆栈放入TSS中
		DD	SelectorStack%[num]; 
		DD	0			; 1 级堆栈
		DD	0			; 
		DD	0			; 2 级堆栈
		DD	0			;               //TSS中最高只能放入Ring2级堆栈，ring3级堆栈不需要放入
		DD	PageDirBase%[num]; CR3
		DD	0			; EIP
		DD	0			; EFLAGS
		DD	0			; EAX
		DD	0			; ECX
		DD	0			; EDX
		DD	0			; EBX
		DD	Stack%[num]Len	; ESP
		DD	0			; EBP
		DD	0			; ESI
		DD	0			; EDI
		DD	0			; ES
		DD	SelectorLDT%[num]Task			; CS
		DD	SelectorLDT%[num]Stack			; SS
		DD	SelectorLDT%[num]Data			; DS
		DD	0			; FS
		DD	SelectorVideo			; GS
		DD	SelectorLDT%[num]; LDT
		DW	0			; 调试陷阱标志
		DW	$ - LABEL_TSS%[num] + 2	; I/O位图基址
		DB	0ffh			; I/O位图结束标志
TSSLen%[num]		equ	$ - LABEL_TSS%[num]   ;求得段的大小
; TSS ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


; LDT
[SECTION .ldt]
ALIGN	32
LABEL_LDT%[num]:
;                                         段基址       段界限     ,   属性
LABEL_LDT%[num]_DESC_TASK:	Descriptor	       0,     Task%[num]Len - 1,   DA_C + DA_32	; Code, 32 位
LABEL_LDT%[num]_DESC_DATA:	Descriptor	       0,     Data%[num]Len - 1,   DA_DRW		; Data, 32 位
LABEL_LDT%[num]_DESC_STACK:	Descriptor	       0,  	 	 Stack%[num]Len,   DA_DRW + DA_32; Stack, 32 位
LDT%[num]Len		equ	$ - LABEL_LDT%[num]

; LDT 选择子
SelectorLDT%[num]Task	equ	LABEL_LDT%[num]_DESC_TASK - LABEL_LDT%[num] + SA_TIL
SelectorLDT%[num]Data	equ	LABEL_LDT%[num]_DESC_DATA - LABEL_LDT%[num] + SA_TIL
SelectorLDT%[num]Stack	equ	LABEL_LDT%[num]_DESC_STACK - LABEL_LDT%[num] + SA_TIL
; END of [SECTION .ldt]

; Task (LDT, 32 位代码段)
[SECTION .la]
ALIGN	32
[BITS	32]
LABEL_Task%[num]:
	sti
	call SelectorFlatC:ProcPagingDemo
	jmp	LABEL_Task%[num]
Task%[num]Len	equ	$ - LABEL_Task%[num]
; END of [SECTION .la]

; Data
[SECTION .da]
ALIGN	32
[BITS	32]
LABEL_Data%[num]:
Data%[num]Len	equ $ - LABEL_Data%[num]
; END of [SECTION .da]

[SECTION .sa]
ALIGN	32
[BITS	32]
Local_LABEL_STACK%[num]:
	times 512 db 0
Stack%[num]Len	equ	$ - Local_LABEL_STACK%[num] - 1
; END of [SECTION .sa]
%assign			num					num + 1
%endrep


