; Copyright 2024 Carl Georg Biermann

.ifndef ::SONG_ENGINE_MULTITRACK_PLAYER_ASM
::SONG_ENGINE_MULTITRACK_PLAYER_ASM = 1

.scope multitrack_player

player_start_timestamp:
    .word 0

.scope detail
    active: .byte 0
    time_stamp: .word 0
    next_time_stamp: .word 0
    next_event: .res 3

    ; Which voice belongs to which channel
    voice_channels:
        .res N_VOICES

    temp_variable_a:
        .byte 0
    temp_variable_b:
        .byte 0
    temp_variable_c:
        .byte 0

    ; state for each event player
    ; player with index 0 is for the currently selected events, players 1-MAX are the clips (and the unselected events of the currently edited clip)
    num_players = MAX_TRACKS + 1 ; we need one extra player for the selected events in the current clip edit view
    next_event_timestamp_l:
        .res num_players
    next_event_timestamp_h:
        .res num_players
    next_event_pointer_a:
        .res num_players
    next_event_pointer_x:
        .res num_players
    next_event_pointer_y: ; this variable doubles as the "active" switch. If zero (NULL pointer), the player is inactive.
        .res num_players
    clip_settings_a:
        .res num_players
    clip_settings_x:
        .res num_players

    ; if no more events available, carry is set upon return
    .proc getNextEventAndTimeStamp
        jsr event_selection::streamGetNextEvent
        bcc :+
        ; loop back to beginning
        stz time_stamp
        stz time_stamp+1
        jsr event_selection::resetStream
        jsr event_selection::streamGetNextEvent
        bcc :+
        ; if we still don't get any new events, there are none. deactivate player
        stz active
        rts
    :   sta next_event
        stx next_event+1
        sty next_event+2
        jsr v5b::read_entry
        lda events::event_time_stamp_l
        sta next_time_stamp
        lda events::event_time_stamp_h
        sta next_time_stamp+1
        clc
        rts
    .endproc

    ; Looks through the 16 voices and tries to find a free one.
    ; Returns the index of the voice in .X
    ; If no voice was found, carry will be set, otherwise clear.
    .proc findFreeVoice
        ldx #0
    @voice_loop:
        lda concerto_synth::voices::Voice::active,x
        beq @voice_found
        inx
        cpx #N_VOICES
        bcc @voice_loop
        rts ; end of voices reached, carry is set as per previous jump condition
    @voice_found:
        clc
        rts
    .endproc

    ; Given a channel and pitch, finds an active voice which matches these (used for polyphonic tracks).
    ; .A : channel
    ; .Y : pitch
    ; Returns voice index in .X
    ; If no voice was found, carry will be set, otherwise clear.
    ; TODO: also look for instrument id (support drum pad)
    .proc findVoiceChannelPitch
        channel = detail::temp_variable_b
        sta channel
        ldx #255
    @voice_loop:
        inx
        cpx #N_VOICES
        bcs @not_found
        lda concerto_synth::voices::Voice::active,x
        beq @voice_loop ; voice inactive, go to next
        lda channel
        cmp voice_channels,x
        bne @voice_loop ; not the channel we are looking for, go to next
        tya
        cmp concerto_synth::voices::Voice::pitch,x
        bne @voice_loop ; not the same pitch that is playing, go to next
    @voice_found:
        clc
    @not_found:
        rts
    .endproc

    ; Given a channel, finds an active voice on it (used for monophonic tracks).
    ; .A : channel
    ; Returns voice index in .X
    ; If no voice was found, carry will be set, otherwise clear.
    .proc findVoiceChannel
        tay
        ldx #255
    @voice_loop:
        inx
        cpx #N_VOICES
        bcs @not_found
        lda concerto_synth::voices::Voice::active, x
        beq @voice_loop ; voice inactive, go to next
        tya
        cmp voice_channels,x
        bne @voice_loop ; not the channel we are looking for, go to next
    @voice_found:
        clc
    @not_found:
        rts
    .endproc

    ; Given a channel, pitch and instrument, finds an active voice which matches these (used for drum pad tracks).
    ; .A : channel
    ; .X : instrument
    ; .Y : pitch
    ; Returns voice index in .X
    ; If no voice was found, carry will be set, otherwise clear.
    ; TODO: also look for instrument id (support drum pad)
    .proc findVoiceChannelPitchInstrument
        channel = detail::temp_variable_b
        instrument = detail::temp_variable_c
        sta channel
        stx instrument
        ldx #255
    @voice_loop:
        inx
        cpx #N_VOICES
        bcs @not_found
        lda concerto_synth::voices::Voice::active,x
        beq @voice_loop ; voice inactive, go to next
        lda channel
        cmp voice_channels, x
        bne @voice_loop ; not the channel we are looking for, go to next
        lda instrument
        cmp concerto_synth::voices::Voice::instrument, x
        bne @voice_loop
        tya
        cmp concerto_synth::voices::Voice::pitch, x
        bne @voice_loop ; not the same pitch that is playing, go to next
    @voice_found:
        clc
    @not_found:
        rts
    .endproc

    ; Sets up event pointer and time stamp for playback on a given track.
    ; Expects pointer to event vector (B/H) in .A/.X
    ; Expects index of player in .Y
    .proc startPlabackOnTrack
        track_index = detail::temp_variable_a
        temp = detail::temp_variable_b
        sty track_index
        jsr v5b::get_first_entry
        bcs :+ ; skip empty tracks
            stx temp
            ldx track_index
            sta detail::next_event_pointer_a, x
            pha
            tya
            sta detail::next_event_pointer_y, x
            lda temp
            sta detail::next_event_pointer_x, x
            pla
            ldx temp
            jsr v5b::read_entry
            ldx track_index
            lda events::event_time_stamp_l
            sta detail::next_event_timestamp_l, x
            lda events::event_time_stamp_h
            sta detail::next_event_timestamp_h, x
        :
        rts
    .endproc

    ; Given the note's "pitch" inside a drum track in .A, figures out the instrument ID and the pitch to be played
    ; Returns instrument index in .X, pitch in .A
    .proc getDrumInstrumentAndPitch
        pha
        and #$0f ; modulo 16
        ora #$10 ; add 16 to get to the range 16-31
        tax
        pla
        and #$f0
        lsr
        lsr
        lsr
        lsr
        clc
        adc #60 ; center pitch around the note 60
        rts
    .endproc


    ; Expects the pointer to an events vector in .A/.X,
    ; and the time stamp in time_stamp (if more flexibility is needed, timing::timestamp_parameter could be used alternatively).
    ; Returns the first event which comes at the given time stamp or later.
    ; If no such event exists, carry will be set; otherwise clear.
    ; This function aims to be performant by doing "hierarchical" linear search,
    ; i.e. it first narrows down the search across chunks, and then within a chunk.
    ; This function only needs to run in the main program (starting playback, potentially drawing routine).
    .proc findEventAtCurrentTimeStamp
        zp_pointer_2 = v5b::zp_pointer_2
        ;bra @linear_search ; TEMPORARY MEASURE to reduce function complexity at the cost of speed
    @chunk_loop:
        sta zp_pointer_2
        stx zp_pointer_2+1
        jsr v5b::get_first_entry ; uses v5b::zp_pointer
        bcc :+ ; only continue if the chunk contains any events
        rts ; return early if chunk doesn't contain any events ... only possible for the first chunk, others must contain at least one event
    :
        ; loop over chunks and find the first chunk whose first event has a time stamp at or after the given one.
        jsr v5b::read_entry ; uses v5b::zp_pointer
        ; check time stamp
        lda events::event_time_stamp_h
        cmp time_stamp+1
        bne :+
        ; high bytes equal, compare low bytes
        lda events::event_time_stamp_l
        cmp time_stamp
        beq @previous_or_this_chunk ; both bytes equal: this chunk or previous (if events with the same time stamp exist in previous chunk)
    :
        bcs @previous_or_this_chunk ; event time stamp was higher -> must be in this or previous chunk
        ; event time stamp was lower -> must go to next chunk
    @check_beginning_of_next_chunk:
        lda zp_pointer_2
        ldx zp_pointer_2+1
        jsr dll::get_next_element ; uses v5b::zp_pointer
        beq @this_chunk ; next chunk doesn't exist, can only be in this chunk
        bra @chunk_loop

    @previous_or_this_chunk:
        ; The time stamp of the start of current chunk is higher or equal to the time stamp.
        ; The most likely scenario is that somewhere within the previous chunk (if it exists), the time stamp was surpassed.
        ; We basically start doing linear search at the start of the previous chunk.
        ; In the unlikely case that it's in fact the beginning of the current chunk, linear search will find it eventually.
        lda zp_pointer_2
        ldx zp_pointer_2+1
        jsr dll::get_previous_element ; uses v5b::zp_pointer
        bne @linear_search
        ; there is no previous element, so the beginning of the current chunk must be it.
        lda zp_pointer_2
        ldx zp_pointer_2+1
        jsr v5b::get_first_entry
        rts

    @this_chunk:
        ; There is no next chunk, so the only place where the time stamp could be crossed is within the current chunk.
        ; We start linear search at the start of the current chunk.
        lda zp_pointer_2
        ldx zp_pointer_2+1

    @linear_search:
        jsr v5b::get_first_entry
    @linear_search_loop:
        pha
        phx
        phy
        jsr v5b::read_entry
        ; do comparison
        lda events::event_time_stamp_h
        cmp time_stamp+1
        bne :+
        ; high bytes equal, compare low bytes
        lda events::event_time_stamp_l
        cmp time_stamp
        beq @event_found ; time stamps equal
    :
        bcs @event_found ; event comes after time stamp
        ply
        plx
        pla
        jsr v5b::get_next_entry
        bcc @linear_search_loop
        ; no event found. carry is already set, just need to return
        rts

    @event_found:
        ply
        plx
        pla
        clc
        rts
    .endproc
.endscope


; Expects channel id in .A
.proc stopVoicesOnChannel
    ldx #0
@voices_loop:
    cmp detail::voice_channels, x
    bne :+
    phx
    pha
    stx concerto_synth::note_voice
    jsr concerto_synth::stop_note
    pla
    plx
:   inx
    cpx #N_VOICES
    bne @voices_loop
    rts
.endproc


; Restarts playback for the given player id from the current time stamp.
; Expects track id in .A
.proc updateTrackPlayer
    track_index = detail::temp_variable_a
    ldx detail::active
    bne :+
    rts
:   sta track_index
    jsr stopVoicesOnChannel
    ldy track_index
    bne @track_player
@selected_events_player:
    lda event_selection::selected_events_vector
    ldx event_selection::selected_events_vector+1
    bra @find_event
@track_player:
    dey
    jsr clips::accessClip
    ; load event vector of the clip
    ; #optimize-for-size: put these commands in function and reuse in startPlayback routine
    ldy #clips::clip_data::event_ptr
    lda (v32b::entrypointer), y
    pha
    iny
    lda (v32b::entrypointer), y
    tax
    pla
@find_event:
    ; Event vector is in .A/.X
    jsr detail::findEventAtCurrentTimeStamp
    bcc :+
    ; no event
    ldx track_index
    stz detail::next_event_pointer_y, x
    rts
