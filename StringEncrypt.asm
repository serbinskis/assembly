cpu 386
bits 16
org 0h


start:                        ;Ok, dont change this stuff either..
    jmp short load_prog
    ident db "Serbix"

;=====================================================================================================================

load_prog:
    cld
    xor ax, ax
    mov ss, ax
    mov sp, 7c00h             ;Setup stack

    mov ax, 8000h
    mov es, ax                ;Initialize es w/ 8000h
    mov ds, ax                ;Initialize ds w/ 8000h

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
    mov [boot_drive], dl

    push es
    mov ax, prog_continue
    push ax
    retf

;=====================================================================================================================    

prog_continue:
    mov ah, 07h                ;Function to call with interrupt
    mov al, 0x00               ;Scroll whole window
    mov bh, 0x0F               ;Black background with white text
    mov cx, 0x0000             ;Row 0,col 0
    mov dx, 0x184f
    int 10h

    mov dh, 0                  ;Cursor position row
    mov dl, 0                  ;Cursor position column
    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Display page number
    int 10h                    ;Call interrupt

    mov bp, 0400h
    mov ah, 0eh
    mov si, 0ffffh
    jmp next

;=====================================================================================================================

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

;=====================================================================================================================

next:
    mov dh, 23                 ;Cursor position row
    mov dl, 1                  ;Cursor position column
    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Display page number
    int 10h                    ;Call interrupt

    mov si, msg1
    call print_str
    mov si, buffer

get_keystrokes:
    xor al, al                 ;Clear buffer
    mov ah,0h                  ;Wait until key press
    int 16h

    mov ah, 03h                ;Get current cusror position
    mov bh, 0                  ;Display page number
    int 10h                    ;Call interrupt

    cmp al, 0                  ;Check for nothing
    je get_keystrokes

    cmp al, 32                 ;Disable spacebar
    je get_keystrokes

    cmp al, 9                  ;Disable tab
    je get_keystrokes

    cmp al, 8                  ;Check for backsapce
    je backspace

    cmp al, 13                 ;Check for enter
    je Encrypt

    cmp dl, 78                 ;Don't let string to get to second line
    je get_keystrokes

    mov ah, 0Eh                ;Teletype user inputed character
    int 10h                    ;Call interrupt
    mov byte [si], al
    inc byte [input_length]
    inc si

    jmp get_keystrokes

backspace:
    mov ah, 03h                ;Get current cusror shape position
    mov bh, 0                  ;Page number
    int 10h                    ;Call interrupt

    cmp dl, msg1_len           ;Make so we don't accidentally delete text contained in msg1
    je get_keystrokes
    dec dl

    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Page number
    int 10h                    ;Jump one column before

    mov al, 0                  ;Zero scancode
    mov ah, 0Eh                ;Teletype character
    int 10h                    ;Call interrupt

    dec si
    dec byte [input_length]
    mov byte [si], 0           ;Clear buffer

    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Page number
    int 10h                    ;Jump one column before

    jmp get_keystrokes

;=====================================================================================================================

Encrypt:
    lea edx, [buffer]
    mov ebx, [input_length]

    enc_loop:
        mov eax, [edx]
        inc ebx
        xor eax, ebx
        mov [edx], eax
        inc edx
        cmp byte [edx], 0
        jne enc_loop

.ClearAll:
    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Page number
    int 10h                    ;Jump one column before

    mov byte [si], 0           ;Clear buffer
    inc si

    cmp dl, msg1_len           ;Clear everything until text contained in msg
    je .DisplayMessage
    dec dl

    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Page number
    int 10h                    ;Jump one column before

    mov al, 0                  ;Zero scancode
    mov ah, 0Eh                ;Teletype character
    int 10h                    ;Call interrupt

    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Page number
    int 10h                    ;Jump one column before

    jmp .ClearAll

.DisplayMessage:
    mov dh, 23                 ;Cursor position row
    mov dl, 1                  ;Cursor position column
    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Display page number
    int 10h                    ;Call interrupt

    mov si, msg1
    call print_str

    mov si, buffer
    call print_str

halt:
    hlt
    jmp halt

;=====================================================================================================================

MBR_Signature:
    boot_drive dd 0
    input_length dd 0
    msg1: db 'Encrypt: ', 0
    msg1_len: equ $-msg1
    times 510-($-$$) db 0
    db 55h,0aah
    times 4096-($-$$) db 0
    buffer: