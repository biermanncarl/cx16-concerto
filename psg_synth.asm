.include "x16.asm"

.zeropage
.include "zeropage.asm"

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

; variables/macros
.include "global_definitions.asm"
.include "synth_macros.asm"
; sub modules
.include "timbres.asm"
.include "voices.asm"
.include "synth_engine.asm"
.include "my_isr.asm"
.include "guiutils.asm"
.include "gui.asm"
.include "mouse.asm"
.include "presets.asm"



start:
   ; startup code

   jsr gui::load_synth_gui

   jsr mouse::mouse_init

   ; initialize patch 0
   ;PRESET_KICK_DRUM_2 0
   ;PRESET_ONE_OSC_PATCH 0
   ;PRESET_LEAD_2 0
   PRESET_ONE_OSC_PATCH 0
   PRESET_BRIGHT_PLUCK 1
   PRESET_LEAD_2 2
   PRESET_KICK_DRUM_2 3
   PRESET_SNARE_DRUM_3 4

   ; do other initializations
   jsr voices::init_voicelist
   jsr my_isr::launch_isr
   ; main loop ... wait until "Q" is pressed.
mainloop:

   ; GUI
   jsr mouse::mouse_tick

   DISPLAY_BYTE ms_curr_panel, 30, 1
   DISPLAY_BYTE ms_curr_component_id, 35, 1
   DISPLAY_BYTE ms_curr_component_ofs, 35, 3
   DISPLAY_BYTE ms_curr_data, 40, 1

   ; clear voices that have been released
   jsr voices::do_stack_releases

   ; keyboard polling
.include "keyboard_polling.asm"

play_note:
   ; determine MIDI note
   sta Note
   lda Octave
   clc
   adc Note

   ; play note
   sta voices::note_pitch
   lda #127
   sta voices::note_velocity
   lda Timbre
   sta voices::note_timbre
   jsr voices::play_note

end_mainloop:

   jmp mainloop


exit:
   jsr my_isr::shutdown_isr

   ; TODO: properly shutdown all PSG voices (panic)

   ; hide mouse pointer
   lda #0
   ldx #0
   jsr MOUSE_CONFIG

   rts            ; return to BASIC
   ; NOTE
   ; The program gets corrupted in memory after returning to BASIC
   ; If running again, reLOAD the program!




; data
.segment "RODATA"
.include "pitch_data.asm"
