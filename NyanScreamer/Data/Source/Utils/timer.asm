defaultClock equ 11932 ; ~100 Hz
currentClock dw defaultClock

; Updates the current timer value
setTimer:
	mov ax, [currentClock]
	out 0x40, al
	mov al, ah
	out 0x40, al
	
	ret
	
maxClock equ defaultClock/6
minClock equ defaultClock*3

; Speed increase is calculated using the following formula:
; currentClock = currentClock * clockPreMul / clockDiv
clockPreMul  equ 2
clockDiv     equ 3
