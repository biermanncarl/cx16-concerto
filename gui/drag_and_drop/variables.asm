; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_DRAG_AND_DROP_VARIABLES_ASM
::GUI_DRAG_AND_DROP_VARIABLES_ASM = 1

; by putting these variables in here (globally), we assume there can only be one scrolling operation going on at any one time
accumulated_x:
    .byte 0
accumulated_y:
    .byte 0
; Keyboard modifiers
ctrl_key_pressed:
    .byte 0
shift_key_pressed:
    .byte 0
; Vectors for processing events
temp_events:
    .res 2
clipboard_events:
    .res 2

; Which kind of drag & drop operation is going on. Values mean different things
drag_action_state:
    .byte 0

.endif ; .ifndef ::GUI_DRAG_AND_DROP_VARIABLES_ASM
