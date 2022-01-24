; Copyright 2021 Carl Georg Biermann

; These are variables located at the zero page.
; The abbreviations stand for "my zero page word B" or "my zero page byte D" and so on
; Each variable serves several purposes, depending on the context.

; Three 16-bit variables (mzpwb, mzpwc and mzpwf) are used in multiplication routines.
; Some details about their usage is found in synth_tick.asm near the top

; my zero page words (ISR)
mzpwb:   .word 0
mzpwc:   .word 0
mzpwf:   .word 0
; my zero page words (main program, timbre management (load, save, copy/paste))
mzpwg:   .word 0

; my zero page bytes (ISR)
mzpba:   .byte 0 ; concerto API register
mzpbb:   .byte 0
mzpbc:   .byte 0
mzpbd:   .byte 0
mzpbg:   .byte 0 ; concerto API register

; variables that are backed up before the ISR, and thus are save to use in the main program, too
; This is especially important for subroutines that shall be callable from both ISR and main program
mzpbe:   .byte 0
mzpbf:   .byte 0 ; concerto API register

