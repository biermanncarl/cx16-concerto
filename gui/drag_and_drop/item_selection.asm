; Copyright 2023 Carl Georg Biermann

; This file implements work with selections. The features work with streams of events.
; Events are located in the entries of a 40bit vector, with the time stamp as the first 16 bits.
; By user interactions with the GUI, these events can become selected and unselected.
; The way how we select and unselect events is by cutting selected events and pasting
; them in a separate, "selected" vector. When an event gets unselected, it is inserted
; back into the original vector.

.ifndef DRAG_AND_DROP_ITEM_SELECTION_ASM
DRAG_AND_DROP_ITEM_SELECTION_ASM = 1

.include "../../common/x16.asm"
.include "../../dynamic_memory/vector_40bit.asm"

.scope item_selection

.pushseg
.zeropage
start_of_stream_variables:
; pointers to the 40bit vectors with events
selected_events: ; not owned by this module
    .res 2
unselected_events: ; not owned by this module
    .res 2
; other variables (no pointers) only here for speed and code size, could be moved out of ZP
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
end_of_stream_variables:
.popseg

; When the ISR uses this code, it might interrupt other routines using it,
; so it has to swap out the ZP variables.
back_buffer_size = end_of_stream_variables - start_of_stream_variables
back_buffer:
    .res back_buffer_size


; Given the pointer to a note-on event in .A/.X/.Y, finds the corresponding note-off event by linear search.
; If no matching note-off is found, carry will be set, otherwise clear.
.proc findNoteOff
    pitch = temp_variable_a
    ; This function could become a bottleneck!
    ; TODO: to make it faster, read only the data we truly need, instead of using v40b::read_entry
    pha
    phx
    phy
    jsr v40b::read_entry
    lda events::note_pitch
    sta pitch
    ply
    plx
    pla
@loop:
    jsr v40b::get_next_entry
    bcs @end ; search failed, end reached before the note-off was found
    pha
    phx
    phy
    jsr v40b::read_entry
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
.endproc





; Common event stream
; ===================
; This section is concerned with providing a unified, temporally ascending
; stream of events, regardless of whether they are selected or not. 


; Resets/initializes the common event stream.
; Expects the selected_events and unselected_events pointers to be set to the respective vectors.
; TODO: actually, we can just keep the selected_events vector, and receive the unselected in .A/.X/.Y ... TBD
.proc reset_stream
    ; reset time stamp
    ; stz current_timestamp
    ; stz current_timestamp+1

    ; reset id counters
    lda #$ff
    sta last_selected_id
    sta last_selected_id+1
    sta last_unselected_id
    sta last_unselected_id+1
    ; reset the event pointers to the beginning
    lda selected_events
    ldx selected_events+1
    jsr v40b::get_first_entry
    bcs @selected_is_empty
@selected_is_populated:
    sta next_selected_event
    stx next_selected_event+1
    sty next_selected_event+2
    bra @continue_to_unselected
@selected_is_empty:
    stz next_selected_event+2 ; invalidate
@continue_to_unselected:
    lda unselected_events
    ldx unselected_events+1
    jsr v40b::get_first_entry
    bcs @unselected_is_empty
@unselected_is_populated:
    sta next_unselected_event
    stx next_unselected_event+1
    sty next_unselected_event+2
    rts
@unselected_is_empty:
    stz next_unselected_event+2 ; invalidate
    rts
.endproc


; Compares two events and decides which of them comes sooner.
; Expects
; * pointer to a valid event in next_selected_event
; * pointer to another valid event in next_unselected_event
; If the "selected" event comes first, carry will be set, otherwise clear (if time stamps and event types are the same, carry will be set)
.proc compareEvents
    ; abusing variables in this function which "belong" to other functions which we don't use
    ; set up zeropage pointers to both entries
    lda next_selected_event+1
    sta v40b::zp_pointer+1
    stz v40b::zp_pointer
    lda next_unselected_event+1
    sta v40b::zp_pointer_2+1
    stz v40b::zp_pointer_2
    ; compute offsets inside the chunk
    lda next_selected_event
    asl
    asl
    adc next_selected_event
    adc #v40b::payload_offset
    sta v40b::value_0 ; selected offset
    lda next_unselected_event
    asl
    asl
    adc next_unselected_event
    adc #v40b::payload_offset
    sta v40b::value_1 ; unselected offset
@compare_high_time_stamp:
    tay
    iny
    ldx next_unselected_event+2
    stx RAM_BANK
    lda (v40b::zp_pointer_2), y ; look up unselected
    ldx next_selected_event+2
    stx RAM_BANK
    ldy v40b::value_0
    iny
    cmp (v40b::zp_pointer), y ; compare to selected
    beq @compare_low_time_stamp
    rts
@compare_low_time_stamp:
    dey
    lda (v40b::zp_pointer), y ; look up selected
    ldx next_unselected_event+2
    stx RAM_BANK
    ldy v40b::value_1
    cmp (v40b::zp_pointer_2), y ; compare with unselected
    beq @compare_event_types
    ; invert the carry flag before returning
    rol
    inc
    ror
    rts
@compare_event_types:
    iny
    iny
    lda (v40b::zp_pointer_2), y ; look up unselected
    ldx next_selected_event+2
    stx RAM_BANK
    ldy v40b::value_0
    iny
    iny
    cmp (v40b::zp_pointer), y ; compare with selected
    rts
.endproc


; Get the next event. This not only takes into account time stamps but also event types, and tries to emit them in the correct order.
; That means, note-offs first, then note-ons, then effects.
; If no more events are available, carry is set upon return, clear otherwise.
; If another event is available, its pointer is returned in .A/.X/.Y
; If another event is available, the content of last_event_source is set to 0 in case the last event was unselected, or $80 if it was selected
; The respective id (last_selected_id/last_unselected_id) is advanced accordingly.
.proc stream_get_next_event
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
    inc last_selected_id
    bne :+
    inc last_selected_id+1
