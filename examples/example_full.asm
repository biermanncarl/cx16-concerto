; Copyright 2021-2022 Carl Georg Biermann


; Compile with: cl65 -t cx16 -o CONCERTO.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_full.asm"

.code

   jmp start

; communicate that we want to compile in timbre data from a file
concerto_use_timbres_from_file = 1
.define CONCERTO_TIMBRES_PATH "FACTORY.COB"

; include the synth engine
.include "../concerto_synth/concerto_synth.asm"

; include the synth gui
.include "../concerto_gui/concerto_gui.asm"

; include the X16 header
.include "../common/x16.asm"

; keyboard variables
Octave:
   .byte 60
Note:
   .byte 0



start:
   jsr concerto_synth::initialize
   jsr concerto_gui::initialize

   jsr concerto_synth::activate_synth

.include "example_full_mainloop.asm"

   jsr concerto_synth::deactivate_synth
   jsr concerto_gui::hide_mouse

   rts            ; return to BASIC
