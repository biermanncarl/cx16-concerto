; Copyright 2021-2022 Carl Georg Biermann

launch_isr:
   lda engine_active
   beq :+
   rts ; engine is already active
:  inc engine_active

   ; prepare FIFO (PCM) playback
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

   ; replace the interrupt handler

   ; copy address of default interrupt handler
   lda IRQVec
   sta default_irq_isr
   lda IRQVec+1
   sta default_irq_isr+1
   ; replace irq handler
   sei            ; block interrupts
   lda #<the_isr
   sta IRQVec
   lda #>the_isr
   sta IRQVec+1
   cli            ; allow interrupts

   ; start playback
   ; this will trigger AFLOW interrupts to occur
   ; set sample rate in multiples of 381.5 Hz = 25 MHz / (512*128)
   lda #1
   sta VERA_audio_rate

   rts

; subroutine for stopping the ISR
shutdown_isr:
   lda engine_active
   bne :+
   rts ; engine already inactive
:  stz engine_active

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
   lda default_irq_isr
   sta IRQVec
   lda default_irq_isr+1
   sta IRQVec+1
   cli            ; allow interrupts

   rts



; The ISR doing the realtime synth stuff
the_isr:
   php

   ; first check if interrupt is an AFLOW interrupt
   lda VERA_isr
   and #$08
   bne @do_fillup
   jmp @end_tick

@do_fillup:
   ; fill FIFO buffer with 3 samples
   ; at lowest possible PCM playback rate
   ; this will generate the next AFLOW interrupt in ~7 ms
   lda #0
   sta VERA_audio_data
   sta VERA_audio_data
   sta VERA_audio_data

@do_tick:
   ; backup shared variables (shared means: both main program and ISR can use them)
   lda mzpba
   pha
   lda mzpbe
   pha
   lda mzpbf
   pha
   lda mzpbg
   pha
   lda VERA_addr_low
   pha
   lda VERA_addr_mid
   pha
   lda VERA_addr_high
   pha
   ; call playback routine
   jsr concerto_playback_routine
   ; do synth tick updates
   jsr synth_engine::synth_tick
   ; restore shared variables
   pla
   sta VERA_addr_high
   pla
   sta VERA_addr_mid
   pla
   sta VERA_addr_low
   pla
   sta mzpbg
   pla
   sta mzpbf
   pla
   sta mzpbe
   pla
   sta mzpba

@end_tick:
   plp
   ; call default interrupt handler
   ; for keyboard service
   jmp (default_isr)