; Copyright 2021-2022 Carl Georg Biermann


; Include this file to your program to include the concerto synth GUI.
;
; For more information, see readme.md

.pushseg
.code

.scope concerto_gui

play_volume:
   .byte 63

.include "../common/x16.asm"
.include "gui_zeropage.asm"
.include "gui_macros.asm"
.include "mouse_definitions.asm"
.include "gui_utils.asm"
.include "gui.asm"
.include "mouse.asm"

; concerto_gui::initialize
; Initializes and draws the GUI on screen. Expects 80x60 characters screen mode.
; Also brings up the mouse cursor.
; PARAMETERS: none
; AFFECTS: A, X, Y
initialize:
   jsr gui::load_synth_gui
   jsr mouse::mouse_init
   rts

; concerto_gui::hide_mouse
; Hides the mouse cursor.
; PARAMETERS: none
; AFFECTS: A, X
hide_mouse = mouse::mouse_hide

; concerto_gui::gui_tick
; Reads the mouse and performs actions according to the mouse input. Call this regularly in your main loop.
; It is NOT recommended to call this in the interrupt service routine.
; PARAMETERS: none
; AFFECTS: A, X, Y
gui_tick = mouse::mouse_tick


.endscope

.popseg
