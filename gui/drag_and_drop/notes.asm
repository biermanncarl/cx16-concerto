; Copyright 2023 Carl Georg Biermann

; This contains implementation of drag and drop of notes within clips.

.include "../../common/x16.asm"
.include "../../dynamic_memory/vector_40bit.asm"
.include "../../song_data/timing.asm"
.include "../../song_data/events.asm"
.include "item_selection.asm"

.scope notes
height = 2


; Needs input:
; * new position do drag to (x,y)
; * object id
; Outputs:
; * new actual position of object (x,y). Reason: hitbox update!
.proc drag
   ; TODO
   rts
.endproc





; implementation stuff (possibly move it into different file later)
; =================================================================

; Value Definitions
; =================

; Data member meaning of 40bit values in note data
event_time_stamp_l = v40b::value_0
event_time_stamp_h = v40b::value_1
event_type = v40b::value_2
event_data_1 = v40b::value_3
event_data_2 = v40b::value_4

; aliases for specific event types
note_pitch = event_data_1 ; for note-on and note-off events



; API variables
; =============



.pushseg
.zeropage
event_vector_a:
   .res 2
event_vector_b:
   .res 2
argument_x:
   .res 2
argument_y:
   .res 1
argument_z:
   .res 1
.popseg

; Temporary variables
.scope detail
; zeropage variables
.pushseg
.zeropage
temp_variable_a:
   .res 1
temp_variable_b:
   .res 1
temp_variable_c:
   .res 1
.popseg

temp_variable_z:
   .res 1
temp_variable_y:
   .res 1
temp_variable_x:
   .res 1

; Editing area rectangle
event_edit_pos_x = 25
event_edit_pos_y = 5
event_edit_width = 50
event_edit_height = 45
event_edit_background_color = 15
event_edit_note_color = 2
event_edit_note_border_unselected_color = 0
event_edit_note_border_selected_color = 10


; Buffers
; -------
; Consider 
; * reusing these for multiple purposes
; * moving them to "golden RAM" ($0400-$07FF)

; column buffers
; used for drawing.
column_buffer:
   .res event_edit_height
; used for hitbox generation
note_is_selected:
   .res event_edit_height
note_id_low:
   .res event_edit_height
note_id_high:
   .res event_edit_height


; Calculates the row of a note and checks if it is inside the view vertically.
; Expects the note's pitch in note_pitch.
; Expects the lowest note inside the view in argument_y
; Sets carry when inside the bounds, clears it otherwise.
; Returns the row index in .X.
.proc calculateRowAndCheckBounds
   lda #event_edit_height-1
   clc
   adc argument_y ; This exact addition is done every time, could be optimized.
   sec
   sbc note_pitch
   tax
   ; check if note is on-screen
   cmp #0
   bcc @exit_no_other_action
   cmp #event_edit_height
   bcs @exit_clear_carry
   sec
   rts
@exit_clear_carry:
   clc
@exit_no_other_action:
   rts
.endproc

.endscope




change_song_tempo = timing::recalculate_rhythm_values ; TODO: actually recalculate ALL time stamps (lossy for sub-1/32 values)


; Sets up a clip with some notes for testing.
; Returns a pointer to the clip in event_vector_a
.proc setup_test_clip
   test_first_eighth_ticks = 32
   test_second_eighth_ticks = 32
   test_quarter_ticks = test_first_eighth_ticks + test_second_eighth_ticks
   ; make sure all the ticks are properly populated
   lda #test_first_eighth_ticks
   sta timing::first_eighth_ticks
   lda #test_second_eighth_ticks
   sta timing::second_eighth_ticks
   jsr timing::recalculate_rhythm_values
   
   ; create unselected vector
   jsr v40b::new
   sta event_vector_a
   stx event_vector_a+1
   ; note-on
   lda #(1*test_quarter_ticks)
   sta event_time_stamp_l
   stz event_time_stamp_h
   lda #events::event_type_note_on
   sta event_type
   lda #50
   sta note_pitch
   stz event_data_2
   lda event_vector_a
   ldx event_vector_a+1
   jsr v40b::append_new_entry
   ; note-off
   lda #(1*test_quarter_ticks+5)
   sta event_time_stamp_l
   lda #events::event_type_note_off
   sta event_type
   lda #50
   sta note_pitch
   stz event_data_2
   lda event_vector_a
   ldx event_vector_a+1
   jsr v40b::append_new_entry
   ; note-on
   lda #(1*test_quarter_ticks+10)
   sta event_time_stamp_l
   stz event_time_stamp_h
   lda #events::event_type_note_on
   sta event_type
   lda #50
   sta note_pitch
   stz event_data_2
   lda event_vector_a
   ldx event_vector_a+1
   jsr v40b::append_new_entry

   ; create selected vector
   jsr v40b::new
   sta event_vector_b
   stx event_vector_b+1
   ; TODO
   rts
