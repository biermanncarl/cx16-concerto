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
; pointers to the 40bit vectors with events
selected_events: ; not owned by this module
    .res 2
unselected_events: ; not owned by this module
    .res 2
; other variables (no pointers) only here for speed and code size, could be moved out of ZP
next_selected_event:
    .res 3
next_selected_id:
    .res 2
next_unselected_event:
    .res 3
next_unselected_id:
    .res 2
; current_timestamp:
    ; .res 0
last_event_source:
    .res 1
.popseg

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
    stz next_selected_id
    stz next_selected_id+1
    stz next_unselected_id
    stz next_unselected_id+1
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


; Get the next event. This not only takes into account time stamps but also event types, and tries to emit them in the correct order.
; That means, note-offs first, then note-ons, then effects.
; If no more events are available, carry is set upon return, clear otherwise.
; If another event is available, its pointer is returned in .A/.X/.Y
; If another event is available, the content of last_event_source is set to 0 in case the last event was unselected, or $80 if it was selected
.proc stream_get_next_event
    ; Check if more events are available
    ldy next_selected_event+2
    bne @selected_not_empty
@selected_empty:
    ldy next_unselected_event+2
    beq @both_empty
    jmp @next_unselected
@both_empty:
    sec ; signal that no more events are available
    rts
@selected_not_empty:
    ldy next_unselected_event+2
    beq @next_selected
@both_available:
    ; abusing variables in this section which "belong" to other functions which we don't use
    ; set up zeropage pointers to both entries
    lda next_selected_event+1
    sta v40b::zp_pointer+1
    stz v40b::zp_pointer
    lda next_unselected_event+1
    sta v40b::zp_pointer_2+1
    stz v40b::zp_pointer_2
    ; compute indices
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
    bcs @next_selected
    bra @next_unselected
@compare_low_time_stamp:
    dey
    lda (v40b::zp_pointer), y ; look up selected
    ldx next_unselected_event+2
    stx RAM_BANK
    ldy v40b::value_1
    cmp (v40b::zp_pointer_2), y ; compare with unselected
    beq @compare_event_types
    bcs @next_unselected
    bra @next_selected
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
    bcs @next_selected
    bra @next_unselected

@next_selected:
    inc next_selected_id
    bne :+
    inc next_selected_id+1
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
    inc next_unselected_id
    bne :+
    inc next_unselected_id+1
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


.endscope

.endif ; .ifndef DRAG_AND_DROP_ITEM_SELECTION_ASM
