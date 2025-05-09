; Copyright 2023-2025 Carl Georg Biermann

; This file implements work with selections. There are two vectors, vector A and vector B,
; which can broadly be imagined as a vector of selected and unselected events, respectively.
; Events are located in the entries of a 5-bytes vector, with the time stamp as the first 2 bytes.
; By user interactions with the GUI, these events can become selected and unselected.
; The way how we select and unselect events is by cutting selected events from their original vector
; (typically vector B) and pasting them in a separate, "selected" vector (typically vector A).
; When an event gets unselected, it is inserted back into the original vector.
; Caution: this functionality is NOT intended for use inside the ISR.
; Variables would have to be backed up. This was the case previously, but was removed due
; to lack of need. Commit where the functionality was removed: d9007fef0743c0

.ifndef SONG_DATA_EVENT_SELECTION_ASM
SONG_DATA_EVENT_SELECTION_ASM = 1

.include "../common/x16.asm"
.include "../common/utility_macros.asm"
.include "../dynamic_memory/vector_5bytes.asm"

.scope event_selection

.include "pre_parsing.asm"

.pushseg
.zeropage
; these variables are only here in ZP for speed and code size, could be moved out if needed

; PART OF API
; pointers to the 5-byte vectors with events.
; Mostly input variables, sometimes output, as well.
event_vector_a: ; data not owned by this module
    .res 2
event_vector_b: ; data not owned by this module
    .res 2

; NOT PART OF API
; other variables (no pointers)
next_event_a:
    .res 3
next_event_b:
    .res 3
most_recent_event_source:
    .res 1
temp_vector_x:
    .res 3
temp_vector_y:
    .res 3
.popseg

; reuse some variables for function calls
move_action = most_recent_event_source


.scope detail
.proc loadNextEventInB
    lda next_event_b
    ldx next_event_b+1
    ldy next_event_b+2
    rts
.endproc

.proc storeNextEventInB
    sta next_event_b
    stx next_event_b+1
    sty next_event_b+2
    rts
.endproc

.proc loadNextEventInA
    lda next_event_a
    ldx next_event_a+1
    ldy next_event_a+2
    rts
.endproc

.proc storeNextEventInA
    sta next_event_a
    stx next_event_a+1
    sty next_event_a+2
    rts
.endproc

.proc advanceNextEventA
    ; Expects the current event of vector a in .A/.X/.Y
    jsr v5b::get_next_entry
    stz next_event_a+2 ; mark next event as invalid preemptively (will override it if not invalid)
    bcc :+
    rts
:   jsr detail::storeNextEventInA
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


; Given the pointer to an event in .A/.X/.Y, finds a pre-ceeding note-on event by linear search.
; The pitch of the note-on has to be passed in findNoteOn::pitch.
; If no matching note-on is found, carry will be set, otherwise clear.
.proc findNoteOn
    ; Question: do we tolerate other note-offs in between? Maybe we shouldn't, maybe it doesn't matter.
    pitch = findNoteOff::pitch  ; simply reusing that variable
@loop:
    jsr v5b::get_previous_entry
    bcs @end ; search failed, end reached before the note-off was found
    pha
    phx
    phy
    jsr v5b::read_entry
    lda events::event_type
    cmp #events::event_type_note_on
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
.endproc


; Expects the pointer to an events vector in .A/.X,
; and the time stamp in timing::time_stamp_parameter.
; Returns the first event which comes at the given time stamp or later.
; If no such event exists, carry will be set; otherwise clear.
; This function aims to be performant by doing "hierarchical" linear search,
; i.e. it first narrows down the search across chunks, and then within a chunk.
; This function only needs to run in the main program (starting playback, moving events about, potentially drawing routine).
.proc findEventAtTimeStamp
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
    cmp timing::time_stamp_parameter+1
    bne :+
    ; high bytes equal, compare low bytes
    lda events::event_time_stamp_l
    cmp timing::time_stamp_parameter
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
    cmp timing::time_stamp_parameter+1
    bne :+
    ; high bytes equal, compare low bytes
    lda events::event_time_stamp_l
    cmp timing::time_stamp_parameter
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




; Common event stream
; ===================
; This section is concerned with providing a unified, temporally ascending
; stream of events, regardless of whether they are in vector a or b.


