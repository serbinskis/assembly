cpu 386
bits 16
org 0h

start:                         ;Ok, dont change this stuff either..
    jmp short load_prog
    ident db "WobbyChip"

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

CHKDSK:
    mov cx, 2607h
    mov ah, 01h
    mov bh, 0
    int 10h

    mov dh, 0                  ;Cursor position line
    mov dl, 0                  ;Cursor position column
    mov ah, 02h
    mov bh, 0
    int 10h                    ;Jump one col before

    mov bh, 0x07               ;Background color
    call ClearScreen

    mov bp,0200h
    call write_char
    call RestoreMBR

    mov ah, 03h
    mov bh, 0
    int 10h

    mov [CURSOR_LINE], dh
    mov [CUSROR_COL], dl

next:
    mov dh, [CURSOR_LINE]      ;Cursor position line
    mov dl, [CUSROR_COL]       ;Cursor position column
    mov ah, 02h
    mov bh, 0
    int 10h

    mov eax, [NUMBERS]
    add eax, 2048              ;Advance value by 2048
    mov [NUMBERS], eax         ;Store final value in NUMBERS

    mov di, strbuf             ;ES:DI points to string buffer to store to
    call uint32_to_str         ;Convert 32-bit unsigned value in EAX to ASCII string
    mov si, di                 ;DS:SI points to string buffer to print
    call print_str

    mov si, msg1
    call print_str

    mov edx, 0
    mov eax, [NUMBERS]
    mov ecx, 2097152
    div ecx                    ;Divide [NUMBERS]/2097152

    mov di, strbuf             ;ES:DI points to string buffer to store to
    call uint32_to_str         ;Convert 32-bit unsigned value in EAX to ASCII string
    mov si, di                 ;DS:SI points to string buffer to print
    call print_str

    mov si, msg2
    call print_str

    mov eax, [NUMBERS]
    cmp eax, 209715200         ;End loop at 209715200
    jl next                    ;Continue until we reach limit

    mov ah, 86h                ;ah = 86
    mov cx, 20                 ;Set for timeout 20
    int 15h                    ;Wait function

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


RestoreMBR:
    ;Read sector
    mov bx,buffer              ;ES: BX must point to the buffer
    mov dl,[BOOT_DRIVE]        ;Use boot drive passed to bootloader by BIOS in DL
    mov dh,0                   ;Head number
    mov ch,0                   ;Track number
    mov cl,3                   ;Sector number
    mov al,8                   ;Number of sectors to read
    mov ah,2                   ;Read function number
    int 13h

    ;Write sector
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
    msg1 db ' of 209715200 (',0
    msg2 db '%)',0
    BOOT_DRIVE dd 0
    CURSOR_LINE dd 0
    CUSROR_COL dd 0
    NUMBERS dd 0
    strbuf db 0
    times 510-($-$$) db 0
    db 55h,0aah
    incbin "CHKDSK.txt"
    times 8192-($-$$) db 0
    buffer: