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
    ; * mouse_variables::curr_data_2 to _5 will contain information about the corresponding event,
    ; and if not, mouse_variables::curr_data_1 will contain hitbox_handle::none.
    .proc check_mouse
        temp_zp = gui_variables::mzpbf
        ; This is basically a "mouse is inside box" check with variable width and height.
        ; Get dragable type
        lda (components_common::data_pointer), y
        sta dnd::dragables::active_type
        tax
        ; check x direction
        lda mouse_variables::curr_x_downscaled
        sec
        sbc dnd::dragables::edit_positions_x, x ; now we have the distance of the mouse pointer to the left side of the hitbox
        ; now A must be smaller than the hitbox' width.
        cmp dnd::dragables::edit_width, x
        bcc @horizontal_in
    @out:
        clc
        rts
    @horizontal_in:  ; we're in
        ; check y direction
        lda mouse_variables::curr_y_downscaled
        sec
        sbc dnd::dragables::edit_positions_y, x
        cmp dnd::dragables::edit_height, x
        bcs @out
        ; Mouse pointer is inside the editing area.

        ; Doing hitbox detection ...
        jsr dnd::hitboxes::load_hitbox_list
        jsr v5b::get_first_entry
        bcs @no_hit
    @loop:
        pha
        phx
        phy
        jsr v5b::read_entry
        ; Check Y coordinate
        ; calculate relative position of the mouse to the hitbox
        ldy dnd::dragables::active_type
        lda mouse_variables::curr_y_downscaled
        sec
        sbc dnd::hitboxes::hitbox_pos_y
        ; should be less than the hitbox height
        cmp dnd::dragables::hitbox_heights, y
        bcs @continue
        ; Check X coordinate (same formulas as above)
        lda mouse_variables::curr_x_downscaled
        sec
        sbc dnd::hitboxes::hitbox_pos_x
        inc ; increment so we can distinguish right end, but that means zero isn't inside anymore
        beq @continue
        cmp dnd::hitboxes::hitbox_width
        beq @hit_right_end
        bcc @hit_bulk
        ; .A is neither equal to nor smaller than hitbox width - 1 --> no hit
    @continue:
        ply
        plx
        pla
        jsr v5b::get_next_entry ; skip the entry with event pointer
        jsr v5b::get_next_entry
        bcc @loop
    @no_hit:
        stz mouse_variables::curr_data_1 ; dnd::hitboxes::hitbox_handle::none
        sec
        rts

        ; We got a hit!
    @hit_right_end:
        lda #dnd::hitboxes::hitbox_handle::right_end
        bra @set_event_pointer
    @hit_bulk:
        lda #dnd::hitboxes::hitbox_handle::bulk
    @set_event_pointer:
        sta mouse_variables::curr_data_1 ; signal that the mouse does point at a hitbox
        ply
        plx
        pla
        jsr v5b::get_next_entry
        jsr v5b::read_entry
        ; load the hitbox the mouse points at into mouse registers
        lda dnd::hitboxes::hitbox_event_a
        sta mouse_variables::curr_data_2
        lda dnd::hitboxes::hitbox_event_x
        sta mouse_variables::curr_data_3
        lda dnd::hitboxes::hitbox_event_y
        sta mouse_variables::curr_data_4
        lda dnd::hitboxes::hitbox_event_selected
        sta mouse_variables::curr_data_5
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

    .proc doPlayerUpdate
        lda dnd::dragables::notes::note_data_changed
        beq @end
        lda #0
        jsr song_engine::multitrack_player::updateTrackPlayer
        lda song_engine::clips::active_clip_id
        inc
        jsr song_engine::multitrack_player::updateTrackPlayer
    @end:
        rts
    .endproc

    .proc event_drag
        php
        sei
        jsr dnd::dragables::notes::doDrag
        jsr doPlayerUpdate
        plp
        rts
    .endproc


    .proc end_drag_event
        php
        sei
        jsr dnd::dragables::notes::doDragEnd
        jsr doPlayerUpdate
        plp
        rts
    .endproc

    .proc initialize
        lda #4
        sta song_engine::timing::detail::new_timing::beats_per_bar
        lda #30
        sta song_engine::timing::detail::new_timing::first_eighth_ticks
        sta song_engine::timing::detail::new_timing::second_eighth_ticks
        jsr song_engine::timing::detail::recalculateTimingValues
        jsr song_engine::timing::detail::commitNewTiming
        ; create vectors for temporary event storage
        jsr v5b::new
        sta dnd::temp_events
        stx dnd::temp_events+1
        jsr v5b::new
        sta dnd::clipboard_events
        stx dnd::clipboard_events+1
        ; create unselected vector isn't needed because that is given by the clip data
        ; create selected vector
        jsr v5b::new
        sta song_engine::event_selection::selected_events_vector
        stx song_engine::event_selection::selected_events_vector+1
        rts
    .endproc

.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_DRAG_AND_DROP_AREA_ASM
