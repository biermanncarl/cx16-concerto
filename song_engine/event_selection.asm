; Copyright 2023-2024 Carl Georg Biermann

; This file implements work with selections. The features work with streams of events.
; Events are located in the entries of a 5-bytes vector, with the time stamp as the first 2 bytes.
; By user interactions with the GUI, these events can become selected and unselected.
; The way how we select and unselect events is by cutting selected events and pasting
; them in a separate, "selected" vector. When an event gets unselected, it is inserted
; back into the original vector.
; Caution: this functionality is NOT intended for use inside the ISR.
; Variables would have to be backed up. This was the case previously, but was removed due
; to lack of need. Commit where the functionality was removed: d9007fef0743c0

.ifndef SONG_DATA_EVENT_SELECTION_ASM
SONG_DATA_EVENT_SELECTION_ASM = 1

.include "../common/x16.asm"
.include "../common/utility_macros.asm"
.include "../dynamic_memory/vector_5bytes.asm"

.scope event_selection


.pushseg
.zeropage
; these variables are only here in ZP for speed and code size, could be moved out if needed

; PART OF API
; pointers to the 40bit vectors with events
selected_events: ; data not owned by this module
    .res 2
unselected_events: ; data not owned by this module
    .res 2

; NOT PART OF API
; other variables (no pointers)
next_selected_event:
    .res 3
last_selected_id:
    .res 2
next_unselected_event:
    .res 3
last_unselected_id:
    .res 2
last_event_source:
    .res 1
.popseg

; reuse some variables for function calls
select_action = last_event_source


.scope detail
.proc loadNextUnselectedEvent
    lda next_unselected_event
    ldx next_unselected_event+1
    ldy next_unselected_event+2
    rts
.endproc

.proc storeNextUnselectedEvent
    sta next_unselected_event
    stx next_unselected_event+1
    sty next_unselected_event+2
    rts
.endproc

.proc loadNextSelectedEvent
    lda next_selected_event
    ldx next_selected_event+1
    ldy next_selected_event+2
    rts
.endproc

.proc storeNextSelectedEvent
    sta next_selected_event
    stx next_selected_event+1
    sty next_selected_event+2
    rts
.endproc

.proc advanceNextSelectedEvent
    ; Expects the current selected event in .A/.X/.Y
    jsr v5b::get_next_entry
    stz next_selected_event+2 ; mark next event as invalid preemptively (will override it if not invalid)
    bcc :+
    rts
:   jsr detail::storeNextSelectedEvent
    rts
.endproc
.endscope

; Given the pointer to a note-on event in .A/.X/.Y, finds the corresponding note-off event by linear search.
; If no matching note-off is found, carry will be set, otherwise clear.
.proc findNoteOff
    ; This function could become a bottleneck!
    ; TODO: to make it faster, read only the data we truly need, instead of using v5b::read_entry, to optimize for speed
    pha
    phx
    phy
    jsr v5b::read_entry
    lda events::note_pitch
    sta pitch
    ply
    plx
    pla
@loop:
    jsr v5b::get_next_entry
    bcs @end ; search failed, end reached before the note-off was found
    pha
    phx
    phy
    jsr v5b::read_entry
    lda events::event_type
    cmp #events::event_type_note_off
    bne @continue_loop
    lda events::note_pitch
    cmp pitch
    beq @success
@continue_loop:
    ply
    plx
    pla
    bra @loop
@success:
    ; recover the pointer from the stack
    ply
    plx
    pla
    clc
@end:
    rts
pitch:
    .byte 0 ; can be optimized away to use a different variable
.endproc





; Common event stream
; ===================
; This section is concerned with providing a unified, temporally ascending
; stream of events, regardless of whether they are selected or not. 


