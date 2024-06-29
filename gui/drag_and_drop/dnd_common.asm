; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_DRAG_AND_DROP_VARIABLES_ASM
::GUI_DRAG_AND_DROP_VARIABLES_ASM = 1

; Vectors for processing events
temp_events:
    .res 2
clipboard_events:
    .res 2

; Which kind of drag & drop operation is going on. Values mean different things
drag_action_state:
    .byte 0

.endif ; .ifndef ::GUI_DRAG_AND_DROP_VARIABLES_ASM
