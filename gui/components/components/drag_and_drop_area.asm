; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_DRAG_AND_DROP_AREA_ASM

::GUI_COMPONENTS_COMPONENTS_DRAG_AND_DROP_AREA_ASM = 1

; Drag and drop areas contain a variable number of editable items,
; which can be moved around via drag and drop.
; The drag and drop functionality is tailored towards the needs of
; editing notes, effects and clips in arrangement views.
; This component serves as glue code between the normal GUI code and
; the 

.include "common.asm"
.include "../../drag_and_drop/drag_and_drop.asm"
.include "../../gui_macros.asm"

.scope drag_and_drop_area
    .struct data_members
        ; One of the dragables::ids
        type .byte ; there can only be one area of each type. Most of their respective properties are hard coded.
    .endstruct

    .scope hitbox_handle
        none = 0
        bulk = 1
        right_end = 2
    .endscope
 
    .proc draw
        ; Todo: switch on type
        phy
        lda (components_common::data_pointer), y
        asl
        tax
        INDEXED_JSR dnd::dragables::jump_table_draw, @return_addr
    @return_addr:
        ply
        iny
        rts
    .endproc

    .proc check_mouse
        temp_zp = gui_variables::mzpbf
        ; This is basically a "mouse is inside box" check with variable width and height.
        ; Get dragable type
        lda (components_common::data_pointer), y
        sta dnd::dragables::active_type
        tax
        ; check x direction
        lda components_common::mouse_downscaled_x
        sec
        sbc dnd::dragables::edit_positions_x, x ; now we have the distance of the mouse pointer to the left side of the checkbox
        ; now A must be smaller than the checkbox' width.
        cmp dnd::dragables::edit_width, x
        bcc @horizontal_in
    @out:
        clc
        rts
    @horizontal_in:  ; we're in
        ; check y direction
        lda components_common::mouse_downscaled_y
        sec
        sbc dnd::dragables::edit_positions_y, x
        cmp dnd::dragables::edit_height, x
        bcs @out
        ; We're in.

        ; Doing hitbox detection ...
        jsr dnd::hitboxes::load_hitbox_list
        jsr v40b::get_first_entry
        bcs @no_hit
    @loop:
        pha
        phx
        phy
        jsr v40b::read_entry
        ; Check Y coordinate
        ; calculate relative position of the mouse to the hitbox
        ldy dnd::dragables::active_type
        lda components_common::mouse_downscaled_y
        sec
        sbc dnd::hitboxes::hitbox_pos_y
        ; should be less than the hitbox height
        cmp dnd::dragables::hitbox_heights, y
        bcs @continue
        ; Check X coordinate (same formulas as above)
        lda components_common::mouse_downscaled_x
        sec
        sbc dnd::hitboxes::hitbox_pos_x
        cmp dnd::hitboxes::hitbox_width
        bcs @continue
        ; We got a hit!
        ; tidy up the stack
        ply
        plx
        pla
        ; load the hitbox the mouse points at into mouse registers
        lda #hitbox_handle::bulk
        sta mouse_variables::curr_data_1 ; signal that the mouse does point at a hitbox
        lda dnd::hitboxes::object_id_l
        sta mouse_variables::curr_data_2
        lda dnd::hitboxes::object_id_h
        sta mouse_variables::curr_data_3
        sec
        rts

    @continue:
        ply
        plx
        pla
        jsr v40b::get_next_entry
        bcc @loop
    @no_hit:
        stz mouse_variables::curr_data_1 ; hitbox_handle::none
        sec
        rts
    .endproc

    .proc event_click
        lda mouse_variables::curr_data_1
        bne :+
        rts
    :
        ; for now, remove the note as a quick test
        lda mouse_variables::curr_data_2
        sta v40b::value_0
        lda mouse_variables::curr_data_3
        sta v40b::value_1
        jsr dnd::dragables::notes::detail::getEntryFromHitboxObjectId
        pha
        phx
        phy
        jsr dnd::dragables::notes::detail::findNoteOff
        jsr v40b::delete_entry
        ply
        plx
        pla
        jsr v40b::delete_entry
        inc gui_variables::request_components_redraw
        rts
    .endproc

    .proc event_drag
        .scope drag_action
            ID_GENERATOR 0, none, scroll_normal, scroll_fast, zoom, box_select, drag, resize
        .endscope

        lda mouse_variables::drag_start
        beq @drag_continue
    @drag_start:
        ; start of a dragging operation. figure out what we're actually doing
        lda mouse_variables::curr_buttons
        and #2 ; check for right button
        bne @right_button
        stz drag_action_state ; #drag_action::none
        rts
    @right_button:
        ;.byte $db
        lda mouse_variables::curr_data_1
        beq @scroll
        stz drag_action_state ; #drag_action::none
        rts
    @scroll:
        lda #drag_action::scroll_normal
        sta drag_action_state
        bra @drag_continue
    
    ; do the actual drag operation
    @drag_continue:
        lda drag_action_state
        asl
        tax
        jmp (@jump_table_drag, x)
    @jump_table_drag:
        .word components_common::dummy_subroutine ; none
        .word doScrollNormal

    drag_action_state:
        .byte 0 ; by putting this variable in here, we assume there can be only one dragging operation going on at the same time
    .endproc

    ; Do a signed division by 8 and modulo 8 operation on the argument in .A.
    ; Returns the quotient in .A and the remainder in .Y.
    ; Preserves .X
    .proc signedDivMod8
        pha
        and #7
        tay
        pla
        clc
        adc #128
        lsr
        lsr
        lsr
        sec
        sbc #128/8
        rts
        ; pha
        ; cmp #0
        ; bmi @negative
    ; @positive:
        ; and #7
        ; tay
        ; pla
        ; lsr
        ; lsr
        ; lsr
        ; rts
    ; @negative:
        ; and #7
        ; ora #%11111000
        ; tay
        ; pla
        ; lsr
        ; lsr
        ; lsr
        ; ora #%11100000
        ; rts
    .endproc

    .proc doScrollNormal
        ; y coordinate
        lda mouse_variables::delta_y
        clc
        adc accumulated_y
        jsr signedDivMod8
        sty accumulated_y
        tax
        ; x coordinate
        lda mouse_variables::delta_x
        clc
        adc accumulated_x
        jsr signedDivMod8
        sty accumulated_x

        ; check if we actually do anything
        cmp #0
        bne @do_scroll
        cpx #0
        bne @do_scroll
        rts
    @do_scroll:
        inc gui_variables::request_components_redraw
        jmp dnd::dragables::notes::doScrollNormal ; TODO: jump to hitbox type specific scroll routine
    
    ; by putting this variable in here, we assume there can be only one scrolling operation going on at any one time
    accumulated_x:
        .byte 0
    accumulated_y:
        .byte 0
    .endproc
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_DRAG_AND_DROP_AREA_ASM
