; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_CLIP_PROPERTIES_ASM

::GUI_PANELS_PANELS_CLIP_PROPERTIES_ASM = 1

.include "../../gui_macros.asm"
.include "common.asm"

.scope clip_properties
    px = 62
    py = 1
    wd = 15
    hg = 22

    comps:
    .scope comps
        COMPONENT_DEFINITION listbox, track_select, px, py, 10, 14, A 0, 0, 0, 1
        COMPONENT_DEFINITION drag_edit, instrument_sel, px+11, py+17, 0, 0, 31, 0, 0 ; TODO make nicer (ideally with named instruments, and combobox or similar)
        COMPONENT_DEFINITION checkbox, monophonic, px, py+19, 12, 0
        COMPONENT_DEFINITION checkbox, drum_pad, px, py+21, 10, 0
        COMPONENT_DEFINITION button, track_name, px, py+14, 10, A panel_common::lb_track_name
        COMPONENT_DEFINITION button, new_track, px+11, py+2, 6, A lb_new
        COMPONENT_DEFINITION button, del_track, px+11, py+4, 6, A lb_delete ; deserves an ok-cancel popup
        COMPONENT_DEFINITION button, move_up, px+11, py+6, 6, A lb_up ; maybe replace by drag&drop later?
        COMPONENT_DEFINITION button, move_dn, px+11, py+8, 6, A lb_down
        COMPONENT_LIST_END
    .endscope

    capts:
        .byte CCOLOR_CAPTION, px, py+17
        .word panel_common::lb_instrument
        .byte CCOLOR_CAPTION, px+2, py+19
        .word lb_mono
        .byte CCOLOR_CAPTION, px+2, py+21
        .word lb_drum
        .byte 0

    lb_mono: STR_FORMAT "monophonic"
    lb_drum: STR_FORMAT "drum pad"
    lb_new: STR_FORMAT " new"
    lb_delete: STR_FORMAT "delete"
    lb_up: STR_FORMAT "  up"
    lb_down: STR_FORMAT " down"

    .proc draw
        lda song_engine::clips::clips_vector
        ldx song_engine::clips::clips_vector+1
        sta comps::track_select + components::listbox::data_members::string_pointer
        stx comps::track_select + components::listbox::data_members::string_pointer+1
        rts
    .endproc

    .proc selectTrack
        ; move all events back into the clip
        php
        sei
        jsr song_engine::event_selection::unselectAllEvents
        ldy song_engine::clips::active_clip_id
        jsr song_engine::clips::accessClip
        ldy #song_engine::clips::clip_data::event_ptr
        lda song_engine::event_selection::unselected_events_vector
        sta (v32b::entrypointer),y
        iny
        lda song_engine::event_selection::unselected_events_vector+1
        sta (v32b::entrypointer),y

        ; update playback
        ; We need to update the track that is being unselected, as well as the "selection player"
        lda song_engine::clips::active_clip_id
        inc
        jsr song_engine::multitrack_player::updateTrackPlayer
        lda #0
        jsr song_engine::multitrack_player::updateTrackPlayer

        ; update to new clip
        LDA_COMPONENT_MEMBER_ADDRESS listbox, track_select, selected_entry
        bpl :+
        ; invalid entry, select last track
        LDA_COMPONENT_MEMBER_ADDRESS listbox, track_select, valid_entries
        dec
        STA_COMPONENT_MEMBER_ADDRESS listbox, track_select, selected_entry
    :   sta song_engine::clips::active_clip_id
        jsr refresh ; calls accessClip on new clip, so we don't have to.
        ; move events of new clip into the GUI
        ldy #song_engine::clips::clip_data::event_ptr
        lda (v32b::entrypointer),y
        sta song_engine::event_selection::unselected_events_vector
        iny
        lda (v32b::entrypointer),y
        sta song_engine::event_selection::unselected_events_vector+1
        plp
        jmp gui_routines__draw_gui
    .endproc

    .proc write
        ldy song_engine::clips::active_clip_id
        jsr song_engine::clips::accessClip

        lda mouse_variables::curr_component_id
        asl
        tax
        jmp (@jmp_tbl, x)
    @jmp_tbl:
        .word selectTrack
        .word @instrument
        .word @mono
        .word @drum_pad
        .word @track_name
        .word @new_track
        .word @del_track
        .word @move_up
        .word @move_down
    @instrument:
        LDA_COMPONENT_MEMBER_ADDRESS drag_edit, instrument_sel, coarse_value
        ldy #song_engine::clips::clip_data::instrument_id
        sta (v32b::entrypointer), y
        sta gui_variables::current_synth_instrument
        rts
    @mono:
        LDA_COMPONENT_MEMBER_ADDRESS checkbox, monophonic, checked
        ldy #song_engine::clips::clip_data::monophonic
        sta (v32b::entrypointer), y
        rts
    @drum_pad:
        LDA_COMPONENT_MEMBER_ADDRESS checkbox, drum_pad, checked
        ldy #song_engine::clips::clip_data::drum_pad
        sta (v32b::entrypointer), y
        rts
    @track_name:
        ; set string pointer to clip name
        lda RAM_BANK
        sta track_name_popup::string_address
        lda v32b::entrypointer+1
        sta track_name_popup::string_address+1
        ; TODO: factor out the GUI stack operation
        ldx panels__panels_stack_pointer
        lda #panels__ids__track_name_popup
        sta panels__panels_stack, x
        inc panels__panels_stack_pointer
        jsr gui_routines__draw_gui
        rts
    @new_track:
        jsr song_engine::multitrack_player::stopPlayback
        jsr song_engine::clips::addClip
        inc gui_variables::request_components_redraw
        rts
    @del_track:
        jsr song_engine::multitrack_player::stopPlayback
        ; TODO: popup "are you sure?"
        lda song_engine::clips::number_of_clips
        cmp #1
        beq @end_delete ; don't delete if there's only one track left
            ; unselect the track to be deleted
            lda song_engine::clips::active_clip_id
            pha ; remember the track
            beq :+
                dec
                bra :++
            :   inc
            :   STA_COMPONENT_MEMBER_ADDRESS listbox, track_select, selected_entry
            jsr selectTrack
            ply ; recall track to be deleted
            phy
            jsr song_engine::clips::getClipEventVector
            jsr v5b::destroy
            lda song_engine::clips::clips_vector
            ldx song_engine::clips::clips_vector+1
            ply ; recall the track to be deleted
            jsr dll::getElementByIndex
            jsr dll::delete_element
            dec song_engine::clips::number_of_clips
            ; Now need to update unselected_events_vector, since we might have invalidated the current pointer
            ldy song_engine::clips::active_clip_id
            jsr song_engine::clips::getClipEventVector
            sta song_engine::event_selection::unselected_events_vector
            stx song_engine::event_selection::unselected_events_vector+1
            jmp gui_routines__draw_gui
        @end_delete:
        rts
    @move_up:
        jsr song_engine::multitrack_player::stopPlayback
        ldy song_engine::clips::active_clip_id
        beq @end_move_up
            ; TODO: swap two clips (need new DLL function for that)
            jmp gui_routines__draw_gui
        @end_move_up:
        rts
    @move_down:
        jsr song_engine::multitrack_player::stopPlayback
        ; TODO
        rts
    .endproc


    .proc refresh
        ldy song_engine::clips::active_clip_id
        STY_COMPONENT_MEMBER_ADDRESS listbox, track_select, selected_entry
        jsr song_engine::clips::accessClip
        ldy #song_engine::clips::clip_data::instrument_id
        lda (v32b::entrypointer), y
        STA_COMPONENT_MEMBER_ADDRESS drag_edit, instrument_sel, coarse_value
        sta gui_variables::current_synth_instrument ; Load the clip's instrument in the synth UI, too
        iny ; monophonic id
        lda (v32b::entrypointer), y
        STA_COMPONENT_MEMBER_ADDRESS checkbox, monophonic, checked
        iny ; drum pad
        lda (v32b::entrypointer), y
        STA_COMPONENT_MEMBER_ADDRESS checkbox, drum_pad, checked
        rts
    .endproc

    keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_CLIP_PROPERTIES_ASM
