; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_LISTBOX_ASM

::GUI_COMPONENTS_COMPONENTS_LISTBOX_ASM = 1

.include "common.asm"
.include "../../../dynamic_memory/vector_32bytes.asm"

.scope listbox
    .struct data_members
        pos_x .byte
        pos_y .byte
        width .byte ; in characters, i.e. multiples of 8 pixels
        height .byte
        string_pointer .word ; pointer to a v32b vector of zero-terminated strings
        scroll_offset .byte ; MUST BE SMALLER THAN NUMBER OF STRINGS. Not sure if byte suffices here --- for now let's go with it.
        selected_entry .byte ; 255=none
    .endstruct

    .proc draw
        pos_x = gui_variables::mzpbd
        pos_y = gui_variables::mzpbf ; mzpbe can't be used here
        width = gui_variables::mzpwd
        height = gui_variables::mzpwd+1
        ; get x and y position
        lda (components_common::data_pointer),y
        sta pos_x
        iny
        lda (components_common::data_pointer),y
        sta pos_y
        iny

        ; get width and height
        lda (components_common::data_pointer),y
        sta width
        iny
        lda (components_common::data_pointer),y
        sta height
        iny
        ; setup access to string list
        lda (components_common::data_pointer),y
        pha
        iny
        lda (components_common::data_pointer),y
        tax
        pla
        iny
        jsr v32b::accessFirstEntry
        ; advance string list to scroll offset
        ; Here we need the assumption that the scroll offset must be smaller than the number of strings.
        lda (components_common::data_pointer),y
        pha ; store offset
        iny
        lda (components_common::data_pointer),y
        inc ; small trick to utilize zero flag (see print line loop)
        sta selected
        plx ; recall offset
        phy
    @scroll_offset_loop: ; maybe make this a v32b subroutine?
        beq @scroll_offset_loop_end
        phx
        jsr v32b::accessNextEntry
        plx
        dec selected
        dex
        bra @scroll_offset_loop
    @scroll_offset_loop_end:

        ; print lines to screen
        ; v32b vectors cannot be empty, hence we don't need to check for that.
        ; We assume that height is at least 1, so we do print at least one line regularly.
    @lines_loop:
        lda pos_x
        ldx pos_y
        jsr guiutils::alternative_gotoxy
        lda v32b::entrypointer
        sta guiutils::str_pointer
        lda v32b::entrypointer+1
        sta guiutils::str_pointer+1
        lda #(16*COLOR_COMBOBOX_POPUP_BG+COLOR_COMBOBOX_POPUP_FG)
        dec selected
        bne :+
        lda #(16*COLOR_COMBOBOX_POPUP_FG+COLOR_COMBOBOX_POPUP_BG)
    :   sta guiutils::color
        ldx width
        inx
        ldy #0
        jsr guiutils::print_with_padding
        jsr v32b::accessNextEntry
        bcs @padding
        inc pos_y
        dec height
        beq @end
        bra @lines_loop

    @padding:
        ; TODO
    @end:
        ply
        iny
        rts
    selected:
        .res 1
    .endproc

    .proc check_mouse
        width = gui_variables::mzpwd
        height = gui_variables::mzpwd+1
        ; this is basically an "mouse is inside box" check
        ; with variable width and height
        ; get the width of the listbox
        phy
        iny
        iny
        lda (components_common::data_pointer), y
        sta width
        iny
        lda (components_common::data_pointer), y
        sta height
        ply
        ; check x direction
        lda mouse_variables::curr_x_downscaled
        lsr
        sec
        sbc (components_common::data_pointer), y ; now we have the distance of the mouse pointer to the left side of the box
        ; now A must be smaller than width.
        cmp width
        bcc @horizontal_in
    @out:   ; "from y" refers to the Y register being at the position of the y coordinate of the component's position data
        clc
        rts
    @horizontal_in:  ; we're in
        ; check y direction
        lda mouse_variables::curr_y_downscaled
        lsr
        iny
        sec
        sbc (components_common::data_pointer), y ; now we have the distance of the mouse pointer to the upper side of the box
        cmp height
        bcs @out
        ; we're in.
        ; store the index of the pointed at item
        iny
        iny
        iny
        iny
        iny
        clc
        adc (components_common::data_pointer), y ; add the scroll offset
        sta mouse_variables::curr_data_1 ; no range check

        sec
        rts
    .endproc

    .proc event_click
        ; TODO
        lda mouse_variables::curr_component_ofs
        clc
        adc #data_members::selected_entry
        tay
        lda mouse_variables::curr_data_1
        sta (components_common::data_pointer), y
        ldy mouse_variables::curr_component_ofs
        jsr draw
        rts
    .endproc

    event_drag = components_common::dummy_subroutine ; TODO: scrolling
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_LISTBOX_ASM
