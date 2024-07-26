; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_TRACK_NAME_POPUP_ASM

::GUI_PANELS_PANELS_TRACK_NAME_POPUP_ASM = 1

.include "common.asm"
.include "../../file_browsing.asm"
.include "file_popups_common.asm"

.scope track_name_popup
    ; popup blocks the whole screen, therefore this panel is "fullscreen" (for click detection)
    px = 0
    py = 0
    wd = 80
    hg = 60
    ; where the actual popup appears
    box_width = 14
    box_height = 6
    box_x = (80 - box_width) / 2
    box_y = (60 - box_height) / 2
    comps:
    .scope comps
        COMPONENT_DEFINITION button, ok, 37, box_y + box_height - 3, 7, A lb_ok
        COMPONENT_DEFINITION text_edit, track_name, box_x+2, box_y+2, 10, A 0, 0, 0 ; width must be one larger than the maximum track name length
        COMPONENT_LIST_END
    .endscope
    capts:
        .byte 16*COLOR_BACKGROUND+1, 40-5, box_y
        .word panel_common::lb_track_name
        .byte 0
    ; data specific to the panel
    lb_ok: STR_FORMAT " close"
    string_address = comps::track_name + components::text_edit::data_members::string_pointer

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
        STZ_COMPONENT_MEMBER_ADDRESS text_edit, track_name, cursor_position
        rts
    .endproc

    .proc write
        ; only the close/ok button will trigger this function
        stz kbd_variables::current_key
        ; close popup
        jsr clearArea
        dec panels_stack_pointer
        jsr gui_routines__draw_gui
        rts
    .endproc

    refresh = panel_common::dummy_subroutine

    .proc keypress
        lda kbd_variables::current_key
        cmp #13 ; enter
        beq write
        LDY_COMPONENT_MEMBER text_edit, track_name, pos_x ; start offset of text edit
        lda #<comps
        sta components::components_common::data_pointer
        lda #>comps
        sta components::components_common::data_pointer+1
        jsr components::text_edit::keyboard_edit
        stz kbd_variables::current_key
        rts
    .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_TRACK_NAME_POPUP_ASM
