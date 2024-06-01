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
        ; modifier keys status
        jsr KBDBUF_GET_MODIFIERS
        pha
        and #KBD_MODIFIER_CTRL
        sta dnd::ctrl_key_pressed
        pla
        and #KBD_MODIFIER_SHIFT
        sta dnd::shift_key_pressed

        jmp dnd::dragables::notes::doDrag
    .endproc

    .proc initialize
        ; create vectors for temporary event storage
        jsr v40b::new
        sta dnd::temp_events
        stx dnd::temp_events+1
        jsr v40b::new
        sta dnd::clipboard_events
        stx dnd::clipboard_events+1
        ; just for testing
        jsr dnd::dragables::notes::setup_test_clip
        rts
    .endproc

.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_DRAG_AND_DROP_AREA_ASM
