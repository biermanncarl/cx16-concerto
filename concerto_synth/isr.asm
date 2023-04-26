; Copyright 2021-2022 Carl Georg Biermann


; This file contains the custom ISR which calls the synth engine.

; Side note: in previous versions of the emulator, an NMI was triggered by VIA1, but now it's a regular IRQ.
; The last commit with the working implementation for NMI is in this commit: eceada786839b36405aa23cdbcc21ee79b79fa05

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
default_irq_isr:
   .word $0000
default_rom_page:
   .byte 0

; AFLOW routines
; ==============
.if concerto_clock_select = CONCERTO_CLOCK_AFLOW

.include "isr_aflow.asm"

.endif ; .if concerto_clock_select = CONCERTO_CLOCK_AFLOW



; VIA1_T1 routines
; ================
.if concerto_clock_select = CONCERTO_CLOCK_VIA1_T1

.include "isr_via1.asm"

.endif ; .if concerto_clock_select = CONCERTCONCERTO_CLOCK_VIA1_T1O_CLOCK_AFLOW


.endscope