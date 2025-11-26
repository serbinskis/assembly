; ===============================================================
; ----------------------- 2. variants ---------------------------
; ===============================================================
; Exercise: Find biggest number in the array

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
    VECTOR   word   2, 7, -1, 16, 15
    VECTOR_SIZE EQU LENGTHOF VECTOR


.data
    whole    dw    ?      ; Signed word for the quotient
    rem      dw    ?      ; Signed word for the remainder

.code
start3 proc
    call index_adressing
    call base_adressing
    call index_scaling
    call base_indexing
    ;jmp exit_program

index_adressing:
    xor ebx, ebx              ; Clear ebx, aka ebx = 0
    mov ecx, VECTOR_SIZE      ; Use ecx for loop, ecx = length(VECTOR)
    mov ax, VECTOR[ebx]       ; Use first element as maximum [AX = 2]
loop_index_adressing:
                              ; This solution was without using cmp, appreantly I didn't need to complicate it
    ;mov dx, VECTOR[ebx]      ; Get the current array element and store it in DX [DX = 7]
    ;sub dx, ax               ; Subtract the current maximum AX from the current element DX [7 - 2 = 5]
    ;test dx, dx              ; Test if number is positive, if so we found bigger number
    ;js skip_index_adressing  ; JS (Jump if Sign) will jump if SF = 1 => DX < 0
    cmp ax, VECTOR[ebx]       ; Compare if AX is bigger than VECTOR[ebx]
    jge skip_index_adressing  ; JGE (Jump if Greater or Equal): If AX >= VECTOR[ebx], then we skip
    mov ax, VECTOR[ebx]       ; Update maximum number if we found bigger one
skip_index_adressing:
    add ebx, 2                ; Increase ebx by 2, because we are working with word
    loop loop_index_adressing ; Loop by default uses ecx as the counter
    ret


base_adressing:
    mov ecx, VECTOR_SIZE      ; Use ecx for loop, ecx = length(VECTOR)
    lea ebx, VECTOR
    mov ax, [ebx]             ; Use first element as maximum [AX = 2]
loop_base_adressing:
    cmp ax, [ebx]             ; Compare if AX is bigger than [ebx]
    jge skip_base_adressing   ; JGE (Jump if Greater or Equal): If AX >= [ebx], then we skip
    mov ax, [ebx]             ; Update maximum number if we found bigger one
skip_base_adressing:
    add ebx, 2                ; Increase ebx by 2, because we are working with word
    loop loop_base_adressing  ; Loop by default uses ecx as the counter
    ret


index_scaling:
    mov ecx, VECTOR_SIZE      ; Use ecx for loop, ecx = length(VECTOR)
    xor edx, edx
    mov ax, VECTOR[edx*2]     ; Use first element as maximum [AX = 2]
loop_index_scaling:
    cmp ax, VECTOR[edx*2]     ; Compare if AX is bigger than VECTOR[edx*2]
    jge skip_index_scaling    ; JGE (Jump if Greater or Equal): If AX >= VECTOR[edx*2], then we skip
    mov ax, VECTOR[edx*2]     ; Update maximum number if we found bigger one
skip_index_scaling:
    inc edx                   ; Increase edx by 1, because we are working with word
    loop loop_index_scaling   ; Loop by default uses ecx as the counter
    ret


base_indexing:
    mov ecx, VECTOR_SIZE         ; Use ecx for loop, ecx = length(VECTOR)
    xor ebx, ebx
    xor esi, esi
    mov ax, VECTOR[ebx][esi]     ; Use first element as maximum [AX = 2]
loop_base_indexing:
    cmp ax, VECTOR[ebx][esi]     ; Compare if AX is bigger than VECTOR[ebx][esi]
    jge skip_base_indexing       ; JGE (Jump if Greater or Equal): If AX >= VECTOR[ebx][esi], then we skip
    mov ax, VECTOR[ebx][esi]     ; Update maximum number if we found bigger one
skip_base_indexing:
    inc ebx
    inc esi
    loop loop_base_indexing      ; Loop by default uses ecx as the counter
    ret

exit_program:
    invoke ExitProcess, 0

start3 endp
    end start3