; Copyright 2021, 2023 Carl Georg Biermann

; mouse variables
; These variables need to be visible to all GUI code (partly for reading, and upon request for writing).
; They cannot live alongside the actual mouse code, as the mouse code depends on the GUI code.
; Including these variables in the mouse code would introduce circular dependencies.

.ifndef ::GUI_MOUSE_DEFINITIONS_ASM
::GUI_MOUSE_DEFINITIONS_ASM = 1

.scope mouse_definitions

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
curr_panel: .byte 0 ; the index of the panel the mouse is at, high bit set (128 or bigger) if no panel.
curr_component_id: .byte 0
curr_component_ofs: .byte 0
curr_data_1: .byte 0 ; used to store the current tab selected, which arrow is clicked etc.
curr_data_2: .byte 0 ; used to store dragging distance (y direction)

.endscope

.endif ; .ifndef ::GUI_MOUSE_DEFINITIONS_ASM
