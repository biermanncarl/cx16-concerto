; This file contains the code that is executed in each tick
; All the updating of the PSG voices is done here.

.scope synth_engine


pitch:      .byte 0
fine:       .byte 0
frequency:  .word 0
volume:     .byte 0
waveform:   .byte 0


synth_tick:
   ; loop over synth voices, counting down from 15 to 0
   ldx #N_VOICES
next_voice:
   dex
   bpl :+
   jmp end_synth_tick
:  ; check if voice active
   lda voices::Voice::active, x
   beq next_voice


   ; voice index is in register X
   ; load timbre index into register Y
   ldy voices::Voice::timbre, x

   ; do attack-decay env generator
   ; advance first
   ; then update volume
   lda voices::Voice::ad1::step, x
   ;cmp #0
   beq AD_do_attack
   cmp #1
   beq AD_do_decay
   jmp next_voice
AD_do_attack:
   ; add attack rate to phase
   clc
   lda timbres_pre::Timbre::ad1::attackL, y
   adc voices::Voice::ad1::phaseL, x
   sta voices::Voice::ad1::phaseL, x
   lda timbres_pre::Timbre::ad1::attackH, y
   adc voices::Voice::ad1::phaseH, x
   sta voices::Voice::ad1::phaseH, x
   ; high byte still in accumulator after addition
   cmp #63 ; this is the threshold for when attack stage is done
   bcc AD_done ; if 64 is still larger than high byte, we're still in attack phase, and therefore done for now
   ; otherwise, advance to next stage:
   inc voices::Voice::ad1::step, x
   lda #63
   sta voices::Voice::ad1::phaseH, x
   stz voices::Voice::ad1::phaseL, x
   bra AD_done
AD_do_decay:
   ; subtract decay rate from phase
   sec
   lda voices::Voice::ad1::phaseL, x
   sbc timbres_pre::Timbre::ad1::decayL, y
   sta voices::Voice::ad1::phaseL, x
   lda voices::Voice::ad1::phaseH, x
   sbc timbres_pre::Timbre::ad1::decayH, y
   sta voices::Voice::ad1::phaseH, x
   ; high byte still in accumulator after subtraction
   bcc AD_finished      ; if overflow occured during subtraction of high byte means we're finished
                        ; because we would have reached a negative value
   bra AD_done
AD_finished:
   ; deactivate voice
   stz voices::Voice::active, x
   ; reset phase
   stz voices::Voice::ad1::phaseL, x
   stz voices::Voice::ad1::phaseH, x
   ; and register for voice release
   ldy voices::Voicemap::rvsp
   txa
   sta voices::Voicemap::releasevoicestack, y
   inc voices::Voicemap::rvsp
   ; mute voice
   VERA_MUTE_VOICE_X
   ; and restore register Y to timbre index (not really necessary since voice has been terminated)
   ; but this might be necessary in the future
   ldy voices::Voice::timbre, x
   jmp next_voice
AD_done:

   ; voice volume is in AD envelope 1 (hard wired for now)
   lda voices::Voice::ad1::phaseH, x
   clc
   adc #192
   sta volume

   ; determine *voice* pitch  (no individual oscillators yet)
   ; check portamento
   lda voices::Voice::porta::active, x
   beq @skip_porta   ; porta inactive?
   cmp #1            ; porta upwards?
   beq @porta_up     ; if not, it is going down:

   ;porta downwards
   lda voices::Voice::porta::posL, x
   sec
   sbc voices::Voice::porta::rateL, x
   sta voices::Voice::porta::posL, x
   sta fine
   lda voices::Voice::porta::posH, x
   sbc voices::Voice::porta::rateH, x
   sta voices::Voice::porta::posH, x
   sta pitch
   cmp voices::Voice::pitch, x
   bcs @voice_pitch_done      ; porta still needs going? if not, end it
   stz voices::Voice::porta::active, x
   stz fine
   lda voices::Voice::pitch, x
   sta pitch
   bra @voice_pitch_done
@porta_up:
   ; porta upwards
   lda voices::Voice::porta::rateL, x
   clc
   adc voices::Voice::porta::posL, x
   sta voices::Voice::porta::posL, x
   sta fine
   lda voices::Voice::porta::rateH, x
   adc voices::Voice::porta::posH, x
   sta voices::Voice::porta::posH, x
   sta pitch
   cmp voices::Voice::pitch, x
   bcc @voice_pitch_done      ; porta still needs going? if not, end it
   stz voices::Voice::porta::active, x
   stz fine
   lda voices::Voice::pitch, x
   sta pitch
   bra @voice_pitch_done
@skip_porta:
   lda voices::Voice::pitch, x
   sta pitch
   stz fine
@voice_pitch_done:




   ; loop over oscillators (i.e. PSG voices)
   ; but not now :P ... now we just treat each voice as one oscillator



   ; do oscillator pitch control
   lda fine
   clc
   adc timbres_pre::Timbre::osc1::fine, y
   sta fine
   lda pitch
   adc timbres_pre::Timbre::osc1::pitch, y
   sta pitch

   phx
   phy
   COMPUTE_FREQUENCY pitch,fine,frequency
   ply
   plx

   lda timbres_pre::Timbre::osc1::waveform, y
   ;lda #64
   sta timbres_pre::Timbre::osc1::waveform, y
   sta waveform
   ;lda #$FF
   ;sta volume
   VERA_SET_VOICE_PARAMS_MEM_X frequency,volume,waveform


   jmp next_voice

   lda #65
   jsr CHROUT

end_synth_tick:

rts

.endscope