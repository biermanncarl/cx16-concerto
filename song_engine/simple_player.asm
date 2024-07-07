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

    ; Given a channel and pitch, finds an active voice which matches these.
    ; .A : channel
    ; .Y : pitch
    ; Returns voice index in .X
    ; If no voice was found, carry will be set, otherwise clear.
    .proc findVoice
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
    channel:
        .byte 0
    .endproc
.endscope

.proc player_tick
    lda detail::active
    bne :+
    rts
:
    jsr event_selection::swapBackFrontStreams

@process_events_loop:
    lda detail::next_time_stamp+1
    cmp detail::time_stamp+1
    bne @end_processing_events
    lda detail::next_time_stamp
    cmp detail::time_stamp
    bne @end_processing_events

    ; it's the current time stamp!
    lda detail::next_event
    ldx detail::next_event+1
    ldy detail::next_event+2
    jsr v5b::read_entry

    lda events::event_type
    beq @note_off ; #events::event_type_note_off
    cmp #events::event_type_note_on
    bne @continue_next_event ; for now, ignore all events that aren't note-on or note-off
@note_on:
    ; Todo read clip/track settings and interpret them
    jsr detail::findFreeVoice
    bcs @continue_next_event ; no free voice found, go to next event
    stx concerto_synth::note_voice
    stz detail::voice_channels, x ; 0 is the channel index for now, todo: read from clip/track
    lda events::note_pitch
    sta concerto_synth::note_pitch
    lda #0  ; concerto_gui::gui_variables::current_synth_instrument
    sta concerto_synth::note_instrument
    lda events::note_velocity
    jsr concerto_synth::play_note
    bra @continue_next_event
@note_off:
    lda #0 ; channel number - todo read from clip/track
    ldy events::note_pitch
    jsr detail::findVoice
    bcs @continue_next_event ; not found (e.g. mono-legato --> note's pitch got changed)
    stx concerto_synth::note_voice
    jsr concerto_synth::release_note

@continue_next_event:
    jsr detail::getNextEventAndTimeStamp
    bcc @process_events_loop
    rts
@end_processing_events:


    inc detail::time_stamp
    bne :+
    inc detail::time_stamp+1
:
    jsr event_selection::swapBackFrontStreams
    rts
.endproc

.proc start_playback
    ; content moved to clip_editing start play button
    ; reason: this module has no ownership of the necessary data vectors
.endproc

; This function must be called whenever the clip data that is being played back is changed.
; (By the way, changing or even reading played back clip data in non-ISR code MUST be masked by SEI...)
; It basically rewinds the playback and fast-forwards to the current time stamp.
.proc updatePlayback
    jsr concerto_synth::panic
    jsr event_selection::resetStream
@fast_forward_loop:
    jsr detail::getNextEventAndTimeStamp
    bcs stop_playback ; basically sneaky jsr without return

    lda detail::next_time_stamp+1
    cmp detail::time_stamp+1
    bcc @fast_forward_loop
    bne @fast_forward_done
    lda detail::next_time_stamp
    cmp detail::time_stamp
    bcc @fast_forward_loop

@fast_forward_done:
    rts
.endproc

.proc stop_playback
    stz detail::active
    jsr concerto_synth::panic
    rts
.endproc

.endscope

.endif ; .ifndef SONG_ENGINE_SIMPLE_PLAYER_ASM
