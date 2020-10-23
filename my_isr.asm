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
   ;sta VERA_audio_data

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
   inc AD_step          ; otherwise, advance to next stage
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

   VERA_SET_VOICE_VOLUME_X 0,192

end_aflow:
   ; call default interrupt handler
   ; for keyboard service
   jmp (Default_isr)