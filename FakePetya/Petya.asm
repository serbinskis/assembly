cpu 386
bits 16
org 0h


start:                         ;Ok, dont change this stuff either..
    jmp short load_prog
    ident db "Serbix"

;=====================================================================================================================

load_prog:
    cld
    xor ax,ax
    mov ss,ax
    mov sp,7c00h               ;Setup stack

    mov ax,8000h
    mov es,ax                  ;Initialize es w/ 8000h
    mov ds,ax                  ;Initialize ds w/ 8000h

load_1:
    mov ax,0210h               ;Function/# of sec to read
    mov cx,0001h               ;0-5 sec # (counts from one), 6-7 hi cyl bits

    ; MDP - Do not clobber DL, it still has the boot drive passed by BIOS
    mov dh,00h                 ;dh=head dl=drive (bit 7=hdd)
    mov bx,0h                  ;Data buffer, points to es:0
    int 13h
    cmp ah,0
    jne load_1                 ;This is allowable because it is relative

    ; MDP - Save boot drive after you set the proper DS segment (0x8000) and after you read the sector into memory
	mov [BOOT_DRIVE], dl

;=====================================================================================================================

    mov cx, 2607h
    mov ah, 01h
    mov bh, 0
    int 10h

Petya:
    xor al, al                 ;Clear buffer
    mov ah, 01h                ;AH = 1
    int 16h                    ;Get for keystroke
    cmp al,0                   ;Compare
    jne Info                   ;If key pressed jump

    mov ah, 86h                ;ah = 86
    mov cx, 1                  ;Set for timeout 1
    int 15h                    ;Wait function

    mov dh, 0                  ;Cursor position line
    mov dl, 0                  ;Cursor position column
    mov ah, 02h
    mov bh, 0
    int 10h                    ;Jump one col before

    cmp byte [COUNT], 1
    je .reverseSkull
    jmp .normalSkull
.normalSkull:
	mov ax, 0x1003
	mov bl, 0
	int 10h

    mov bh, 0x4F               ;Background color
    call ClearScreen
    mov bp,0400h
    call write_char
    mov byte [COUNT], 1
    jmp Petya

.reverseSkull:
	mov ax, 0x1003
	mov bl, 0
	int 10h

    mov bh, 0x74               ;Background color
    call ClearScreen
    mov bp,0400h
    call write_char
    mov byte [COUNT], 2
    jmp Petya

;=====================================================================================================================

Info:
    mov byte [COUNT], 0        ;Clear COUNT
    mov dh, 0                  ;Cursor position line
    mov dl, -1                 ;Cursor position column
    mov ah, 02h
    mov bh, 0
    int 10h

    mov cx, 0607h
    mov ah, 01h
    mov bh, 0
    int 10h

    mov bh, 0x4F               ;Background color
    call ClearScreen

    mov bp,0A00h
    call write_char
    call RestoreMBR

    mov ah, 03h
    mov bh, 0
    int 10h

    mov [CURSOR_LINE], dh
    mov [CUSROR_COL], dl

    mov dh,1                   ;Cursor position line
    mov dl,0                   ;Cursor position column
    mov ah,02h                 ;Set cursor position
    mov bh,0                   ;Page number
    int 10h

    mov al, 220                ;ASCII character
    mov ah, 09                 ;Write character and attribute at cursor position
    mov cx, 80                 ;Number of times to print character
    mov bl, 0x4F               ;Color
    int 10h

    mov dh, [CURSOR_LINE]      ;Cursor position line
    mov dl, [CUSROR_COL]       ;Cursor position column
    mov ah, 02h
    mov bh, 0
    int 10h

key:
    mov si, msg1
    call print_str

get_keystrokes:
    xor al, al                 ;Clear buffer
    mov ah,0h                  ;Wait until key press
    int 16h

    inc byte [COUNT]
    cmp byte [COUNT], 1
    je get_keystrokes

    mov ah, 03h                ;Get cursor position
    mov bh, 0                  ;Page number
    int 10h                    ;Call interrupt
    
    cmp dl, 78
    je incorrect_key

    cmp al, 0                  ;Check for nothing
    je get_keystrokes

    cmp al, 8                  ;Check for Backsapce
    je backspace

    cmp al, 13                 ;Check for Enter
    je incorrect_key

    mov ah, 0Eh
    int 10h                    ;Teletype user inputed character
    jmp get_keystrokes

incorrect_key:
    mov si, msg2
    call print_str
    jmp key

backspace:
    mov ah, 03h
    mov bh, 0
    int 10h

    cmp dl, 6
    je get_keystrokes
    dec dl

    mov ah, 02h
    mov bh, 0
    int 10h                    ;Jump one col before

    mov al, 32                 ;Space scancode
    mov ah, 0Eh
    int 10h                    ;Teletype character

    mov ah, 02h
    mov bh, 0
    int 10h                         ;

    jmp get_keystrokes

;=====================================================================================================================

ClearScreen:
    mov ah, 07h                 ;Function to call with interrupt
    mov al, 0h                  ;Scroll whole window
    mov cx, 0h                  ;Row 0,col 0
    mov dx, 184fh
    int 10h
    ret


write_char:
    mov ah,0eh
    mov si,0ffffh
    inc si
.charloop:
    push bp
    mov al, [byte ds:bp + si]
    mov bx, 07h
    int 10h                    ;Teletype the character
    pop bp
    inc si
    cmp byte [ds:bp + si],0    ;Keep writing until there is a null byte 
    jnz .charloop
    ret


print_str:
    push ax
    push di
    mov ah,0eh
.getchar:
    lodsb                      ;Same as mov al,[si] and inc si
    test al, al                ;Same as cmp al,0
    jz .end
    int 10h
    jmp .getchar
.end:
    pop di
    pop ax
    ret


RestoreMBR:
    ;---read sector
    mov bx,buffer              ;ES: BX must point to the buffer
    mov dl,[BOOT_DRIVE]        ;Use boot drive passed to bootloader by BIOS in DL
    mov dh,0                   ;Head number
    mov ch,0                   ;Track number
    mov cl,2                   ;Sector number
    mov al,1                   ;Number of sectors to read
    mov ah,2                   ;Read function number
    int 13h

    ;---write sector
    mov bx,buffer              ;ES: BX must point to the buffer
    mov dl,[BOOT_DRIVE]        ;Use boot drive passed to bootloader by BIOS in DL
    mov dh,0                   ;Head number
    mov ch,0                   ;Track number
    mov cl,1                   ;Sector number
    mov al,8                   ;Number of sectors to write
    mov ah,3                   ;Write function number
    int 13h
    ret

;=====================================================================================================================



MBR_Signature:
    COUNT dd 0
    BOOT_DRIVE dd 0
    CURSOR_LINE dd 0
    CUSROR_COL dd 0
    msg1 db ' Key: ',0
    msg2 db 13,10,' Incorrect key! Please try again.',13,10,13,10
    times 510-($-$$) db 0
    db 55h,0aah
    times 1024-($-$$) db 0
    incbin "Skull.txt"
    times 2560-($-$$) db 0
    incbin "Info.txt"
    times 8192-($-$$) db 0
    buffer:
