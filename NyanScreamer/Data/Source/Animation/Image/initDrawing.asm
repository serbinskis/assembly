initDrawing:
	; Set the extra segment to video memory
	push es
	push 0xb800
	pop es
	mov di, 0
	
	mov ax, 0x00DC
	mov cx, nyanTimeVideoStart/2
	rep stosw
	
	mov al, 0xDC
	mov cx, frameSize - nyanTimeVideoStart/2
	rep stosw
	
	pop es
	ret
