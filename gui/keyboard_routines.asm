; Copyright 2024 Carl Georg Biermann

; keyboard routines

.ifndef ::GUI_KEYBOARD_ROUTINES_ASM
::GUI_KEYBOARD_ROUTINES_ASM = 1

.include "keyboard_variables.asm"

.scope keyboard

.scope detail


    ; This handler could be called, even while another ISR is running (because keyboard interrupts can happen any time)!
    .proc musicalKbdHandler
        ; keycodes can be found here: https://github.com/X16Community/x16-rom/blob/master/inc/keycode.inc
        lowest_relevant_keycode = $12 ; keycode for "w" key
        highest_relevant_keycode = $29 ; single quote on english keyboard, rightmost key on second row

        ; check bypass
        ldy kbd_variables::musical_keyboard_bypass
        bne @finish_direct

        ; save .A and .X for original keyboard handler, and RAM bank
        pha
        phx
        ldx RAM_BANK
        phx

        cmp #128
        ldx #0
        bcs :+
        inx
    :   stx key_down
        and #$7F
        sec
        sbc #lowest_relevant_keycode
        cmp #(highest_relevant_keycode + 1 - lowest_relevant_keycode) ; this and higher key codes are irrelevant for musical keyboard
        bcs @finish
        tax
        lda key_pitch_map_lut, x
        bmi @finish ; filter out irrelevant keys

        clc
        adc gui_variables::musical_kbd_basenote

        ldy key_down
        beq @key_up
    @key_down:
        php
        sei
        sta song_engine::events::note_pitch
        lda gui_variables::musical_kbd_velocity
        sta song_engine::events::note_velocity
        lda #song_engine::events::event_type_note_on
        sta song_engine::events::event_type
        lda #kbd_variables::musical_keyboard_channel
        sta song_engine::multitrack_player::processEvent::player_index
        jsr song_engine::multitrack_player::processEvent
        plp
        bra @finish
    @key_up:
        php
        sei
        sta song_engine::events::note_pitch
        lda #song_engine::events::event_type_note_off
        sta song_engine::events::event_type
        lda #kbd_variables::musical_keyboard_channel
        sta song_engine::multitrack_player::processEvent::player_index
        jsr song_engine::multitrack_player::processEvent
        plp
    @finish:
        ; restore .A and .X for original keyboard handler, and RAM bank
        plx
        stx RAM_BANK
        plx
        pla
    @finish_direct:
        jmp (kbd_variables::original_keyboard_handler)
    key_down:
        .byte 0
    key_pitch_map_lut:
        .byte 1 ; w
        .byte 3 ; e
        .byte $FF ; r
        .byte 6 ; t
        .byte 8 ; z
        .byte 10 ; u
        .byte $FF ; i
        .byte 13 ; o
        .byte 15 ; p
        .byte $FF ; [
        .byte $FF ; ]
        .byte $FF ; \
        .byte $FF ; caps lock
        .byte 0 ; a
        .byte 2 ; s
        .byte 4 ; d
        .byte 5 ; f
        .byte 7 ; g
        .byte 9 ; h
        .byte 11 ; j
        .byte 12 ; k
        .byte 14 ; l
        .byte 16 ; ;
        .byte 17 ; '
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
