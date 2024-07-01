; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_TEXT_EDIT_ASM

::GUI_COMPONENTS_COMPONENTS_TEXT_EDIT_ASM = 1


.include "common.asm"
.include "../../../dynamic_memory/vector_32bytes.asm"

.scope text_edit
    .struct data_members
        pos_x  .byte
        pos_y  .byte
        width  .byte ; the maximum length of the string is width-1 because the cursor needs one character
        string_pointer .word ; B/H pointer to a valid v32b entry with a zero-terminated string
        string_length .byte ; gets calculated during draw routine
        cursor_position .byte
    .endstruct

    ; Expects the (components_common::data_pointer), y addressing to be set up correctly prior to calling this.
    .proc setupAccess
        iny
        iny
        iny
        lda (components_common::data_pointer), y
        pha
        iny
        lda (components_common::data_pointer), y
        tax
        pla
        jmp v32b::accessFirstEntry
    .endproc

    .proc draw
        pos_x = gui_variables::mzpbh
        pos_y = gui_variables::mzpbf

        phy
        jsr setupAccess
        ply
        lda v32b::entrypointer
        sta guiutils::str_pointer
        lda v32b::entrypointer+1
        sta guiutils::str_pointer+1
        lda #(16*0+1)
        sta guiutils::color

        lda (components_common::data_pointer), y
        sta pos_x
        iny
        lda (components_common::data_pointer), y
        sta pos_y
        tax
        lda pos_x
        jsr guiutils::alternative_gotoxy
        iny
        lda (components_common::data_pointer), y
        tax
        inx

        phy
        ldy #0
        jsr guiutils::print_with_padding
        tya ; string length
        ply
        iny
        iny
        iny
        sta (components_common::data_pointer), y ; store string length

        ; mark curser position by changing the color of the respective pixel
        lda pos_x
        iny
        clc
        adc (components_common::data_pointer), y
        ldx pos_y
        jsr guiutils::alternative_gotoxy
        ldx VERA_data0 ; advance the data0 pointer without modifying the character
        lda #(16*1+0) ; inverse color

        sta VERA_data0

        iny
        rts
    .endproc

    .proc check_mouse
        width = gui_variables::mzpbf
        ; this is basically a "mouse is inside box" check
        ; with variable width
        ; get the width
        iny
        iny
        lda (components_common::data_pointer), y
        asl ; get width in multiples of 4 pixels
        sta width
        dey
        dey
        ; check x direction
        lda (components_common::data_pointer), y
        asl
        sec
        sbc mouse_variables::curr_x_downscaled
        eor #$ff
        inc ; now we have the distance of the mouse pointer to the left side of the box
        ; now A must be smaller than the box' width.
        cmp width
        bcc @horizontal_in
        ; we're out
    @out:
        clc
        rts
    @horizontal_in:  ; we're in
        ; preemptively calculate the character position we point at
        inc ; round up during division by two. This is more intuitive (I hope)?
        lsr
        sta mouse_variables::curr_data_1
        ; check y direction
        lda mouse_variables::curr_y_downscaled
        lsr
        iny
        cmp (components_common::data_pointer), y
        bne @out
        ; we're in
        sec
        rts
    .endproc

    ; The clicked at character position is in curr_data1
    .proc event_click
        ; Update the cursor position
        lda mouse_variables::curr_component_ofs
        clc
        adc #data_members::string_length
        tay
        lda mouse_variables::curr_data_1
        cmp (components_common::data_pointer), y
        bcc :+
        lda (components_common::data_pointer), y
    :   iny ; go to cursor_position
        sta (components_common::data_pointer), y

        ldy mouse_variables::curr_component_ofs
        jmp draw
    .endproc

    event_drag = components_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_TEXT_EDIT_ASM
