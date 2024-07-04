; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_DYNAMIC_LABEL_ASM
::GUI_COMPONENTS_COMPONENTS_DYNAMIC_LABEL_ASM = 1


; The dynamic label is a non-interactive component which is capable of displaying
; both Petscii and Screencode strings in both low and banked RAM.
.include "common.asm"

.scope dynamic_label
    .struct data_members
        pos_x .byte
        pos_y .byte
        color .byte
        width .byte ; Maximum string length
        ram_bank .byte ; most significant bit: 0 if petscii, 1 if screencode
        label_address .word
    .endstruct

    .proc draw
        lda (components_common::data_pointer), y
        pha
        iny
        lda (components_common::data_pointer), y
        tax
        pla
        jsr guiutils::alternative_gotoxy
        iny
        lda (components_common::data_pointer), y
        sta guiutils::color
        iny
        lda (components_common::data_pointer), y
        pha ; store width
        iny
        ldx #0
        lda (components_common::data_pointer), y
        bmi :+
        inx
    :   stx guiutils::draw_data1
        and #$7f
        sta RAM_BANK
        iny
        lda (components_common::data_pointer), y
        sta guiutils::str_pointer
        iny
        lda (components_common::data_pointer), y
        sta guiutils::str_pointer+1
        iny
        plx ; recall width
        inx
        phy
        ldy #0
        jsr guiutils::print_with_padding
        ply
        rts
    .endproc

    .proc check_mouse
        ; #optimize-for-size add clc before components_common::dummy_subroutine and use it as no-op check-mouse
        clc
        rts
    .endproc

    event_click = components_common::dummy_subroutine
    event_drag = components_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_DYNAMIC_LABEL_ASM
