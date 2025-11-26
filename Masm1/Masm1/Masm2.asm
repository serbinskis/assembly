; ===============================
; --------- 12. variants --------
; ===============================

.386
.model flat, stdcall
option casemap:none

include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

.stack   4096

.const
    x        byte   -11    ; Signed byte
    y        byte   -12    ; Signed byte
    z        byte   -50    ; Signed byte

.data
    whole    dw    ?      ; Signed word for the quotient
    rem      dw    ?      ; Signed word for the remainder

.code
start2 proc
    ; ===============================
    ; --- Calculate A = XY^2 + Z^2 --
    ; ===============================

    ; Calculate Y^2
    mov  al, y      ; al = y
    imul al         ; imul 8bit: al * 8bit (al) => ax | ax = y * y = y^2

    ; Calculate X * Y^2
    movsx bx, x     ; bx = x
    imul bx, ax     ; bx = bx * ax = x * y^2

    ; Calculate Z^2
    mov  al, z      ; al = z
    imul al         ; ax = z * z = z^2

    ; Calculate A = XY^2 + Z^2
    add  ax, bx     ; ax = Z^2 + XY^2
    mov  di, ax     ; Store the final value of A in di

    cmp  di, 0        ; Compare A with 0
    jg a_is_positive  ; If A > 0, jump to calculate B
    jl a_is_negative  ; If A < 0, jump to calculate C
    jmp exit_program  ; If A == 0, exit the program

a_is_positive:
    ; ==================================
    ; --- Calculate B = -3XY - 2Z - 1 --
    ; ==================================

    ; Calculate -3 * X * Y
    mov al, -3      ; al = -3
    imul x          ; ax = -3 * X
    movsx bx, y        ; bx = Y
    imul bx, ax     ; bx = bx * ax = -3*X*Y

    ; Calculate -2 * Z
    mov  al, -2     ; al = -2
    imul z          ; ax = -2 * al = -2*Z
    add bx, ax      ; bx = -3XY + (-2Z)

    ; Calculate B = -3XY - 2Z - 1
    dec bx          ; si = -3XY - 2Z - 1

    ; Check if B is zero before division
    mov si, bx      ; Store the final value of B in si 
    cmp si, 0       ; Compare B with 0
    je exit_program ; If B == 0, exit the program
    jmp divide_and_print

a_is_negative:
    ; =============================
    ; --- Calculate C = XZ - Y^3 --
    ; =============================

    ; Calculate X * Z
    mov  al, x      ; al = x
    imul z          ; ax = x * z
    mov bx, ax      ; bx = ax

    ; Calculate Y^3
    mov  al, y      ; al = y
    imul al         ; ax = y^2
    movsx cx, y     ; idk, I was told to put this here, it allows to work with bigger numbers (now I understand)
    ;imul y         ; removed, because (imul 8bit = al (not ax) * y => ax)
    imul cx            ; ax = y^3 (but imul 16bit = ax * cx => ax)

    ; Calculate C = XZ - Y^3
    sub  bx, ax     ; bx = XZ - Y^3

    ; Check if C is zero before division
    mov si, bx      ; Store the final value of C in si 
    cmp si, 0       ; Compare C with 0
    je exit_program ; If C == 0, exit the program
    jmp divide_and_print

divide_and_print:
    ; Perform division A / B
    mov  ax, di     ; Move A (from di) into ax for division
    cwd             ; Sign-extend ax into dx:ax
    idiv si         ; Divide dx:ax by B (in si). Quotient in ax, Remainder in dx.

    ; As it was asked to store results in eax and edx
    movsx eax, ax  ; Store whole number in eax
    movsx edx, dx  ; Store remainder in edx

    ; Store results (not asked, just for myself)
    mov  whole, ax  ; Store quotient
    mov  rem, dx    ; Store remainder

    ; Print the integer result (quotient) to the console
    movsx eax, whole ; Sign-extend 16-bit result to 32-bit for printing (ik it is duplicated and idc)
    push eax
    call print_int32
    jmp exit_program

exit_program:
    invoke ExitProcess, 0

; --- Utility Functions for Random Stuff ---

