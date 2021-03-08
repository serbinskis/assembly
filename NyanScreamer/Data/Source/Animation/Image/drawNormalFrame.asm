drawNormalFrame:
	push es
	push 0xb800
	pop es
	
	; Display the frame
	.displayFrame:
		mov di, 1 ; Offset one byte
		
		mov cx, frameSize
		.draw:
			lodsb
			stosb
			inc di
		loop .draw
		
		mov [frameIndex], si
		
	.end:
	    pop es
	    ret
