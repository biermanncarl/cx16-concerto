; Copyright 2024 Carl Georg Biermann

; keyboard variables
; These variables need to be visible to all GUI code.
; They cannot live alongside the actual keyboard code, as it depends on the GUI code, which itself relies
; on the keyboard variables, creating circular dependency.

.ifndef ::GUI_KEYBOARD_VARIABLES_ASM
::GUI_KEYBOARD_VARIABLES_ASM = 1

.scope kbd_variables
    current_key:
        .byte 0

    ; Variables which are populated on-demand
    ; Keyboard modifiers
    ctrl_key_pressed:
        .byte 0
    shift_key_pressed:
        .byte 0
    alt_key_pressed:
        .byte 0

    original_keyboard_handler:
        .word 0
    musical_keyboard_base_pitch:
        .byte 60
    musical_keyboard_channel = $FF
.endscope

.endif ; .ifndef ::GUI_KEYBOARD_VARIABLES_ASM
