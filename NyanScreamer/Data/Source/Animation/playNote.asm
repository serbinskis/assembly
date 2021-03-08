lastIntroNote equ 0+26*2
lastNote      equ 0

soundIndex dw 0
soundWait  db 0

playNote:
	mov si, [soundIndex]
	cmp si, lastNote
	jb .nextNote

	; Go back to the beginning
	mov si, lastIntroNote

	.nextNote:
	dec byte [soundWait]
	cmp byte [soundWait], -1
	jne .end

	lodsw
	mov cx, ax
	and ah, 00011111b

	shr ch, 5
	mov [soundWait], ch
	mov [soundIndex], si
	.end: ret
