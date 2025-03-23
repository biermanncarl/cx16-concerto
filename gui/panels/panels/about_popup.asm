; Copyright 2025 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_ABOUT_POPUP_ASM

::GUI_PANELS_PANELS_ABOUT_POPUP_ASM = 1

.include "common.asm"

.scope about_popup
    ; popup blocks the whole screen, therefore this panel is "fullscreen" (for click detection)
    px = 0
    py = 0
    wd = 80
    hg = 60
    ; where the actual popup appears
        box_width = 40
        box_height = 40
        box_x = (80 - box_width) / 2
        box_y = (60 - box_height) / 2
    comps:
    .scope comps
        COMPONENT_DEFINITION button, ok, 37, box_y + box_height - 3, 6, A panel_common::lb_ok
        COMPONENT_DEFINITION text_field, about_text, box_x+2, box_y+3, 36, 33, A vram_assets::about_text
        COMPONENT_LIST_END
    .endscope
    capts:
        .byte 0

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
        jmp guiutils::clear_rectangle
    .endproc

    .proc draw
        ; #optimize-for-size because this is almost the same code as for other popups
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
        jmp guiutils::draw_frame
    .endproc

    .proc write
        ; close popup
        jsr clearArea
        dec panels_stack_pointer
        jmp gui_routines__draw_gui
    .endproc

    refresh = panel_common::dummy_subroutine

    .proc keypress
        lda kbd_variables::current_key
        stz kbd_variables::current_key
        cmp #13 ; enter
        beq write
        cmp #$1B ; escape
        beq write
        rts
    .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_ABOUT_POPUP_ASM
