; This file contains the code that is executed in each tick
; All the updating of the PSG voices is done here.

.scope synth_engine


pitch:      .byte 0
fine:       .byte 0
frequency:  .word 0
volume:     .byte 0
waveform:   .byte 0


synth_tick:
   ; loop over synth voices
   ; loop over oscillators (i.e. PSG voices)

   ; but not now :P



   ; skip if voice inactive
   lda voices::Voice::active
   bne :+
   jmp skip_voice

   ; do voice specific stuff

:  ; do attack-decay env generator
   ; advance first
   ; then update volume
   lda voices::Voice::ad1::step
   ;cmp #0
   beq AD_do_attack
   cmp #1
   beq AD_do_decay
   jmp skip_voice
AD_do_attack:
   ADD16 voices::Voice::ad1::phase, timbres_pre::Timbre::ad1::attack
   ; high byte still in accumulator after addition
   tax
   cmp #63
   bcc AD_update_volume ; if 64 is still larger than high byte, just update volume
   ; otherwise, advance to next stage:
   inc voices::Voice::ad1::step
   lda #63
   tax
   sta voices::Voice::ad1::phase+1
   stz voices::Voice::ad1::phase
   bra AD_update_volume
AD_do_decay:
   SUB16 voices::Voice::ad1::phase, timbres_pre::Timbre::ad1::decay
   ; high byte still in accumulator after subtraction
   bcc AD_finished      ; if overflow occured during subtraction of high byte means we're finished
                        ; because we would have reached a negative value
   tax
   bra AD_update_volume
AD_finished:
   ldx #0
   stz voices::Voice::active
AD_update_volume:
   ; volume is in X
   txa
   clc
   adc #192
   sta volume

   ; determine *voice* pitch  (no oscillator pitch yet)
   ; check portamento
   lda voices::Voice::porta::active
   beq @skip_porta   ; porta inactive?
   cmp #1            ; porta upwards?
   beq @porta_up     ; if not, it is going down:

   ;porta downwards
   lda voices::Voice::porta::pos+1
   sec
   sbc voices::Voice::porta::rate+1
   sta voices::Voice::porta::pos+1
   sta fine
   lda voices::Voice::porta::pos
   sbc voices::Voice::porta::rate
   sta voices::Voice::porta::pos
   sta pitch
   cmp voices::Voice::pitch
   bcs @voice_pitch_done      ; porta still needs going. if not, end it
   stz voices::Voice::porta::active
   stz fine
   lda voices::Voice::pitch
   sta pitch
   bra @voice_pitch_done
@porta_up:
   ; porta upwards
   lda voices::Voice::porta::rate+1
   clc
   adc voices::Voice::porta::pos+1
   sta voices::Voice::porta::pos+1
   sta fine
   lda voices::Voice::porta::rate
   adc voices::Voice::porta::pos
   sta voices::Voice::porta::pos
   sta pitch
   cmp voices::Voice::pitch
   bcc @voice_pitch_done      ; porta still needs going. if not, end it
   stz voices::Voice::porta::active
   stz fine
   lda voices::Voice::pitch
   sta pitch
   bra @voice_pitch_done
@skip_porta:
   lda voices::Voice::pitch
   sta pitch
   stz fine
@voice_pitch_done:







   ; do oscillator pitch control
   lda fine
   clc
   adc timbres_pre::Timbre::osc1::fine
   sta fine
   lda pitch
   adc timbres_pre::Timbre::osc1::pitch
   sta pitch

   COMPUTE_FREQUENCY pitch,fine,frequency

   lda #64
   sta waveform
   ;lda #$FF
   ;sta volume
   VERA_SET_VOICE_PARAMS_MEM frequency,volume,waveform
   



skip_voice:

rts

.endscope