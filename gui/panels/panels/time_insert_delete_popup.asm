; Copyright 2025 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_TIME_INSERT_DELETE_POPUP_ASM

::GUI_PANELS_PANELS_TIME_INSERT_DELETE_POPUP_ASM = 1

.include "common.asm"

.scope time_insert_delete_popup
    ; popup blocks the whole screen, therefore this panel is "fullscreen" (for click detection)
    px = 0
    py = 0
    wd = 80
    hg = 60
    ; where the actual popup appears
        box_width = 40
        box_height = 6
        box_x = (80 - box_width) / 2
        box_y = (60 - box_height) / 2
    comps:
    .scope comps
        COMPONENT_DEFINITION button, ok, 41, box_y + box_height - 3, 6, A panel_common::lb_ok
        COMPONENT_DEFINITION button, cancel, 33, box_y + box_height - 3, 6, A panel_common::lb_cancel
        COMPONENT_DEFINITION drag_edit, num_bars, box_x+9, box_y+2, %00000000, 0, 64, 0, 0
        COMPONENT_LIST_END
    .endscope
    capts:
        ; If we have more use-cases for this panel, we may need to convert the caption into a dynamic label
        .byte 16*COLOR_BACKGROUND+1, box_x+2, box_y+2
        .word lb_insert
        .byte 16*COLOR_BACKGROUND+1, box_x+14, box_y+2
        .word lb_message
        .byte 16*COLOR_BACKGROUND+8, 36, box_y
        .word lb_caution
        .byte 0
    ; data specific to the panel
    lb_insert: STR_FORMAT "insert"
    lb_delete: STR_FORMAT "delete"
    lb_message: STR_FORMAT "bars at playback marker?"
    lb_caution: STR_FORMAT "caution"
    action_label_address = capts + 3
    mode: ; delete (0) or insert (1)
        .byte 0

    ; Expects 0 for delete, 1 for insert in .A
    .proc setup
        ; Load address of delete label, overwrite if necessary. This is optimized for code size.
        ldx #<lb_delete
        ldy #>lb_delete
        sta mode
        cmp #0
        beq @write_label_address
    @insert:
        ldx #<lb_insert
        ldy #>lb_insert
    @write_label_address:
        stx action_label_address
        sty action_label_address+1
        rts
    .endproc

    .proc clearArea
        lda #box_x-1
        sta guiutils::draw_x
        lda #box_y-1
        sta guiutils::draw_y
        lda #box_width+2
        sta guiutils::draw_width
        lda #box_height+2
        sta guiutils::draw_height
        lda #(16*COLOR_BACKGROUND)
        sta guiutils::color
        jsr guiutils::clear_rectangle
        rts
    .endproc

    .proc draw
        ; #optimize-for-size because this is pretty much the same code as for the file save/load popups but with different parameters
        inc kbd_variables::musical_keyboard_bypass
        jsr clearArea
        lda #box_x
        sta guiutils::draw_x
        lda #box_y
        sta guiutils::draw_y
        lda #box_width
        sta guiutils::draw_width
        lda #box_height
        sta guiutils::draw_height
        stz guiutils::draw_data1
        jsr guiutils::draw_frame
        rts
    .endproc

    .proc write
        ; TODO: for 2 buttons, we don't need a jump table
        lda mouse_variables::curr_component_id
        asl
        tax
        jmp (@jmp_tbl, x)
    @jmp_tbl:
        .word button_ok
        .word button_cancel
        .word panel_common::dummy_subroutine ; num_bars, we'll just read ourselves when doing the thing
    button_ok:
        ; TODO

        ; fall through to button_cancel, which closes the popup
    button_cancel:
        ; close popup
        jsr clearArea
        dec panels_stack_pointer
        jsr gui_routines__draw_gui
        rts
    .endproc

    refresh = panel_common::dummy_subroutine

    .proc keypress
        lda kbd_variables::current_key
        stz kbd_variables::current_key
        cmp #13 ; enter
        beq write::button_ok
        cmp #$1B ; escape
        beq write::button_cancel
        rts
    .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_TIME_INSERT_DELETE_POPUP_ASM
