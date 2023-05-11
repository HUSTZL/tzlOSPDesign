; ==========================================
; superv2.asm
; ���뷽����nasm superv2.asm -o superv2.com
; ʵ�ֹ��ܣ�  ֧�ּ���PCB�����֣�pid����̬���ȼ�����̬���ȼ�������֧�ֶ�����׽��̣�LDT��TSS��ҳĿ¼��ҳ�������ֶ���д��
; 			ʹ�ö�ҳʽ��ַӳ�䣬֮ǰһ�湲��ҳĿ¼��ҳ��
;			�˰汾Ϊÿ�����׽��̴���ҳĿ¼��ҳ����Ϊ�˼򻯣�ҳĿ¼��ҳ���ֱ�ӽ����Ե�ֱַ��ӳ��Ϊ�����ַ��
; ==========================================

%include	"pm.inc"	; ����, ��, �Լ�һЩ˵��

%define SetNumberOfProcess 5	

%assign 		PhysicalAddress 	200000h
%assign			num					1
%rep			SetNumberOfProcess
PageDirBase%[num]	equ	PhysicalAddress	; ҳĿ¼��ʼ��ַ:	2M
%assign 		PhysicalAddress 	PhysicalAddress + 01000H
PageTblBase%[num]	equ	PhysicalAddress	; ҳ��ʼ��ַ:		2M +  4K
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
;                                         �λ�ַ,       �ν���     , ����
LABEL_GDT:			Descriptor	       0,                 0, 0				; ��������
LABEL_DESC_NORMAL:	Descriptor	       0,            0ffffh, DA_DRW			; Normal ������
LABEL_DESC_FLAT_C:	Descriptor         0,           0fffffh, DA_CR | DA_32 | DA_LIMIT_4K; 0 ~ 4G
LABEL_DESC_FLAT_RW:	Descriptor         0,           0fffffh, DA_DRW | DA_LIMIT_4K	; 0 ~ 4G
LABEL_DESC_CODE32:	Descriptor	       0,  SegCode32Len - 1, DA_CR | DA_32	; ��һ�´����, 32
LABEL_DESC_CODE16:	Descriptor	       0,            0ffffh, DA_C			; ��һ�´����, 16
LABEL_DESC_DATA:	Descriptor	       0,		DataLen - 1, DA_DRW				; Data
LABEL_DESC_STACK:	Descriptor	       0,        TopOfStack, DA_DRWA | DA_32; Stack, 32 λ

%assign 		num 	1
%rep			SetNumberOfProcess
LABEL_DESC_STACK%[num]:	Descriptor	   0,  TopOfStack%[num], DA_DRWA | DA_32; Stack, 32 λ
LABEL_DESC_LDT%[num]:	Descriptor	   0,  LDT%[num]Len - 1, DA_LDT			; LDT
LABEL_DESC_TSS%[num]:	Descriptor	   0,  TSSLen%[num] - 1, DA_386TSS		; TSSs
%assign 		num 	num + 1
%endrep

LABEL_DESC_VIDEO:	Descriptor	 0B8000h,            0ffffh, DA_DRW			; �Դ��׵�ַ
; GDT ����

GdtLen		equ	$ - LABEL_GDT	; GDT����
GdtPtr		dw	GdtLen - 1		; GDT����
			dd	0				; GDT����ַ

; GDT ѡ����
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
	db	%1				;�����������ܳ���10���ַ�
	%strlen charcnt %1
	%rep	10 - charcnt
	db	0
	%endrep
	dw	%2				;pid
	dw	%3				;��ǰ���̳��е�ʱ��Ƭ
	dw	%4				;��̬���ȼ�
%endmacro ; �� 16 �ֽ�

