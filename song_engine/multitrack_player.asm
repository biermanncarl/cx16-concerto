; Copyright 2024-2025 Carl Georg Biermann

.ifndef ::SONG_ENGINE_MULTITRACK_PLAYER_ASM
::SONG_ENGINE_MULTITRACK_PLAYER_ASM = 1

.scope multitrack_player

player_start_timestamp:
    .word 0

.scope detail
    active: .byte 0
    time_stamp: .word 0

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
    ; Note that we "route" the actual events from event player 0 into the track that is currently selected in the GUI.
    ; We also pass the corresponding player id to processEvent, so that player id 0 can be used for the musical keyboard.
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
    ; For the clip settings, index 0 contains the settings of the musical keyboard, which are read by processEvent.
    clip_settings_a:
        .res num_players
    clip_settings_x:
        .res num_players


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


    ; Looks through the active voices and tries to free resources for a new voice by stealing
    ; them from voices that are currently in the release phase.
    ; Prioritizes voices with the same instrument.
    ; Expects instrument id in concerto_synth::note_instrument
    ; If successful, carry will be clear. If unsuccessful, it will be set.
    ; If successful, returns the index of a usable voice in .X
    .proc stealReleasedVoice
        ; We also steal the concerto_synth::note_voice register, since it's not used just yet ... hehe
        ldx #255
        @same_instrument_loop:
            ; The advantage with finding a voice of the same instrument is:
            ; 1. it's relatively likely that another voice of the same instrument just ended
            ; 2. we know for sure that enough resources will be freed
            inx
            cpx #N_VOICES
            beq @same_instrument_loop_done
            lda concerto_synth::voices::Voice::instrument, x
            cmp concerto_synth::note_instrument
            bne @same_instrument_loop ; voice of same instrument?
            lda concerto_synth::voices::Voice::env::step, x
            cmp #4 ; voice in release phase?
            bne @same_instrument_loop
            lda concerto_synth::voices::Voice::active, x ; voice active?
            beq @same_instrument_loop
        @caught_same:
            stx concerto_synth::note_voice
            jsr concerto_synth::stop_note
            clc
            ldx concerto_synth::note_voice
            rts ; job done
        @same_instrument_loop_done:

        ldx #255
        ; Relatively crude method: just kill everything currently in the release phase until we got enough resources
        @generic_loop:
            inx
            cpx #N_VOICES
            beq @generic_loop_done
            lda concerto_synth::voices::Voice::env::step, x
            cmp #4 ; voice in release phase?
            bne @generic_loop
            lda concerto_synth::voices::Voice::active, x ; voice active?
            beq @generic_loop
        @caught_generic:
            stx concerto_synth::note_voice
            jsr concerto_synth::stop_note
            ; check if we were successful
            ldy concerto_synth::note_instrument
            jsr concerto_synth::voices::checkOscillatorResources
            ldx concerto_synth::note_voice
            bcc @generic_loop ; not successful --> hunt more
            clc
            rts ; job done
        @generic_loop_done:
        sec
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
    ; jsr stopVoicesOnChannel  ; commented out for now. I think all notes stopping on a track on all sorts of occasions is a major annoyance, and maybe not necessary at all.
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
    ldy detail::time_stamp
    sty timing::time_stamp_parameter
    ldy detail::time_stamp+1
    sty timing::time_stamp_parameter+1
    jsr event_selection::findEventAtTimeStamp
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
    player_index = detail::temp_variable_a
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
    lda #0
    jsr updateTrackPlayer
    ; We leave the clip_settings for index 0 untouched because they contain the settings of the musical keyboard


    ; Copy the track settings pointers into the player
    stz player_index ; actually, in the first half of below loop, this variable is treated as clip index
@track_loop:
    ldy player_index
    jsr clips::accessClip ; this is not very efficient, but small code...
    inc player_index ; converts from clip index to player index
    ldx player_index
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



