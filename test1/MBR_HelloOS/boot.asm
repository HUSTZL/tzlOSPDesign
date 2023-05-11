org 07c00h
mov ax, cs
mov ds, ax
mov es, ax
call DispStr
jmp $
DispStr:
mov ax, BootMessage
mov bp, ax
mov cx, 16
mov ax, 01301h
mov bx, 000ch
mov dl, 0
int 10h
mov ah, 0x0e
mov al, 0x0d
int 0x10
mov al, 0x0a
int 0x10
mov ax, 0x88
int 0x15
add ax, 1024
mov bx, 10
xor cx, cx
xor si, si
loopi:  xor dx, dx
div bx
or dl, 0x30
mov [heap+si], dl
inc si     
inc cx
cmp ax, 0
jnz loopi
dec si
mov ah, 0x0e
loopj: mov al, [heap+si]
int 0x10
dec si
loop loopj 
mov ah, 0x0e
mov al, 0x0d
int 0x10
mov al, 0x0a
int 0x10
ret
BootMessage: db "Hello, OS world!"
heap: dw 10
times 510 - ($-$$) db 0
dw 0xaa55
