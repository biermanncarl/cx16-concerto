; Copyright 2021-2025 Carl Georg Biermann


; This file contains the custom ISR which calls the synth engine.

; Side note: in previous versions of the emulator, an NMI was triggered by VIA1, but now it's a regular IRQ.
; The last commit with the working implementation for NMI is in this commit: eceada786839b36405aa23cdbcc21ee79b79fa05

.scope isr

; define default timing source selector, if no other source has been selected yet
.ifndef ::concerto_clock_select
   ; ::concerto_clock_select = CONCERTO_CLOCK_AFLOW
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
   lda dll_zp_pointer
   pha
   lda dll_zp_pointer+1
   pha
   lda dll_zp_pointer_2
   pha
   lda dll_zp_pointer_2+1
   pha
   lda v5b::value_0
   pha
   lda v5b::value_1
   pha
   lda v5b::value_2
   pha
   lda v5b::value_3
   pha
   lda v5b::value_4
   pha
   lda v32b::entrypointer
   pha
   lda v32b::entrypointer+1
   pha
   ; we only back up Data0 so far, and we expect Data0 to be selected at all times when the ISR can be executed
   ; stz VERA_ctrl  ; not needed as long as Data0 is always selected
   lda VERA_addr_low
   pha
   lda VERA_addr_mid
   pha
   lda VERA_addr_high
   pha
   ; do synth tick updates
   jsr synth_engine::synth_tick
   ; call playback routine (done after the synth tick to reduce jitter caused by fluctuating computational load inside the playback routine.
   ; Jitter hasn't been a problem so far, this move was done in anticipation of jitter)
   .ifdef ::concerto_full_daw
      jsr concerto_gui__gauges__tick_isr
   .endif
   jsr concerto_playback_routine
   ; restore shared variables
   pla
   ; we only back up Data0 so far, and we expect Data0 to be selected at all times when the ISR can be executed
   ; stz VERA_ctrl  ; not needed as long as Data0 is always selected
   sta VERA_addr_high
   pla
   sta VERA_addr_mid
   pla
   sta VERA_addr_low
   pla
   sta v32b::entrypointer+1
   pla
   sta v32b::entrypointer
   pla
   sta v5b::value_4
   pla
   sta v5b::value_3
   pla
   sta v5b::value_2
   pla
   sta v5b::value_1
   pla
   sta v5b::value_0
   pla
   sta dll_zp_pointer_2+1
   pla
   sta dll_zp_pointer_2
   pla
   sta dll_zp_pointer+1
   pla
   sta dll_zp_pointer
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