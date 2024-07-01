; Copyright 2023 Carl Georg Biermann

.code
    jmp start

.include "../../../testing/testing.asm"
.include "../../../common/random.asm"
heap_max_ram_bank = 10
.include "../../../dynamic_memory/vector_5bytes.asm"
.include "../../../song_engine/events.asm"
.include "../../../song_engine/event_selection.asm"

; option to enforce a unique order of events (less generic test scenario)
; Uncomment to run generic test with partially ambivalent order.
enforce_unique_order = 1

vec_a:
    .word 0
vec_b:
    .word 0

time_stamp:
    .word 0
previous_event_type:
    .byte 0

last_selected_id:
    .word $ffff
last_unselected_id:
    .word $ffff


; some errors only occur very rarely, so this number should be as high as possible to increase chances of hitting it
number_of_events = 800

loop_counter:
    .word 0

start:
    START_TEST
    RNG_SEED 1, 2, 3

    ; create two random streams
    ; =========================
    jsr v5b::new
    sta vec_a
    stx vec_a+1
    jsr v5b::new
    sta vec_b
    stx vec_b+1

@generate_loop:
@increment_time_stamp:
    ; increment time stamp?
    jsr rng::random_bit
    bcc @end_inc_timestamp
    stz previous_event_type ; reset event type to lowest possible
:   jsr rng::random_byte
    lsr ; divide by 2 to give us more headroom before we suffer time stamp overflow
    cmp #0 ; make sure it's not zero
    beq :-
    clc
    adc time_stamp
    sta time_stamp
    lda #0
    adc time_stamp+1
    sta time_stamp+1
    EXPECT_CARRY_CLEAR ; ensure that we don't have an overflow in the time stamp
@end_inc_timestamp:
    ; fill the new event data
    lda time_stamp
    sta events::event_time_stamp_l
    lda time_stamp+1
    sta events::event_time_stamp_h
    ; choose a random event type
    jsr rng::random_byte
    cmp previous_event_type ; need to ensure that the event type is same or higher than previous event in the same time stamp (otherwise would be invalid data)
    bcc @increment_time_stamp ; if the event type was lower, try again
.ifdef enforce_unique_order
    beq @increment_time_stamp ; If we want unique order of events, we cannot have the same event twice in a row
.endif
    sta events::event_type
    sta previous_event_type
    ; fill the "data": use the counter, so we can check later if the merge operation was correct
    lda loop_counter
    sta events::event_data_1
    lda loop_counter+1
    sta events::event_data_2

    ; choose a stream to add the event
    jsr rng::random_bit
    bcc :+
    lda vec_a
    ldx vec_a+1
    bra :++
:   lda vec_b
    ldx vec_b+1
:   jsr v5b::append_new_entry
    EXPECT_CARRY_CLEAR

    ; advance the loop
    inc loop_counter
    bne :+
    inc loop_counter+1
:   lda loop_counter+1
    cmp #>number_of_events
    beq :+
    jmp @generate_loop
:   lda loop_counter
    cmp #<number_of_events
    beq @end_generate_loop
    jmp @generate_loop
@end_generate_loop:


    ; test the merged stream
    ; ======================
    ; setup the event vectors
    lda vec_a
    ldx vec_a+1
    sta event_selection::selected_events
    stx event_selection::selected_events+1
    lda vec_b
    ldx vec_b+1
    sta event_selection::unselected_events
    stx event_selection::unselected_events+1
    jsr event_selection::resetStream

    stz previous_event_type
    stz loop_counter
    stz loop_counter+1
    stz time_stamp
    stz time_stamp+1


@test_loop:
    ; get next event
    jsr event_selection::streamGetNextEvent
    bcc :+
    jmp @end_test_loop
:   jsr v5b::read_entry

    ; check last_event_source in conjunction with ids
    lda event_selection::last_event_source
    bne @next_selected
@next_unselected:
    lda last_unselected_id
    ldx last_unselected_id+1
    EXPECT_EQ_MEM_16 last_unselected_id
    inc last_unselected_id
    bne :+
    inc last_unselected_id+1
:   bra @end_check_id
@next_selected:
    lda last_selected_id
    ldx last_selected_id+1
    EXPECT_EQ_MEM_16 last_selected_id
    inc last_selected_id
    bne :+
    inc last_selected_id+1
:   bra @end_check_id
@end_check_id:

    ; test the values
    ;----------------
.ifdef enforce_unique_order
    ; index should be the same as the running index
    lda events::event_data_1
    ldx events::event_data_2
    EXPECT_EQ_MEM_16 loop_counter
.endif

    ; event type must increase monotonically within the same time stamp
    lda events::event_time_stamp_l
    ldx events::event_time_stamp_h
    IS_EQ_MEM_16 time_stamp
    bcc @skip_type_check
    lda events::event_type
    EXPECT_GE_MEM previous_event_type
@skip_type_check:
    lda events::event_type
    sta previous_event_type

    ; time stamp must increase monotonically
    lda events::event_time_stamp_l
    ldx events::event_time_stamp_h
    EXPECT_GE_MEM_16 time_stamp
    sta time_stamp
    stx time_stamp+1

    inc loop_counter
    bne :+
    inc loop_counter+1
    ; count how many events we get
:
    jmp @test_loop
@end_test_loop:


    ; number of events must be the same we put in
    lda loop_counter
    ldx loop_counter+1
    EXPECT_EQ_16 number_of_events

    FINISH_TEST
    rts
