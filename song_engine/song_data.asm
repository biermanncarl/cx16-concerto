; Copyright 2024-2025 Carl Georg Biermann

.ifndef ::SONG_ENGINE_SONG_DATA_ASM
::SONG_ENGINE_SONG_DATA_ASM = 1

.scope song_data
    .scope detail
        ; stealing some ZP variables, I hope that's fine with them
        .pushseg
            .zeropage
            ; We might be able to use some ZP variables from pre-parsing here if we don't use that functionality in this file.
            time_delta:
                .res 2
        .popseg

        ; Calculates the number of ticks in N bars.
        ; Expects the number of bars in .Y
        ; Returns number of ticks in time_delta
        .proc calculateLengthOfNBars
            ticks_one_bar = event_selection::temp_vector_y
            stz ticks_one_bar
            stz ticks_one_bar+1
            ldx timing::beats_per_bar
        @ticks_in_bar_loop: ; calculate number of ticks in one bar
            lda timing::detail::quarter_ticks
            clc
            adc ticks_one_bar
            sta ticks_one_bar
            bcc :+
            inc ticks_one_bar+1
        :   dex
            bne @ticks_in_bar_loop

            stz time_delta
            stz time_delta+1
        @ticks_in_n_bars_loop: ; multiply that by N
            lda time_delta
            clc
            adc ticks_one_bar
            sta time_delta
            lda time_delta+1
            adc ticks_one_bar+1
            sta time_delta+1
            dey
            bne @ticks_in_n_bars_loop
            rts
        .endproc

        ; Advances a given event pointer so that all events are skipped until either the time stamp doesn't match time_stamp_parameter
        ; or it isn't a note-off.
        ; (I.e. all note-offs at current time stamp are skipped)
        ; Expects event pointer in .A/.X/.Y
        ; Returns event pointer in .A/.X/.Y
        ; If no event exists past the current time stamp, carry is set. Clear otherwise.
        .proc skipNoteOffs
            temp_pointer = event_selection::temp_vector_y
            @skip_note_off_loop:
                sta temp_pointer
                stx temp_pointer+1
                sty temp_pointer+2
                jsr v5b::read_entry
                lda events::event_type
                bne @end_skip_note_off_loop
                lda events::event_time_stamp_l
                cmp timing::time_stamp_parameter
                bne @end_skip_note_off_loop
                lda events::event_time_stamp_h
                cmp timing::time_stamp_parameter+1
                bne @end_skip_note_off_loop
                ; it's note-off and still the same time stamp --> skip
                lda temp_pointer
                ldx temp_pointer+1
                ldy temp_pointer+2
                jsr v5b::get_next_entry
                bcc @skip_note_off_loop
            @end_skip_note_off_loop:
            lda temp_pointer
            ldx temp_pointer+1
            ldy temp_pointer+2
            rts
        .endproc


        ; Parses an event vector and appends the "effective" content (individual note-on, note-off or no-op for each note)
        ; at time time_stamp_parameter to vector squash_result.
        ; Expects the events to be squashed in squash_input
        ; squash_input is destroyed.
        ; If squash_result is empty, carry will be set and squash_result destroyed.
        ; Otherwise, carry will be clear and squash_result a valid event vector.
        .proc squashEventVector
            ; TODO: to speed this up, we might be able to reuse the fast pre-parsing code, but that will require some rework of existing code.
            ; Most important differences are that pre_parsing ignores leading note-offs and trailing note-ons.
            ; Furthermore, it has no means of tracking excess of note-off (i.e. a leading note-off).
            ; Therefore, for now, I'll make a slow but functional version with the v5b API.
            squash_input = event_selection::temp_vector_y
            squash_result = event_selection::temp_vector_x

            parity_counters = event_selection::pre_parsing::notes_active
            jsr event_selection::pre_parsing::clearActiveNotes

            ; Count #note-ons - #note-offs for each pitch, and remember the velocity
            lda squash_input
            ldx squash_input+1
            jsr v5b::get_first_entry
            @event_loop:
                pha
                phx
                phy
                jsr v5b::read_entry
                ldx events::note_pitch
                lda events::event_type
                beq @note_off
                cmp #events::event_type_note_on
                bne @goto_next_event
                @note_on:
                    lda parity_counters, x
                    and #%11000000 ; delete previous velocity, keep parity info
                    ora events::note_velocity ; add new velocity info
                    clc
                    adc #%01000000 ; note-on adds to parity
                    sta parity_counters, x
                    bra @goto_next_event
                @note_off:
                    lda parity_counters, x
                    sec
                    sbc #%01000000; note-off subtracts from parity
                    sta parity_counters, x
            @goto_next_event:
                ply
                plx
                pla
                jsr v5b::get_next_entry
                bcc @event_loop

            lda squash_input
            ldx squash_input+1
            jsr v5b::destroy

            ; parse results and create squashed vector
            jsr v5b::new
            sta squash_result
            stx squash_result+1
            ; All new events have the same time stamp
            lda timing::time_stamp_parameter
            sta events::event_time_stamp_l
            lda timing::time_stamp_parameter+1
            sta events::event_time_stamp_h
            ; Note-offs come first
            stz events::event_type ; note-off
            ldx #0
            @pitch_loop_1:
                lda parity_counters, x
                and #%11000000 ; isolate parity info
                bpl @goto_next_pitch_1
                stx events::note_pitch
                phx
                lda squash_result
                ldx squash_result+1
                jsr v5b::append_new_entry
                plx
            @goto_next_pitch_1:
                inx
                bne @pitch_loop_1

            ; Note-ons come second
            lda #events::event_type_note_on
            sta events::event_type
            ldx #0
            @pitch_loop_2:
                lda parity_counters, x
                and #%11000000 ; isolate parity info
                beq @goto_next_pitch_2
                bmi @goto_next_pitch_2
                lda parity_counters, x
                and #%00111111 ; isolate velocity info
                sta events::note_velocity
                stx events::note_pitch
                phx
                lda squash_result
                ldx squash_result+1
                jsr v5b::append_new_entry
                plx
            @goto_next_pitch_2:
                inx
                bne @pitch_loop_2

            lda squash_result
            ldx squash_result+1
            jsr v5b::is_empty
            bcc :+
            jsr v5b::destroy
            sec
        :   rts
        .endproc
    .endscope


    .proc changeSongTempo
        jsr clips::flushClip
        jsr timing::detail::recalculateTimingValues
        ; recalculate ALL time stamps (lossy for sub-1/32 values, and if events move beyond what is representable by 16 bits)
        ldy #0
    @clips_loop:
        phy
        jsr clips::getClipEventVector
        jsr v5b::get_first_entry
        bcs @events_loop_end
        @events_loop:
            pha
            phx
            phy
            jsr v5b::read_entry

            lda events::event_time_stamp_h
            ldx events::event_time_stamp_l
            jsr timing::disassemble_time_stamp
            ; handle residual ticks, crop to length of thirtysecondth note
            pha
            phx
            txa
            and #$07
            tax
            tya
            cmp timing::detail::new_timing::thirtysecondth_ticks, x
            bcc :+
            lda timing::detail::new_timing::thirtysecondth_ticks, x
        :   tay
            plx
            pla
            jsr timing::detail::assembleTimeStamp
            sta events::event_time_stamp_h
            stx events::event_time_stamp_l

            ; TODO: remove zero-tick length notes!
            ply
            plx
            pla
            pha
            phx
            phy
            jsr v5b::write_entry
            ply
            plx
            pla
            jsr v5b::get_next_entry
            bcc @events_loop
        @events_loop_end:
        ply
        iny
        cpy clips::number_of_clips
        bne @clips_loop

        jsr timing::detail::commitNewTiming
        rts
    .endproc

    .scope data_block_type
        ID_GENERATOR 0, none, clip
    .endscope

    ; Assumes that a file is opened for writing.
    ; Dumps all the song data into the file.
    .proc saveSong
        jsr clips::flushClip
        ; Fixed data size stuff
        ; ---------------------
        ; Song tempo
        lda song_engine::timing::beats_per_bar
        jsr CHROUT
        lda song_engine::timing::first_eighth_ticks
        jsr CHROUT
        lda song_engine::timing::second_eighth_ticks
        jsr CHROUT
        ; Instrument data
        jsr concerto_synth::instruments::dump_to_chrout

        ; Flexible data size stuff
        ; ------------------------

        ; Clip data
        ldy #0
    @clips_loop:
        phy
        lda #data_block_type::clip
        jsr CHROUT
        ply
        phy
        jsr clips::saveClipToFile
        ply
        iny
        cpy clips::number_of_clips
        bne @clips_loop

        ; TODO: other song data, such as song markers

        ; mark end of file
        lda #data_block_type::none
        jsr CHROUT
        rts
    .endproc
 
    ; Assumes that a file is opened for reading
    ; Loads all song data from the file
    .proc loadSong
        ; Fixed data size stuff
        ; ---------------------
        ; Song tempo
        jsr CHRIN
        sta song_engine::timing::detail::new_timing::beats_per_bar
        jsr CHRIN
        sta song_engine::timing::detail::new_timing::first_eighth_ticks
        jsr CHRIN
        sta song_engine::timing::detail::new_timing::second_eighth_ticks
        jsr song_engine::timing::detail::recalculateTimingValues
        jsr song_engine::timing::detail::commitNewTiming
        ; Instrument data
        jsr concerto_synth::instruments::restore_from_chrin

        ; Flexible data size stuff
        ; ------------------------
        ; Clip data
        jsr CHRIN ; ignore ... we know it must be #data_block_type::clip
        jsr clips::clearClips
        ldy #0
    @clips_loop:
        phy
        jsr clips::readClipFromFile
        jsr CHRIN ; check if there are more clips to read
        cmp #data_block_type::clip
        bne @clips_loop_end
        jsr clips::addClip
        ply
        iny
        bra @clips_loop
    @clips_loop_end:
        ply

        rts
    .endproc


    ; Inserts time at the current position of the playback start marker.
    ; Expects number of bars to insert in .Y
    .proc insertTime
        ; stealing some ZP variables, I hope that's fine with them
        temp_pointer = event_selection::temp_vector_y ; used inside calculateLengthOfNBars, so can only use it after that function is called.

        jsr detail::calculateLengthOfNBars

        ldy #0
    @clips_loop:
        phy
        jsr clips::getClipEventVector
        ldy multitrack_player::player_start_timestamp
        sty timing::time_stamp_parameter
        ldy multitrack_player::player_start_timestamp+1
        sty timing::time_stamp_parameter+1
        jsr event_selection::findEventAtTimeStamp
        bcs @continue
        
        ; lazy version first, using the v5b API. If that's too slow, we could work on the raw data directly.

        ; skip note-offs at the current time stamp (want to keep them on the left side of the newly formed time gap)
        jsr detail::skipNoteOffs
        bcs @continue

        ; shift events
        @shift_events_loop:
            sta temp_pointer
            stx temp_pointer+1
            sty temp_pointer+2
            jsr v5b::read_entry

            lda events::event_time_stamp_l
            clc
            adc detail::time_delta
            sta events::event_time_stamp_l
            lda events::event_time_stamp_h
            adc detail::time_delta+1
            sta events::event_time_stamp_h

            lda temp_pointer
            ldx temp_pointer+1
            ldy temp_pointer+2
            jsr v5b::write_entry

            lda temp_pointer
            ldx temp_pointer+1
            ldy temp_pointer+2
            jsr v5b::get_next_entry
            bcc @shift_events_loop
    @continue:
        ply
        iny
        cpy clips::number_of_clips
        bne @clips_loop

        rts
    .endproc


    ; Deletes time at the current position of the playback start marker.
    ; Expects number of bars to delete in .Y
    .proc deleteTime
        ; stealing some ZP variables, I hope that's fine with them
        temp_pointer = event_selection::next_event_b
        delete_interval_end = event_selection::next_event_a
        first_event_is_inside_interval = event_selection::most_recent_event_source

        jsr detail::calculateLengthOfNBars

        jsr clips::flushClip

        ; Calculate end of delete time interval
        lda multitrack_player::player_start_timestamp
        clc
        adc detail::time_delta
        sta delete_interval_end
        lda multitrack_player::player_start_timestamp+1
        adc detail::time_delta+1
        sta delete_interval_end+1

        ldy #0
    @clips_loop:
        phy
        jsr clips::getClipEventVector

        ; !! Spaghetti Code Alert !!

        ; Find first event inside (or after) the delete time interval
        ldy multitrack_player::player_start_timestamp
        sty timing::time_stamp_parameter
        ldy multitrack_player::player_start_timestamp+1
        sty timing::time_stamp_parameter+1
        jsr event_selection::findEventAtTimeStamp
        bcs @continue ; No event to be deleted, and nothing after the interval --> continue.
        ; Save pointer to first event within the delete time interval.
        sta temp_pointer
        stx temp_pointer+1
        sty temp_pointer+2

        ; Find first event after the delete time interval.
        ; Use the current event's chunk as starting point for the next search.
        tya ; converts an .A/.X/.Y event pointer into the B/H pointer to a chunk.
        ldy delete_interval_end
        sty timing::time_stamp_parameter
        ldy delete_interval_end+1
        sty timing::time_stamp_parameter+1
        jsr event_selection::findEventAtTimeStamp
        bcs @something_is_inside_interval ; nothing after interval's end. We can conclude from the fact that something comes after t1, and nothing after t2, that something is between t1 and t2.
        ; check if the first event after the delete interval is the same as the first after interval's start
        cmp temp_pointer
        bne @something_is_inside_interval
        cpx temp_pointer+1
        bne @something_is_inside_interval
        cpy temp_pointer+2
        bne @something_is_inside_interval
        ; pointers are the same --> there's nothing inside the interval, i.e. nothing to be deleted. But we need to shift the events after the interval.
        jsr shiftLeft
        bra @continue


    @something_is_inside_interval:
        stz first_event_is_inside_interval
        lda temp_pointer
        ldx temp_pointer+1
        ldy temp_pointer+2
        jsr v5b::is_first_entry
        bcc @delete_from_middle
        @delete_from_beginning:
            inc first_event_is_inside_interval
            tya
            bra @delete_common
        @delete_from_middle:
            jsr v5b::splitVectorBeforeEntry
            ; all good so far.
    @delete_common:
        jsr deleteUntilTime ; could be inlined again (only one place uses it)
        bcc @manage_second_part
        @no_second_part:
            lda first_event_is_inside_interval
            beq @continue  ; no events remain after the deleted time interval --> nothing to be shifted.
            ; The entire content got deleted. Need to create new one.
            jsr v5b::new
            sta temp_pointer+2
            stx temp_pointer+1
            bra @update_event_pointer
    @manage_second_part:
        ; Shift events after the deleted time interval.
        pha
        phx
        jsr v5b::get_first_entry
        jsr shiftLeft

        ; Concatenate the two vectors
        plx
        pla
        ldy first_event_is_inside_interval
        bne @update_event_pointer
        @first_part_still_exists:
            sta v5b::zp_pointer_2
            stx v5b::zp_pointer_2+1
            ; Load pointer to first part, which still remains at its original address.
            ply ; Get current clip id
            phy
            jsr clips::getClipEventVector
            jsr v5b::concatenateVectors
            bra @continue

        ; If we deleted from somewhere in the middle of the vector, the newly joint event vector still has the original starting address.
        ; On the other hand, deleting events directly from the beginning will end up changing the vector's start address.
        ; I choose not to preserve the pointer to the start of the vector, but rather update the clip's pointer if necessary.
        ; In that case, also the "unselected_events_vector" might need updating in case the currently selected clip is affected.
        @update_event_pointer:
            ply ; Get current clip id
            phy
            jsr clips::setClipEventPointer
            ; We'll update unselected_events_vector at the end of this function.
    @end_update_event_pointer:

    @continue:
        ply
        iny
        cpy clips::number_of_clips
        beq :+
        jmp @clips_loop
    :

        ; Re-load selected events pointer, clip data's location might have changed.
        ldy clips::active_clip_id
        jsr clips::loadClip
        rts

        ; Deletes all events in a vector up until the given timestamp.
        ; Expects the timestamp in time_stamp_parameter
        ; Expects the vector address in .A/.X
        ; Assumes that at least one event will be deleted.
        ; If new event vector exists, carry will be clear. Otherwise set.
        ; Returns the new vector address in .A/.X
        .proc deleteUntilTime
            sta detail::squashEventVector::squash_input
            stx detail::squashEventVector::squash_input+1
            jsr event_selection::findEventAtTimeStamp
            bcs @delete_until_end
            @delete_until_middle:
                jsr v5b::splitVectorBeforeEntry
                pha ; save latter half so we can glue it back on later
                phx
                jsr detail::squashEventVector
                bcs @no_squash_1 ; is squashed vector empty (non-existent) ?
                @glue_end_on_squash:
                    lda detail::squashEventVector::squash_result
                    ldx detail::squashEventVector::squash_result+1
                    ply
                    sty v5b::zp_pointer_2+1
                    ply
                    sty v5b::zp_pointer_2
                    jsr v5b::concatenateVectors
                    bra @load_squash_result
                @no_squash_1:
                    plx
                    pla
                    clc
                    rts
            @delete_until_end:
                jsr detail::squashEventVector
                bcc @load_squash_result
                @deleted_whole_vector:
                    ; sec ; carry is already set
                    rts
            @load_squash_result:
                lda detail::squashEventVector::squash_result
                ldx detail::squashEventVector::squash_result+1
                clc
                rts
        .endproc

        ; Shifts the given and all subsequent events to the left.
        .proc shiftLeft
            @shift_events_loop:
                pha
                phx
                phy
                jsr v5b::read_entry

                lda events::event_time_stamp_l
                sec
                sbc detail::time_delta
                sta events::event_time_stamp_l
                lda events::event_time_stamp_h
                sbc detail::time_delta+1
                sta events::event_time_stamp_h

                ply
                plx
                pla
                pha
                phx
                phy
                jsr v5b::write_entry

                ply
                plx
                pla
                jsr v5b::get_next_entry
                bcc @shift_events_loop
            rts
        .endproc
    .endproc
.endscope

.endif ; .ifndef SONG_ENGINE_SONG_DATA_ASM