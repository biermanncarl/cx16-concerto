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


   ;VERA_SET_VOICE_VOLUME_X 0,192
   ; volume is in X
   txa
   clc
   adc #192
   sta volume

   ; do pitch control
   lda voices::Voice::pitch
   clc
   adc timbres_pre::Timbre::osc1::pitch
   sta pitch
   lda timbres_pre::Timbre::osc1::fine
   sta fine

   ; TODO
   ; portamento logic

   COMPUTE_FREQUENCY pitch,fine,frequency

   lda #64
   sta waveform
   ;lda #$FF
   ;sta volume
   VERA_SET_VOICE_PARAMS_MEM frequency,volume,waveform
   



skip_voice:

rts

.endscope