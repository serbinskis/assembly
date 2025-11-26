; ===============================
; --------- 12. variants --------
; ===============================

.386
.model flat, stdcall
option casemap:none

;include \masm32\include\windows.inc ; Used for extra windows functions
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

.stack   4096

.const
    ; Store variables for operations
    x        byte   5    ; Signed byte
    y        byte   -4   ; Signed byte
    z        byte   -3   ; Signed byte

.data
    buffer     db 12 DUP(0) ; To store int32 as text inside buffer (11 digits + null)
    whole    word  ?      ; Signed word for quotient
    rem      dw    ?      ; Signed word for remainder

.code
start proc
    ; ==================================
    ; --- Calculate A = -X Z^3 Y + 2 ---
    ; ==================================

    ; Calculate Z^3
    mov  al, z      ; Store byte value in al, we cannot store z in ax, because byte and register size must be the same
    imul al         ; imul 8bit: al * 8bit (al) => ax
    mov  bx, ax     ; Store result of multiplication inside bx
    mov  al, z      ; Load byte value into al, remember we cannot just load 8bit into 16bit ax
    cbw             ; Extend al into ax, this is required for next opration
    imul bx         ; imul 16bit: ax * 16bit (bx) => ax
    mov  bx, ax     ; Store final result in bx

    ; Calculate X * Z^3
    mov  al, x      ; al := 5
    cbw             ; al => ax := 5
    imul bx         ; imul 16bit: ax * 16bit (bx) => ax (25)
    mov  bx, ax     ; BX = X * Z^3 (2)

    ; Calculate (X * Z^3) * Y
    mov  al, y      ; AL = Y (3)
    cbw             ; AX = Y (3)
    imul bx         ; AX = (X * Z^3) * Y (3 * 2 = 6)

    ; Calculate -(X * Z^3 * Y)
    neg  ax         ; Convert value inside ax into opposite value

    ; Calculate -(X * Z^3 * Y) + 2
    add  ax, 2      ; AX = -6 + 2 = -4. AX now holds A.
    mov  di, ax     ; Store A in DX temporarily

    ; ====================================
    ; --- Calculate B = 2X^2 + Y^2 - 1 ---
    ; ====================================

    ; Calculate X^2
    mov  al, x      ; AL = X (2)
    imul al         ; AX = X * X = X^2 (2 * 2 = 4)
    mov  bx, ax     ; BX = X^2 (4)

    ; Calculate 2 * X^2
    mov  ax, 2      ; AL = 2
    imul bx         ; AX = 2 * X^2 (2 * 4 = 8)
    mov  bx, ax     ; BX = 2X^2 (8)

    ; Calculate Y^2
    mov  al, y      ; AL = Y (3)
    imul al         ; AX = Y * Y = Y^2 (3 * 3 = 9)

    ; Calculate 2X^2 + Y^2
    add  bx, ax     ; BX = 2X^2 + Y^2 (8 + 9 = 17)

    ; Calculate 2X^2 + Y^2 - 1
    dec  bx         ; BX = 17 - 1 = 16. BX now holds B.
    mov  si, bx     ; Store B in SI temporarily

    ; ===============================
    ; --- Perform A (di) / B (si) ---
    ; ===============================
    
    cmp di, 0
    je exit_process ; Compare if A is not a 0, if it is then jump to exit
    cmp si, 0
    je exit_process ; Compare if B is not a 0, if it is then jump to exit

    xchg ax, di      ; Swap values, also could just use mov, but it was required in the exercise to use xchg
    cwd                 ; Extend AX into DX:AX, needed in case if DX is not empty or for signed negative numbers
    idiv si          ; Divides stored number inside DX:AX by SI into AX (whole) and DX (remainder)

    mov  whole, ax  ; Store quotient (0) in 'whole'
    mov  rem, dx    ; Store remainder (-4) in 'rem'

    movsx eax, whole
    call print_int32


; Exit the process
exit_process:
    push 0
    call ExitProcess



;Print 32-bit unsigned value in EAX to Console 
print_uint32:
    mov edi, offset buffer  ; EDI is 32-bit pointer
    call uint32_to_str      ; convert EAX -> string at EDI
    invoke StdOut, edi      ; print string
    ret

;Convert 32-bit unsigned value in EAX to ASCII string (EDI) 
uint32_to_str:
    push edx
    push eax
    push ecx
    push bx
    push edi
    xor bx, bx                 ; Digit count
    mov ecx, 10                ; Divisor
uint32_digloop:
    xor edx, edx               ; Division will use 64-bit dividend in EDX:EAX
    div ecx                    ; Divide EDX:EAX by 10 ; EAX=Quotient ; EDX=Remainder(the current digit)
    add dl, '0'                ; Convert digit to ASCII
    push dx                    ; Push on stack so digits can be popped off in reverse order when finished
    inc bx                     ; Digit count += 1
    test eax, eax
    jnz uint32_digloop         ; If dividend is zero then we are finished converting the number
uint32_popdigloop:             ; Get digits from stack in reverse order we pushed them
    pop ax
    stosb                      ; Same as mov [ES:EDI], al and inc EDI
    dec bx
    jne uint32_popdigloop      ; Loop until all digits have been popped
    mov al, 0
    stosb                      ; NUL terminate string ; Same as mov [ES:EDI], al and inc EDI
    pop edi
    pop bx
    pop ecx
    pop eax
    pop edx
    ret

;Print 32-bit signed value in EAX to Console 
print_int32:
    mov edi, offset buffer  ; EDI is 32-bit pointer
    call int32_to_str       ; convert EAX -> string at EDI
    invoke StdOut, edi      ; print string
    ret

; Convert 32-bit signed value in EAX to ASCII string (EDI)
int32_to_str:
    push edx
    push eax
    push ecx
    push ebx
    push edi
    mov ebx, 0                 ; Digit count
    mov ecx, 10                ; Divisor
    xor edx, edx
    test eax, eax              ; Check sign
    jge int32_digloop          ; If EAX >= 0, skip
    mov byte ptr [edi], '-'    ; Store '-' at start
    inc edi
    neg eax                    ; Make positive
int32_digloop:
    xor edx, edx               ; Clear remainder high bits
    div ecx                    ; Unsigned divide EAX by 10 (works now since positive)
    add dl, '0'                ; Convert remainder to ASCII
    push dx                    ; Save digit on stack
    inc ebx                    ; Digit count++
    test eax, eax
    jnz int32_digloop
int32_popdigloop:
    pop ax
    stosb                      ; Write digit to buffer
    dec ebx
    jne int32_popdigloop
    mov al, 0
    stosb                      ; NUL terminate
    pop edi
    pop ebx
    pop ecx
    pop eax
    pop edx
    ret

start endp
    end start