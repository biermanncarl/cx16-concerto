; Copyright 2021-2022 Carl Georg Biermann


; This file contains the custom ISR which calls the synth engine.
; The AFLOW interrupt is hijacked, which is generated at
; regular intervals if the FIFO buffer is fed with equally sized chunks of data.
; PCM playback is fed with a few zeros, and played back at the lowest
; possible sample rate. Therefore, not much time has to be spent feeding the
; FIFO buffer.

.scope isr

; define default timing source selector, if no other source has been selected yet
.ifndef concerto_clock_select
   ;concerto_clock_select = CONCERTO_CLOCK_AFLOW
   concerto_clock_select = CONCERTO_CLOCK_VIA1_T1
.endif

; this variable says whether or not the Concerto synth engine has been activated or not.
; This is to prevent damage e.g. when launch_isr is called twice instead of once.
engine_active:
   .byte 0
default_isr:
   .word $0000

; subroutine for launching the ISR
launch_isr:
   lda engine_active
   beq :+
   rts ; engine is already active
:  inc engine_active

   ; setup the timer
.if concerto_clock_select = CONCERTO_CLOCK_AFLOW
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

   ; start playback
   ; this will trigger AFLOW interrupts to occur
   ; set sample rate in multiples of 381.5 Hz = 25 MHz / (512*128)
   lda #1
   sta VERA_audio_rate
.endif ; concerto_clock_select = CONCERTO_CLOCK_AFLOW

.if concerto_clock_select = CONCERTO_CLOCK_VIA1_T1
   ; backup original NMI routine
   lda NMIVec
   sta default_isr
   lda NMIVec+1
   sta default_isr+1
   ; overwrite NMI vector with our own routine
   lda #<the_isr
   ldy #>the_isr
   sta NMIVec  ; let's just hope that no NMI occurs between those two instructions  ...
   sty NMIVec+1

   ; initialize VIA Timer 1
   ; enable timer interrupts
   lda VIA_IER
   ora #%01000000 ; set bit 6 to enable T1 to issue NMIs
   sta VIA_IER
   ;load time interval into latches ($F5BE should generate a 127.17 Hz timer with an 8 MHz clock)
   lda #$BE
   sta VIA_T1C_L
   lda #$F5
   sta VIA_T1C_H ; this causes the latched values to be loaded into the counter and thus starts the timer
   ; select operation mode of T1
   lda VIA_ACR
   ; mode 01 - continuous operation, but no operation of PB7 pinout of the VIA.
   and #%01111111 ; deactivate bit 7
   ora #%01000000 ; activate bit 6
   sta VIA_ACR
.endif ; concerto_clock_select = CONCERTO_CLOCK_VIA1_T1
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
   lda default_isr
   sta IRQVec
   lda default_isr+1
   sta IRQVec+1
   cli            ; allow interrupts

   rts



; The ISR doing the realtime synth stuff
the_isr:
   php

.if concerto_clock_select = CONCERTO_CLOCK_VIA1_T1
   pha
   phx
   phy
.endif

.if concerto_clock_select = CONCERTO_CLOCK_AFLOW
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
.endif

.if concerto_clock_select = CONCERTO_CLOCK_VIA1_T1
   ; most importantly: check if the timer is the culprit and clear interrupt flag
   lda VIA_IFR
   and #%01000000 ; when bit 6 is set, the timer was the culprit
   beq @end_tick
   ; timer was the culprit. reset timer interrupt flag
   lda VIA_T1C_L
.endif

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
.if concerto_clock_select = CONCERTO_CLOCK_AFLOW
   plp
   ; call default interrupt handler
   ; for keyboard service
   jmp (default_isr)
.endif
.if concerto_clock_select = CONCERTO_CLOCK_VIA1_T1
   ply
   plx
   pla
   plp
   ; Strangely, the computer freezes up when the original NMI routine is called.
   ; If RTI is done instead, everything just works fine.
   rti
   ;jmp (original_nmi_routine)
.endif







   ; VIA notes
   ; VIA #1's IRQ line is connected to the CPU's NMI line
   ; Therefore we need to install a custom NMI routine, which
   ; checks if the timer was the culprit, and also forwards to the original NMI routine.
   ; Only timer 1 has both long enough timing intervals, and a free-running timer.
   ; When T1 reaches zero, bit 6 of the interrupt flag register (IFR) on the VIA is set.
   ; if bit 6 in the interrupt enable register (IER) is set, an interrupt is issued.
   ; To reset the IFR flag, the counter T1L or T1H needs to be read.

   ; how to initialize the VIA
   ; set bit 6 of ACR
   ; reset bit 7 of ACR
   ; set the interval time by writing to the counter latches. This will be loaded every time the timer counter reaches zero in continuous mode.
   ; this results in continuous interrupts mode

   ; rough estimation of counter values: 8 MHz -> 1 tick is 1/8000000 s long, aka 1.25e-7 s
   ; 65536 * 1.25e-7 = 8.192 ms !
   ; This is the longest duration we can time with the VIA, if I understand correctly!
   ; Needed for Concerto: 7.863696 ms. Good!
   ; Need counter of 62909.568 ~= 62910 = $F5BE

   
   ; create custom NMI routine
   lda NMIVec
   sta original_nmi_routine
   lda NMIVec+1
   sta original_nmi_routine+1
   lda #<my_nmi_routine
   ldy #>my_nmi_routine
   sta NMIVec  ; let's just hope that no NMI occurs between those two instructions  ...
   sty NMIVec+1

   jmp continue

original_nmi_routine: .word 0
nmi_counter: .byte 0

my_nmi_routine:
   ; push registers on stack
   php
   pha
   phx
   phy
   lda VERA_addr_low
   pha
   lda VERA_addr_mid
   pha
   lda VERA_addr_high
   pha
   ; most importantly: check if the timer is the culprit and clear interrupt flag
   lda VIA_IFR
   and #%01000000 ; when bit 6 is set, the timer was the culprit
   beq forward_nmi
   ; timer was the culprit. reset timer interrupt flag
   lda VIA_T1C_L
   inc nmi_counter
   ;DISPLAY_BYTE nmi_counter, 0, 0
forward_nmi:
   pla
   sta VERA_addr_high
   pla
   sta VERA_addr_mid
   pla
   sta VERA_addr_low
   ply
   plx
   pla
   plp
   ; Strangely, the computer freezes up when I call the original NMI function. If I do RTI instead, everything just works fine.
   rti
   ;jmp (original_nmi_routine)
   ;jmp $E343 ; original NMI vector (R41)
   

continue:
   ;DISPLAY_BYTE nmi_counter, 0, 0

   ; initialize VIA Timer 1
   ; enable interrupts
   lda VIA_IER
   ora #%01000000 ; set bit 6 to enable T1 to issue NMIs
   sta VIA_IER
   ; select operation mode of T1
   lda VIA_ACR
   ; mode 01 - continuous operation, but no operation of PB7 pinout of the VIA.
   and #%01111111 ; deactivate bit 7
   ;and #%10111111 ; deactivate bit 6
   ora #%01000000 ; activate bit 6
   sta VIA_ACR
   ;load time interval into latches
   lda #$BE
   sta VIA_T1C_L
   lda #$F5
   sta VIA_T1C_H ; this should start the timer








.endscope