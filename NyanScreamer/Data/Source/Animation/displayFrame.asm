frameIndex dw 0
frameSize: equ (80*50) / 2 ; Raw binary size of a frame
lastFrame: equ afterFrame


displayFrame:
	; Set the extra segment to video memory
	push es
	push 0xb800
	pop es

	mov di, 0

	mov si, [frameIndex]

	cmp word [soundIndex], lastIntroNote
	ja .normalFrame

	; Reset the frame index
	mov si, frames
	jmp .normalFrame

	; Normal Animation Frame
	.normalFrame:
		call drawNormalFrame

	; Reset frame index when the last frame has been reached
	cmp word [frameIndex], lastFrame
	jb .end
	mov word [frameIndex], frames

	.end:
	    pop es
	    ret

%include "Animation/Image/initDrawing.asm"
%include "Animation/Image/drawNormalFrame.asm"
