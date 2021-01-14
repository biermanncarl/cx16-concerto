; This file contains the custom ISR which calls the synth engine.
; The AFLOW interrupt is hijacked, which is generated at
; regular intervals if the FIFO buffer is fed with equally sized chunks of data.
; PCM playback is fed with a few zeros, and played back at the lowest
; possible sample rate. Therefore, not much time has to be spent feeding the
; FIFO buffer.

.scope my_isr

default_isr:
   .word $0000
isr_running:
   .byte 0

; subroutine for launching the ISR
launch_isr:

   ; replace the interrupt handler

   ; copy address of default interrupt handler
   lda IRQVec
   sta default_isr
   lda IRQVec+1
   sta default_isr+1
   ; replace irq handler
   sei            ; block interrupts
   lda #<the_isr
   sta IRQVec
   lda #>the_isr
   sta IRQVec+1
   cli            ; allow interrupts

   ; setup the timer

   ; prepare playback
   lda #$8F       ; reset PCM buffer, 8 bit mono, 0 volume
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

rts

; subroutine for stopping the ISR
shutdown_isr:
   ; disable AFLOW interrupt
   lda VERA_ien
   and #$F7
   sta VERA_ien

   ; stop PCM
   lda #0
   sta VERA_audio_rate

   ; reset FIFO buffer
   lda #$8F
   sta VERA_audio_ctrl

   ; restore interrupt handler
   sei            ; block interrupts
   lda #<default_isr
   sta IRQVec
   lda #>default_isr
   sta IRQVec+1
   cli            ; allow interrupts

rts



; The ISR doing the realtime synth stuff
the_isr:
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
   ;lda #4
   sta VERA_audio_data
   ;sta VERA_audio_data
   ;sta VERA_audio_data

   ; safety check, if my ISR is already running. If so, skip sound engine tick.
   lda isr_running
   beq do_psg_control
isr_choke:
   jmp end_aflow

   ; now do all PSG control
do_psg_control:
   lda #1
   sta isr_running
   ;jsr player::player_tick
   jsr synth_engine::synth_tick
   stz isr_running

end_aflow:
   ; call default interrupt handler
   ; for keyboard service
jmp (default_isr)


.endscope