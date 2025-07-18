; Copyright 2021-2025 Carl Georg Biermann


; Include this file to your program to include the concerto synth GUI.
;
; For more information, see readme.md

.pushseg
.code

.scope concerto_gui


; macros
.include "../common/x16.asm"
.include "gui_macros.asm"
; variable definitions
.include "gui_variables.asm"
.include "keyboard_variables.asm"
.include "mouse_variables.asm"
; submodules
.include "drawing_utils.asm"
.include "file_browsing.asm"
.include "components/components.asm"
.include "panels/panels.asm"
.ifdef ::concerto_full_daw
   .include "gauges.asm"
.endif
; higher level routines
.include "gui_routines.asm"
.include "keyboard_routines.asm"
.include "mouse_routines.asm"
; backward definitions
.include "gui_backward_definitions.asm"

; concerto_gui::initialize
; Initializes and draws the GUI on screen. Expects 80x60 characters screen mode.
; Also brings up the mouse cursor.
; PARAMETERS: none
; AFFECTS: A, X, Y
initialize:
   stz gui_variables::request_program_exit
   lda VERA_L1_mapbase
   sta guiutils::original_map_base
   jsr mouse::mouse_init
   ; Initializations used for both DAW and COS2ZSM applications
   jsr song_engine::clips::initialize
   jsr file_browsing::initialize
   jsr panels::file_save_popup::initialize
   jsr panels::file_load_popup::initialize
.ifdef ::concerto_full_daw
   jsr song_engine::multitrack_player::musical_keyboard::initialize
   jsr keyboard::installMusicalKeyboard
   jsr components::dnd::hitboxes::initialize
   jsr components::drag_and_drop_area::initialize
   jsr gui_routines::load_clip_gui
.elseif ::concerto_cos2zsm_converter
   jsr gui_routines::load_cos2zsm_converter_gui
.endif
   ; prevent emulator from intercepting Ctrl+V because we want to use it ourselves
   lda #1
   sta $9FB7
   rts

; concerto_gui::hide_gui
; Hides the mouse cursor and restores the previous tilemap base.
; PARAMETERS: none
; AFFECTS: A, X
hide:
.ifdef ::concerto_full_daw
   jsr keyboard::uninstallMusicalKeyboard
.endif
   lda guiutils::original_map_base
   sta VERA_L1_mapbase
   jsr mouse::mouse_hide
   rts

; concerto_gui::gui_tick
; Reads the mouse and performs actions according to the mouse input. Call this regularly in your main loop.
; It is NOT recommended to call this in the interrupt service routine.
; You can safely stop calling this regularly at any time, no special shutdown of the GUI is needed.
; PARAMETERS: none
; AFFECTS: A, X, Y
.proc gui_tick
   jsr keyboard::tick
   jsr mouse::mouse_tick
.ifdef ::concerto_full_daw
   jsr gauges::tick
.endif
   rts
.endproc


.endscope

.popseg
