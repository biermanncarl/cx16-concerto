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

; mouse variables
; they need to be visible to all GUI code,
; so I cannot simply put them into the mouse scope

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
ms_gui_write: .byte 0 ; used to determine whether or not an action has caused a value to be changed. If this is set, the respective panel's "write" subroutine will be called.