; Copyright 2023-2024 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_DRAG_AND_DROP_AREA_ASM

::GUI_COMPONENTS_COMPONENTS_DRAG_AND_DROP_AREA_ASM = 1

; Drag and drop areas contain a variable number of editable items,
; which can be moved around via drag and drop.
; The drag and drop functionality is tailored towards the needs of
; editing notes, effects and clips in arrangement views.
; This component serves as glue code between the normal GUI code and
; the algorithms that operate on the notes, effects and clips data.

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

    .scope detail
        ; by putting these variables in here (globally), we assume there can be only one scrolling operation going on at any one time
        accumulated_x:
            .byte 0
        accumulated_y:
            .byte 0
        
        ; Vectors for processing events
        temp_events:
            .res 2
        clipboard_events:
            .res 2
        
        ; Keyboard modifiers
        ctrl_key_pressed:
            .byte 0
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


    ; If the mouse is inside the editing area, carry will be set, otherwise clear.
    ; If the mouse touches a dragable object,
    ; * mouse_variables::curr_data_1 will contain hitbox_handle::bulk or hitbox_handle::right_end depending on where it is
    ; * mouse_variables::curr_data_2 and _3 will contain the id of the hitbox (curr_data_3's MSB signals whether the hitbox is a selected or unselected one)
    ; and if not, mouse_variables::curr_data_1 will contain hitbox_handle::none.
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
        ; TODO: implement right_handle !
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
        ; TODO: implementation of notes/effects/clips jump table (needed?)
        ; This is somewhat a "drag_end" operation -- not sure if we need it?
        lda mouse_variables::curr_data_1
        bne :+ ; clicked any hitbox?
        rts
    :
        ; TODO
        rts
    .endproc

    .proc event_drag
        .scope drag_action
            ID_GENERATOR 0, none, scroll, zoom, box_select, drag, resize
        .endscope

        ; preparations
        SET_SELECTED_VECTOR dnd::dragables::notes::selected_events_vector
        SET_UNSELECTED_VECTOR dnd::dragables::notes::unselected_events_vector
        ; CTRL key status
        jsr KBDBUF_GET_MODIFIERS
        and #KBD_MODIFIER_CTRL
        sta detail::ctrl_key_pressed

        lda mouse_variables::drag_start
        bne @drag_start ; TODO: make this a sub routine (so that RTS goes to drag_continue)
        jmp @drag_continue
    @drag_start:
        ; start of a dragging operation. figure out what we're actually doing
        lda mouse_variables::curr_buttons
        and #1 ; check for left button
        bne @left_button
        lda mouse_variables::curr_buttons
        and #2 ; check for right button
        beq :+
        jmp @right_button
    :   lda mouse_variables::curr_buttons
        and #4 ; check for middle button
        beq :+
        jmp @middle_button
    :   stz drag_action_state ; #drag_action::none
        rts
    @left_button:
        ; LMB down: mostly selection / unselection stuff
        inc gui_variables::request_components_redraw
        lda mouse_variables::curr_data_1
        bne @lmb_no_event_clicked ; no event clicked? -> unselect all, start box selection
            lda detail::ctrl_key_pressed
            bne :+ ; if CTRL is pressed, skip unselection of all
                jsr dnd::dragables::item_selection::unSelectAllEvents
            :
            ; TODO: implement box selection
            ; lda #drag_action::box_select
            lda #drag_action::none
            sta drag_action_state
            rts
        @lmb_no_event_clicked:
            lda mouse_variables::curr_data_2
            sta v40b::value_0
            lda mouse_variables::curr_data_3
            sta v40b::value_1
            bmi @already_selected
            @not_yet_selected:
                lda detail::ctrl_key_pressed
                beq :+
                ; CTRL was pressed --> allow multiple selection
                SET_SELECTED_VECTOR dnd::dragables::notes::selected_events_vector
                jsr dnd::dragables::notes::detail::getEntryFromHitboxObjectId
                jsr dnd::dragables::item_selection::selectEvent
                rts
            :
                ; event wasn't selected yet --> we want to unselect all, and select the clicked-at one
                ; This is difficult because the moment we unselect all events, the pointer to the clicked-at event becomes unusable.
                ; Therefore, we first need to select the clicked-at event into temp, before unselecting all others.
                SET_SELECTED_VECTOR detail::temp_events
                jsr dnd::dragables::notes::detail::getEntryFromHitboxObjectId
                jsr dnd::dragables::item_selection::selectEvent
                SET_SELECTED_VECTOR dnd::dragables::notes::selected_events_vector
                jsr dnd::dragables::item_selection::unSelectAllEvents
                ; now, swap selected with temp vector, as they have the correct contents already
                SWAP_VECTORS detail::temp_events, dnd::dragables::notes::selected_events_vector
                rts
            @already_selected:
                lda detail::ctrl_key_pressed
                beq :+
                SET_SELECTED_VECTOR dnd::dragables::notes::selected_events_vector
                jsr dnd::dragables::notes::detail::getEntryFromHitboxObjectId
                jsr dnd::dragables::item_selection::unselectEvent
            :   rts

        rts
    @right_button:
        lda mouse_variables::curr_data_1
        beq @scroll ; only scroll when the mouse did not point at any note (?)
        stz drag_action_state ; #drag_action::none
        rts
    @middle_button:
        lda #drag_action::zoom
        sta drag_action_state
        bra @drag_continue
    @scroll:
        lda #drag_action::scroll
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
        .word doScroll
        .word doZoom

    
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
    .endproc

    .proc doScroll
        ; y coordinate
        lda mouse_variables::delta_y
        ldy detail::ctrl_key_pressed
        beq :+
        asl ; multiply by 4 for fast scrolling when CTRL is pressed
        asl
    :   clc
        adc detail::accumulated_y
        jsr signedDivMod8
        sty detail::accumulated_y
        tax
        ; x coordinate
        lda mouse_variables::delta_x
        ldy detail::ctrl_key_pressed
        beq :+
        asl ; fast scrolling
        asl
    :   clc
        adc detail::accumulated_x
        jsr signedDivMod8
        sty detail::accumulated_x

        ; check if we actually do anything
        cmp #0
        bne @do_scroll
        cpx #0
        bne @do_scroll
        rts
    @do_scroll:
        inc gui_variables::request_components_redraw
        jmp dnd::dragables::notes::doScrollNormal ; TODO: jump to hitbox type specific scroll routine
    .endproc

    .proc doZoom
        ; y coordinate
        lda mouse_variables::delta_y
        clc
        adc detail::accumulated_y
        jsr signedDivMod8
        sty detail::accumulated_y

        cmp #0
        bne @do_zoom
        rts
    @do_zoom:
        inc gui_variables::request_components_redraw
        jmp dnd::dragables::notes::doZoom
    .endproc

    .proc initialize
        ; create vectors for temporary event storage
        jsr v40b::new
        sta detail::temp_events
        stx detail::temp_events+1
        jsr v40b::new
        sta detail::clipboard_events
        stx detail::clipboard_events+1
        ; just for testing
        jsr dnd::dragables::notes::setup_test_clip
        rts
    .endproc

.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_DRAG_AND_DROP_AREA_ASM