[SECTION .data1]	 ; ���ݶ�
ALIGN	32
[BITS	32]
LABEL_DATA:
; ʵģʽ��ʹ����Щ����
; �ַ���
_szPMMessage:		db	"In Protect Mode now. ^-^", 0Ah, 0Ah, 0	; ���뱣��ģʽ����ʾ���ַ���
_szMemChkTitle:		db	"BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0	; ���뱣��ģʽ����ʾ���ַ���
_szRAMSize:			db	"RAM size:", 0
_szReturn:			db	0Ah, 0
; ����
_wSPValueInRealMode:dw	0
_dwMCRNumber:		dd	0	; Memory Check Result
_dwDispPos:			dd	(80 * 6 + 0) * 2	; ��Ļ�� 6 ��, �� 0 �С�
_dwMemSize:			dd	0
_ARDStruct:			; Address Range Descriptor Structure
_dwBaseAddrLow:		dd	0
_dwBaseAddrHigh:	dd	0
_dwLengthLow:		dd	0
_dwLengthHigh:		dd	0
_dwType:			dd	0
_PageTableNumber:	dd	0
_SavedIDTR:			dd	0	; ���ڱ��� IDTR
					dd	0
_SavedIMREG:		db	0	; �ж����μĴ���ֵ
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



; ����ģʽ��ʹ����Щ����
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


; ȫ�ֶ�ջ��
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
; ��                                Ŀ��ѡ����,            ƫ��, DCount, ����
%rep 32
			Gate	SelectorCode32, SpuriousHandler,      0, DA_386IGate
%endrep
.020h:		Gate	SelectorCode32,    ClockHandler,      0, DA_386IGate
%rep 95
			Gate	SelectorCode32, SpuriousHandler,      0, DA_386IGate
%endrep
.080h:		Gate	SelectorCode32,  UserIntHandler,      0, DA_386IGate

IdtLen		equ	$ - LABEL_IDT
IdtPtr		dw	IdtLen - 1	; �ν���
			dd	0		; ����ַ
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

	; �õ��ڴ���
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

	; ��ʼ�� 16 λ�����������
	mov	ax, cs
	movzx	eax, ax
	shl	eax, 4
	add	eax, LABEL_SEG_CODE16
	mov	word [LABEL_DESC_CODE16 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE16 + 4], al
	mov	byte [LABEL_DESC_CODE16 + 7], ah

	; ��ʼ�� 32 λ�����������
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

	; ��ʼ�����ݶ�������
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_DATA
	mov	word [LABEL_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_DATA + 4], al
	mov	byte [LABEL_DESC_DATA + 7], ah

	; ��ʼ����ջ��������
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK
	mov	word [LABEL_DESC_STACK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK + 4], al
	mov	byte [LABEL_DESC_STACK + 7], ah

	; ��ʼ��ÿһ������
%assign 		num 	1
%rep			SetNumberOfProcess
	; ��ʼ���ں˶�ջ��������
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK%[num]
	mov	word [LABEL_DESC_STACK%[num] + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK%[num] + 4], al
	mov	byte [LABEL_DESC_STACK%[num] + 7], ah

	; ��ʼ�� LDT �� GDT �е�������
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_LDT%[num]
	mov	word [LABEL_DESC_LDT%[num] + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_LDT%[num] + 4], al
	mov	byte [LABEL_DESC_LDT%[num] + 7], ah

	; ��ʼ�� TSS ������
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_TSS%[num]
	mov	word [LABEL_DESC_TSS%[num] + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_TSS%[num] + 4], al
	mov	byte [LABEL_DESC_TSS%[num] + 7], ah

	; ��ʼ�� LDT �е�������
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

	; Ϊ���� GDTR ��׼��
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt ����ַ
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt ����ַ

	; Ϊ���� IDTR ��׼��
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_IDT		; eax <- idt ����ַ
	mov	dword [IdtPtr + 2], eax	; [IdtPtr + 2] <- idt ����ַ

	; ���� IDTR
	sidt	[_SavedIDTR]

	; �����ж����μĴ���(IMREG)ֵ
	in	al, 21h
	mov	[_SavedIMREG], al

	; ���� GDTR
	lgdt	[GdtPtr]

	; ���� IDTR
	lidt	[IdtPtr]

	; �򿪵�ַ��A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; ׼���л�������ģʽ
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; �������뱣��ģʽ
	jmp	dword SelectorCode32:0	; ִ����һ���� SelectorCode32 װ�� cs, ����ת�� Code32Selector:0  ��

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LABEL_REAL_ENTRY:		; �ӱ���ģʽ���ص�ʵģʽ�͵�������
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, [_wSPValueInRealMode]

	lidt	[_SavedIDTR]	; �ָ� IDTR ��ԭֵ

	mov	al, [_SavedIMREG]	; ���ָ��ж����μĴ���(IMREG)��ԭֵ
	out	21h, al				; ��

	in	al, 92h			; ��
	and	al, 11111101b	; �� �ر� A20 ��ַ��
	out	92h, al			; ��

	sti			; ���ж�

	mov	ax, 4c00h	; ��
	int	21h			; ���ص� DOS
