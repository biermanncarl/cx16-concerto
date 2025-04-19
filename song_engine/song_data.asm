; Copyright 2024 Carl Georg Biermann

.ifndef ::SONG_ENGINE_SONG_DATA_ASM
::SONG_ENGINE_SONG_DATA_ASM = 1

.scope song_data
    .scope detail
        ; stealing some ZP variables, I hope that's fine with them
        time_delta = event_selection::temp_vector_x

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
            bcs @continue
            bra @skip_note_off_loop
        @end_skip_note_off_loop:

        ; shift events
        lda temp_pointer
        ldx temp_pointer+1
        ldy temp_pointer+2
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
.endscope

.endif ; .ifndef SONG_ENGINE_SONG_DATA_ASM