; Processes a single event.
; The track index must be set in player_index.
; The event is expected in the v5b data registers.
; Can be called from ISR and main program, but in main program, interrupt must be disabled (player_index could be cluttered)
; NOTE: player_index is not the clip index, but the index into the player-internal array of pointers clip_settings_a/x.
.proc processEvent
    ; Right now, there are only note-on and note-off events.
    ; In both cases, we are interested in finding a note that is currently playing on the same track, pitch and instrument.
    ; At note-off events, we would obviously like to end it.
    ; At note-on events, we have to end it, too, and replace it with the new note.
    ; (Otherwise, note-off events wouldn't be guaranteed to be assigned to the correct one of several identical notes.)
    ; So, finding an already playing note with the specified parameters is what we have to do first.

    lda #$ff
    sta concerto_synth::note_voice ; invalidate voice index

    ; Setup access to clip settings
    ldy player_index
    lda detail::clip_settings_a, y
    ldx detail::clip_settings_x, y
    jsr v32b::accessEntry
    ; check for drum pad
    ldy #clips::clip_data::drum_pad
    lda (v32b::entrypointer), y
    beq @melodic
    @find_drum_note:
        lda events::note_pitch
        jsr detail::getDrumInstrumentAndPitch
        stx concerto_synth::note_instrument ; not needed for note-offs, but doesn't hurt, either
        sta concerto_synth::note_pitch ; not needed for note-offs, but doesn't hurt, either
        tay
        lda player_index
        jsr detail::findVoiceChannelPitchInstrument
        bcs @check_event_type
        stx concerto_synth::note_voice
        bra @check_event_type
@melodic:
@setup_pitch_and_instrument:
    lda events::note_pitch
    sta concerto_synth::note_pitch ; not needed for note-offs, but doesn't hurt, either
    ldy #clips::clip_data::instrument_id
    lda (v32b::entrypointer), y
    sta concerto_synth::note_instrument ; not needed for note-offs, but doesn't hurt, either
    ; Check for monophonic
    ldy #clips::clip_data::monophonic
    lda (v32b::entrypointer), y
    beq @polyphonic_find
    @monophonic_find:
        ; find voice with current channel & pitch --> replace
        lda player_index
        jsr detail::findVoiceChannel
        bcs :+
        stx concerto_synth::note_voice
    :   bra @check_event_type
    @polyphonic_find:
        lda player_index
        ldy events::note_pitch
        jsr detail::findVoiceChannelPitch
        bcs :+
        stx concerto_synth::note_voice
    :
@check_event_type:
    ; This section expects the following "inputs":
    ; If a voice has been selected (to be released or replaced), it should be stored in concerto_synth::note_voice,
    ; otherwise that variable should sit at 255.
    ; If a new note is to be played, concerto_synth::note_instrument and note_pitch should be set to the correct values. (?)
    lda events::event_type
    bne @note_on  ; the only non-zero event currently is note-on
@note_off: ; #events::event_type_note_off
    ldx concerto_synth::note_voice
    bmi @return ; note to be released could not be found --> either the note wasn't played or the voice got stolen
    ; Check for monophonic (there we must only release notes of the correct pitch)
    ldy #clips::clip_data::monophonic
    lda (v32b::entrypointer), y
    beq :+
    ; compare pitch
    lda concerto_synth::voices::Voice::pitch, x
    cmp concerto_synth::note_pitch
    bne @return
:   jsr concerto_synth::release_note
@return:
    rts
@note_on:
    lda concerto_synth::note_voice
    bmi @no_voice_selected
    ; voice already selected
    ldy #clips::clip_data::monophonic
    lda (v32b::entrypointer), y ; is clip monophonic?
    beq @stop_note
    @monophonic:
        ; check if currently playing mono-note is still going or already in release phase
        ldx concerto_synth::note_voice
        lda concerto_synth::voices::Voice::env::step, x
        cmp #4
        beq @stop_note ; if in release phase, stop note and start new one
        bra @play_note
    @stop_note:
        jsr concerto_synth::stop_note
@no_voice_selected:
@check_oscillators:
    ldy concerto_synth::note_instrument
    jsr concerto_synth::voices::checkOscillatorResources
    bcs @enough_oscillators_available
    @need_more_resources:
        ; not enough oscillators or voices. Hunt for released (but still running) voices.
        jsr detail::stealReleasedVoice ; returns usable voice in .X if found
        bcc :+
        ; could not free the needed resources --> set signal
        .ifdef ::concerto_full_daw
            lda #concerto_gui__gauges__flash_duration_ticks
            sta concerto_gui__gauges__cooldown_note_drop
        .endif
        rts
    :   stx concerto_synth::note_voice
        .ifdef ::concerto_full_daw
            lda #concerto_gui__gauges__flash_duration_ticks
            sta concerto_gui__gauges__cooldown_note_steal
        .endif
        bra @play_note
    @enough_oscillators_available:
        lda concerto_synth::note_voice
        bpl @play_note
        jsr detail::findFreeVoice
        bcs @need_more_resources
        stx concerto_synth::note_voice
@play_note:
    ; concerto_synth::note_voice contains the voice to be used
    lda player_index
    sta detail::voice_channels, x
    lda events::note_velocity
    jsr concerto_synth::play_note
    rts
player_index:
    .byte 0
.endproc


.ifdef ::concerto_full_daw
    .scope musical_keyboard
        ; Musical keyboard stuff
        velocity: .byte 63
        instrument: .byte 0
        mono: .byte 0
        drum: .byte 0
        basenote: .byte 60
        buffer_size = 4
        buffer_num_events:
            .byte 0
        buffer:
            .res buffer_size
        musical_keyboard_channel = $00
        last_key_down:
            .byte 0

        is_recording:
            .byte 0
        ; Having a smaller buffer explicitly listing active note pitches would also be possible, but might require more code overall
        ; for searching and removing array entries.
        ; Unfortunately, golden RAM is full already, so we'll have to provide another big buffer here.
        recording_active_notes:
            .res 256

        ; pointer to musical keyboard settings
        ; While we could handle the musical keyboard entirely separately from the multitrack player, using the
        ; multitrack-player function "processEvent" has some advantages:
        ; It handles mono/polyphony, drum pad and voice stealing.
        ; On the downside, we have to provide a pointer to the settings -- essentially an invisible "clip"
        musical_kbd_settings_a = detail::clip_settings_a
        musical_kbd_settings_x = detail::clip_settings_x


        ; Initializes the musical keyboard, which is now handled by the multitrack-player, as well.
        .proc initialize
            jsr v32b::new
            sta musical_kbd_settings_a
            stx musical_kbd_settings_x
            jsr v32b::accessEntry
            ldy #clips::clip_data::instrument_id
            lda #0
            sta (v32b::entrypointer), y ; set instrument id to zero
            iny
            sta (v32b::entrypointer), y ; set to polyphonic
            iny
            sta (v32b::entrypointer), y ; disable drum pad
            ; clear musical keyboard buffer
            stz musical_keyboard::buffer_num_events
            rts
        .endproc

        ; Looks through our keyboard buffer and handles key presses.
        ; ISR only.
        .proc handleMusicalKeyboard
            ; keycodes can be found here: https://github.com/X16Community/x16-rom/blob/master/inc/keycode.inc
            lowest_relevant_keycode = $12 ; keycode for "w" key
            highest_relevant_keycode = $29 ; single quote on english keyboard, rightmost key on second row of letters

            ; move updated musical keyboard settings to the place where the multitrack player expects them
            ; This could be done whenever panels__global_navigation__redrawMusicalKeyboardSettings is called.
            ; #optimize-for-speed
            lda musical_keyboard::musical_kbd_settings_a
            ldx musical_keyboard::musical_kbd_settings_x
            jsr v32b::accessEntry
            ldy #clips::clip_data::instrument_id
            lda musical_keyboard::instrument
            sta (v32b::entrypointer), y ; set instrument id
            iny
            lda musical_keyboard::mono
            sta (v32b::entrypointer), y ; set mono/poly
            iny
            lda musical_keyboard::drum
            sta (v32b::entrypointer), y ; set drum pad

            ; check for new key down/up events
            lda musical_keyboard::buffer_num_events
            bne :+
            rts
        :   

            ; process all key-up events
            stz kbd_event_index
            @key_up_loop:
                jsr isKeyUp
                bpl @skip1 ; skip key-down events in this loop
                jsr isKeyRelevant
                bcs @skip1
            @key_up_event:
                cmp musical_keyboard::last_key_down
                bne :+
                ldx #$ff
                stx musical_keyboard::last_key_down
            :   ; TODO: clear entry in recording_active_notes
                lda #events::event_type_note_off
                sta events::event_type
                ; recording
                ldx is_recording
                beq @skip_recording_note_off
                ; check if note was active
                ldx events::note_pitch
                lda recording_active_notes, x
                beq @skip_recording_note_off
                stz recording_active_notes, x
                jsr recordEvent
            @skip_recording_note_off:
                lda #events::event_type_note_off
                sta events::event_type
                lda #musical_keyboard::musical_keyboard_channel
                sta processEvent::player_index
                jsr processEvent
                inc concerto_gui__gui_variables__request_components_refresh_and_redraw
            @skip1:
                lda kbd_event_index
                cmp musical_keyboard::buffer_num_events
                bne @key_up_loop

            ; process all key-down events
            stz kbd_event_index
            @key_down_loop:
                jsr isKeyUp
                bmi @skip2 ; skip key-up events in this loop
                jsr isKeyRelevant
                bcs @skip2
            @key_down_event:
                cmp musical_keyboard::last_key_down ; check for keyboard autorepeat
                beq @skip2
                sta musical_keyboard::last_key_down
                lda #musical_keyboard::musical_keyboard_channel
                sta processEvent::player_index
                lda musical_keyboard::velocity
                sta events::note_velocity
                lda #events::event_type_note_on
                sta events::event_type
                ; recording
                lda is_recording
                beq @skip_recording_note_on
                ldx events::note_pitch
                inc recording_active_notes, x
                jsr recordEvent
                inc concerto_gui__gui_variables__request_components_refresh_and_redraw
            @skip_recording_note_on:
                jsr processEvent
                ; in case of a drum pad event, we want to update the instrument shown in the GUI accordingly
                lda concerto_synth::note_instrument
                cmp concerto_gui__gui_variables__current_synth_instrument
                beq @skip2
                    sta concerto_gui__gui_variables__current_synth_instrument
                    inc concerto_gui__gui_variables__request_components_refresh_and_redraw
            @skip2:
                lda kbd_event_index
                cmp musical_keyboard::buffer_num_events
                bne @key_down_loop


            stz musical_keyboard::buffer_num_events
            rts

            kbd_event_index = detail::temp_variable_a
            key_down:
                .byte 0
            key_pitch_map_lut:
                .byte 1 ; w
                .byte 3 ; e
                .byte $FF ; r
                .byte 6 ; t
                .byte 8 ; z
                .byte 10 ; u
                .byte $FF ; i
                .byte 13 ; o
                .byte 15 ; p
                .byte $FF ; [
                .byte $FF ; ]
                .byte $FF ; \
                .byte $FF ; caps lock
                .byte 0 ; a
                .byte 2 ; s
                .byte 4 ; d
                .byte 5 ; f
                .byte 7 ; g
                .byte 9 ; h
                .byte 11 ; j
                .byte 12 ; k
                .byte 14 ; l
                .byte 16 ; ;
                .byte 17 ; '

            ; Reads the current keyboard event and checks if it's key-up or key-down.
            ; If key-up, minus flag is set; clear otherwise.
            ; Event code is returned in .A
            ; kbd_event_index is incremented.
            .proc isKeyUp
                ldx kbd_event_index
                inc kbd_event_index
                lda musical_keyboard::buffer, x
                rts
            .endproc

            ; Expects current keyboard event in .A
            ; If key is relevant for musical keyboard, carry is clear upon return; set otherwise.
            ; If carry is clear, both .A and song_engine::events::note_pitch are set to the corresponding pitch.
            .proc isKeyRelevant
                and #$7F
                sec
                sbc #lowest_relevant_keycode
                cmp #(highest_relevant_keycode + 1 - lowest_relevant_keycode) ; this and higher key codes are irrelevant for musical keyboard
                ; If carry is set, key is irrelevant
                bcc :++
            :   rts
            :   tax
                lda key_pitch_map_lut, x
                asl
                bcs :-- ; irrelevant key within the LUT
                lsr
                ; carry is clear as per above instructions
                adc musical_keyboard::basenote
                sta song_engine::events::note_pitch ; save the pitch value (in case it's significant)
                clc ; #optimize-for-size CLC can probably be omitted, if the maximal basenote is low enough. Haven't checked yet.
                rts
            .endproc
        .endproc

        ; Also acts as playback start for convenience.
        .proc startKeyboardRecording
            jsr event_selection::unselectAllEvents
            ; No flushClip needed because that is being done when the track is unselected
            ; (or any other occasion where the correct pointer in Clip data must be guaranteed: saving song, tempo change ...)
            ldx #0
            @loop:
                stz recording_active_notes, x
                inx
                bne @loop
            lda #1
            sta is_recording
            inc concerto_gui__gui_variables__request_components_refresh_and_redraw
            ; The player for selected events should get deactivated immediately, since there are no events in it (yet).
            ; Therefore, recording won't interfere with playback.
            jmp startPlayback
        .endproc

        .proc stopKeyboardRecording
            lda is_recording
            beq @end
            jsr flushRecording
            stz is_recording
            inc concerto_gui__gui_variables__request_components_refresh_and_redraw
        @end:
            rts
        .endproc

        .proc recordEvent
            ; Set timestamp
            lda detail::time_stamp
            sta events::event_time_stamp_l
            lda detail::time_stamp+1
            sta events::event_time_stamp_h
            lda event_selection::selected_events_vector
            ldx event_selection::selected_events_vector+1
            jmp v5b::append_new_entry
        .endproc

        ; Finishes all currently unfinished notes, so it becomes safe to unselect the recorded events.
        .proc flushRecording
            lda #events::event_type_note_off
            sta events::event_type
            ldx #0
            @loop:
                lda recording_active_notes, x
                beq :+
                stx events::note_pitch
                phx
                jsr recordEvent
                plx
            :   stz recording_active_notes, x
                inx
                bne @loop
            rts
        .endproc

        .proc stopPlaybackIfRecording
            lda is_recording
            bne :+
            rts
        :   jmp stopPlayback 
        .endproc
    .endscope
.endif

; Utility macro to make functions recording-safe
.macro RTS_IF_RECORDING
   lda song_engine::multitrack_player::musical_keyboard::is_recording
   beq :+
   rts
:
.endmacro

; ISR only
.proc playerTick
    .ifdef ::concerto_full_daw
        jsr musical_keyboard::handleMusicalKeyboard
    .endif
    lda detail::active
    bne :+
    rts
:
    lda #3
    sta event_threshold
@start_track_loop:
    ldx #0
@track_loop:
    stx player_counter
    lda detail::next_event_pointer_y, x
    beq @finish_track
    @process_events_loop:
        lda detail::next_event_timestamp_l, x
        cmp detail::time_stamp
        bne @finish_track
        lda detail::next_event_timestamp_h, x
        cmp detail::time_stamp+1
        bne @finish_track
        
        ; it's the current time stamp!
        ; Dispatch current event
        ldx player_counter
        ldy detail::next_event_pointer_y, x
        lda detail::next_event_pointer_x, x
        pha
        lda detail::next_event_pointer_a, x
        plx

        pha
        phx
        phy
        jsr v5b::read_entry
        ; check if we're in the correct phase
        lda event_threshold
        cmp events::event_type
        bcc @finish_track_phase
        lda player_counter
        bne :+
        lda clips::active_clip_id ; if the player id is 0 (player of selected events), we treat the event as part of the parent clip
        inc
    :   sta processEvent::player_index
        jsr processEvent
        ply
        plx
        pla
        jsr v5b::get_next_entry
        bcs @disable_track
    @go_to_next_event:
        pha
        phy
        phx
        ldx player_counter
        sta detail::next_event_pointer_a, x
        tya
        sta detail::next_event_pointer_y, x
        pla
        sta detail::next_event_pointer_x, x
        tax
        ply
        pla
        jsr v5b::read_entry
        ldx player_counter
        lda events::event_time_stamp_l
        sta detail::next_event_timestamp_l, x
        lda events::event_time_stamp_h
        sta detail::next_event_timestamp_h, x
        bra @process_events_loop

    @disable_track:
        ldx player_counter
        stz detail::next_event_pointer_y, x
        bra @finish_track
    @finish_track_phase:
    ply
    plx
    pla
@finish_track:
    ldx player_counter
    inx
    cpx #MAX_TRACKS+1
    bcs :+
    jmp @track_loop
:
    lda event_threshold
    cmp #3
    bne @finish_tick
    lda #255
    sta event_threshold
    jmp @start_track_loop ; second time iterating through all tracks

@finish_tick:
    inc detail::time_stamp
    bne :+
    inc detail::time_stamp+1
:
    rts
event_threshold:
    ; phase 3 means note-offs only (to potentially free up voices)
    ; phase 255 means note-ons (and in the future, potentially effects)
    .byte 0
player_counter:
    .byte 0
.endproc


.proc stopPlayback
    stz detail::active
    jsr concerto_synth::panic
    .ifdef ::concerto_full_daw
        jsr musical_keyboard::stopKeyboardRecording
    .endif
    rts
.endproc

.ifdef ::concerto_cos2zsm_converter
    ; If any track is currently playing back something, carry will be set upon return. Clear otherwise.
    .proc anyTracksActive
        ldx #detail::num_players
        @loop:
            dex
            bmi @loop_end
            lda detail::next_event_pointer_y, x
            beq @loop
            sec
            rts
        @loop_end:
        clc
        rts
    .endproc
.endif

.endscope

.endif ; .ifndef SONG_ENGINE_MULTITRACK_PLAYER_ASM
