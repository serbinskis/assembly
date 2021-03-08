cli ; Disable Interrupts

; Setup the timer interrupt handler
setupInterrupt 0, timerHandler

sti ; Enable Interrupts again