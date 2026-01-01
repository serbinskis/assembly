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

    push es
    mov ax, counter_inc
    push ax
    retf

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

counter_inc:
    mov eax, [number]
    mov di, strbuf             ;ES:DI points to string buffer to store to
    call uint32_to_str         ;Convert 32-bit unsigned value in EAX to ASCII string
    mov si, di                 ;DS:SI points to string buffer to print
    call print_str

    mov al, 13                 ;Zero scancode
    mov ah, 0Eh                ;Teletype character
    int 10h                    ;Call interrupt

    mov al, 10                 ;Zero scancode
    mov ah, 0Eh                ;Teletype character
    int 10h                    ;Call interrupt

    mov eax, [number]
    add eax, 1                 ;Increase value by 1
    mov [number], eax          ;Store final value in number

    cmp eax, 1000
    je timeout
    jmp counter_inc

timeout:
    mov ah, 86h               ;AH = 86
    mov cx, 25                ;Set for timeout 50
    int 15h                   ;Wait function

counter_dec:
    mov eax, [number]
    mov di, strbuf             ;ES:DI points to string buffer to store to
    call uint32_to_str         ;Convert 32-bit unsigned value in EAX to ASCII string
    mov si, di                 ;DS:SI points to string buffer to print
    call print_str

    mov al, 13                 ;Zero scancode
    mov ah, 0Eh                ;Teletype character
    int 10h                    ;Call interrupt

    mov al, 10                 ;Zero scancode
    mov ah, 0Eh                ;Teletype character
    int 10h                    ;Call interrupt

    mov eax, [number]
    sub eax, 1                 ;Decrease value by 1
    mov [number], eax          ;Store final value in number

    cmp eax, 0
    je halt
    jmp counter_dec

halt:
    hlt
    jmp halt

;=====================================================================================================================

MBR_Signature:
    number dd 0
    strbuf db 0
    times 510-($-$$) db 0
    db 55h,0aah
    times 4096-($-$$) db 0