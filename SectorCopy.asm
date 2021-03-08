org 0x7c00
bits 16

;=====================================================================================================================

RestoreMBR:	
    ;Setup segments
    xor ax, ax                  ;AX=0
    mov ax, ds                  ;DS=ES=0 because we use an org of 0x7c00 - Segment<<4+offset = 0x0000<<4+0x7c00 = 0x07c00
    mov ax, es
    mov ax, ss
    mov sp, 0x7c00              ;SS:SP= 0x0000:0x7c00 stack just below bootloader

    ;Read sector - 2th
    mov bx, buffer              ;ES: BX must point to the buffer
;   mov dl, 0                   ;Use boot drive passed to bootloader by BIOS in DL
    mov dh, 0                   ;Head number
    mov ch, 0                   ;Track number
    mov cl, 2                   ;Sector number - (2th)
    mov al, 1                   ;Number of sectors to read
    mov ah, 2                   ;Read function number
    int 13h

    ;Write sector - 1th
    mov bx, buffer              ;ES: BX must point to the buffer
;   mov dl, 0                   ;Use boot drive passed to bootloader by BIOS in DL
    mov dh, 0                   ;Head number
    mov ch, 0                   ;Track number
    mov cl, 1                   ;Sector number - (1th)
    mov al, 1                   ;Number of sectors to write
    mov ah, 3                   ;Write function number
    int 13h

;=====================================================================================================================

buffer equ 4096                 ;Buffer address (decimal)
times 510 - ($-$$) db 0
dw 0xaa55                       ;MBR signature