; Resets/initializes the common event stream.
; Expects the event_vector_a and event_vector_b pointers to be set to the respective vectors.
; TODO: actually, we can just keep the event_vector_a vector, and receive the first event of vector B in .A/.X/.Y ... TBD (#dataOwnership)
.proc resetStream
    ; reset the event pointers to the beginning
    lda event_vector_a
    ldx event_vector_a+1
    jsr v5b::get_first_entry
    bcs @vector_a_is_empty
@vector_a_is_populated:
    jsr detail::storeNextEventInA
    bra @continue_vector_b
@vector_a_is_empty:
    stz next_event_a+2 ; invalidate
@continue_vector_b:
    lda event_vector_b
    ldx event_vector_b+1
    jsr v5b::get_first_entry
    bcs @vector_b_is_empty
@vector_b_is_populated:
    jsr detail::storeNextEventInB
    rts
@vector_b_is_empty:
    stz next_event_b+2 ; invalidate
    rts
.endproc


; Like resetStream, but it sets the B event pointer to NULL, so
; streamGetNextEvent only returns events of vector A in sequence.
; It also doesn't care about id (yet).
; This routine could be optimized for size by factoring out common code with resetStream
.proc resetStreamVectorAOnly
    ; set B to NULL
    stz next_event_b+2
    ; reset the event pointer A to the beginning
    lda event_vector_a
    ldx event_vector_a+1
    jsr v5b::get_first_entry
    bcs @vector_a_is_empty
@vector_a_is_populated:
    jsr detail::storeNextEventInA
    rts
@vector_a_is_empty:
    stz next_event_a+2 ; invalidate
    rts
.endproc


; Compares two events and decides which of them comes sooner. (not part of stream API)
; Expects
; * pointer to a valid event in next_event_a
; * pointer to another valid event in next_event_b
; If the vector-A event comes first, carry will be set, otherwise clear (if time stamps and event types are the same, carry will be set)
.proc compareEvents
    ; abusing variables in this function which "belong" to other functions which we don't use
    ; set up zeropage pointers to both entries
    lda next_event_a+1
    sta v5b::zp_pointer+1
    stz v5b::zp_pointer
    lda next_event_b+1
    sta v5b::zp_pointer_2+1
    stz v5b::zp_pointer_2
    ; compute offsets inside the chunk
    lda next_event_a
    asl
    asl
    adc next_event_a
    adc #v5b::payload_offset
    sta v5b::value_0 ; offset in vector A's chunk
    lda next_event_b
    asl
    asl
    adc next_event_b
    adc #v5b::payload_offset
    sta v5b::value_1 ; offset in vector B's chunk
@compare_high_time_stamp:
    tay
    iny
    ldx next_event_b+2
    stx RAM_BANK
    lda (v5b::zp_pointer_2), y ; look up in B
    ldx next_event_a+2
    stx RAM_BANK
    ldy v5b::value_0
    iny
    cmp (v5b::zp_pointer), y ; compare with A
    beq @compare_low_time_stamp
    rts
@compare_low_time_stamp:
    dey
    lda (v5b::zp_pointer), y ; look up in A
    ldx next_event_b+2
    stx RAM_BANK
    ldy v5b::value_1
    cmp (v5b::zp_pointer_2), y ; compare with B
    beq @compare_event_types
    ; invert the carry flag before returning
    rol
    inc
    ror
    rts
@compare_event_types:
    iny
    iny
    lda (v5b::zp_pointer_2), y ; look up in B
    ldx next_event_a+2
    stx RAM_BANK
    ldy v5b::value_0
    iny
    iny
    cmp (v5b::zp_pointer), y ; compare with A
    rts
.endproc


; Get the next event. This not only takes into account time stamps but also event types, and tries to emit them in the correct order.
; That means, note-offs first, then note-ons, then effects.
; If no more events are available, carry is set upon return, clear otherwise.
; If another event is available, its pointer is returned in .A/.X/.Y
; If another event is available, the content of most_recent_event_source is set to 0 in case the last event was vector_b, or $80 if it was vector_a
.proc streamGetNextEvent
    ; Check if more events are available
    ldy next_event_a+2
    bne @vector_a_not_empty
@vector_a_empty:
    ldy next_event_b+2
    beq @both_empty
    bra @next_vector_b
@both_empty:
    sec ; signal that no more events are available
    rts
@vector_a_not_empty:
    ldy next_event_b+2
    beq @next_vector_a
@both_available:
    jsr compareEvents
    bcc @next_vector_b

@next_vector_a:
    lda #$80
    sta most_recent_event_source
    jsr detail::loadNextEventInA
    pha
    phx
    phy
    jsr detail::advanceNextEventA
    bra @return_pointer
@next_vector_b:
    stz most_recent_event_source
    jsr detail::loadNextEventInB
    pha
    phx
    phy
    jsr v5b::get_next_entry
    stz next_event_b+2 ; mark next event as invalid preemptively (will override it if not invalid)
    bcs @return_pointer
    jsr detail::storeNextEventInB
@return_pointer:
    ply
    plx
    pla
    clc
    rts
.endproc


; If available, returns the pointer to the next event of vector_a in .A/.X/.Y without advancing
; the stream.
; If available, carry will be clear; set otherwise.
.proc streamPeekNextEventInA
    jsr detail::loadNextEventInA
    cpy #0
    bne :+
    sec
    rts
:   clc
    rts
.endproc

; Deletes the next event from vector_a and advances the stream to the next event in A.
; Expects that the next event in A actually exists (that is, before it gets deleted).
; Meant for use in conjunction with streamPeekNextEventInA.
.proc streamDeleteNextEventInA
    jsr detail::loadNextEventInA
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
    jsr detail::advanceNextEventA
    rts
@delete_first_event:
    ; If the first event gets deleted, we know for sure that afterwards,
    ; the vector is either empty or the original event pointer is a valid one afterwards, too.
    jsr detail::loadNextEventInA
    jsr v5b::delete_entry
    bcc :+
    stz next_event_a+2 ; it was the only event, invalidate next event in vector A.
:   rts
.endproc


.macro SET_VECTOR_A vector_address
    lda vector_address
    sta song_engine::event_selection::event_vector_a
    lda vector_address+1
    sta song_engine::event_selection::event_vector_a+1
.endmacro

.macro SET_VECTOR_B vector_address
    lda vector_address
    sta song_engine::event_selection::event_vector_b
    lda vector_address+1
    sta song_engine::event_selection::event_vector_b+1
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



; Individual item selection and unselection
; =========================================
; This is a separate API, which cannot be used at the same time as the
; "Common streams" API as it works with partly the same ZP variables, and some functions (the "merge" ones) use the streams API internally.
; (this could be changed, though, so that each API has its own ZP variables
; and can be used fully independently from each other).


; Moves an event from an event vector to event_vector_a and merges potentially overlapping notes.
; event_vector_b will be cluttered, event_vector_a may be relocated.
; * In .A/.X/.Y, expects the pointer to the object to be moved,
; * In move_action, expects the action to be done on the original event (one of moveEventToA::action options).
; If the object is a note-on, the corresponding note-off is automatically moved, too.
; Best used in conjunction with the macro
.proc moveEventToA
    .scope action
        ID_GENERATOR 0, delete_original, invalidate_original, keep_original
    .endscope
    ; Append event(s) to new temporary vector.
    jsr detail::storeNextEventInA ; save event pointer
    jsr v5b::read_entry
    jsr v5b::new
    sta event_vector_b
    stx event_vector_b+1
    jsr v5b::append_new_entry
    ; Deal with potential note-off
    lda events::event_type
    cmp #events::event_type_note_on
    bne @note_off_done
        jsr detail::loadNextEventInA
        jsr findNoteOff
        jsr detail::storeNextEventInB
        jsr v5b::read_entry
        lda event_vector_b
        ldx event_vector_b+1
        jsr v5b::append_new_entry
        jsr detail::loadNextEventInB
        jsr handleOriginal
    @note_off_done:
    jsr detail::loadNextEventInA
    jsr handleOriginal
    ; Now merge the temporary vector into event_vector_a
    jsr moveAllEventsFromBToA
    ; Destroy temporary vector
    lda event_vector_b
    ldx event_vector_b+1
    jmp v5b::destroy

    ; performs the desired action on the originally selected event.
    ; In .A/.X/.Y, expects the pointer to the originally selected event.
    .proc handleOriginal
        pha
        lda move_action
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
.endproc


; Expects pointer to event in .A/.X/.Y
.macro MOVE_EVENT_TO_VECTOR target_vector
    pha
    lda target_vector
    sta song_engine::event_selection::event_vector_a
    lda target_vector+1
    sta song_engine::event_selection::event_vector_a+1
    pla
    jsr song_engine::event_selection::moveEventToA
    lda song_engine::event_selection::event_vector_a
    sta target_vector
    lda song_engine::event_selection::event_vector_a+1
    sta target_vector+1
.endmacro


; Merges all events from vector_b into vector_a.
; Caution: This subroutine may alter the location of the vectors. After calling this, you need to read back event_vector_a and event_vector_b.
; Solves "merge conflicts" (e.g. overlapping notes) between the two vectors.
; Therefore best used in conjunction with the macro MOVE_EVENTS_FROM_B_TO_A.
.proc moveAllEventsFromBToA
    ; This is a more efficient implementation than the first one, especially for a large disparity in vector sizes.
    ; It only does timestamp-based merging of the two vectors on the section necessary (overlapping time stamps)
    ; and splices the other parts.

    jsr resetStream
    jsr streamGetNextEvent  ; just used to get info about the first events. Stream will be re-initialized before actual merge.
    bcc @at_least_one_vector_not_empty
    @finish_early:
        ; both vectors empty, nothing to do
        rts
    @at_least_one_vector_not_empty:

    ; Check if vector B is empty, because then we don't need to do anything.
    lda next_event_b+2
    beq @finish_early
    ; We can't finish early if vector A is empty because we still need to make sure that the notes in B aren't self-overlapping.

    ; The goal of this block is to have in
    ; * event_vector_a  all relevant events for the merge (events starting with )
    ; * event_vector_b  as provided by the caller
    ; * temp_vector_x   all events which come before those in vector B. If there are none, it shall be NULL
    ; Pre-parsing shall be run up to the point where merging starts.
    lda most_recent_event_source
    beq @vector_b_first
    @vector_a_first:
        ; Since A is trusted, we can cut it at the first time stamp of B and start parsing events from there.
        ; get first timestamp of vector B
        lda next_event_b
        ldx next_event_b+1
        ldy next_event_b+2
        jsr v5b::read_entry
        lda events::event_time_stamp_l
        sta pre_parsing::target_timestamp
        lda events::event_time_stamp_h
        sta pre_parsing::target_timestamp+1
        ; do the split
        lda event_vector_a
        ldx event_vector_a+1
        jsr pre_parsing::findActiveNotesAtTimestamp ; also returns the next event at that time stamp
        bcc @split_needed
        @no_split_needed:
            ; no events after that time stamp, no split needed
            lda event_vector_a
            ldx event_vector_a+1
            sta temp_vector_x
            stx temp_vector_x+1
            ; Create a new empty vector
            jsr v5b::new
            sta event_vector_a
            stx event_vector_a+1
            bra @which_first_done
        @split_needed:
            ; .A/.X/.Y contain the pointer to the next event after the time stamp
            jsr v5b::splitVectorBeforeEntry ; returns the second half of the split
            cmp #0
            bne @split_really_needed ; This can only happen when both vectors start at the same timestamp.
            @no_split_needed_2:
                stz temp_vector_x
                bra @which_first_done
            @split_really_needed:
            jsr v5b::get_first_entry
            sta next_event_a
            stx next_event_a+1
            sty next_event_a+2
            ; Move the first part of the split vector to temp_vector_x
            lda event_vector_a
            ldx event_vector_a+1
            sta temp_vector_x
            stx temp_vector_x+1
            ; Replace former event_vector_a by the second half of its split
            lda next_event_a+2
            ldx next_event_a+1
            sta event_vector_a
            stx event_vector_a+1
            bra @which_first_done
    @vector_b_first:
        ; B comes first, we have to start parsing events normally from the beginning.
        ; Set temp_vector_x to NULL so we don't do an unnecessary concatenation later.
        stz temp_vector_x
        ; Since we start parsing directly from the beginning of both vectors, there are no active notes.
        jsr pre_parsing::clearActiveNotes
    @which_first_done:

    ; Set up new vector for events to be written to
    ; We don't just append to temp_vector_x because then we would have to find its end for every event we want to add.
    ; We have to do the same with the new vector, but it's likely much shorter.
    jsr v5b::new
    sta temp_vector_y
    stx temp_vector_y+1

    jsr resetStream
    @merge_loop:
        jsr streamGetNextEvent
        ; no need to check carry because we check for empty vectors ourselves
        jsr v5b::read_entry
        lda events::event_type
        beq @note_off
        cmp #events::event_type_note_on
        bne @do_copy
        @note_on:
            ; check if there is already a note active at the same pitch
            ldx events::note_pitch
            lda pre_parsing::notes_active, x
            inc
            cmp #1 ; would after this note-on be exactly one note at this pitch be active?
            sta pre_parsing::notes_active, x
            ; yes? --> all good, copy the note-on
            beq @do_copy
            ; no? Uh-oh, we've got overlapping notes.
            ; It would be nice to insert a note-off and retain the note-on.
            ; But there are two problems which make it more complicated than it seems:
            ; * We need to ensure that in the target vector, all note-offs within a time stamp preceed note-ons.
            ; * There is a possibility that we are creating a note of zero length.
            ; We could cope with these problems, but for now, the safest and easiest solution is to just omit the surplus note-on.
            bra @merge_loop
        @note_off:
            ; check if there is already a note active at the same pitch
            ldx events::note_pitch
            dec pre_parsing::notes_active, x
            ; Zero-flag denotes whether before this note-off, there would have been exactly one note active.
            ; If yes, we take the note-on, otherwise we've got overlapping notes and omit the note-off.
            beq @do_copy
            bra @merge_loop
        @do_copy:
        lda temp_vector_y
        ldx temp_vector_y+1
        jsr v5b::append_new_entry

        ; check if we arrived at the end of vector B (if vector B ends before A, we splice in the tail of A because A is the trusted vector)
        lda next_event_b+2
        bne @merge_loop
    @end_merge_loop:

    ; Our merge strategy of omitting any events as long as there are overlapping notes ensures that we won't have
    ; any dangling note-off events in the remaining events that haven't been parsed.

    ; Vector A                    o---------------o     o---o ....
    ; Vector B                           o---o                       (note-off is last event in Vector B, merge loop will stop here)
    ; Result                      o------x---x-...                   (events in Vector B discarded, note-off in Vector A remains and matches still active note)

    ; Vector A                           o--------o     o---o ....
    ; Vector B                    o----------o                       (note-off is last event in Vector B, merge loop will stop here)
    ; Result                      o------x---x-...                   (events during overlap discarded, note-off in Vector A remains and matches still active note)

    ; Vector A                           o---o          o---o ....
    ; Vector B                    o---------------o                  (note-off is last event in Vector B, merge loop will stop here)
    ; Result                      o------x---x----o                  (events in Vector A discarded, no dangling note-off, no active note)

    ; The current solution should even be able to cope with overlapping notes within a single vector (e.g. after resizing operation)

    ; We've copied all events from vector B, so let's empty it.
    lda event_vector_b
    ldx event_vector_b+1
    jsr v5b::clear

    ; Check if vector A still contains events, and if yes, append them to temp_vector_y.
    ldy next_event_a+2
    beq @vector_a_already_used_up
        ; Need to cut vector a and append to temp_vector_y
        lda next_event_a
        ldx next_event_a+1
        jsr v5b::splitVectorBeforeEntry
        cmp #0
        bne @vector_a_was_split
        @vector_a_wasnt_split:
            ; the event was the first one, i.e. all events in vector B came earlier than those from vector A
            ; Append entire vector A to temp_vector_y
            lda event_vector_a
            ldx event_vector_a+1
            sta v5b::zp_pointer_2
            stx v5b::zp_pointer_2+1
            lda temp_vector_y
            ldx temp_vector_y+1
            jsr v5b::concatenateVectors
            ; No cleanup of vector A needed as it continues to exist inside temp_vector_y.
            bra @splice_end_done
        @vector_a_was_split:
            ; Could be optimized for size (couple of common code lines with block above)
            sta v5b::zp_pointer_2
            stx v5b::zp_pointer_2+1
            lda temp_vector_y
            ldx temp_vector_y+1
            jsr v5b::concatenateVectors
            ; Fall through to vector_a_already_used_up
    @vector_a_already_used_up:
        ; Cleanup the part of A that was already merged earlier.
        lda event_vector_a
        ldx event_vector_a+1
        jsr v5b::destroy
    @splice_end_done:
    ; Pointer in event_vector_a may be overwritten now.


    ; merge temp_vector_x with temp_vector_y and copy result to event_vector_a
    lda temp_vector_x
    beq @no_merge_needed
    @do_merge:
        ldx temp_vector_x+1
        ; already set event_vector_a to the beginning of the merged new vector
        sta event_vector_a
        stx event_vector_a+1
        ; Do the merge
        ldy temp_vector_y
        sty v5b::zp_pointer_2
        ldy temp_vector_y+1
        sty v5b::zp_pointer_2+1
        jmp v5b::concatenateVectors
    @no_merge_needed:
        ; Nothing in temp_vector_x, just use temp_vector_y.
        lda temp_vector_y
        ldx temp_vector_y+1
        sta event_vector_a
        stx event_vector_a+1
        rts
.endproc




; Previous (functional) version, but without resolving merge conflicts and without splicing.
; Merges all events from vector_b into vector_a.
; For the other direction, call swapVectorsAB before and after this function.
.proc moveAllEventsFromBToA_simple
    ; Using stream API.
    ; Basically stream them, but instead of just "consuming" the event, it gets inserted into vector A.
    ; We need to do some more book-keeping to not break the stream API's illusion that it's just normally streaming.
    ; One thing we don't do here is to correct the "most recent ids" as they are not needed here.
    jsr resetStream
@merge_loop:
    jsr streamGetNextEvent
    bcs @merge_loop_end ; returns event pointer in .A/.X/.Y
    pha
    ; is the next event already in vector A?
    lda most_recent_event_source
    bpl @insert_event ; action required
    ; already in vector A, no action required --> go to next
    pla
    bra @merge_loop

@insert_event:
    ; insert event into vector A
    pla
    jsr v5b::read_entry

    ldy next_event_a+2
    beq @append_event ; are we already at the end of vector A?
    ; vector A isn't empty: insert before next_event_a
    lda next_event_a
    ldx next_event_a+1
    jsr v5b::insert_entry
    ; Use the fact that v5b::insert_entry returns the new position of the inserted entry:
    jsr v5b::get_next_entry
    bcc :+
    ldy #0 ; set to nullptr if next event in vector A doesn't exist
:   jsr detail::storeNextEventInA
    bra @merge_loop
@append_event:
    lda event_vector_a
    ldx event_vector_a+1
    jsr v5b::append_new_entry
    ; don't need to deal with next_event_a, since it is already nullptr, which is what we want in this case
    bra @merge_loop

@merge_loop_end:
    ; remove all events vector B
    lda event_vector_b
    ldx event_vector_b+1
    jsr v5b::clear
    rts
.endproc


; Moves all events from vector b to vector a.
; The contents of vector b are checked for self-overlapping notes, and the two vectors are cross-checked for overlaps.
; Overlapping notes are joined into one long note.
; Caution: The addresses of the vectors may change. In other words, this macro assumes temporary ownership of the vectors.
;          Other copies of the pointer need to be updated.
; Parameters: vector_a absolute address of B/H pointer to an event vector (all events will be merged into this one)
;             vector_b absolute address of B/H pointer to another event vector (this vector will be empty afterwards)
.macro MOVE_EVENTS_FROM_B_TO_A vector_a, vector_b
    SET_VECTOR_A vector_a
    SET_VECTOR_B vector_b
    jsr song_engine::event_selection::moveAllEventsFromBToA
    lda song_engine::event_selection::event_vector_a
    ldx song_engine::event_selection::event_vector_a+1
    sta vector_a
    stx vector_a+1
    lda song_engine::event_selection::event_vector_b
    ldx song_engine::event_selection::event_vector_b+1
    sta vector_b
    stx vector_b+1
.endmacro


.macro MOVE_EVENTS_FROM_B_TO_A_SIMPLE vector_a, vector_b
    SET_VECTOR_A vector_a
    SET_VECTOR_B vector_b
    jsr song_engine::event_selection::moveAllEventsFromBToA_simple
    lda song_engine::event_selection::event_vector_a
    ldx song_engine::event_selection::event_vector_a+1
    sta vector_a
    stx vector_a+1
    lda song_engine::event_selection::event_vector_b
    ldx song_engine::event_selection::event_vector_b+1
    sta vector_b
    stx vector_b+1
.endmacro


; Deletes all invalid events from an event vector.
; Expects the pointer to the vector in .A/.X
.proc deleteAllInvalidEvents
    ; iterate from last to first event for slight efficiency boost (need to move less data around)
    jsr v5b::get_last_entry
    bcc @events_loop
    rts

@events_loop:
    jsr detail::storeNextEventInB ; save current event
    jsr v5b::read_entry
    lda events::event_type
    cmp #events::event_type_invalid
    php ; remember if it's an invalid event
    jsr detail::loadNextEventInB ; recall current event to get previous
    jsr v5b::get_previous_entry
    bcc :+
    ldy #0 ; set event pointer to NULL if no previous one exists
:   jsr detail::storeNextEventInA
    plp ; recall if it's an invalid event
    bne @continue
@delete_event:
    jsr detail::loadNextEventInB
    jsr v5b::delete_entry
@continue:
    jsr detail::loadNextEventInA
    cpy #0 ; check if NULL
    bne @events_loop
    rts
.endproc


; Vectors of currently processed events on the GUI.
; unselected_events_vector will typically be pointed at the event vector of a clip, so it's a "non-owning" pointer.
; selected_events_vector is initialized as an empty vector, so events can be selected into and unselected from it. It's an "owning" pointer of all currently selected events.
.pushseg ; why on zeropage??
.zeropage
unselected_events_vector:
   .res 2
selected_events_vector:
   .res 2
.popseg


; Assumes that unselected_events_vector is free of overlapping notes, but
; removes note overlap from within selected_events_vector and between it and the unselected events.
; Overlapping notes will be merged into one long note.
.proc unselectAllEvents
    MOVE_EVENTS_FROM_B_TO_A unselected_events_vector, selected_events_vector
    rts
.endproc


.proc selectEvent
    MOVE_EVENT_TO_VECTOR song_engine::event_selection::selected_events_vector
    rts
.endproc


; Moves a note-on in .A/.X/.Y into the vector of selected events, and returns its new location in .A/.X/.Y.
; Also moves the corresponding note-off.
; If the moved note-on cannot be found, pointed_at_event will be set to NULL. (E.g. during "merge conflicts")
; In move_action, expects the action to be done on the original event (one of moveEventToA::action options).
.proc selectNoteFindNewLocation
    pitch = next_event_b
    ; remember timestamp and pitch of note-on so we can find it later (We'll just assume it's a note-on for now, so only need to remember pitch)
    jsr detail::storeNextEventInA
    jsr v5b::read_entry
    lda events::note_pitch
    pha
    lda events::event_time_stamp_l
    pha
    lda events::event_time_stamp_h
    pha

    ; Move the note
    jsr detail::loadNextEventInA
    jsr selectEvent
    
    ; Find its new location
    pla
    sta song_engine::timing::time_stamp_parameter+1
    pla
    sta song_engine::timing::time_stamp_parameter
    pla
    sta pitch
    lda song_engine::event_selection::selected_events_vector
    ldx song_engine::event_selection::selected_events_vector+1
    jsr song_engine::event_selection::findEventAtTimeStamp
    bcs @not_found
    @check_loop:
        jsr detail::storeNextEventInA
        jsr v5b::read_entry
        ; make sure it's the same time stamp (if not, search is guaranteed to fail)
        lda events::event_time_stamp_l
        cmp song_engine::timing::time_stamp_parameter
        bne @not_found
        lda events::event_time_stamp_h
        cmp song_engine::timing::time_stamp_parameter+1
        bne @not_found
        ; check if its the same event
        lda events::note_pitch
        cmp pitch
        bne @goto_next
        lda events::event_type
        cmp #events::event_type_note_on
        bne @goto_next
            ; It's the right one!
            jmp detail::loadNextEventInA ; done!
        @goto_next:
        jsr detail::loadNextEventInA
        jsr v5b::get_next_entry
        bcc @check_loop
        ; fall through to not_found
@not_found:
    ldy #0
    rts
.endproc


.endscope

.endif ; .ifndef SONG_DATA_EVENT_SELECTION_ASM
