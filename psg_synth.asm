.include "x16.inc"


.zeropage
   ; DSP variables on ZP for moar shpeeed
my_zp_ptr:
   .word 0
csample:
   .byte 0     ; current sample


.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

Default_isr:
   .word $0000

message:
   .byte $0D, "controls", $0D
   .byte "--------", $0D, $0D
   .byte "a,w,s,...   play notes", $0D
   .byte "z,x         toggle octaves", $0D
   .byte "q           quit", $0D
end_message:

   ; keyboard values
Octave:
   .byte 60
Note:
   .byte 0

   ; AD-Envelope variables
   ; front end
AD_attack:
   .byte 0
AD_decay:
   .byte 0
   ; back-end
AD_attack_rate:
   .word 0
AD_decay_rate:
   .word 0
AD_step:
   .byte 0
AD_phase:
   .word 0


   ; handles the sound generation
My_isr:
   ; first check if interrupt is an AFLOW interrupt
   lda VERA_isr
   and #$08
   bne do_fillup
   jmp end_aflow

do_fillup:
   ; fill FIFO buffer with 4 samples
   ; this will generate the next AFLOW interrupt in ~10 ms
   ; at lowest possible PCM playback rate
   lda #0
   sta VERA_audio_data
   sta VERA_audio_data
   ; lda #4
   sta VERA_audio_data
   sta VERA_audio_data

   ; now do all PSG control
do_psg_control:
   ; do env generator
   ; advance first
   ; then update volume
   lda AD_step
   cmp #1
   beq AD_do_attack
   cmp #2
   beq AD_do_decay
   bra end_aflow
AD_do_attack:
   clc
   lda AD_attack_rate
   adc AD_phase
   sta AD_phase
   lda AD_attack_rate+1
   adc AD_phase+1
   sta AD_phase+1
   tax
   cmp #63
   bcc AD_update_volume ; if 64 is still larger than high byte, just update volume
   inc AD_step
   lda #63
   tax
   sta AD_phase+1
   stz AD_phase
   bra AD_update_volume
AD_do_decay:
   sec
   lda AD_phase
   sbc AD_decay_rate
   sta AD_phase
   lda AD_phase+1
   sbc AD_decay_rate+1
   bcc AD_finished
   sta AD_phase+1
   tax
   bra AD_update_volume
AD_finished:
   lda #0
   tax
   stz AD_step
AD_update_volume:
   lda #0
   sta VERA_ctrl
   lda #$C2
   sta VERA_addr_low
   lda #$F9
   sta VERA_addr_high
   lda #$11
   sta VERA_addr_bank
   txa
   clc
   adc #192    ; activate channels LR
   sta VERA_data0

end_aflow:
   ; call default interrupt handler
   ; for keyboard service
   jmp (Default_isr)




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
   lda #0
   sta AD_decay_rate
   lda #5
   sta AD_decay_rate+1

   ; start playback of PSG waveform
   ; select port 0 to the VERA
   lda #0
   sta $9F25
   ; set address of first PSG register into VRAM address register
   lda #$C0
   sta $9F20
   lda #$F9
   sta $9F21
   lda #$11
   sta $9F22   ; this also sets the auto-increment to 1
   ; load data into VERA
   lda #0
   sta $9F23   ; freq low byte
   lda #0
   sta $9F23   ; freq high byte
   lda #$FF
   sta $9F23   ; both channels, max volume
   lda #$64
   sta $9F23   ; sawtooth waveform

   ; setup the timer

   ; prepare playback
   lda #$8F       ; reset PCM buffer, 8 bit mono, max volume
   sta VERA_audio_ctrl

   lda #0         ; set playback rate to zero
   sta VERA_audio_rate

   ; fill buffer up to 1/4
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
   jsr GETIN      ; get charakter from keyboard
   cmp #65        ; check if pressed "A"
   bne @skip_a
   jmp @keyboard_a
@skip_a:
   cmp #87        ; check if pressed "W"
   bne @skip_w
   jmp @keyboard_w
@skip_w:
   cmp #83        ; check if pressed "S"
   bne @skip_s
   jmp @keyboard_s
@skip_s:
   cmp #69        ; check if pressed "E"
   bne @skip_e
   jmp @keyboard_e