; END of [SECTION .s16]


[SECTION .s32]; 32 λ�����. ��ʵģʽ����.
[BITS	32]

LABEL_SEG_CODE32:
	mov	ax, SelectorData
	mov	ds, ax			; ���ݶ�ѡ����
	mov	es, ax
	mov	ax, SelectorVideo
	mov	gs, ax			; ��Ƶ��ѡ����

	mov	ax, SelectorStack
	mov	ss, ax			; ��ջ��ѡ����

	mov	esp, TopOfStack

	call	Init8259A

	; ������ʾһ���ַ���
	push	szPMMessage
	call	DispStr
	add	esp, 4

	push	szMemChkTitle
	call	DispStr
	add	esp, 4

	call	DispMemSize		; ��ʾ�ڴ���Ϣ

	call	StartPage		; ������ҳ����
	

	mov 	ax, SelectorLDT1
	lldt 	ax
	jmp 	SelectorLDT1Task:0

	call	SetRealmode8259A

	; ����ֹͣ
	jmp	SelectorCode16:0


; Init8259A ---------------------------------------------------------------------------------------------
Init8259A:
	mov	al, 011h
	out	020h, al	; ��8259, ICW1.
	call	io_delay

	out	0A0h, al	; ��8259, ICW1.
	call	io_delay

	mov	al, 020h	; IRQ0 ��Ӧ�ж����� 0x20
	out	021h, al	; ��8259, ICW2.
	call	io_delay

	mov	al, 028h	; IRQ8 ��Ӧ�ж����� 0x28
	out	0A1h, al	; ��8259, ICW2.
	call	io_delay

	mov	al, 004h	; IR2 ��Ӧ��8259
	out	021h, al	; ��8259, ICW3.
	call	io_delay

	mov	al, 002h	; ��Ӧ��8259�� IR2
	out	0A1h, al	; ��8259, ICW3.
	call	io_delay

	mov	al, 001h
	out	021h, al	; ��8259, ICW4.
	call	io_delay

	out	0A1h, al	; ��8259, ICW4.
	call	io_delay

	mov	al, 11111110b	; ����������ʱ���ж�
	out	021h, al	; ��8259, OCW1.
	call	io_delay

	mov	al, 11111111b	; ���δ�8259�����ж�
	out	0A1h, al	; ��8259, OCW1.
	call	io_delay

	ret
; Init8259A ---------------------------------------------------------------------------------------------


; SetRealmode8259A ---------------------------------------------------------------------------------------------
SetRealmode8259A:
	mov	ax, SelectorData
	mov	fs, ax

	mov	al, 017h
	out	020h, al	; ��8259, ICW1.
	call	io_delay

	mov	al, 008h	; IRQ0 ��Ӧ�ж����� 0x8
	out	021h, al	; ��8259, ICW2.
	call	io_delay

	mov	al, 001h
	out	021h, al	; ��8259, ICW4.
	call	io_delay

	mov	al, [fs:SavedIMREG]	; ���ָ��ж����μĴ���(IMREG)��ԭֵ
	out	021h, al			; ��
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
	out	20h, al				; ���� EOI

	mov ax, SelectorData
	mov ds, ax
	mov es, ax

	mov	ah, 0Fh			; 0000: �ڵ�    1111: ����
	mov	al, '1'
    add eax, dword [ds:nowProcess]
	mov	[gs:((80 * 0 + 0) * 2)], ax	; ��Ļ�� 0 ��, �� 0 �С�

	mov esi, dword [ds:nowProcess]
	shl esi, 4
	add	esi, 0Ch			; �õ�	word [ds:PCB+esi]�д�ŵĵ�ǰ���̵�counter
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
	xor bx, bx ; bx��ŵ�ǰcounter���Ľ��̺�
	xor dx, dx ; dx��ŵ�ǰ�����Ľ��̺�
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
	mov	ah, 0Ch				; 0000: �ڵ�    1100: ����
	mov	al, 'I'
	mov	[gs:((80 * 0 + 80) * 2)], ax	; ��Ļ�� 0 ��, �� 70 �С�
	iretd

