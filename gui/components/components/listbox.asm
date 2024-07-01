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
        valid_entries .byte ; gets calculated during draw routine, but gets truncated at the last item visible (not a problem so far)
    .endstruct

    .proc draw
        pos_x = gui_variables::mzpbh
        pos_y = gui_variables::mzpbf ; mzpbe can't be used here
        width = gui_variables::mzpwd
        height = gui_variables::mzpwd+1
        ; get x and y position
        lda (components_common::data_pointer),y
        iny
        sta pos_x
        lda (components_common::data_pointer),y
        iny
        sta pos_y

        ; get width and height
        lda (components_common::data_pointer),y
        iny
        sta width
        lda (components_common::data_pointer),y
        iny
        sta height
        ; setup access to string list
        lda (components_common::data_pointer),y
        iny
        sta temp
        lda (components_common::data_pointer),y
        iny
        tax
        ; pointer to string list in temp/.X
        lda (components_common::data_pointer),y ; read scroll offset
        iny
        phy ; remember data offset
        ; Here we need the assumption that the scroll offset must be smaller than the number of strings.
        ; advance string list to scroll offset
        sta valid_entries ; use scroll offset as starting point here
        tay
        lda temp
        jsr dll::getElementByIndex ; we assume it succeeds ...
        jsr v32b::accessFirstEntry ; actually not the first entry here

        ; calculate position of selected entry relative to first visible line
        ply
        lda (components_common::data_pointer),y
        phy
        inc ; trick to better utilize zero-flag in the print loop
        sec
        sbc valid_entries
        sta selected

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
        ; check if valid
        lda (v32b::entrypointer), y
        beq :+
        inc valid_entries
        ; print line
    :   lda #1
        sta guiutils::draw_data1
        jsr guiutils::print_with_padding
        jsr v32b::accessNextEntry
        inc pos_y
        dec height
        bcs @padding ; carry is return value from accessNextEntry
        beq @end
        bra @lines_loop

    @padding:
        lda pos_x
        sta guiutils::draw_x
        lda pos_y
        sta guiutils::draw_y
        lda width
        sta guiutils::draw_width
        lda height
        beq @end ; skip if padding height is 0
        sta guiutils::draw_height
        lda #(16*COLOR_COMBOBOX_POPUP_BG)
        sta guiutils::color
        jsr guiutils::clear_rectangle
    @end:
        ply
        iny
        lda valid_entries
        sta (components_common::data_pointer),y
        iny
        rts
    temp:
    selected:
        .res 1
    valid_entries:
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
        lda mouse_variables::curr_component_ofs
        clc
        adc #data_members::valid_entries
        tay
        lda mouse_variables::curr_data_1
        cmp (components_common::data_pointer), y
        bcc :+
        lda #255 ; none selected
    :   dey
        sta (components_common::data_pointer), y
        ldy mouse_variables::curr_component_ofs
        inc gui_variables::request_component_write
        jmp draw
    .endproc

    .proc event_drag
        ; This routine is kinda crude. It is safe but disallows a lot of operations which could be clamped instead.
        lda mouse_variables::prev_component_ofs
        clc
        adc #data_members::scroll_offset
        pha ; store offset
        jsr mouse__getMouseChargridMotion
        txa
        ply ; recall offset
        clc
        adc (components_common::data_pointer),y
        iny
        iny
        cmp (components_common::data_pointer),y ; compare with number of valid entries
        bcs :+
        dey
        dey    
        sta (components_common::data_pointer),y ; store new scroll offset
        ldy mouse_variables::curr_component_ofs
        jsr draw
    :   rts
    .endproc
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_LISTBOX_ASM
