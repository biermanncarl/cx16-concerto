; Copyright 2024 Carl Georg Biermann

.ifndef ::SONG_ENGINE_SIMPLE_PLAYER_ASM
::SONG_ENGINE_SIMPLE_PLAYER_ASM = 1

; This player serves as a provisional way to play back note/event data.
; Whether it will later be expanded into a full, multi-track engine is not decided yet.
; This code has nothing to do with the one under /simple_player/concerto_player.asm  --  sorry for the bad uncreative naming.

.scope simple_player

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
.endscope


; New, multitrack capable version
; Possible adaptation later: start from time stamp
.proc startPlayback
    track_index = detail::temp_variable_a
    temp = detail::temp_variable_b
    php
    sei
    ; First, deactivate all players
    ldx #0
@deactivate_loop:
    stz detail::next_event_pointer_y, x
    inx
    cpx #MAX_TRACKS
    bne @deactivate_loop

    ; Set time stamp to zero
    stz detail::time_stamp
    stz detail::time_stamp+1

    ; Initialize player for selected events (player index 0)
    ; Set up pointer to clip options data
    ldy clips::active_clip_id
    lda clips::clips_vector
    ldx clips::clips_vector+1
    jsr dll::getElementByIndex ; returns pointer in .A/.X
    sta detail::clip_settings_a ; player index 0, no offset needed
    stx detail::clip_settings_x
    ; Set up timestamp & pointer to event data
    lda selected_events_vector
    ldx selected_events_vector+1
    ldy #0
    jsr detail::startPlabackOnTrack


    ; Now, initialize the normal players
    ldy #1
    sty track_index ; track index 0 was already initialized above
    dey
    jsr clips::accessClip
@track_loop:
    ; backup RAM BANK
    lda RAM_BANK
    pha
    ; setup pointer to clip data on current track
    ldx track_index
    ; B component of B/H pointer was RAM BANK, already loaded above
    sta detail::clip_settings_a, x
    lda v32b::entrypointer_h
    sta detail::clip_settings_x, x
    ; load first event of the clip
    ldy #clips::clip_data::event_ptr
    lda (v32b::entrypointer), y
    pha
    iny
    lda (v32b::entrypointer), y
    tax
    pla
@setup_first_event:
    ldy track_index
    jsr detail::startPlabackOnTrack

    inc track_index
    pla
    sta RAM_BANK
    jsr v32b::accessNextEntry
    bcc @track_loop

    lda #1
    sta song_engine::simple_player::detail::active

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
        jsr v32b::accessFirstEntry
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
        jsr v32b::accessFirstEntry
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



; This function must be called whenever the clip data that is being played back is changed.
; (By the way, changing or even reading played back clip data in non-ISR code MUST be masked by SEI...)
; It basically rewinds the playback and fast-forwards to the current time stamp.
.proc updatePlayback
    ; TODO: remove
    rts
.endproc

.proc stopPlayback
    stz detail::active
    jsr concerto_synth::panic
    rts
.endproc

.endscope

.endif ; .ifndef SONG_ENGINE_SIMPLE_PLAYER_ASM