_SpuriousHandler:
SpuriousHandler	equ	_SpuriousHandler - $$
	mov	ah, 0Ch				; 0000: �ڵ�    1100: ����
	mov	al, '!'
	mov	[gs:((80 * 0 + 70) * 2)], ax	; ��Ļ�� 0 ��, �� 75 �С�
	jmp	$
	iretd
; ---------------------------------------------------------------------------

; ������ҳ���� --------------------------------------------------------------
SetupPaging:
	; �����ڴ��С����Ӧ��ʼ������PDE�Լ�����ҳ��
	xor	edx, edx
	mov	eax, [dwMemSize]
	mov	ebx, 400000h	; 400000h = 4M = 4096 * 1024, һ��ҳ���Ӧ���ڴ��С
	div	ebx
	mov	ecx, eax	; ��ʱ ecx Ϊҳ��ĸ�����Ҳ�� PDE Ӧ�õĸ���
	test	edx, edx
	jz	.no_remainder
	inc	ecx		; ���������Ϊ 0 ��������һ��ҳ��
.no_remainder:
	mov	[PageTableNumber], ecx	; �ݴ�ҳ�����

	; ��ʼ��ҳ����ҳĿ¼
	; Ϊ�򻯴���, �������Ե�ַ��Ӧ��ȵ������ַ. ���Ҳ������ڴ�ն�.
%assign 		num 	1
%rep			SetNumberOfProcess
	; ���ȳ�ʼ��ҳĿ¼
	mov	ax, SelectorFlatRW
	mov	es, ax
	mov	edi, PageDirBase%[num]	; �˶��׵�ַΪ PageDirBase
	xor	eax, eax
	mov	eax, PageTblBase%[num] | PG_P  | PG_USU | PG_RWW
LocalTable1%[num]:
	stosd
	add	eax, 4096		; Ϊ�˼�, ����ҳ�����ڴ�����������.
	loop	LocalTable1%[num]

	; �ٳ�ʼ������ҳ��
	mov	eax, [PageTableNumber]	; ҳ�����
	mov	ebx, 1024		; ÿ��ҳ�� 1024 �� PTE
	mul	ebx
	mov	ecx, eax		; PTE���� = ҳ����� * 1024
	mov	edi, PageTblBase%[num]	; �˶��׵�ַΪ PageTblBase
	xor	eax, eax
	mov	eax, PG_P  | PG_USU | PG_RWW
LocalTable2%[num]:
	stosd
	add	eax, 4096		; ÿһҳָ�� 4K �Ŀռ�
	loop	LocalTable2%[num]

	; �ڴ˼����ڴ��Ǵ��� 8M ��
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
; ��ҳ����������� ----------------------------------------------------------

; ���Է�ҳ���� --------------------------------------------------------------
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
	mov	ds, ax			; ���ݶ�ѡ����
	mov	es, ax

	call	SetupPaging		; ������ҳ

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
	mov	ah, 0Ch			; 0000: �ڵ�    1100: ����
	mov	al, 'V'
	mov	[gs:((80 * 17 + 0) * 2)], ax	; ��Ļ�� 17 ��, �� 0 �С�
	mov	al, 'E'
	mov	[gs:((80 * 17 + 1) * 2)], ax	; ��Ļ�� 17 ��, �� 1 �С�
	mov	al, 'R'
	mov	[gs:((80 * 17 + 2) * 2)], ax	; ��Ļ�� 17 ��, �� 2 �С�
	mov	al, 'Y'
	mov	[gs:((80 * 17 + 3) * 2)], ax	; ��Ļ�� 17 ��, �� 3 �С�
	jmp looptask1
	ret