@skip_e:
   cmp #68        ; check if pressed "D"
   bne @skip_d
   jmp @keyboard_d
@skip_d:
   cmp #70        ; check if pressed "F"
   bne @skip_f
   jmp @keyboard_f
@skip_f:
   cmp #84        ; check if pressed "T"
   bne @skip_t
   jmp @keyboard_t
@skip_t:
   cmp #71        ; check if pressed "G"
   bne @skip_g
   jmp @keyboard_g
@skip_g:
   cmp #89        ; check if pressed "Y"
   bne @skip_y
   jmp @keyboard_y
@skip_y:
   cmp #72        ; check if pressed "H"
   bne @skip_h
   jmp @keyboard_h
@skip_h:
   cmp #85        ; check if pressed "U"
   bne @skip_u
   jmp @keyboard_u
@skip_u:
   cmp #74        ; check if pressed "J"
   bne @skip_j
   jmp @keyboard_j
@skip_j:
   cmp #75        ; check if pressed "K"
   bne @skip_k
   jmp @keyboard_k
@skip_k:
   cmp #79        ; check if pressed "O"
   bne @skip_o
   jmp @keyboard_o
@skip_o:
   cmp #76        ; check if pressed "L"
   bne @skip_l
   jmp @keyboard_l
@skip_l:
   cmp #32        ; check if pressed "SPACE"
   bne @skip_space
   jmp @keyboard_space
@skip_space:
   cmp #90        ; check if pressed "Z"
   bne @skip_z
   jmp @keyboard_z
@skip_z:
   cmp #88        ; check if pressed "X"
   bne @skip_x
   jmp @keyboard_x
@skip_x:
   cmp #81        ; exit if pressed "Q"
   bne @end_keychecks
   jmp done
@end_keychecks:
   jmp @end_mainloop

@keyboard_a:
   lda #0
   jmp @play_note
@keyboard_w:
   lda #1
   jmp @play_note
@keyboard_s:
   lda #2
   jmp @play_note
@keyboard_e:
   lda #3
   jmp @play_note
@keyboard_d:
   lda #4
   jmp @play_note
@keyboard_f:
   lda #5
   jmp @play_note
@keyboard_t:
   lda #6
   jmp @play_note
@keyboard_g:
   lda #7
   jmp @play_note
@keyboard_y:
   lda #8
   jmp @play_note
@keyboard_h:
   lda #9
   jmp @play_note
@keyboard_u:
   lda #10
   jmp @play_note
@keyboard_j:
   lda #11
   jmp @play_note
@keyboard_k:
   lda #12
   jmp @play_note
@keyboard_o:
   lda #13
   jmp @play_note
@keyboard_l:
   lda #14
   jmp @play_note
@keyboard_space:

   jmp @end_mainloop
@keyboard_z:
   lda Octave
   beq @end_mainloop
   sec
   sbc #12
   sta Octave
   jmp @end_mainloop
@keyboard_x:
   lda Octave
   cmp #108
   beq @end_mainloop
   clc
   adc #12
   sta Octave
   jmp @end_mainloop

@play_note:
   ; determine MIDI note
   sta Note
   lda Octave
   clc
   adc Note
   ; multiply by 2 to get memory address of frequency data
   asl
   tax

   ; upload frequency to the VERA
   lda #0
   sta $9F25
   ; set address of first PSG register into VRAM address register
   lda #$C0
   sta $9F20
   lda #$F9
   sta $9F21
   lda #$11
   sta $9F22   ; this also sets the auto-increment to 1
   ; load data into VERA
   lda pitch_data,x
   sta $9F23   ; freq low byte
   inx
   lda pitch_data,x
   sta $9F23   ; freq high byte

   ; launch ENV generator
   stz AD_phase
   stz AD_phase+1
   lda #1
   sta AD_step
@end_mainloop:

   jmp mainloop


done:

   ; stop PSG waveform
   ; select port 0 to the VERA
   lda #0
   sta $9F25
   ; set address of first PSG register into VRAM address register
   lda #$C2
   sta $9F20
   lda #$F9
   sta $9F21
   lda #$01
   sta $9F22   ; this also sets the auto-increment to 0
   ; load data into VERA
   lda #$00
   sta $9F23   ; no channels, 0 volume


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

.include "pitch_data.inc"