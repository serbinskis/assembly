bits 16
org 0x7c00
;
; EGA register equates.
;
SC_INDEX            equ 0x3c4  ; SC index register
SC_MAP_MASK         equ 2      ; SC map mask register
GC_INDEX            equ 0x3ce  ; GC index register
GC_SET_RESET        equ 0      ; GC set/reset register
GC_ENABLE_SET_RESET equ 1      ; GC enable set/reset register
;
; Macro to set indexed register INDEX of SC chip to SETTING.
;
%macro SETSC   2
    mov dx, SC_INDEX
    mov al, %1
    out dx, al
    inc dx
    mov al, %2
    out dx, al
    dec dx
%endmacro

;
; Macro to set indexed register INDEX of GC chip to SETTING.
;
%macro SETGC   2
    mov dx, GC_INDEX
    mov al, %1
    out dx, al
    inc dx
    mov al, %2
    out dx, al
    dec dx
%endmacro

start:
    xor ax, ax                 ; AX=0
    mov ds, ax                 ; DS=ES=0 because we use an org of 0x7c00
                               ;     Segment<<4+offset = 0x0000<<4+0x7c00 = 0x07c00
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00             ; SS:SP= 0x0000:0x7c00 stack just below bootloader
    cld                        ; Forward direction for string instructions like movsb

Set_Video:
    mov ah, 0x41               ; Int 13h/AH=41h: Check if extensions present
    mov bx, 0x55aa
    int 0x13
    cmp bx, 0xaa55             ; Is BX 0xaa55?
    mov ax, 12h                ; Graphics mode (640x480x16)
    int 10h                    ; BIOS video call

    mov si, DAP                ; Load BMP Sectors
    mov ah, 42h
    int 13h                    ; Read the BMP file


    ; Segment that our BMP (and BMP header) was read into */
    mov ax, 0x07e0
    mov ds, ax

    mov di, [46]               ; Get number of colors from DIB header
    test di, di
    jnz color_set              ; If number of colors is 0
    mov di, 2                  ;     then set to 2 (we assume BMP has color depth 1)

color_set:
    mov si, [14]               ; Get the offset of color table from DIB header
    add si, 14                 ; Add the length of the BMP header to color table offset
                               ; to get actual offset of the color table
    xor bx, bx                 ; Curent color index to process = 0

.paletteloop:
    mov ch, [si+1]             ; Get green value
    shr ch, 1
    shr ch, 1                  ; VGA color values are 6 bit. Shift 8-bit value in
                               ;     color table entry right by 2 to get a 6-bit value
    mov cl, [si]               ; Get blue value
    shr cl, 1
    shr cl, 1                  ; VGA color values are 6 bit. Shift 8-bit value in
                               ;     color table entry right by 2 to get a 6-bit value
    mov dh, [si+2]             ; Get red value
    shr dh, 1
    shr dh, 1                  ; VGA color values are 6 bit. Shift 8-bit value in
                               ;     color table entry right by 2 to get a 6-bit value
    mov ax, 0x1010             ; Set palette entry for current color index
    int 0x10

    inc bx                     ; Go to next color index
    add si, 4                  ; Go to next memory offset where next colorentry starts
    dec di
    jnz .paletteloop           ; Loop until we have processed all color entries

    SETSC SC_MAP_MASK, 0x0f        ; must set map mask to enable all
                                   ; planes, so set/reset values can
                                   ; be written to planes 1, 2 & 3
                                   ; and CPU data can be written to
                                   ; plane 0 (the blue plane)
    SETGC GC_ENABLE_SET_RESET, 0xe ; CPU data to plane 1, 2, & 3 will be
                                   ; replaced by set/reset value
    SETGC GC_SET_RESET, 0x1        ; set/reset value is 0ffh for plane 0
                                   ; (the blue plane) and 0 for other
                                   ; planes

    mov ax, 0xA000
    mov es, ax                     ; 0xA000 = Memory segment for VGA/EGA graphics display

    mov si, [10]                   ; Get offset to pixel data from BMP header
    xor di, di                     ; Destination offset in video segment starts at 0x0000
    mov cx, (640/8*480)/2          ; Total number of words (16-bit values) to copy
    rep movsw                      ; Move CX number of words from DS:DI to ES:SI
    pop ds
    jmp endloop                    ; We are finished go into infinite loop

;Endless loop
endloop:
    cli                            ; Disable interrupts
.repeat:
    hlt                            ; Wait for next interrupt
    jmp .repeat                    ; Continue looping indefinitely

SECTOR_SIZE equ 512

; Disk address packet
DAP:
    db 10h, 0
    dw (BMP_SIZE+(SECTOR_SIZE-1))/SECTOR_SIZE 	 ; Number of sectors BMP uses (rounded up)
    dw 0x0000, 0x07e0         					 ; Read to 0x07e0:0x0000 = Phys Address 0x07e00
    dq 1                      					 ; (Start at second sector)

;Fake MBR signature
times 510 - ($ - $$) db 0
dw 0xAA55

;My bitmap
bitmap: incbin "BSOD.bmp"    ; Flipped image 640x480x1
BMP_SIZE equ $-bitmap        ; Size of BMP in bytes
times 32768 - ($ - $$) db 0