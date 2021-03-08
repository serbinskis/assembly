org 0x7c00
bits 16

;=====================================================================================================================

start:
    cld
    xor ax,ax
    mov ss,ax
    mov sp,7c00h                 ;Setup stack

    mov ax,8000h
    mov es,ax                    ;Initialize es w/ 8000h
    mov ds,ax                    ;Initialize ds w/ 8000h

    mov ah, 07h                ;Function to call with interrupt
    mov al, 0x00               ;Scroll whole window
    mov bh, 0x0F               ;Black background with white text
    mov cx, 0x0000             ;Row 0,col 0
    mov dx, 0x184f
    int 10h                    ;Clear screen just in case

    mov dh, 0                  ;Cursor position row
    mov dl, 0                  ;Cursor position column
    mov bh, 0                  ;Display page number
    mov ah, 02h                ;Set cursor position
    int 10h                    ;Set cursor postion to begining of screen

;=====================================================================================================================

get_keystrokes:
    xor al, al
    mov ah, 0h
    int 16h

    mov [INPUTED_CHAR], al
    mov eax, [INPUTED_CHAR]

    mov di, strbuf               ;ES:DI points to string buffer to store to
    call uint32_to_str           ;Convert 32-bit unsigned value in EAX to ASCII string
    mov si, strbuf               ;DS:SI points to string buffer to print
    call print_str

    mov al, 13
    mov ah, 0Eh
    int 10h                      ;Teletype character

    mov al, 10
    mov ah, 0Eh
    int 10h                      ;Teletype character

    jmp get_keystrokes

;=====================================================================================================================

print_str:
    push ax
    push di
    mov ah, 0eh
.getchar:
    lodsb                        ;Same as mov al,[si] and inc si
    test al, al                  ;Same as cmp al,0
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
    xor bx, bx                   ;Digit count
    mov ecx, 10                  ;Divisor
.digloop:
    xor edx, edx                 ;Division will use 64-bit dividend in EDX:EAX
    div ecx                      ;Divide EDX:EAX by 10 ; EAX=Quotient ; EDX=Remainder(the current digit)
    add dl, '0'                  ;Convert digit to ASCII
    push dx                      ;Push on stack so digits can be popped off in everse order when finished
    inc bx                       ;Digit count += 1
    test eax, eax
    jnz .digloop                 ;If dividend is zero then we are finished converting the number
.popdigloop:                     ;Get digits from stack in reverse order we pushed them
    pop ax
    stosb                        ;Same as mov [ES:DI], al and inc di
    dec bx
    jne .popdigloop              ;Loop until all digits have been popped
    mov al, 0
    stosb                        ;NUL terminate string ; Same as mov [ES:DI], al and inc di
    pop di
    pop bx
    pop ecx
    pop eax
    pop edx
    ret

;=====================================================================================================================



MBR_Signature:
    INPUTED_CHAR db 0,13,10,0
    strbuf db 0
	times 510-($-$$) db 0
	db 55h,0aah