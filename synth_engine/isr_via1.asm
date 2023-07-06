; Copyright 2021-2022 Carl Georg Biermann

; This file contains the VIA1 timer option.

; subroutine for launching the ISR
launch_isr:
   ; set ROM page to zero
   lda ROM_BANK
   sta default_rom_page
   stz ROM_BANK

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
   lda #<the_isr
   ldx #>the_isr
   sei            ; block interrupts
   sta IRQVec
   stx IRQVec+1
   cli            ; allow interrupts

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
   lda engine_active
   bne :+
   rts ; engine already inactive
:  stz engine_active

   ; disable VIA#1 T1 timer interrupts
   lda VIA_IER
   and #%10111111
   sta VIA_IER

   ; select operation mode of T1
   lda VIA_ACR
   ; mode 00 - timed interrupt (one-shot), and no operation of PB7 pinout of the VIA.
   and #%00111111 ; deactivate bits 7 and 6
   sta VIA_ACR

   ; load time interval into timer latches ($0000 to stop the timer NOW and inhibit any further NMIs down the line, which make our life miserable)
   stz VIA_T1C_L
   stz VIA_T1C_H ; this causes the latched values to be loaded into the counter and thus stops the timer
   ; an NMI will occur pretty much right away, as we set the counter to 0
   ; We don't uninstall the NMI here, but let the NMI uninstall itself. This is safer.
   ; If we were to allow an NMI to occur with the original NMI vector, we would be facing a BRK,
   ; or worse, an emulator crash (when the wrong ROM page is selected).
   ; Hence, we keep ours for the last iteration and allow it to uninstall itself.

   ; restore IRQ interrupt handler
   sei            ; block interrupts
   lda default_irq_isr
   sta IRQVec
   lda default_irq_isr+1
   sta IRQVec+1
   cli            ; allow interrupts

   ; set ROM bank back to original
   lda default_rom_page
   sta ROM_BANK

   rts



; The ISR doing the realtime synth stuff
the_isr:
   php

   ; check if the timer is the culprit and clear interrupt flag
   lda VIA_IFR
   and #%01000000 ; when bit 6 is set, the timer was the culprit
   beq @end_tick
   ; timer was the culprit. reset timer interrupt flag
   lda VIA_T1C_L

   lda tick_is_running
   bne @end_tick ; skip running the tick 
   lda #1
   sta tick_is_running ; prevent ISR from interrupting itself
   jsr do_tick
   stz tick_is_running

@end_tick:
   plp
   jmp (default_irq_isr)


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
