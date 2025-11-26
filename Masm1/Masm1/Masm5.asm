; ===============================================================
; ----------------------- 5. variants ---------------------------
; ===============================================================
; Exercise: All negative elements avarage in all columns

.386
.model flat, stdcall
option casemap:none

include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

M        equ  2               ; Amount of rows
N        equ  3               ; Amount of columns

.stack   4096

.data
    Matrix   word 1, 2, -3    ; -> Rindas | Horizontaly
             word 4, -5, 6    ; 
    S        equ  size Matrix ; Size of one element in matrix
    vector   word N dup (0)

.code

start5 proc
    call Variants1
    call Variants2
    jmp exit_program

Variants1:
    xor  ebx, ebx
    mov  ecx, N
    lea  edi, vector
Rows1:   
    push ecx
    mov  ecx, M
    xor  esi, esi
    xor  ax, ax
    xor  dx, dx
Cols1:
    cmp  Matrix[ebx][esi], 0  ; Check if element is negative
    jge   False1              ; If not skip the element
    inc  dx                   ; Count the amount of negative elements
    add  ax, Matrix[ebx][esi] ; Count the value of negative elements
False1:
    add  esi, S*N
    loop Cols1

    cmp dx, 0
    je ZeroSkip1
    push ebx                  ; Temporary store ebx
    mov  bx, dx               ; Move amount to bx for division
    cwd                       ; Sign-extend ax into dx:ax
    idiv bx                   ; Divide dx:ax by amount. Quotient in ax, Remainder in dx.
    mov  [edi], ax            ; Store avarage value of negative elemnts into vector
    pop  ebx                  ; Restore ebx back
ZeroSkip1:
    add  ebx, S
    add  edi, S
    pop  ecx
    loop Rows1   

    xor  ebx, ebx
    mov  ecx, N               ; Loop over vector this amount of times
Print1:
    mov  ax, vector[ebx]
    add  ebx, S
    loop Print1
    ret


Variants2:
    lea  ebx, Matrix
    mov  ecx, N
    xor  edi, edi
Rows2:   
    push ecx
    mov  ecx, M
    xor  esi, esi
    xor  ax, ax
    xor  dx, dx
Cols2:
    cmp  [ebx][esi], word ptr 0 ; Check if element is negative
    jge   False2                ; If not skip the element
    inc  dx                     ; Count the amount of negative elements
    add  ax, [ebx][esi]         ; Count the value of negative elements
False2:
    add  esi, S*N
    loop Cols2

    cmp dx, 0
    je ZeroSkip2
    push ebx                  ; Temporary store ebx
    mov  bx, dx               ; Move amount to bx for division
    cwd                       ; Sign-extend ax into dx:ax
    idiv bx                   ; Divide dx:ax by amount. Quotient in ax, Remainder in dx.
    mov  vector[edi], ax      ; Store avarage value of negative elemnts into vector
    pop  ebx                  ; Restore ebx back
ZeroSkip2:
    add  ebx, S
    add  edi, S
    pop  ecx
    loop Rows2   

    xor  ebx, ebx
    mov  ecx, N               ; Loop over vector this amount of times
Print2:
    mov  ax, vector[ebx]
    add  ebx, S
    loop Print2
    ret

exit_program:
    invoke ExitProcess, 0

start5 endp
    end start5