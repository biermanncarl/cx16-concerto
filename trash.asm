; This file contains code that has been removed from the main project,
; but is kept for reference.




; this snippet is a draft from the SCALE5_16 macro
; it is supposed to rightshift a 16 bit register by N times (N: 0..15)
; the naive approach can be horribly slow if N is large
    ; do rightshifts
    .local @loopH
    .local @skipH
    lda moddepth, y
    and #%00001111
    beq @skipH
    phy
    tay
    lda mzpwb+1 ; 15 cycles
    ; we're here with a nonzero value in y which denotes the number of rightshifts to be done
@loopH:
    clc
    ror
    ror mzpwb   ; unfortunately, we cannot ROR both bytes entirely inside CPU ... or can we (efficiently) ?
    dey
    bne @loopH  ; 14 cycles * number of RSHIFTS

    sta mzpwb+1
    ply         ; plus 6 cycles
@skipH:

    ; naive scheme: 20 cycles + 14 * number of rightshifts





; just parking this here


