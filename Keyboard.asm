org 0x7c00
bits 16

start:
    mov ah, 07h                ;Function to call with interrupt
    mov al, 0x00               ;Scroll whole window
    mov bh, 0x0F               ;Black background with white text
    mov cx, 0x0000             ;Row 0, Col 0
    mov dx, 0x184f
    int 10h                    ;Clear screen just in case

    mov dh, 0                  ;Cursor position row
    mov dl, 0                  ;Cursor position column
    mov bh, 0                  ;Display page number
    mov ah, 02h                ;Set cursor position
    int 10h                    ;Set cursor postion to begining of screen

get_keystrokes:
    xor al, al                 ;Clear buffer
    mov ah, 0h                 ;Wait until key press
    int 16h

    cmp al, 0                  ;Check for nothing
    je get_keystrokes

    cmp al, 8                  ;Check for Backsapce
    je backspace
    
    cmp al, 13                 ;Check for Enter
    je next_row

    call get_cur_pos           ;Get cursor position

    cmp dh, 24                 ;Check if not finall row
    je .finall_row             ;If it is then jump to .finall_row
    jmp .teletype_character

.finall_row:
    cmp dl, 79                 ;Check if not end of col
    je get_keystrokes          ;If it is then jump to get_keystrokes

.teletype_character:
    mov ah, 0Eh                ;Teletype output
    int 10h                    ;Teletype user inputed character
    jmp get_keystrokes

backspace:
    call get_cur_pos           ;Get cursor position

    cmp dl, 0                  ;Check if cursor is at begining of the row
    je back_row                ;If it is then jump to back_row

    dec dl                     ;dl - Register where is saved position of cursor x
    mov ah, 02h                ;Set cursor position
    int 10h                    ;Jump one col before

    mov al, 32                 ;Space scancode
    mov ah, 0Eh                ;Teletype output
    int 10h                    ;Rewrite character with space

    mov ah, 02h                ;Set cursor position
    int 10h                    ;Set cursor back because previsos interrupt moved it forward

    jmp get_keystrokes

next_row:
    call get_cur_pos           ;Get cursor position
    cmp dh, 24                 ;Check if not at end of screen
    je get_keystrokes          ;If it is then jump to get_keystrokes

    inc dh                     ;dh - Register where is saved position of cursor y
    mov dl, 0                  ;dl - Register where is saved position of cursor x
    mov ah, 02h                ;Set cursor position
    int 10h                    ;Set cursor to next row

    jmp get_keystrokes

back_row:
    call get_cur_pos           ;Get cursor position
    cmp dh, 0                  ;dh - Register where is saved position of cursor y
    je get_keystrokes          ;Check if current row isn't first

    dec dh                     ;dh - Register where is saved position of cursor y
    mov dl, 80                 ;dl - Register where is saved position of cursor x
    mov ah, 02h                ;Set cursor position
    int 10h                    ;Set cursor position one row back

carriage_return:
    dec dl                     ;dl - Register where is saved position of cursor x
    mov ah, 02h                ;Set cursor position
    int 10h                    ;Jump one col before

    mov ah, 08h                ;Get character at cursor position
    int 10h                    ;Call interrupt

    cmp al, 32                 ;Check if chacrter is space and do it until it's not
    je .checkCol               ;Or until it's not start of line
    jmp .notSpace

.checkCol:
    cmp dl, 0                  ;Check if col is 0 because it is start of line
    je get_keystrokes          ;If it is then jump to get_keystrokes
    jmp carriage_return        ;Else continue loop

.notSpace:
    inc dl                     ;dl - Register where is saved position of cursor x
    mov ah, 02h                ;Set cursor position
    int 10h                    ;Set cursor back
    
    cmp dl, 80                 ;We don't want to see cursor outside of the screen
    je backspace
    jmp get_keystrokes

get_cur_pos:
    mov ah, 03h                ;Get cursor position
    int 10h                    ;Call interrupt
    ret

times 510 - ($-$$) db 0        ;Fill rest of the sector with 0.
dw 0xaa55                      ;Boot Signature.