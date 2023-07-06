; Copyright 2021-2022 Carl Georg Biermann

; These are variables located at the zero page.
; The abbreviations stand for "my zero page word B" or "my zero page byte D" and so on
; Each variable serves several purposes, depending on the context.

.pushseg
.zeropage

; my zero page words (main program)
mzpwa:   .word 0
mzpwd:   .word 0
mzpwe:   .word 0   ; this is used mainly as a pointer for string operations

; The user interface also uses the "shared" zero page variables from the synth,
; which are safe to use in the main program
mzpbd = concerto_synth::mzpbd
mzpbe = concerto_synth::mzpbe
mzpbf = concerto_synth::mzpbf

.popseg