LenTask1	equ	$ - task1
; ---------------------------------------------------------------------------


; task2 -----------------------------------------------------------------------
task2:
OffsetTask2	equ	task2 - $$
looptask2:
	mov	ah, 0Fh			; 0000: �ڵ�    1111: ����
	mov	al, 'L'
	mov	[gs:((80 * 17 + 0) * 2)], ax	; ��Ļ�� 17 ��, �� 0 �С�
	mov	al, 'O'
	mov	[gs:((80 * 17 + 1) * 2)], ax	; ��Ļ�� 17 ��, �� 1 �С�
	mov	al, 'V'
	mov	[gs:((80 * 17 + 2) * 2)], ax	; ��Ļ�� 17 ��, �� 2 �С�
	mov	al, 'E'
	mov	[gs:((80 * 17 + 3) * 2)], ax	; ��Ļ�� 17 ��, �� 3 �С�
	jmp looptask2
	ret
LenTask2	equ	$ - task2
; ---------------------------------------------------------------------------


; task3 -----------------------------------------------------------------------
task3:
OffsetTask3	equ	task3 - $$
looptask3:
	mov	ah, 0Ch			; 0000: �ڵ�    1100: ����
	mov	al, 'H'
	mov	[gs:((80 * 17 + 0) * 2)], ax	; ��Ļ�� 17 ��, �� 0 �С�
	mov	al, 'U'
	mov	[gs:((80 * 17 + 1) * 2)], ax	; ��Ļ�� 17 ��, �� 1 �С�
	mov	al, 'S'
	mov	[gs:((80 * 17 + 2) * 2)], ax	; ��Ļ�� 17 ��, �� 2 �С�
	mov	al, 'T'
	mov	[gs:((80 * 17 + 3) * 2)], ax	; ��Ļ�� 17 ��, �� 3 �С�
	jmp looptask3
	ret
LenTask3	equ	$ - task3
; ---------------------------------------------------------------------------


; task4 -----------------------------------------------------------------------
task4:
OffsetTask4	equ	task4 - $$
looptask4:
	mov	ah, 0Fh			; 0000: �ڵ�    1111: ����
	mov	al, 'M'
	mov	[gs:((80 * 17 + 0) * 2)], ax	; ��Ļ�� 17 ��, �� 0 �С�
	mov	al, 'R'
	mov	[gs:((80 * 17 + 1) * 2)], ax	; ��Ļ�� 17 ��, �� 1 �С�
	mov	al, 'S'
	mov	[gs:((80 * 17 + 2) * 2)], ax	; ��Ļ�� 17 ��, �� 2 �С�
	mov	al, 'U'
	mov	[gs:((80 * 17 + 3) * 2)], ax	; ��Ļ�� 17 ��, �� 3 �С�
	jmp looptask4
	ret
LenTask4	equ	$ - task4
; ---------------------------------------------------------------------------

; task5 -----------------------------------------------------------------------
task5:
OffsetTask5	equ	task5 - $$
looptask5:
	mov	ah, 0Ch			; 0000: �ڵ�    1100: ����
	mov	al, '-'
	mov	[gs:((80 * 17 + 0) * 2)], ax	; ��Ļ�� 17 ��, �� 0 �С�
	mov	al, 'H'
	mov	[gs:((80 * 17 + 1) * 2)], ax	; ��Ļ�� 17 ��, �� 1 �С�
	mov	al, 'H'
	mov	[gs:((80 * 17 + 2) * 2)], ax	; ��Ļ�� 17 ��, �� 2 �С�
	mov	al, 'F'
	mov	[gs:((80 * 17 + 3) * 2)], ax	; ��Ļ�� 17 ��, �� 3 �С�
	jmp looptask5
	ret
