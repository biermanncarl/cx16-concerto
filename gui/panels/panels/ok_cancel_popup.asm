; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_OK_CANCEL_POPUP_ASM

::GUI_PANELS_PANELS_OK_CANCEL_POPUP_ASM = 1

.include "common.asm"
.include "../../file_browsing.asm"
.include "file_popups_common.asm"

.scope ok_cancel_popup
    ; popup blocks the whole screen, therefore this panel is "fullscreen" (for click detection)
    px = 0
    py = 0
    wd = 80
    hg = 60
    ; where the actual popup appears
        box_width = 26
        box_height = 6
        box_x = (80 - box_width) / 2
        box_y = (60 - box_height) / 2
    comps:
    .scope comps
        COMPONENT_DEFINITION button, ok, 41, box_y + box_height - 3, 6, A lb_ok
        COMPONENT_DEFINITION button, cancel, 33, box_y + box_height - 3, 6, A panel_common::lb_cancel
        COMPONENT_DEFINITION dynamic_label, filename_msg, box_x+2, box_y+2, CCOLOR_CAPTION, box_width-4, 0, A 0
        COMPONENT_LIST_END
    .endscope
    capts:
        ; If we have more use-cases for this panel, we may need to convert the caption into a dynamic label
        .byte 16*COLOR_BACKGROUND+1, 40-8, box_y
        .word lb_overwrite
        .byte 0
    ; data specific to the panel
    lb_ok: STR_FORMAT "  ok"
    lb_overwrite: STR_FORMAT "overwrite file?"
    string_bank = comps::filename_msg + components::dynamic_label::data_members::ram_bank
    string_address = comps::filename_msg + components::dynamic_label::data_members::label_address

    ; This popup panel might be used for a number of different things in the future
    ; .scope ok_cancel_type
        ; ID_GENERATOR 0, overwrite
    ; .endscope
    ; ok_cancel_type:
        ; .byte 0

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
        lda mouse_variables::curr_component_id
        asl
        tax
        jmp (@jmp_tbl, x)
    @jmp_tbl:
        .word button_ok
        .word button_cancel
    button_ok:
        ; TODO

        ; ; get reference to file name
        ; lda file_browsing::files
        ; ldx file_browsing::files+1
        ; LDY_COMPONENT_MEMBER_ADDRESS listbox, file_select, selected_entry
        ; cpy #255
        ; beq :+ ; don't open invalid file
        ; jsr dll::getElementByIndex
        ; ; open file
        ; ldy #0 ; open for writing
        ; jsr file_browsing::openFile
        ; bcs button_cancel
        ; lda gui_variables::current_synth_timbre
        ; php
        ; sei
        ; jsr concerto_synth::voices::panic
        ; jsr concerto_synth::timbres::loadInstrument
        ; plp
        ; jsr file_browsing::closeFile

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

.endif ; .ifndef ::GUI_PANELS_PANELS_OK_CANCEL_POPUP_ASM
