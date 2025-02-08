; Copyright 2024 Carl Georg Biermann

; keyboard routines

.ifndef ::GUI_KEYBOARD_ROUTINES_ASM
::GUI_KEYBOARD_ROUTINES_ASM = 1

.include "keyboard_variables.asm"

.scope keyboard

.scope detail


    ; Apparently, since this keyboard handler is an ISR, it never occurs simultaneously with the concerto synth/player tick.
    ; We therefore (probably, from experience) don't have to worry about ISR compatibility of this keyboard handler.
    ; Its run time is of bigger concern. PS/2 communication might suffer if it takes too long. (Can result in glitchy mouse)
    ; Therefore, we use a small buffer to store keyboard events and let our ISR do the rest.
    .proc musicalKbdHandler
        ; We need to preserve .A and .X.

        ; check bypass
        ldy kbd_variables::musical_keyboard_bypass
        bne @finish_direct

        ldy song_engine::multitrack_player::musical_keyboard::buffer_num_events
        cpy #song_engine::multitrack_player::musical_keyboard::buffer_size ; keyboard event buffer full?
        bcs @finish_direct
        ; put keyboard event into buffer
        sta song_engine::multitrack_player::musical_keyboard::buffer, y
        inc song_engine::multitrack_player::musical_keyboard::buffer_num_events

    @finish_direct:
        jmp (kbd_variables::original_keyboard_handler)

    .endproc
.endscope

.proc tick
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
    ; key presses
    jsr GETIN
    sta kbd_variables::current_key
    jmp gui_routines::keypress_event
.endproc


.proc installMusicalKeyboard
    php
    sei
    lda KBDVec
    sta kbd_variables::original_keyboard_handler
    lda KBDVec+1
    sta kbd_variables::original_keyboard_handler+1
    lda #<detail::musicalKbdHandler
    ldx #>detail::musicalKbdHandler
    sta KBDVec
    stx KBDVec+1
    plp
    rts
.endproc

.proc uninstallMusicalKeyboard
    php
    sei
    lda kbd_variables::original_keyboard_handler
    sta KBDVec
    lda kbd_variables::original_keyboard_handler+1
    sta KBDVec+1
    plp
    rts
.endproc

.endscope

.endif ; .ifndef ::GUI_KEYBOARD_ROUTINES_ASM
