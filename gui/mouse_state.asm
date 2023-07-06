; Copyright 2021, 2023 Carl Georg Biermann

; mouse variables
; These variables need to be visible to all GUI code (partly for reading, and upon request for writing).
; They cannot live alongside the actual mouse code, as the mouse code depends on the GUI code.
; Including these variables in the mouse code would introduce circular dependencies.

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