; Resets/initializes the common event stream.
; Expects the selected_events and unselected_events pointers to be set to the respective vectors.
; TODO: actually, we can just keep the selected_events vector, and receive the unselected in .A/.X/.Y ... TBD (#dataOwnership)
.proc resetStream
    ; reset id counters
    lda #$ff
    sta last_selected_id
    sta last_selected_id+1
    sta last_unselected_id
    sta last_unselected_id+1
    ; reset the event pointers to the beginning
    lda selected_events
    ldx selected_events+1
    jsr v5b::get_first_entry
    bcs @selected_is_empty
@selected_is_populated:
    jsr detail::storeNextSelectedEvent
    bra @continue_to_unselected
@selected_is_empty:
    stz next_selected_event+2 ; invalidate
@continue_to_unselected:
    lda unselected_events
    ldx unselected_events+1
    jsr v5b::get_first_entry
    bcs @unselected_is_empty
@unselected_is_populated:
    jsr detail::storeNextUnselectedEvent
    rts
@unselected_is_empty:
    stz next_unselected_event+2 ; invalidate
    rts
.endproc


; Like resetStream, but it sets the unselected event pointer to NULL, so
; streamGetNextEvent only returns selected events in sequence.
; It also doesn't care about id (yet).
; This routine could be optimized for size by factoring out common code with resetStream
.proc resetStreamSelectedOnly
    ; set unselected to NULL
    stz next_unselected_event+2
    ; reset the selected event pointer to the beginning
    lda selected_events
    ldx selected_events+1
    jsr v5b::get_first_entry
    bcs @selected_is_empty
@selected_is_populated:
    jsr detail::storeNextSelectedEvent
    rts
@selected_is_empty:
    stz next_selected_event+2 ; invalidate
    rts
.endproc


; Compares two events and decides which of them comes sooner. (not part of stream API)
; Expects
; * pointer to a valid event in next_selected_event
; * pointer to another valid event in next_unselected_event
; If the "selected" event comes first, carry will be set, otherwise clear (if time stamps and event types are the same, carry will be set)
.proc compareEvents
    ; abusing variables in this function which "belong" to other functions which we don't use
    ; set up zeropage pointers to both entries
    lda next_selected_event+1
    sta v5b::zp_pointer+1
    stz v5b::zp_pointer
    lda next_unselected_event+1
    sta v5b::zp_pointer_2+1
    stz v5b::zp_pointer_2
    ; compute offsets inside the chunk
    lda next_selected_event
    asl
    asl
    adc next_selected_event
    adc #v5b::payload_offset
    sta v5b::value_0 ; selected offset
    lda next_unselected_event
    asl
    asl
    adc next_unselected_event
    adc #v5b::payload_offset
    sta v5b::value_1 ; unselected offset
@compare_high_time_stamp:
    tay
    iny
    ldx next_unselected_event+2
    stx RAM_BANK
    lda (v5b::zp_pointer_2), y ; look up unselected
    ldx next_selected_event+2
    stx RAM_BANK
    ldy v5b::value_0
    iny
    cmp (v5b::zp_pointer), y ; compare to selected
    beq @compare_low_time_stamp
    rts
@compare_low_time_stamp:
    dey
    lda (v5b::zp_pointer), y ; look up selected
    ldx next_unselected_event+2
    stx RAM_BANK
    ldy v5b::value_1
    cmp (v5b::zp_pointer_2), y ; compare with unselected
    beq @compare_event_types
    ; invert the carry flag before returning
    rol
    inc
    ror
    rts
@compare_event_types:
    iny
    iny
    lda (v5b::zp_pointer_2), y ; look up unselected
    ldx next_selected_event+2
    stx RAM_BANK
    ldy v5b::value_0
    iny
    iny
    cmp (v5b::zp_pointer), y ; compare with selected
    rts
.endproc


; Get the next event. This not only takes into account time stamps but also event types, and tries to emit them in the correct order.
; That means, note-offs first, then note-ons, then effects.
; If no more events are available, carry is set upon return, clear otherwise.
; If another event is available, its pointer is returned in .A/.X/.Y
; If another event is available, the content of last_event_source is set to 0 in case the last event was unselected, or $80 if it was selected
; The respective id (last_selected_id/last_unselected_id) is advanced accordingly.
.proc streamGetNextEvent
    ; Check if more events are available
    ldy next_selected_event+2
    bne @selected_not_empty
@selected_empty:
    ldy next_unselected_event+2
    beq @both_empty
    bra @next_unselected
@both_empty:
    sec ; signal that no more events are available
    rts
@selected_not_empty:
    ldy next_unselected_event+2
    beq @next_selected
@both_available:
    jsr compareEvents
    bcc @next_unselected

@next_selected:
    lda #$80
    sta last_event_source
    inc last_selected_id
    bne :+
    inc last_selected_id+1
:   jsr detail::loadNextSelectedEvent
    pha
    phx
    phy
    jsr detail::advanceNextSelectedEvent
    bra @return_pointer
@next_unselected:
    stz last_event_source
    inc last_unselected_id
    bne :+
    inc last_unselected_id+1
:   jsr detail::loadNextUnselectedEvent
    pha
    phx
    phy
    jsr v5b::get_next_entry
    stz next_unselected_event+2 ; mark next event as invalid preemptively (will override it if not invalid)
    bcs @return_pointer
    jsr detail::storeNextUnselectedEvent
@return_pointer:
    ply
    plx
    pla
    clc
    rts
.endproc


; If available, returns the pointer to the next selected event in .A/.X/.Y without advancing
; the stream.
; If available, carry will be clear; set otherwise.
.proc streamPeekNextSelectedEvent
    jsr detail::loadNextSelectedEvent
    cpy #0
    bne :+
    sec
    rts
:   clc
    rts
.endproc

; Deletes the next event from the selected events and advances the stream to the next selected event.
; Expects that the next selected event actually exists (that is, before it gets deleted).
; Meant for use in conjunction with streamPeekNextSelectedEvent.
.proc streamDeleteNextSelectedEvent
    jsr detail::loadNextSelectedEvent
    jsr v5b::get_previous_entry
    bcs @delete_first_event
    pha
    phx
    phy
    jsr v5b::get_next_entry ; lazy way of getting back the original event
    jsr v5b::delete_entry
    ply
    plx
    pla
    jsr detail::advanceNextSelectedEvent
    rts
@delete_first_event:
    ; If the first event gets deleted, we know for sure that afterwards,
    ; the vector is either empty or the original event pointer is a valid one afterwards, too.
    jsr detail::loadNextSelectedEvent
    jsr v5b::delete_entry
    bcc :+
    stz next_selected_event+2 ; it was the only event, invalidate next selected event.
:   rts
.endproc


.macro SET_SELECTED_VECTOR vector_address
    lda vector_address
    sta song_engine::event_selection::selected_events
    lda vector_address+1
    sta song_engine::event_selection::selected_events+1
.endmacro

.macro SET_UNSELECTED_VECTOR vector_address
    lda vector_address
    sta song_engine::event_selection::unselected_events
    lda vector_address+1
    sta song_engine::event_selection::unselected_events+1
.endmacro

; maybe move into v5b?
.macro SWAP_VECTORS vector_a, vector_b
    pha
    phy
    lda vector_a
    ldy vector_b
    sty vector_a
    sta vector_b
    lda vector_a+1
    ldy vector_b+1
    sty vector_a+1
    sta vector_b+1
    ply
    pla
.endmacro


; Swaps the selected and unselected vector.
; This is useful to unselect items.
.proc swapSelectedUnselectedVectors
    SWAP_VECTORS selected_events, unselected_events
    rts
.endproc



; Individual item selection and unselection
; =========================================
; This is a separate API, which cannot be used at the same time as the
; "Common streams" API as it works with partly the same ZP variables, and some functions (the "merge" ones) use the streams API internally.
; (this could be changed, though, so that each API has its own ZP variables
; and can be used fully independently from each other).


; Moves an event from an event vector to the selected events vector.
; * In .A/.X/.Y, expects the pointer to the object to be selected,
; * In select_action, expects the action to be done on the original event (one of selectEvent::action options).
; If the object is a note-on, the corresponding note-off is automatically selected, too.
; Returns in .A/.X/.Y the address of the newly selected event.
.proc selectEvent
    .scope action
        ID_GENERATOR 0, delete_original, invalidate_original, keep_original
    .endscope
    jsr detail::storeNextUnselectedEvent
    lda selected_events
    ldx selected_events+1
    jsr v5b::get_first_entry
    bcc :+
    ldy #0 ; set .A/.X/.Y pointer to NULL if event doesn't exist
:   jsr detail::storeNextSelectedEvent
    jsr insertInSelectedEvents
    pha ; remember address of the newly selected event
    phx
    phy
    beq @handle_note_off ; if it wasn't a note-on, we can go straight to deleting this event
    jsr detail::loadNextUnselectedEvent
@handle_original:
    jsr handleOriginal
    ; pull the address of the newly selected event from the stack
    ply
    plx
    pla
    rts

@handle_note_off:
    ; As the event was a note-on, need to also select note-off.
    ; save the position of the recently selected event
    jsr detail::storeNextSelectedEvent
    ; first, save the currently selected element, so we can deal with it later (delete/invalidate/keep)
    jsr detail::loadNextUnselectedEvent
    pha
    phx
    phy
    ; copy the note-off to selected events
    jsr findNoteOff
    jsr detail::storeNextUnselectedEvent
    jsr insertInSelectedEvents
    ; delete note-off first because then we know for sure where the remaining note-on is (the other way round we wouldn't know for sure)
    jsr detail::loadNextUnselectedEvent
    jsr handleOriginal
    ; deal with note-on
    ply
    plx
    pla
    bra @handle_original

    ; performs the selected action on the original selected event.
    ; In .A/.X/.Y, expects the pointer to the original selected event.
    .proc handleOriginal
        pha
        lda select_action
        bne @check_keep
        pla
        jsr v5b::delete_entry
        rts
    @check_keep:
        cmp #action::keep_original
        bne @invalidate
        pla
        rts
    @invalidate:
        ; the only action remaining is invalidate
        pla
        pha
        phx
        phy
        jsr v5b::read_entry
        lda #events::event_type_invalid
        sta events::event_type
        ply
        plx
        pla
        jsr v5b::write_entry
        rts
    .endproc

    ; sub routine which does the insertion of a single event in the "selected" events vector.
    ; Expects:
    ;   * in next_unselected_event, pointer event to be copied
    ;   * in next_selected_event, pointer to any event known to come before the given event (WRT time stamps)
    ;     in the "selected" vector, or NULL if such an event is not contained
    ; Returns:
    ;   * in zero flag, whether the event was a note-on (z=1 if yes, z=0 if not)
    ;   * in .A/.X/.Y, the position of the copied event where it has been inserted
    ;   * next_unselected_event is preserved
    .proc insertInSelectedEvents
    @search_loop:
        ldy next_selected_event+2
        beq @append ; append if next selected is NULL
        jsr compareEvents
        bcc @insert_position_found
        jsr detail::loadNextSelectedEvent
        jsr v5b::get_next_entry
        bcs @append
        jsr detail::storeNextSelectedEvent
        bra @search_loop

    @append:
        jsr readEventAndCheckNoteOn
        php
        lda selected_events ; alternatively, we could use the values in next_selected_event and thus make it independent from selected_events being set correctly.
        ldx selected_events+1 ; This could allow for efficient "selection" into varying vectors.
        jsr v5b::append_new_entry
        lda selected_events
        ldx selected_events+1
        jsr v5b::get_last_entry
        plp
        rts
    @insert_position_found:
        jsr readEventAndCheckNoteOn
        php
        jsr detail::loadNextSelectedEvent
        jsr v5b::insert_entry
        plp
        rts

        .proc readEventAndCheckNoteOn
            jsr detail::loadNextUnselectedEvent
            jsr v5b::read_entry
            lda events::event_type
            cmp #events::event_type_note_on
            rts
        .endproc
    .endproc
.endproc


; Moves an event from the selected to the unselected vector.
; * In .A/.X/.Y, expects the pointer to the object to be unselected,
; * In select_action, expects the action to be done on the original event (one of selectEvent::action options).
; If the object is a note-on, the corresponding note-off is automatically unselected, too.
.proc unselectEvent
    jsr swapSelectedUnselectedVectors
    jsr selectEvent
    jsr swapSelectedUnselectedVectors
    rts
.endproc


; Merges all unselected events into the selected events vector. (Untested!)
; To unselect all, call swapSelectedUnselectedVectors before and after this function.
.proc selectAllEvents
    ; Using stream API.
    ; Basically stream them, but instead of just "consuming" the event, it gets inserted into the selected vector.
    ; We need to do some more book-keeping to not break the stream API's illusion that it's just normally streaming.
    ; One thing we don't do here is to correct the selected/unselected id as it is not needed here.
    jsr resetStream
@merge_loop:
    jsr streamGetNextEvent
    bcs @merge_loop_end ; returns event pointer in .A/.X/.Y
    pha
    ; is the next event already selected?
    lda last_event_source
    bpl @insert_event ; action required
    ; already selected, no action required --> go to next
    pla
    bra @merge_loop

@insert_event:
    ; insert event into selected events vector
    pla
    jsr v5b::read_entry

    ldy next_selected_event+2
    beq @append_event ; are we already at the end of the selected events vector?
    ; selected events vector isn't empty: insert before next_selected_event
    lda next_selected_event
    ldx next_selected_event+1
    jsr v5b::insert_entry
    ; Use the fact that v5b::insert_entry returns the new position of the inserted entry:
    jsr v5b::get_next_entry
    bcc :+
    ldy #0 ; set to nullptr if next selected event doesn't exist
:   jsr detail::storeNextSelectedEvent
    bra @merge_loop
@append_event:
    lda selected_events
    ldx selected_events+1
    jsr v5b::append_new_entry
    ; don't need to deal with next_selected_event, since it is already nullptr, which is what we want in this case
    bra @merge_loop

@merge_loop_end:
    ; remove all events from unselected vector
    lda unselected_events
    ldx unselected_events+1
    jsr v5b::clear
    rts
.endproc


; Merges all selected events into the unselected events vector.
.proc unSelectAllEvents
    jsr swapSelectedUnselectedVectors
    jsr selectAllEvents
    jsr swapSelectedUnselectedVectors
    rts
.endproc

; Deletes all invalid events from an event vector.
; Expects the pointer to the vector in .A/.X
.proc deleteAllInvalidEvents
    ; iterate from last to first event for slight efficiency boost (need to move less data around)
    jsr v5b::get_last_entry
    bcc @events_loop
    rts

@events_loop:
    jsr detail::storeNextUnselectedEvent ; save current event
    jsr v5b::read_entry
    lda events::event_type
    cmp #events::event_type_invalid
    php ; remember if it's an invalid event
    jsr detail::loadNextUnselectedEvent ; recall current event to get previous
    jsr v5b::get_previous_entry
    bcc :+
    ldy #0 ; set event pointer to NULL if no previous one exists
:   jsr detail::storeNextSelectedEvent
    plp ; recall if it's an invalid event
    bne @continue
@delete_event:
    jsr detail::loadNextUnselectedEvent
    jsr v5b::delete_entry
@continue:
    jsr detail::loadNextSelectedEvent
    cpy #0 ; check if NULL
    bne @events_loop
    rts
.endproc


.if 0
    ; Earlier attempt at writing this functionality (not sure if finished)
    ; Merges all unselected events into the selected events vector.
    ; To unselect all, call swapSelectedUnselectedVectors before and after this function.
    .proc selectAllEvents
        ; This function is implemented for small code size.
        ; Should it become a bottleneck, this could be implemented without calling selectEvent.
        ; The main point of optimization would be that we don't have to delete the events from the
        ; unselected vector individually (an expensive operation), but could discard them at the
        ; end at once. We would also not need to care about finding matching note-offs, as they
        ; will always be contained in "all".

        ; Initialization
        lda selected_events
        ldx selected_events+1
        jsr v5b::get_first_entry
        jsr detail::storeNextSelectedEvent
        ; we basically grab the first event over and over again (as they get deleted one by one)
    @merge_loop:
        lda unselected_events
        ldx unselected_events+1
        jsr v5b::get_first_entry
        bcs @end_merge_loop

        
        bra @merge_loop
    @end_merge_loop:


        rts
    .endproc

.endif

.endscope

.endif ; .ifndef SONG_DATA_EVENT_SELECTION_ASM