.endproc


; Draws the editing area of notes within a clip. (Later perhaps effects, too)
; Expects pointer to unselected events in event_vector_a, selected events in event_vector_b
; Expects time stamp of the left border in argument_x (low and high). Must be aligned with the currently selected grid.
; Expects the pitch of the lowest on-screen note in argument_y
; Expects the temporal zoom level in argument_z (0 means single-tick precision, 1 means 1/32 grid, 2 means 1/16, 3 means 1/8, 4 means 1/4 and so forth)
.proc draw_events
   ; DEFINITIONS
   ; ===========
   running_time_stamp_l = detail::temp_variable_a
   running_time_stamp_h = detail::temp_variable_b
   end_of_data = detail::temp_variable_c
   thirtysecondth_stride = detail::temp_variable_z ; how many thirtysecondth notes we advance with every column
   thirtysecondth_count = detail::temp_variable_y
   column_index = detail::temp_variable_x

   ; column data format
   ; The high bit of the row's byte indicates whether the note is selected or not.
   ; The lower 7 bits count for how many columns a note has been running (used for hitbox generation).
   ; 0 means no note is active
   ; Exceptions to this are the following values (the high bit selection rule still applies to them)
   column_buffer_no_note = 0
   column_buffer_short_note = $7F ; a note which is shorter than a column (has ended within the column)
   column_buffer_multiple_last_on = $7E ; at least two note-on events are present within the current column, the last event was a note-on event
   column_buffer_multiple_last_off = $7D ; at least two note-on events are present within the current column, the last event was a note-off event

   ; INITIALIZATION
   ; ==============

   ; column starting point
   lda argument_x+1
   ldx argument_x
   jsr timing::disassemble_time_stamp
   stx thirtysecondth_count

   ; column stride
   ldx argument_z
   jsr timing::get_note_duration_thirtysecondths
   sta thirtysecondth_stride

   ; running time stamp
   lda argument_x
   sta running_time_stamp_l
   lda argument_x+1
   sta running_time_stamp_h

   ; clear the column buffer (don't need to clear the hitbox buffers)
   ldx #(detail::event_edit_height-1)
@clear_column_buffer_loop:
   stz detail::column_buffer, x
   dex
   bpl @clear_column_buffer_loop

   ; event sources: unselected and selected events
   lda event_vector_a
   sta item_selection::unselected_events
   lda event_vector_a+1
   sta item_selection::unselected_events+1
   lda event_vector_b
   sta item_selection::selected_events
   lda event_vector_b+1
   sta item_selection::selected_events+1
   jsr item_selection::reset_stream

   ; TODO: clear the hitbox list
   ; TODO: calculate keyboard roll visualization offset

   stz end_of_data

   ; get first entry
   jsr item_selection::stream_get_next_event
   bcs @pre_parsing_end_of_data
@clip_is_not_empty:
   ; we have at least one event. get that event's time stamp
   jsr v40b::read_entry


   ; PARSING EVENTS BEFORE THE DISPLAYED TIME WINDOW
   ; This serves two purposes:
   ; 1. finding the first events in the unselected and selected event vector, respectively, that are relevant for the current view
   ; 2. register any notes which begin off-screen but continue into the view
   ; =============================================================================================================================
@pre_parsing_loop:
   lda argument_x+1
   cmp event_time_stamp_h
   bcc @end_pre_parsing_loop ; if time stamp's high is bigger than reference, we must end
   bne @continue_pre_parsing_loop ; if they're not equal, (and implicitly not bigger), it must be smaller -> we can continue
   lda event_time_stamp_l ; high bytes are equal --> need to check low byte
   cmp argument_x
   bcs @end_pre_parsing_loop ; if time stamp's low byte is equal or higher than threshold, we end
@continue_pre_parsing_loop:
   ; interpret current event
   ; we assume the current event is already in the API variables
   ; calculate row (before knowing the event type, to reduce code duplication, could be optimized for speed)
   jsr detail::calculateRowAndCheckBounds
   bcc @pre_parsing_next_event ; when outside the view vertically, continue to next event
   ; check event type
   lda event_type
   beq @pre_parsing_note_off
   cmp #events::event_type_note_on
   bne @pre_parsing_next_event
@pre_parsing_note_on:
   lda #2 ; for the purpose of pre-parsing, this is much simpler than in the actual parsing (just toggle on-off). Set to 2 so they won't look like they start at the left border of the time window
   bra @pre_parsing_write_to_buffer
@pre_parsing_note_off:
   lda #column_buffer_no_note
@pre_parsing_write_to_buffer:
   sta detail::column_buffer, x
@pre_parsing_next_event:
   ; get next event
   jsr item_selection::stream_get_next_event
   bcs @pre_parsing_end_of_data
   jsr v40b::read_entry
   bra @pre_parsing_loop

@pre_parsing_end_of_data:
   inc end_of_data
@end_pre_parsing_loop:



   ; DRAWING THE TIME WINDOW
   ; =======================
   lda #detail::event_edit_pos_x
   sta column_index
@columns_loop:
   ; 1. calculate the time stamp up to which events are registered in this column
   ; 2. loop over events relevant for the current column, update the column buffer (skip if end of data), meanwhile update hitboxes
   ; 3. draw column

   ; Calculate relevant end time stamp for current column (up to which point do we need to register events for the current column)
   ; ====================================================
   ; get the length of the next column in ticks
   ; add it to the running time stamp (TODO: keep copy of it, but use a time stamp that was only advanced by half the column duration to achieve "nearest neighbor rounding")

   lda thirtysecondth_count
   clc
   adc thirtysecondth_stride
   sta thirtysecondth_count
   tax
   lda argument_z ; zoom level
   jsr timing::get_note_duration_ticks
   clc
   adc running_time_stamp_l
   sta running_time_stamp_l
   bcc :+
   inc running_time_stamp_h
:

   ; LOOP OVER EVENTS
   ; ================
   lda end_of_data
   beq :+
   jmp @end_parse_events
:
@main_parse_events_loop:
   ; We assume the next event's data to be already loaded in the event_time_stamp_h etc. variables
   ; check if time stamp is within current column
   lda event_time_stamp_h
   cmp running_time_stamp_h
   bcc @time_stamp_within_column ; if carry is clear this means event time stamp is lower than column's border
   bne @end_parse_events ; if the time stamps aren't equal (and also event time stamp is not lower), the event time stamp is higher --> quit event parsing
   lda event_time_stamp_l ; high time stamps are equal, need to check low time stamp
   cmp running_time_stamp_l
   bcs @end_parse_events ; if carry is clear this means event time stamp is lower than column's border
@time_stamp_within_column:
   ; interpret event type
   lda event_type
   beq @handle_note_off
   cmp #events::event_type_note_on
   beq @handle_note_on

@handle_note_on:
   jsr detail::calculateRowAndCheckBounds
   bcc @parse_next_event ; if outside our view (vertically), skip the event
   lda detail::column_buffer, x ; check what's inside the current row
   ; since it's a note-on, we don't check if what's in there is selected. We get that info from the event source (item_selection::last_event_source)
   asl ; get rid of upper bit
   cmp #(2*column_buffer_short_note)
   beq @crowded_on
   cmp #(2*column_buffer_multiple_last_off)
   beq @crowded_on
   ; in all other cases, we do a note on ... even when they don't make sense (e.g. note-on on top of an already running note)
@new_note:
   lda item_selection::last_event_source
   lsr ; move "selected" bit into carry
   lda #(2*1) ; active note, minimum length 1, left shifted once (undoing it next instruction)
   ror ; move "selected" bit to the top of the value
   bra @write_to_column_buffer
@crowded_on:
   lda item_selection::last_event_source
   lsr ; move "selected" bit into carry
   lda #(2*column_buffer_multiple_last_on) ; multiplied by 2 as we right shift it next instruction
   ror ; move "selected" bit to the top of the value
   bra @write_to_column_buffer
@handle_note_off:
   ; extract "selection bit", remember it; push it out --> we multiply the "size" by 2 already to get multiples of 4 pixels size)
   ; handle different cases
   ; possibly create hitbox (leave as TODO for now)
   ; add selection bit back
   ; write to column buffer
   jsr detail::calculateRowAndCheckBounds
   bcc @parse_next_event ; if outside our view (vertically), skip the event
   lda detail::column_buffer, x ; check what's inside the current row
   asl ; get rid of the upper bit
   cmp #(2*column_buffer_multiple_last_on)
   beq @crowded_off
   cmp #(2*1) ; note started this column
   beq @short_note
   ; we have a note running over at least one full column
   lda #0
   ; TODO: hitbox generation!
   bra @write_to_column_buffer ; could be optimized to stz and direct branch