; Prints a 32-bit signed value passed on the stack to the console.
print_int32:
    push ebp
    mov ebp, esp                  ; Prologue: Set up our stack frame
    pushad                        ; Push all general purpose registers
    mov eax, [ebp+8]              ; Get the number to print (which is our parameter)
    push 1024                     ; Push buffer size as paramater (yeah I could put 12, but idc), 12 = sign (1) + digits (10) + null (1)
    call allocate_memory          ; Allocate buffer, pointer in EDI
    push edi                      ; Arg 2 for int32_to_str: pointer to the buffer
    push eax                      ; Arg 1 for int32_to_str: the value to convert
    call int32_to_str              ; Convert 32-bit signed value
    invoke StdOut, edi            ; Print signed value in console
    push edi                      ; Pass parameter: pointer to the buffer to free
    call deallocate_memory        ; Free the buffer.
    popad                         ; Restore all registers 
    leave                         ; This undoes the prologue (mov esp, ebp; pop ebp)
    ret 4                         ; Return AND clean up the 4-byte parameter passed to us.

; Converts a 32-bit signed value to a null-terminated ASCII string.
; Accepts: 32-bit value and a pointer to a destination buffer (on the stack).
int32_to_str:
    push ebp
    mov ebp, esp            ; Prologue: Set up our stack frame
    pushad                  ; Push all general purpose registers
    mov eax, [ebp+8]        ; Get the value to convert.
    mov edi, [ebp+12]       ; Get the pointer to the buffer.
    mov ebx, 10             ; Divisor
    test eax, eax           ; Check if number is negative
    jns positive_num        ; If not, jump to conversion
    neg eax                 ; Make it positive
    mov byte ptr [edi], '-' ; Add negative sign if negative
    inc edi                 ; Increase pointer to buffer
positive_num:
    xor ecx, ecx            ; ECX will count the digits, using xor because it is faster than mov ecx, 0
push_digits:
    xor edx, edx            ; Set EDX to 0, for correct division (positives only)
    div ebx                 ; Divide EDX:EAX by 10. EAX = quotient, EDX = remainder
    push edx                ; Push remainder onto the stack, so it can be popped off in everse order when finished
    inc ecx                 ; Increment digit count
    test eax, eax
    jnz push_digits         ; Loop if quotient is not zero
pop_digits:
    pop eax                 ; Pop digit
    add al, '0'             ; Convert to ASCII
    mov [edi], al           ; Move to buffer
    inc edi
    loop pop_digits         ; Loop ecx amount of times
    mov byte ptr [edi], 0   ; Null-terminate the string
    popad                   ; Restore all registers
    leave                   ; This undoes the prologue (mov esp, ebp; pop ebp)
    ret 8                   ; Return AND clean up the 8-byte parameter passed to us.

; Allocates a block of memory from the heap.
; Accepts: Size in bytes (on the stack).
; Returns: Pointer to the allocated memory (in EDI).
allocate_memory:
    push ebp
    mov ebp, esp                  ; Prologue: Set up our stack frame
    sub esp, 4                    ; Reserve 4 bytes for a local variable at [ebp-4].
    pushad                        ; Push all general purpose registers
    mov ecx, [ebp+8]              ; Get the 'size' passed by the caller.
    invoke GetProcessHeap         ; The heap handle is now in EAX.
    mov ebx, eax                  ; Save the handle in EBX for safekeeping.
    invoke HeapAlloc, ebx, 8, ecx ; Allocate 'ecx' bytes. The new pointer is in EAX.
    mov [ebp-4], eax              ; Store the result from EAX into our safe local variable.
    popad                         ; This will restore the original EAX, but our result is safe.
    mov edi, [ebp-4]              ; Get the saved pointer and put it into EDI.
    leave                         ; Automatically does: mov esp, ebp; pop ebp
    ret 4                         ; Return to caller and clean up the 4-byte 'size' parameter.

; Frees a previously allocated block of memory.
; Accepts: Pointer to the memory to free (on the stack).
deallocate_memory:
    push ebp
    mov ebp, esp                  ; Prologue: Set up our stack frame
    pushad                        ; Push all general purpose registers
    mov ebx, [ebp+8]              ; Get the pointer we need to free into EBX.
    invoke GetProcessHeap         ; EAX now holds the heap handle
    invoke HeapFree, eax, 0, ebx  ; Free the memory block pointed to by EBX.
    popad                         ; Restore all registers 
    leave                         ; This undoes the prologue (mov esp, ebp; pop ebp)
    ret 4                         ; Return and clean up the 4-byte pointer parameter.

start2 endp
    end start2