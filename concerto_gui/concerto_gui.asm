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
; Usage:
;   - include the Concerto synth engine before including this file.
;   - include gui_zeropage.asm into your zeropage segment.
;   - Start up the GUI calling ...
;   - call ... in the main loop in order to be able to use the mouse and keyboard
;   - you may stop calling the GUI tick at any time.

.scope concerto_gui

.include "gui_macros.asm"
.include "gui_variables.asm"
.include "gui_utils.asm"
.include "gui.asm"
.include "mouse.asm"

initialize:
   jsr gui::load_synth_gui
   jsr mouse::mouse_init
   rts

hide_mouse = mouse::mouse_hide

gui_tick = mouse::mouse_tick

; currently active timbre (in GUI editor)
Timbre:
   .byte 0

.endscope