@crowded_off:
   lda item_selection::last_event_source
   lsr ; put selection bit into carry
   lda #(2*column_buffer_multiple_last_off)
   ror ; append the selection bit
   ; TODO: hitbox generation! (yes, even in crowded environments we want hitboxes, so "box selection" works)
   bra @write_to_column_buffer
@short_note:
   lda item_selection::last_event_source
   lsr ; put selection bit into carry
   lda #(2*column_buffer_short_note)
   ror ; append the selection bit
   ; TODO: hitbox generation!
@write_to_column_buffer:
   sta detail::column_buffer, x
   bra @parse_next_event

@parse_next_event:
   jsr item_selection::stream_get_next_event
   bcs :+ ; new data available?
   ; new data available.
   jsr v40b::read_entry
   jmp @main_parse_events_loop
:  inc end_of_data
@end_parse_events:

@start_drawing_and_buffer_update:
   ; .X is Y position
   ; .Y is X position
   ldy column_index
   ldx #0
@rows_loop:
   ; TODO: use reusable routine to place the VERA "cursor"
   stz VERA_ctrl
   lda #$10
   sta VERA_addr_high
   txa
   clc
   adc #detail::event_edit_pos_y
   sta VERA_addr_mid
   tya
   asl
   sta VERA_addr_low

   ; update column buffer and draw stuff
   lda detail::column_buffer, x
   and #$7F ; get rid of selection bit for now
   beq @draw_space
   cmp #column_buffer_multiple_last_off
   beq @update_multiple_last_off
   cmp #column_buffer_multiple_last_on
   beq @update_multiple_last_on
   cmp #column_buffer_short_note
   beq @update_short_note
   ; all other cases are running_notes
   bra @update_long_note
