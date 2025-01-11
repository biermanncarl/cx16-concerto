; Copyright 2025 Carl Georg Biermann

; This file contains multiplication routines used in the synthesizer engine.
; (Actually not (yet), they still live in synth_macros.asm)
; It uses the relatively recent Vera FX.


; The routines in this file make the following assumptions:
; * The Vera FX registers will be used ONLY for multiplication
; 

.scope multiplication

; Configure Vera FX for multiplication.
; This is a one-time setup, assuming that Vera FX won't be used otherwise.
.proc setup
    lda #(2 << 1)
    sta VERA_ctrl        ; bring up VERA FX config, as well as select DATA0  (DCSEL=2)
    stz VERA_FX_CTRL     ; (mainly to reset Addr1 Mode to 0)
    lda #%00010000
    sta VERA_FX_MULT     ; enable multiplication
    rts
.endproc


.endscope