:   lda next_selected_event
    ldx next_selected_event+1
    ldy next_selected_event+2
    pha
    phx
    phy
    jsr v40b::get_next_entry
    stz next_selected_event+2 ; mark next event as invalid preemptively (will override it if not invalid)
    bcs @return_pointer
    sta next_selected_event
    stx next_selected_event+1
    sty next_selected_event+2
    lda #$80
    sta last_event_source
    bra @return_pointer
@next_unselected:
    inc last_unselected_id
    bne :+
    inc last_unselected_id+1
:   lda next_unselected_event
    ldx next_unselected_event+1
    ldy next_unselected_event+2
    pha
    phx
    phy
    jsr v40b::get_next_entry
    stz next_unselected_event+2 ; mark next event as invalid preemptively (will override it if not invalid)
    bcs @return_pointer
    sta next_unselected_event
    stx next_unselected_event+1
    sty next_unselected_event+2
    stz last_event_source
@return_pointer:
    ply
    plx
    pla
    clc
    rts
.endproc


; Swaps the stream in the active ZP buffer with the back buffer.
; This enables concurrent usage of two streams, which is most important for the ISR,
; which could interrupt the main program's stream usage.
; TODO: check if we really need this.
.proc swapBackFrontStreams
    ldx #0
@swap_loop:
    ldy start_of_stream_variables, x
    lda back_buffer, x
    sta start_of_stream_variables, x
    tya
    sta back_buffer, x
    inx
    cpx #back_buffer_size
    bne @swap_loop
    rts
.endproc




; Individual item selection and unselection
; =========================================
; This is a separate API, which cannot be used at the same time as the
; "Common streams" API as it works with partly the same ZP variables.
; (this could be changed, though, so that each API has its own ZP variables
; and can be used fully independently from each other).


; Swaps the selected and unselected vector.
; This is useful to unselect items.
.proc swapSelectedUnselectedVectors
    lda selected_events
    ldy unselected_events
    sta unselected_events
    sty selected_events
    lda selected_events+1
    ldy unselected_events+1
    sta unselected_events+1
    sty selected_events+1
    rts
.endproc



; Moves an event from the unselected to the selected vector.
; * In .A/.X/.Y, expects the pointer to the object to be selected,
; * in next_selected_event, expects the pointer to either the beginning of the (possibly empty) vector of selected events, OR any selected event known to come before the one to be selected.
;   (not preserved!)
; If the object is a note-on, the corresponding note-off is automatically selected, too.
; To unselect, swap the vectors using swapSelectedUnselectedVectors, call this function, and then swap back.
.proc selectEvent
    ; Actually, this could/should be a generic function, usable in both directions.
    ; Can it be partially recursive?
    ; * if the event is a note-on, it finds the note-off, calls itself on the note-off and then proceeds with normal operation
    ; * normal operation moves the pointed at event, regardless of its event type
    ; How to move?
    ; We need to find the target pointer/index.
    ; * linear search?
    ; * binary search in sorted list
    ; * combined method: find chunk first, then do linear search within the chunk
    ; * allow for a "hint" (index, pointer, chunk) before which the function doesn't need to search
    ;   * this allows efficient integration of repeated calls of this function
    ; Once target pointer is found:
    ; * read the entry to be selected (into value_0 ... value_4)
    ; * delete it
    ; * insert it directly at target location


    ; ====================================================================================================================
    ; Do the most basic implementation now ... possible improvements/optimizations for speed can be done later if needed.
    ; Remember the pointer to the event, so we can delete it later
    pha
    phx
    phy
    ; Load the values of the entry to be selected
    jsr v40b::read_entry

    ; We do linear search to find the address to insert the event.
    ; next_selected_event is the candidate where to insert the event.
    lda next_selected_event+2
    ldx next_selected_event+1
    jsr v40b::is_empty
    bcs @append
@search_loop:
    jsr compareEvents
    bcc @insert_position_found
    lda next_selected_event
    ldx next_selected_event+1
    ldy next_selected_event+2
    jsr v40b::get_next_entry
    bcs @append
    sta next_selected_event
    stx next_selected_event+1
    sty next_selected_event+2
    bra @search_loop

@append:
    lda next_selected_event+2
    ldx next_selected_event+1
    jsr v40b::append_new_entry
    bra @check_note_off
@insert_position_found:
    lda next_selected_event
    ldx next_selected_event+1
    ldy next_selected_event+2
    jsr v40b::insert_entry
    ; Remember the pointer to the newly inserted event, as entries might get moved around in an insert operation.
    sta next_selected_event
    stx next_selected_event+1
    sty next_selected_event+2
@check_note_off:
    ; If the event type is a note-on, we have to also select the note-off.
    lda events::event_type
    cmp #events::event_type_note_on
    bne @delete_entry

@select_note_off:
    ; We assume the note-off IS THERE (no error handling in case it's not).
    ; Recall pointer to original event
    ply
    plx
    pla
    ; remember the original pointer again, so we can delete it later from the unselected vector.
    ; We can't delete it now because findNoteOff still needs it.
    pha
    phx
    phy
    jsr findNoteOff
    jsr selectEvent ; recursive call

@delete_entry:
    ; Finally, delete the original (unselected) event
    ply
    plx
    pla
    jsr v40b::delete_entry
    rts
.endproc


.endscope

.endif ; .ifndef DRAG_AND_DROP_ITEM_SELECTION_ASM
