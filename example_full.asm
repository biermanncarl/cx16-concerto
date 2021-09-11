; Copyright 2021 Carl Georg Biermann


; Compile with: cl65 -t cx16 -o CONCERTO.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_full.asm"

.zeropage
; define zero page variables of the submodules
.include "concerto_synth/synth_zeropage.asm"
.include "concerto_gui/gui_zeropage.asm"


.code

   jmp start

; include the synth engine
.include "concerto_synth/concerto_synth.asm"

; include the synth gui
.include "concerto_gui/concerto_gui.asm"

; include the X16 header
.include "concerto_synth/x16.asm"

; keyboard variables
Octave:
   .byte 60
Note:
   .byte 0



start:
   ; set ROM bank to 0 (from 4, the BASIC ROM)
   ; this is for better performance (the BASIC ROM has shown to have a hit on performance over the 0 ROM)
   stz ROM_BANK

   jsr concerto_synth::initialize
   jsr concerto_gui::initialize

   jsr concerto_synth::activate_synth

.include "example_full_mainloop.asm"

   jsr concerto_synth::deactivate_synth
   jsr concerto_gui::hide_mouse

   ; restore BASIC ROM page
   lda #4
   sta ROM_BANK

   rts            ; return to BASIC
