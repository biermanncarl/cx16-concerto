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


.ifndef GLOBAL_DEFS_INC ; include protector ...
GLOBAL_DEFS_INC = 1

; Synth engine definitions
.define N_VOICES 16
.define N_TIMBRES 32
.define N_OSCILLATORS 16 ; total number of PSG voices, which correspond to oscillators
.define MAX_OSCS_PER_VOICE 6
.define MAX_ENVS_PER_VOICE 3
.define MAX_LFOS_PER_VOICE 1
.define N_TOT_MODSOURCES MAX_ENVS_PER_VOICE+MAX_LFOS_PER_VOICE
.define MAX_VOLUME 64

; GUI definitions
; colors
.define COLOR_BACKGROUND 11
.define COLOR_FRAME 15
.define COLOR_CAPTION 15
.define COLOR_IMPORTANT_CAPTION 5; 13 is too bright
.define COLOR_TABS 1
.define COLOR_ARROWED_EDIT_BG 0
.define COLOR_ARROWED_EDIT_FG 3
.define COLOR_ARROWED_EDIT_ARROWS 1
.define COLOR_CHECKBOX 1
.define COLOR_LISTBOX_BG 0
.define COLOR_LISTBOX_FG 15
.define COLOR_LISTBOX_ARROW 1
.define COLOR_LISTBOX_POPUP_BG 0
.define COLOR_LISTBOX_POPUP_FG 7 ; or better 3?
; combined colors (foreground & background)
.define CCOLOR_CAPTION 16*COLOR_BACKGROUND+COLOR_CAPTION
.define CCOLOR_CHECKBOX_CLEAR 16*COLOR_CHECKBOX + COLOR_BACKGROUND
.define CCOLOR_CHECKBOX_TICK 16*COLOR_CHECKBOX + 0
.define CCOLOR_BUTTON 16*1 + 0
; others
.define N_PANELS 7   ; number of panels



; keyboard variables
Octave:
   .byte 60
Note:
   .byte 0
Channel:
   .byte (N_VOICES-1)
Volume:
   .byte MAX_VOLUME

; currently active timbre (in Synth GUI and keyboard)
Timbre:
   .byte 0

; debug variable
debug_a: .byte 0

; mouse variables
ms_status: .byte 0
; reference values
ms_ref_x: .word 0
ms_ref_y: .word 0
ms_ref_buttons: .byte 0
ms_ref_panel: .byte 0
ms_ref_component_id: .byte 0  ; component ID (from 0 to ...)
ms_ref_component_ofs: .byte 0 ; component offset (in a panel's component string)
; current values
ms_curr_x: .word 0
ms_curr_y: .word 0
ms_curr_buttons: .byte 0
ms_curr_panel: .byte 0
ms_curr_component_id: .byte 0
ms_curr_component_ofs: .byte 0
ms_curr_data: .byte 0 ; used to store the current tab selected, which arrow is clicked etc.
ms_curr_data2: .byte 0 ; used to store dragging distance (y direction)
ms_gui_write: .byte 0 ; used to determine whether or not an action has caused a value was changed.


.endif