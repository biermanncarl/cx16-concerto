; Copyright 2024 Carl Georg Biermann

; keyboard routines

.ifndef ::GUI_KEYBOARD_ROUTINES_ASM
::GUI_KEYBOARD_ROUTINES_ASM = 1

.include "keyboard_variables.asm"

.scope keyboard

.proc tick
    ; jsr GETIN ; uncomment once main loop doesn't do this anymore
    sta kbd_variables::current_key
    ; modifier keys statuses
    jsr KBDBUF_GET_MODIFIERS
    tax
    and #KBD_MODIFIER_CTRL
    sta kbd_variables::ctrl_key_pressed
    txa
    and #KBD_MODIFIER_SHIFT
    sta kbd_variables::shift_key_pressed
    txa
    and #KBD_MODIFIER_ALT
    sta kbd_variables::alt_key_pressed
    rts
.endproc

.endscope

.endif ; .ifndef ::GUI_KEYBOARD_ROUTINES_ASM
