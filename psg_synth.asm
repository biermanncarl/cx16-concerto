.include "x16.asm"

.zeropage
.include "zeropage.asm"

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

; data
.include "pitch_data.asm"
; variables/macros
.include "global_definitions.asm"
.include "synth_macros.asm"
; sub modules
.include "timbres.asm"
.include "voices.asm"
.include "synth_engine.asm"
.include "my_isr.asm"
.include "gui.asm"
.include "presets.asm"



start:
   ; startup code

   ; clear screen
   lda #$93
   jsr CHROUT

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

   ; initialize patch 0
   ;PRESET_SNARE_DRUM_3 0
   ;PRESET_ONE_OSC_PATCH 0
   PRESET_ONE_OSC_PATCH 0


   ; do other initializations
   jsr voices::init_voicelist
   jsr my_isr::launch_isr
   ; main loop ... wait until "Q" is pressed.
mainloop:


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


   jsr voices::do_stack_releases
.include "keyboard_polling.asm"

play_note:
   ; determine MIDI note
   sta Note
   lda Octave
   clc
   adc Note

   ; play note
   sta voices::note_pitch
   lda #127
   sta voices::note_velocity
   stz voices::note_timbre
   jsr voices::play_note

end_mainloop:

   jmp mainloop


exit:
   jsr my_isr::shutdown_isr

   rts            ; return to BASIC
   ; NOTE
   ; The program gets corrupted in memory after returning to BASIC
   ; If running again, reLOAD the program!

