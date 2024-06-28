; Copyright 2021-2024 Carl Georg Biermann

.code

   jmp start

; binary assets
.include "../assets/vram_assets.asm"

; communicate that we want to compile in timbre data from a file
concerto_use_timbres_from_file = 1
.define CONCERTO_TIMBRES_PATH "FACTORY.COB"

; include the synth and song engines
.include "../song_engine/song_engine.asm"

; include the synth gui
::concerto_full_daw = 1
.include "../gui/concerto_gui.asm"

; include the X16 header
.include "../common/x16.asm"

.include "../gui/file_browsing.asm"

; keyboard variables
Octave:
   .byte 60
Note:
   .byte 0



start:
   ; testing the directory functions
   jsr file_browsing::initialize
   ldx #file_browsing::file_type::instrument
   jsr file_browsing::getFiles
   jsr file_browsing::printFiles
   rts

   jsr concerto_synth::initialize
   jsr concerto_gui::initialize

   jsr concerto_synth::activate_synth

.include "concerto_mainloop.asm"

   jsr concerto_synth::deactivate_synth
   jsr concerto_gui::hide

   rts            ; return to BASIC
