; Copyright 2021 Carl Georg Biermann

; This file is part of Concerto.

; Concerto is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;*****************************************************************************

; Include this file to your program to include the concerto synth GUI.
;
; For more information, see readme.md

.scope concerto_gui

play_volume:
   .byte 63

.include "../concerto_synth/x16.asm"
.include "gui_macros.asm"
.include "gui_variables.asm"
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
; It is NOT recommended to call this in the interrupt service routine, although it's possible to do so.
; PARAMETERS: none
; AFFECTS: A, X, Y
gui_tick = mouse::mouse_tick

; currently active timbre (in GUI editor)
Timbre:
   .byte 0

.endscope