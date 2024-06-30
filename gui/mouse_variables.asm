; Copyright 2021-2024 Carl Georg Biermann

; mouse variables
; These variables need to be visible to all GUI code (partly for reading, and upon request for writing).
; They cannot live alongside the actual mouse code, as the mouse code depends on the GUI code.
; Including these variables in the mouse code would introduce circular dependencies.

.ifndef ::GUI_mouse_variables_ASM
::GUI_mouse_variables_ASM = 1

.scope mouse_variables
    ; state machine state
    ; status definitions
    ms_idle = 0
    ms_hold_L = 1
    ms_hold_other = 2
    status: .byte 0
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
    ; Mouse data, set by components' check_mouse routines to convey more information about the clicked at objects,
    ; e.g. the current tab selected, which arrow is clicked etc.
    curr_data_1: .byte 0
    curr_data_2: .byte 0 ; also used to store dragging distance (y direction) (use a different variable for that if necessary)
    curr_data_3: .byte 0
    ; distance since last tick
    delta_x: .byte 0
    delta_y: .byte 0
    ; others
    drag_start: .byte 0 ; used to indicate whether a drag event is the first since the mouse button has been held down
    .pushseg
    .zeropage
        ; downscaled mouse coordinates in multiples of 4 pixels
        curr_x_downscaled: .byte 0
        curr_y_downscaled: .byte 0
    .popseg

    ; State of getMouseChargridMotion, updated on-demand by calling getMouseChargridMotion in the respective drag routine
    ; By putting these variables in here (globally), we assume there can only be one scrolling operation going on at any one time
    accumulated_x:
        .byte 0
    accumulated_y:
        .byte 0
.endscope

.endif ; .ifndef ::GUI_mouse_variables_ASM
