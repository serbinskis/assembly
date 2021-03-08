org 0h
mov al,0x00
mov bx,0x0000
mov cx,0x0001
cycle:
mov ah,0x09
int 0x10
mov ah,0x0e
int 0x10
inc al
inc bl
jmp cycle

MBR_signature:
	times 510 - ($ - $$) db 0
	dw 0xAA55