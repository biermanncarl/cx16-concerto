; Copyright 2021, 2023 Carl Georg Biermann

; mouse variables
; These variables need to be visible to all GUI code (partly for reading, and upon request for writing).
; They cannot live alongside the actual mouse code, as the mouse code depends on the GUI code.
; Including these variables in the mouse code would introduce circular dependencies.

.ifndef MOUSE_STATE_ASM
MOUSE_STATE_ASM = 1

.scope mouse_state

; reference values
prev_x: .word 0
prev_y: .word 0
prev_panel: .byte 0
prev_component_id: .byte 0  ; component ID (from 0 to ...)
prev_component_ofs: .byte 0 ; component offset (in a panel's component string)
; current values
curr_x: .word 0
curr_y: .word 0
curr_buttons: .byte 0
curr_panel: .byte 0
curr_component_id: .byte 0
curr_component_ofs: .byte 0
curr_data_1: .byte 0 ; used to store the current tab selected, which arrow is clicked etc.
curr_data_2: .byte 0 ; used to store dragging distance (y direction)
gui_write: .byte 0 ; used to determine whether or not an action has caused a value to be changed. If this is set, the respective panel's "write" subroutine will be called.

.endscope

.endif ; .ifndef MOUSE_STATE_ASM