@update_long_note:
   ; update column buffer
   inc detail::column_buffer, x
   ; draw note
   dec ; check if note length was 1
   beq @draw_start_of_note
   ; if not, fall through to drawing a running note
@draw_running_note:
   lda #119
   bra @draw_note
@update_short_note:
   lda #0
   sta detail::column_buffer, x
   bra @draw_start_of_note
@update_multiple_last_off:
   lda #0
   sta detail::column_buffer, x
   bra @draw_multiple
@update_multiple_last_on:
   lda #2 ; running note in next column
   sta detail::column_buffer, x
   bra @draw_multiple
@draw_space:
   lda #32
   sta VERA_data0
   lda #(16*detail::event_edit_background_color+0)
   sta VERA_data0
   bra @advance_row
@draw_start_of_note:
   lda #79
@draw_note:
   sta VERA_data0
   lda detail::column_buffer, x
   bpl :+
   lda #(detail::event_edit_note_border_selected_color)
   bra :++
:  lda #(detail::event_edit_note_border_unselected_color)
:  clc
   adc #(16*detail::event_edit_note_color)
   sta VERA_data0
   bra @advance_row
@draw_multiple:
   lda #102
   bra @draw_note
@advance_row:
   inx
   cpx #detail::event_edit_height
   bne @rows_loop

   iny
   sty column_index
   cpy #(detail::event_edit_pos_x+detail::event_edit_width)
   beq @end_column_loop
   jmp @columns_loop
@end_column_loop:

   ; TODO: finish off unfinished notes by creating their hitboxes


   rts
.endproc

.endscope
