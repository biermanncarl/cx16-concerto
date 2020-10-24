.include "x16.asm"
.include "macros.asm"

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
; variables
.include "global_variables.asm"
; subroutines
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

   ; copy address of default interrupt handler
   lda IRQVec
   sta Default_isr
   lda IRQVec+1
   sta Default_isr+1
   ; replace irq handler
   sei            ; block interrupts
   lda #<My_isr
   sta IRQVec
   lda #>My_isr
   sta IRQVec+1
   cli            ; allow interrupts

   ; initialize AD env generator
   ; for now, just use the rates directly
   ; instead of deriving them from times
   lda #0
   sta AD_attack_rate
   lda #63
   sta AD_attack_rate+1
   lda #16
   sta AD_decay_rate
   lda #0
   sta AD_decay_rate+1

   ; setup playback of PSG waveform
   VERA_SET_VOICE_PARAMS 0,$0000,$00,64

   ; setup the timer

   ; prepare playback
   lda #$8F       ; reset PCM buffer, 8 bit mono, max volume
   sta VERA_audio_ctrl

   lda #0         ; set playback rate to zero
   sta VERA_audio_rate

   ; fill FIFO buffer up to 1/4
   lda #4
   tax
   lda #0
   tay
@loop:
   sta VERA_audio_data
   iny
   bne @loop
   dex
   bne @loop

   ; enable AFLOW interrupt
   ; TODO: disable other interrupts for better performance
   ; (and store which ones were activated in a variable to restore them on exit)
   lda VERA_ien
   ora #$08
   sta VERA_ien

   ; start playback
   ; this will trigger AFLOW interrupts to occur
   ; set sample rate in multiples of 381.5 Hz = 25 MHz / (512*128)
   lda #1
   sta VERA_audio_rate




   ; main loop ... wait until "Q" is pressed.
mainloop:
.include "keyboard_polling.asm"

play_note:
   ; determine MIDI note
   sta Note
   lda Octave
   clc
   adc Note
   sta Pitch

   ; launch ENV generator
   stz AD_phase
   stz AD_phase+1
   lda #1
   sta AD_step
end_mainloop:

   jmp mainloop


exit:

   ; stop PSG waveform
   VERA_MUTE_VOICE 0


   ; stop PCM
   lda #0
   sta VERA_audio_rate

   ; restore interrupt handler
   sei            ; block interrupts
   lda #<Default_isr
   sta IRQVec
   lda #>Default_isr
   sta IRQVec+1
   cli            ; allow interrupts

   ; reset FIFO buffer
   lda #$8F
   sta VERA_audio_ctrl

   ; disable AFLOW interrupt
   lda VERA_ien
   and #$F7
   sta VERA_ien

   rts            ; return to BASIC
   ; NOTE
   ; The program gets corrupted in memory after returning to BASIC
   ; If running again, reLOAD the program!

