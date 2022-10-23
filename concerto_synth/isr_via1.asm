; Copyright 2021-2022 Carl Georg Biermann

; flag which signals that a tick should be executed
do_tick_flag:
   .byte 0

; flag which signals that a tick currently cannot be executed by the NMI
dont_tick_flag:
   .byte 0

default_nmi_isr:
   .word 0


; subroutine for launching the ISR
launch_isr:
   lda engine_active
   beq :+
   rts ; engine is already active
:  inc engine_active

   ; replace irq handler with the auxiliary ISR first
   ; copy address of default interrupt handler
   ; since we are actively using it by doing a JMP to it, we need to decrement the address.
   lda IRQVec
   ;sec
   ;sbc #1
   sta default_irq_isr
   lda IRQVec+1
   ;sbc #0
   sta default_irq_isr+1
   ; overwrite vector with new address
   lda #<aux_isr
   ldx #>aux_isr
   sei            ; block interrupts
   sta IRQVec
   stx IRQVec+1
   cli            ; allow interrupts

   ; backup original NMI routine
   lda NMIVec
   sta default_nmi_isr
   lda NMIVec+1
   sta default_nmi_isr+1
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

   rts

; subroutine for stopping the ISR
shutdown_isr:
   ; disable VIA#1 T1 timer interrupts
   lda VIA_IER
   and #%10111111
   sta VIA_IER

   ; restore original NMI interrupt handler
   lda default_nmi_isr
   ldx default_nmi_isr+1
   sta NMIVec
   stx NMIVec+1

   ; restore IRQ interrupt handler
   sei            ; block interrupts
   lda default_irq_isr
   sta IRQVec
   lda default_irq_isr+1
   sta IRQVec+1
   cli            ; allow interrupts

   rts



; The ISR doing the realtime synth stuff
the_isr:
   pha
   phx
   phy

   ; most importantly: check if the timer is the culprit and clear interrupt flag
   lda VIA_IFR
   and #%01000000 ; when bit 6 is set, the timer was the culprit
   beq @end_tick
   ; timer was the culprit. reset timer interrupt flag
   lda VIA_T1C_L
   ; Now, check if the NMI interrupted another ISR (or code that should not be interrupted by an ISR)
   ; For that, look at the stack whether the Interrupt flag has been set prior to this NMI call.
   ; Status register is the last one that has been pushed to the stack before this ISR
   tsx
   lda $0104,x
   and #%00000100
   ;.byte $db
   beq @do_tick ; If I flag was reset, we did not interrupt an ISR for sure. It's safe to do the tick.

   lda do_tick_flag
   bne @set_signal

   ; I flag was set. Now we hafe to dig deeper. We actually want to prevent interruptions of PS/2 operations.
   ; The respective code is located in ROM (addr >= $C000). To check that, look up high byte of return address.
   lda $0106,x
   cmp #$C0
   bcc  @do_tick; If carry is clear, the return address is lower than $C000, hence not in ROM. Therefore, we did not interrupt PS/2 code.

   ; otherwise, we'll have to wait for the ISR to finish.
@set_signal:
   lda #1
   sta do_tick_flag
   bra @end_tick

@do_tick:
   jsr do_tick


@end_tick:
   ply
   plx
   pla
   rti ; in this case, the original NMI routine doesn't have to be called. It seems to just be a placeholder that can be overwritten.






   ; auxiliary ISR for normal IRQs.
   ; This is incase we did interrupt PS/2 communication.
   ; By intercepting the normal IRQ, we can give ourselves a "hook" at the end of the Kernal's ISR,
   ; check there if the do_tick_flag has been set, and then do the tick after the normal ISR has finished.
aux_isr:
   ; Situation: an IRQ has occurred.
   ; The Kernal Code has called us and has pushed A, X and Y before this piece of code is reached.
   ; We now simulate an IRQ to the Kernel that gives us the hook at the end.
   ; To achieve this, we need to insert three bytes into the stack. (This *should* be safe).

   ; push A, X and Y to the top of the stack
   ;.byte $db
   tsx
   lda $0103,x
   pha
   lda $0102,x
   pha
   lda $0101,x
   pha

   ; sneak our return address (and processor status for RTI) into the stack
   lda #>aux_isr_hook
   sta $0103,x
   lda #<aux_isr_hook
   sta $0102,x
   php
   pla
   sta $0101,x

   ; set flag that Kernal's ISR is running and hence no ticks are allowed
   lda #1
   sta dont_tick_flag

   jmp (default_irq_isr)


   ; when the Kernal's IRQ is done, it will return here.
aux_isr_hook:
   php
   pha
   phx
   phy

   ; check if NMI attempted to do a tick
   lda do_tick_flag
   beq @end_aux
   jsr do_tick
   stz do_tick_flag

@end_aux:
   ; ticks are now allowed for the NMI again
   stz dont_tick_flag
   ply
   plx
   pla
   plp
   rti



do_tick:
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

   rts

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

   
   ; Problem with NMIs: they are non-maskable.
   ; They can therefore interrupt other interrupt service routines.
   ; For example, when reading out keyboard or mouse data is done in a normal IRQ, it can be interrupted
   ; by a NMI, and if the NMI takes too long, the keyboard or mouse data gets lost while the NMI is still executing.
   ; This has been observed when using the NMI as timing source.
   ; Despite using the NMI as timing source, the actual execution of the sound engine
   ; should therefore be prioritized lower than the normal IRQ routine.