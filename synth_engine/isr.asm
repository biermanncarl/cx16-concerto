; Copyright 2021-2022 Carl Georg Biermann


; This file contains the custom ISR which calls the synth engine.

; Side note: in previous versions of the emulator, an NMI was triggered by VIA1, but now it's a regular IRQ.
; The last commit with the working implementation for NMI is in this commit: eceada786839b36405aa23cdbcc21ee79b79fa05

.scope isr

; define default timing source selector, if no other source has been selected yet
.ifndef ::concerto_clock_select
   ;::concerto_clock_select = CONCERTO_CLOCK_AFLOW
   ::concerto_clock_select = CONCERTO_CLOCK_VIA1_T1
.endif

; this variable says whether or not the Concerto synth engine has been activated or not.
; This is to prevent damage e.g. when launch_isr is called twice instead of once.
engine_active:
   .byte 0
default_irq_isr:
   .word $0000
default_rom_page:
   .byte 0
; flag which signals that a tick is currently already running
tick_is_running:
   .byte 0


; this is the common part between the AFLOW and VIA1 solutions
do_tick:
   ; backup RAM bank
   lda RAM_BANK
   pha
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
   ; The variables used by v40b are NOT backed up and instead, in the main program, v40b usage is constrained to self-contained blocks masked with SEI.
   ; Self-contained means that at the end of the SEI-masked block, whatever state is in the v40b API variables can safely be discarded and overwritten by the ISR.
   ; As for non-API v40b variables, these must not be changed by the ISR. The ISR must not modify the content of any dynamic memory storage.
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
   ; restore RAM bank
   pla
   sta RAM_BANK
   rts



; AFLOW routines
; ==============
.if ::concerto_clock_select = CONCERTO_CLOCK_AFLOW

.include "isr_aflow.asm"

.endif ; .if concerto_clock_select = CONCERTO_CLOCK_AFLOW



; VIA1_T1 routines
; ================
.if ::concerto_clock_select = CONCERTO_CLOCK_VIA1_T1

.include "isr_via1.asm"

.endif ; .if concerto_clock_select = CONCERTCONCERTO_CLOCK_VIA1_T1O_CLOCK_AFLOW


.endscope