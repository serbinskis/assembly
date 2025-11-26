; ===============================================================
; ----------------------- 6. variants ---------------------------
; ===============================================================
; Exercise: All negative elements avarage in all columns, with procedures

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
    Vector   word N dup (0)

.code


MatrixProcess proc
    enter 0, 0
    pushad                  ; Yes I Know, And I Dont Care, I dont want to list all register manually
    mov  edi, [ebp+20]      ; EDI = Vector Address
    mov  ebx, [ebp+16]      ; EBX = Matrix Address
    mov  ecx, [ebp+12]      ; ECX = N (Outer Loop: Columns)
MatrixProcessMain:
MatrixProcessRows:   
    push ecx
    mov  ecx, [ebp+8]            ; ECX = M (Inner Loop: Rows)
    mov  esi, ebx
    xor  eax, eax
    xor  edx, edx
MatrixProcessCols:
    cmp  word ptr [esi], 0       ; Check if element is negative
    jge  MatrixProcessFalse      ; If not skip the element
    inc  dx                      ; Count the amount of negative elements
    add  ax, [esi]               ; Count the value of negative elements
MatrixProcessFalse:
    push eax                     ; Save Sum (EAX)
    imul eax, [ebp+12], S        ; EAX = Cols * 2
    add  esi, eax                ; add esi, S*N
    pop  eax                     ; Restore Sum        
    loop MatrixProcessCols
    cmp dx, 0
    je MatrixProcessZeroSkip
    push ebx                  ; Temporary store ebx
    mov  bx, dx               ; Move amount to bx for division
    cwd                       ; Sign-extend ax into dx:ax
    idiv bx                   ; Divide dx:ax by amount. Quotient in ax, Remainder in dx.
    mov  [edi], ax            ; Store avarage value of negative elemnts into vector
    pop  ebx                  ; Restore ebx back
MatrixProcessZeroSkip:
    add  ebx, S
    add  edi, S
    pop  ecx
    loop MatrixProcessRows
MatrixProcessEnd:
    popad                   ; We Do Not Care
    leave                   ; mov esp, ebp / pop ebp
    ret 16                  ; Return and clean 16 bytes (4 params * 4 bytes)
MatrixProcess endp



VectorPrintSim proc
    enter 0, 0
    pushad                  ; Yes I Know, And I Dont Care, I dont want to list all register manually
    mov  esi, [ebp+12]      ; [ebp+12] = Count
    mov  ecx, [ebp+8]       ; [ebp+8]  = Address
VectorPrintSimMain:
    xor  eax, eax
    mov  ax, [esi]          ; "Simulate" print: Load value to AX
                            ; Idk, We can DO actial printing, but we wont
    add  esi, S             ; Next element
    loop VectorPrintSimMain
VectorPrintSimEnd:
    popad                   ; We Do Not Care
    leave                   ; mov esp, ebp / pop ebp
    ret 8                   ; Return and clean 8 bytes (2 params * 4 bytes)
VectorPrintSim endp



start6 proc
    push offset Vector      ; [ebp+20] -> Param 4: Vector Address
    push offset Matrix      ; [ebp+16] -> Param 3: Matrix Address
    push N                  ; [ebp+12] -> Param 2: Columns (N)
    push M                  ; [ebp+8]  -> Param 1: Rows (M)
    call MatrixProcess

    push offset Vector      ; [ebp+12] -> Param 2: Vector Address
    push N                  ; [ebp+8]  -> Param 1: Element Count
    call VectorPrintSim
    invoke ExitProcess, 0

start6 endp
    end start6