LenTask5	equ	$ - task5
; ---------------------------------------------------------------------------

; ��ʾ�ڴ���Ϣ --------------------------------------------------------------
DispMemSize:
	push	esi
	push	edi
	push	ecx

	mov	esi, MemChkBuf
	mov	ecx, [dwMCRNumber]	;for(int i=0;i<[MCRNumber];i++) // ÿ�εõ�һ��ARDS(Address Range Descriptor Structure)�ṹ
.loop:						;{
	mov	edx, 5				;	for(int j=0;j<5;j++)	// ÿ�εõ�һ��ARDS�еĳ�Ա����5����Ա
	mov	edi, ARDStruct		;	{			// ������ʾ��BaseAddrLow��BaseAddrHigh��LengthLow��LengthHigh��Type
.1:							;
	push	dword [esi]		;
	call	DispInt			;		DispInt(MemChkBuf[j*4]); // ��ʾһ����Ա
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

%include	"lib.inc"	; �⺯��

SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]


; 16 λ�����. �� 32 λ���������, ������ʵģʽ
[SECTION .s16code]
ALIGN	32
[BITS	16]
LABEL_SEG_CODE16:
	; ����ʵģʽ:
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
	jmp	0:LABEL_REAL_ENTRY	; �ε�ַ���ڳ���ʼ�������ó���ȷ��ֵ

Code16Len	equ	$ - LABEL_SEG_CODE16
; END of [SECTION .s16code]


%assign			num					1
%rep			SetNumberOfProcess
; TSS ---------------------------------------------------------------------------------------------
;��ʼ������״̬��ջ��(TSS)
[SECTION .tss]         ;��ø��εĴ�С
ALIGN	32              ;align��һ�������ݶ���ĺꡣͨ��align�Ķ�����1��4��8�ȡ������align 32��û������ģ���Ϊ��������ֻ��32b�ĵ�ַ���߿�ȡ�
[BITS	32]             ;32λģʽ�Ļ�������
LABEL_TSS%[num]:              ;����LABEL_TSS
		DD	0			; Back
		DD	TopOfStack%[num]	; 0 ����ջ   //�ڲ�ring0����ջ����TSS��
		DD	SelectorStack%[num]; 
		DD	0			; 1 ����ջ
		DD	0			; 
		DD	0			; 2 ����ջ
		DD	0			;               //TSS�����ֻ�ܷ���Ring2����ջ��ring3����ջ����Ҫ����
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
		DW	0			; ���������־
		DW	$ - LABEL_TSS%[num] + 2	; I/Oλͼ��ַ
		DB	0ffh			; I/Oλͼ������־
TSSLen%[num]		equ	$ - LABEL_TSS%[num]   ;��öεĴ�С
; TSS ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


; LDT
[SECTION .ldt]
ALIGN	32
LABEL_LDT%[num]:
;                                         �λ�ַ       �ν���     ,   ����
LABEL_LDT%[num]_DESC_TASK:	Descriptor	       0,     Task%[num]Len - 1,   DA_C + DA_32	; Code, 32 λ
LABEL_LDT%[num]_DESC_DATA:	Descriptor	       0,     Data%[num]Len - 1,   DA_DRW		; Data, 32 λ
LABEL_LDT%[num]_DESC_STACK:	Descriptor	       0,  	 	 Stack%[num]Len,   DA_DRW + DA_32; Stack, 32 λ
LDT%[num]Len		equ	$ - LABEL_LDT%[num]

; LDT ѡ����
SelectorLDT%[num]Task	equ	LABEL_LDT%[num]_DESC_TASK - LABEL_LDT%[num] + SA_TIL
SelectorLDT%[num]Data	equ	LABEL_LDT%[num]_DESC_DATA - LABEL_LDT%[num] + SA_TIL
SelectorLDT%[num]Stack	equ	LABEL_LDT%[num]_DESC_STACK - LABEL_LDT%[num] + SA_TIL
; END of [SECTION .ldt]

; Task (LDT, 32 λ�����)
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


