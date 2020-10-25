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
.include "timbres_user.asm"
.include "timbres_preint.asm"
.include "voices.asm"
.include "synth_engine.asm"
.include "my_isr.asm"



start:
   ; startup code
   ; print message
   lda #<message
   sta my_zp_ptr
   lda #>message
   sta my_zp_ptr+1
   ldy #0
@loop_msg:
   cpy #(end_message-message)
   beq @done_msg
   lda (my_zp_ptr),y
   jsr CHROUT
   iny
   bra @loop_msg
@done_msg:



   ; initialize AD env generator
   ; for now, just use the rates directly
   ; instead of deriving them from times
   lda #0
   sta timbres_pre::Timbre::ad1::attack
   lda #16
   sta timbres_pre::Timbre::ad1::attack+1
   lda #128
   sta timbres_pre::Timbre::ad1::decay
   lda #0
   sta timbres_pre::Timbre::ad1::decay+1

   ; setup playback of PSG waveform
   ; VERA_SET_VOICE_PARAMS 0,$0000,$00,64

   jsr my_isr::launch_isr
   ; main loop ... wait until "Q" is pressed.
mainloop:

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
   jsr voices::play_monophonic

end_mainloop:

   jmp mainloop


exit:
   jsr my_isr::shutdown_isr

   rts            ; return to BASIC
   ; NOTE
   ; The program gets corrupted in memory after returning to BASIC
   ; If running again, reLOAD the program!

