;my_zp_ptr:
;   .word 0
;my_bit_register:
;   .byte 0

; my zero page words (main program)
mzpwa:   .word 0
; my zero page words (ISR)
mzpwb:   .word 0

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