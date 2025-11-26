; ===============================================================
; ----------------------- 7. variants ---------------------------
; ===============================================================
; Exercise: Trim spaces at the end of string

.386
.model flat, stdcall
option casemap:none

include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

.stack   4096

.data
    input     db  'A string to trim      ', 0
    input_len equ $ - input - 1
    output    db  input_len DUP(0)

.code

start4 proc
    push es
    push ds
    pop es

     ; === Find last non-space ===
    std
    mov ecx, input_len
    mov al,  ' '             ; Space character
    lea edi, input + input_len - 1
    repe scasb               ; Search for non-space from the end
    inc edi                  ; EDI points to the non-space character (we can also do add edi, 2 and remove inc ecx)
    mov edx, edi             ; Save end pointer

    ; === Copy from start to end ===
    cld                      ; forward direction
    lea esi, input
    lea edi, output
    mov ecx, edx
    sub ecx, esi             ; Number of bytes to copy
    inc ecx                  ; Include that last non-space
    rep movsb                ; Copy that many bytes
    mov byte ptr [edi], 0    ; null-terminate

exit_program:
    pop es
    invoke ExitProcess, 0

start4 endp
    end start4