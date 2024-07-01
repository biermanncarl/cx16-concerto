; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_FILE_POPUPS_COMMON_ASM

::GUI_PANELS_PANELS_FILE_POPUPS_COMMON_ASM = 1

.include "common.asm"
.include "../../file_browsing.asm"

.scope file_popups_common
    ; where the actual popup appears
    box_width = 26
    box_height = 15
    box_x = (80 - box_width) / 2
    box_y = (60 - box_height) / 2

    lb_cancel: STR_FORMAT "cancel"

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

    .proc clearAndDrawFrame
        jsr clearArea
        ; clearArea already populates draw_x, draw_y, draw_width, draw_height, but we want different values unfortunately
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
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FILE_POPUPS_COMMON_ASM
