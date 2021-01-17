; This file contains variables on the zero page.
; They are given more general names to be reusable for different purposes.
; They are subdivided into two categories:
;   * Variables that can be used by the main program (i.e. main loop)
;   * Variables that can be used by the interrupt service routine (ISR)
; This is, because the ISR can be called at any time, and would disturb the main program's
; variables if they were using the same ones.

; my zero page words (main program)
mzpwa:   .word 0
; my zero page words (main program)
mzpwd:   .word 0
; (need four main program ZP bytes in a row for mouse operation)
; my zero page words (main program)
mzpwe:   .word 0   ; this is used mainly as a pointer for string operations
; my zero page words (ISR)
mzpwb:   .word 0
; my zero page words (ISR)
mzpwc:   .word 0
; my zero page words (ISR)
mzpwf:   .word 0

; my zero page bytes (main program)
mzpba:   .byte 0
; my zero page bytes (ISR)
mzpbb:   .byte 0
; my zero page bytes (ISR)
mzpbc:   .byte 0
; my zero page bytes (ISR)
mzpbd:   .byte 0
; my zero page bytes (ISR)
mzpbe:   .byte 0
; my zero page bytes (ISR)
mzpbf:   .byte 0
; my zero page bytes (ISR)
mzpbg:   .byte 0
; my zero page bytes (main program)
mzpbh:   .byte 0

; player data pointer
pld_ptr: .word 0