:   ; an event
    pha
    phx
    phy
    jsr v5b::read_entry
    ldx track_index
    lda events::event_time_stamp_l
    sta detail::next_event_timestamp_l, x
    lda events::event_time_stamp_h
    sta detail::next_event_timestamp_h, x
    pla
    sta detail::next_event_pointer_y, x
    pla
    sta detail::next_event_pointer_x, x
    pla
    sta detail::next_event_pointer_a, x
    rts
.endproc


; New, multitrack capable version
; Possible adaptation later: start from time stamp
.proc startPlayback
    track_index = detail::temp_variable_a
    temp = detail::temp_variable_b
    php
    sei
    ; First, deactivate all players and voices
    jsr concerto_synth::panic ; stop all voices
    ldx #0
@deactivate_loop:
    stz detail::next_event_pointer_y, x
    inx
    cpx #MAX_TRACKS
    bne @deactivate_loop

    ; Set time stamp to zero
    lda player_start_timestamp
    sta detail::time_stamp
    lda player_start_timestamp+1
    sta detail::time_stamp+1
    ; Set player to active (done early because updateTrackPlayer wants it)
    lda #1
    sta song_engine::multitrack_player::detail::active

    ; Initialize player for selected events (player index 0)
    ; Set up pointer to clip options data. (Selected events use the same settings as the currently visible clip)
    ldy clips::active_clip_id
    lda clips::clips_vector
    ldx clips::clips_vector+1
    jsr dll::getElementByIndex ; returns pointer in .A/.X
    sta detail::clip_settings_a ; player index 0, no offset needed
    stx detail::clip_settings_x
    lda #0
    jsr updateTrackPlayer


    ; Copy the track settings pointers into the player
    stz track_index
@track_loop:
    ldy track_index
    jsr clips::accessClip ; this is not very efficient, but small code...
    inc track_index
    ldx track_index
    lda RAM_BANK
    sta detail::clip_settings_a, x
    lda v32b::entrypointer_h
    sta detail::clip_settings_x, x
    cpx clips::number_of_clips
    bne @track_loop

    ; Start all players
    lda #255
@start_playback_loop:
    inc
    pha
    jsr updateTrackPlayer
    pla
    cmp clips::number_of_clips
    bne @start_playback_loop

    plp
    rts
.endproc



.proc playerTick
    track_index = detail::temp_variable_a
    lda detail::active
    bne :+
    rts
:
    ldx #0
@track_loop:
    stx track_index
    lda detail::next_event_pointer_y, x
    bne @process_events_loop
