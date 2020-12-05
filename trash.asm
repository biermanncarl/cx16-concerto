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










; initial startup message
; string constants
message:
   .byte $0D, "controls", $0D
   .byte "--------", $0D, $0D
   .byte "a,w,s,...   play notes", $0D
   .byte "z,x         toggle octaves", $0D
   .byte "q           quit", $0D
end_message:

   ; print message
   lda #<message
   sta mzpwa
   lda #>message
   sta mzpwa+1
   ldy #0
@loop_msg:
   cpy #(end_message-message)
   beq @done_msg
   lda (mzpwa),y
   jsr CHROUT
   iny
   bra @loop_msg
@done_msg:








; Voicing system debug GUI
; message strings
msg_freevoicelist:
   STR_FORMAT "freevoicelist"
msg_nfv:
   STR_FORMAT "number of free voices"
msg_ffv:
   STR_FORMAT "first free voice"
msg_lfv:
   STR_FORMAT "last free voice"

msg_usedvoicelist:
   STR_FORMAT "usedvoicelist"
msg_uvl_up:
   STR_FORMAT "up"
msg_uvl_dn:
   STR_FORMAT "dn"
msg_uvl_oldest:
   STR_FORMAT "oldest"
msg_uvl_youngest:
   STR_FORMAT "youngest"

   ; displaying for debugging
   ; freevoicelist
   DISPLAY_LABEL msg_freevoicelist, 2, 10
   DISPLAY_LABEL msg_nfv, 2, 12
   DISPLAY_BYTE voices::Voicemap::nfv, 2,13
   DISPLAY_LABEL msg_ffv, 27, 12
   DISPLAY_BYTE voices::Voicemap::ffv, 27, 13
   DISPLAY_LABEL msg_lfv, 52, 12
   DISPLAY_BYTE voices::Voicemap::lfv, 52, 13

   DISPLAY_BYTE voices::Voicemap::freevoicelist+00,  2, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+01,  6, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+02, 10, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+03, 14, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+04, 18, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+05, 22, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+06, 26, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+07, 30, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+08, 34, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+09, 38, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+10, 42, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+11, 46, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+12, 50, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+13, 54, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+14, 58, 15
   DISPLAY_BYTE voices::Voicemap::freevoicelist+15, 62, 15

   DISPLAY_LABEL msg_usedvoicelist, 2, 18
   DISPLAY_LABEL msg_uvl_oldest, 2, 20
   DISPLAY_BYTE voices::Voicemap::uvf, 2,21
   DISPLAY_LABEL msg_uvl_youngest, 27, 20
   DISPLAY_BYTE voices::Voicemap::uvl, 27,21
   DISPLAY_LABEL msg_uvl_up, 2, 23
   DISPLAY_LABEL msg_uvl_dn, 2, 25

   DISPLAY_BYTE voices::Voicemap::usedvoicesup+00,  6, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+01, 10, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+02, 14, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+03, 18, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+04, 22, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+05, 26, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+06, 30, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+07, 34, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+08, 38, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+09, 42, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+10, 46, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+11, 50, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+12, 54, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+13, 58, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+14, 62, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+15, 66, 23

   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+00,  6, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+01, 10, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+02, 14, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+03, 18, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+04, 22, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+05, 26, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+06, 30, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+07, 34, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+08, 38, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+09, 42, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+10, 46, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+11, 50, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+12, 54, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+13, 58, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+14, 62, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+15, 66, 25




   ; draw something
   lda cx
   sta guiutils::cur_x
   lda cy
   sta guiutils::cur_y
   jsr guiutils::set_cursor
   lda #65
   sta VERA_data0



; just parking this here



   lda my_switch  ; load the variable which tells us what to do
   asl            ; multiply with 2, so we can index 16 bit addresses
   tax            ; put it into indexing register
   jmp (jmp_table, x)
jmp_table:
   .word subroutine_1
   .word subroutine_2
   .word subroutine_3
return_here:
   ; continue your program
   ; ...

subroutine_1:
   ; do something 1
   jmp return_here

subroutine_2:
   ; do something 2
   jmp return_here

subroutine_3:
   ; do something 3
   jmp return_here