; Copyright 2024 Carl Georg Biermann

.ifndef ::SONG_ENGINE_SONG_DATA_ASM
::SONG_ENGINE_SONG_DATA_ASM = 1

.scope song_data

    .proc changeSongTempo
        jsr event_selection::unselectAllEvents
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

.endscope

.endif ; .ifndef SONG_ENGINE_SONG_DATA_ASM