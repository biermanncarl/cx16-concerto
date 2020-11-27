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
.include "panels.asm"
.include "presets.asm"



start:
   ; startup code

   jsr panels::load_synth_gui

   ; initialize mouse
   lda #1
   ldx #1
   jsr MOUSE_CONFIG

   ; initialize patch 0
   PRESET_KICK_DRUM_2 0
   ;PRESET_ONE_OSC_PATCH 0
   ;PRESET_LEAD_2 0


   ; do other initializations
   jsr voices::init_voicelist
   jsr my_isr::launch_isr
   ; main loop ... wait until "Q" is pressed.
mainloop:

   ; GUI
   jsr panels::mouse_get_panel

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
   stz voices::note_timbre
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