@jmp_to_finish_track:
    jmp @finish_track
    @process_events_loop:
        lda detail::next_event_timestamp_l, x
        cmp detail::time_stamp
        bne @jmp_to_finish_track
        lda detail::next_event_timestamp_h, x
        cmp detail::time_stamp+1
        bne @jmp_to_finish_track
        
        ; it's the current time stamp!
        ; Dispatch current event
        ldx track_index
        ldy detail::next_event_pointer_y, x
        lda detail::next_event_pointer_x, x
        pha
        lda detail::next_event_pointer_a, x
        plx

        pha
        phx
        phy
        jsr v5b::read_entry

        lda events::event_type
        beq @note_off ; #events::event_type_note_off
        cmp #events::event_type_note_on
        beq @note_on
        jmp @continue_next_event ; for now, ignore all events that aren't note-on or note-off
    @note_on:
        ; Setup access to clip settings
        ldy track_index
        lda detail::clip_settings_a, y
        ldx detail::clip_settings_x, y
        jsr v32b::accessEntry
        ; check for drum pad
        ldy #clips::clip_data::drum_pad
        lda (v32b::entrypointer), y
        beq @melodic
        @drum_pad:
            ; we assume that the same note can't be played twice (same channel, pitch and instrument)
            ; So we don't (need to) look for existing one
            lda events::note_pitch
            jsr detail::getDrumInstrumentAndPitch
            stx concerto_synth::note_instrument
            sta concerto_synth::note_pitch
            jsr detail::findFreeVoice
            bcs @continue_next_event ; no free voice found, go to next event
            bra @start_new_note
    @melodic:
        ; Check for monophonic
        ldy #clips::clip_data::monophonic
        lda (v32b::entrypointer), y
        beq @find_free_voice
        @monophonic:
            ; find voice with current channel & pitch --> replace
            lda track_index
            ldy events::note_pitch
            jsr detail::findVoiceChannel
            bcc @setup_pitch_and_instrument ; jump if note was found --> continue playing the same note
            ; not found, fall through to finding a voice
    @find_free_voice:
        jsr detail::findFreeVoice
        bcs @continue_next_event ; no free voice found, go to next event
    @setup_pitch_and_instrument:
        lda events::note_pitch
        sta concerto_synth::note_pitch
        ldy #clips::clip_data::instrument_id
        lda (v32b::entrypointer), y
        sta concerto_synth::note_instrument
    @start_new_note:
        ; .X still contains the voice to be used
        stx concerto_synth::note_voice
        lda track_index
        sta detail::voice_channels, x
        lda events::note_velocity
        jsr concerto_synth::play_note
        bra @continue_next_event

    @note_off:
        ; Setup access to clip settings
        ldy track_index
        lda detail::clip_settings_a, y
        ldx detail::clip_settings_x, y
        jsr v32b::accessEntry
        ; check for drum pad
        ldy #clips::clip_data::drum_pad
        lda (v32b::entrypointer), y
        beq @melodic_off
        @drum_pad_off:
            lda events::note_pitch
            jsr detail::getDrumInstrumentAndPitch
            tay
            lda track_index
            jsr detail::findVoiceChannelPitchInstrument
            bcs @continue_next_event ; not found
            bra @stop_note
    @melodic_off:
        lda track_index
        ldy events::note_pitch
        jsr detail::findVoiceChannelPitch
        bcs @continue_next_event ; not found (e.g. mono-legato --> note's pitch got changed)
    @stop_note:
        stx concerto_synth::note_voice
        jsr concerto_synth::release_note

    @continue_next_event:
        ply
        plx
        pla
        jsr v5b::get_next_entry
        bcs @disable_track
    @go_to_next_event:
        pha
        phy
        phx
        ldx track_index
        sta detail::next_event_pointer_a, x
        tya
        sta detail::next_event_pointer_y, x
        pla
        sta detail::next_event_pointer_x, x
        tax
        ply
        pla
        jsr v5b::read_entry
        ldx track_index
        lda events::event_time_stamp_l
        sta detail::next_event_timestamp_l, x
        lda events::event_time_stamp_h
        sta detail::next_event_timestamp_h, x
        jmp @process_events_loop

    @disable_track:
        ldx track_index
        stz detail::next_event_pointer_y, x

    @finish_track:
    ldx track_index
    inx
    cpx #MAX_TRACKS+1
    bcs :+
    jmp @track_loop
:
    
    inc detail::time_stamp
    bne :+
    inc detail::time_stamp+1
:
    rts
.endproc


.proc stopPlayback
    stz detail::active
    jsr concerto_synth::panic
    rts
.endproc

.endscope

.endif ; .ifndef SONG_ENGINE_MULTITRACK_PLAYER_ASM
