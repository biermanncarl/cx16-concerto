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
        lda #1
        sta guiutils::draw_data1
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

    ; Keyboard editing
    ; Expects kbd_variables::current_key to be populated with recent key stroke.
    ; Expects (components_common::data_pointer),y to access the first data member
    .proc keyboard_edit
        offset = gui_variables::mzpbh
        cursor_pos = gui_variables::mzpbf
        ; pos_x = gui_variables::mzpbh
        ; pos_y = gui_variables::mzpbf ; mzpbe can be used here?
        ; width = gui_variables::mzpwd
        ; height = gui_variables::mzpwd+1
        sty offset
        tya
        clc
        adc #data_members::cursor_position
        tay
        lda (components_common::data_pointer), y
        sta cursor_pos
        dey
        dey
        lda (components_common::data_pointer), y
        tax
        dey
        lda (components_common::data_pointer), y
        jsr v32b::accessFirstEntry
        iny
        iny
        iny ; .Y is back to cursor position

        ; interpret key stroke
        lda kbd_variables::current_key
        ; .byte $db

        cmp #29 ; cursor right
        beq @cursor_right
        cmp #157 ; cursor left
        beq @cursor_left
        cmp #19 ; home position
        beq @home
        cmp #4 ; line end
        beq @line_end
        cmp #20 ; backspace
        beq @backspace
        cmp #25 ; delete
        beq @delete
        bra @other

    @cursor_right:
        lda cursor_pos
        dey
        cmp (components_common::data_pointer), y
        bne :+
        rts
    :   iny
        inc
        sta (components_common::data_pointer), y
        bra @done
    @cursor_left:
        lda cursor_pos
        bne :+
        rts
    :   dec
        sta (components_common::data_pointer), y
        bra @done
    @home:
        lda #0
        sta (components_common::data_pointer), y
        bra @done
    @line_end:
        dey
        lda (components_common::data_pointer), y
        iny
        sta (components_common::data_pointer), y
        bra @done
    @backspace:
        dec cursor_pos
        ; fall through to delete
    @delete:
        lda cursor_pos
        phy
        dey
        cmp (components_common::data_pointer), y ; compare with line length
        bcc :+
        ply
        rts
    :   ; proceed with deletion of character
        ldy cursor_pos
        @delete_loop:
            iny
            lda (v32b::entrypointer), y
            dey
            sta (v32b::entrypointer), y
            iny
            cmp #0
            bne @delete_loop
        ply
        lda cursor_pos
        sta (components_common::data_pointer), y
        dey
        ; new string length will be calculated in draw routine
        bra @done

    @done:
        ldy offset
        jmp draw
    
    @other:
        lda kbd_variables::current_key
        cmp #$60 ; cannot use characters above $60
        bcc :++
    :   rts
    :   cmp #$20
        bcc :--
        cmp #$40 ; can't display @ symbol
        beq :--

        ; compare input length with maximum string length (which is width - 1)
        dey
        lda (components_common::data_pointer), y
        inc
        dey
        dey
        dey
        cmp (components_common::data_pointer), y
        bcc :+
        rts
    :   ; make room for new character
        iny
        iny
        iny
        lda (components_common::data_pointer), y ; string length (and index of null-byte)
        phy
        tay
        iny
        @insert_loop:
            dey
            lda (v32b::entrypointer), y
            iny
            sta (v32b::entrypointer), y
            dey
            cpy cursor_pos
            bne @insert_loop
        ; insert new character
        lda kbd_variables::current_key
        jsr guiutils::petsciiToScreencode
        sta (v32b::entrypointer), y
        ; update cursor position
        tya
        inc
        ply
        iny
        sta (components_common::data_pointer), y
        bra @done
    .endproc
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_TEXT_EDIT_ASM
