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
        jsr v40b::read_entry
        lda events::event_time_stamp_l
        sta next_time_stamp
        lda events::event_time_stamp_h
        sta next_time_stamp+1
        clc
        rts
    .endproc
.endscope

.proc player_tick
    lda detail::active
    bne :+
    rts
:
    ; TODO: take care of ISR-stream-swap
    ; TODO: do live updates while editing
    ; TODO: polyphony
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
    jsr v40b::read_entry

    lda events::event_type
    beq @note_off ; #events::event_type_note_off
    cmp #events::event_type_note_on
    bne @continue_next_event ; for now, ignore all events that aren't note-on or note-off
@note_on:
    lda events::note_pitch
    sta concerto_synth::note_pitch
    lda #0  ; concerto_gui::gui_variables::current_synth_timbre
    sta concerto_synth::note_timbre
    lda #0 ; TODO: polyphony
    sta concerto_synth::note_channel
    lda #MAX_VOLUME ;concerto_gui::play_volume   ; TODO: velocity sensitivity
    jsr concerto_synth::play_note
    bra @continue_next_event
@note_off:
    ; TODO: pitch sensitivity for polyphony
    ldx #0
    stx concerto_synth::note_channel
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
    ;jsr concerto_synth::panic
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
