; Copyright 2021-2025 Carl Georg Biermann

::concerto_full_daw = 1

.code

   jmp start

; binary assets
.include "../assets/vram_assets.asm"

; Scratchpad memory for memory-hungry single-shot applications.
.include "../common/scratchpad_memory.asm"

; communicate that we want to compile in instrument data from a file
; Disabled because FACTORY.COB contains the old instrument data format without YM2151 LFO settings
; concerto_use_instruments_from_file = 1
; .define CONCERTO_INSTRUMENTS_PATH "FACTORY.COB"

; include the synth and song engines
.include "../song_engine/song_engine.asm"

; include the synth gui
.include "../gui/concerto_gui.asm"

; include the X16 header
.include "../common/x16.asm"

.include "global_backwards_definitions.asm"


start:
   jsr concerto_synth::initialize
   jsr concerto_gui::initialize

   jsr concerto_synth::activate_synth

mainloop:
   jsr concerto_gui::gui_tick
   lda concerto_gui::gui_variables::request_program_exit
   beq mainloop

exit:
   jsr concerto_synth::deactivate_synth
   jsr concerto_gui::hide

   ; Cold-start enter BASIC: program is cleared.
   sec
   jmp ENTER_BASIC
