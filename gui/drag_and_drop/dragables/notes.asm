; Copyright 2023 Carl Georg Biermann

; This contains implementation of drag and drop of notes within clips.

.ifndef ::GUI_DRAG_AND_DROP_NOTES_ASM
::GUI_DRAG_AND_DROP_NOTES_ASM = 1

.include "../../../common/x16.asm"
.include "../../../dynamic_memory/vector_40bit.asm"
.include "../../../song_data/timing.asm"
.include "../../../song_data/events.asm"
.include "../item_selection.asm"
.include "common.asm"

.scope notes

; aliases for specific event types
note_pitch = events::event_data_1 ; for note-on and note-off events

; Starting time (left border) of the visualzation area
window_time_stamp:
   .word 0
; Starting pitch (bottom border) of the visualization area, lowest on-screen pitch
window_pitch:
   .byte 12
; Temporal zoom level (0 to 4)
; 0 means single-tick precision, 1 means 1/32 grid, 2 means 1/16, 3 means 1/8, 4 means 1/4 and so forth
temporal_zoom:
   .byte 2


.pushseg
.zeropage
unselected_events_vector: ; todo: remove ownership of note data from this file
   .res 2
selected_events_vector:
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
   event_edit_note_color_unselected = 2
   event_edit_note_color_selected = 7
   event_edit_note_border_color = 0
   event_edit_note_border_color_high_velocity = 10 ; ??


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
   ; Sets carry when inside the bounds, clears it otherwise.
   ; Returns the row index in .X.
   .proc calculateRowAndCheckBounds
      lda #event_edit_height-1
      clc
      adc window_pitch ; This exact addition is done every time, could be optimized.
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

   ; Sets the note hitbox active on the row with index .X
   ; Basically just copies the event pointer into the buffer.
   ; preserves .X and .Y
   .proc startNoteHitbox
      lda item_selection::last_event_source
      sta note_is_selected, x
      bne @selected
   @unselected:
      lda item_selection::last_unselected_id
      ldy item_selection::last_unselected_id+1
      bra @store_id
   @selected:
      lda item_selection::last_selected_id
      ldy item_selection::last_selected_id+1
   @store_id:
      sta note_id_low, x
      tya
      sta note_id_high, x
      rts
   .endproc

   ; Finishes off a note hitbox on the row with index .X
   ; column end position is expected in detail::temp_variable_x
   ; preserves .X
   .proc finishNoteHitbox
      column_index = detail::temp_variable_x

      ; hitbox width
      lda column_buffer, x
      dec ; the column buffer contains a value always one bigger than the note width
      asl
      sta hitboxes__hitbox_width
      ; hitbox x position
      lda column_index
      asl
      sec
      sbc hitboxes__hitbox_width
      sta hitboxes__hitbox_pos_x
      ; grant short notes a hitbox of non-zero width. (We do it after the x position calculation, as otherwise, we would get x wrong in case of a short note)
      lda hitboxes__hitbox_width
      bne :+
      lda #2
      sta hitboxes__hitbox_width
   :  
      ; hitbox y position
      txa
      clc
      adc #detail::event_edit_pos_y
      asl
      sta hitboxes__hitbox_pos_y
      ; hitbox object id
      lda note_id_low, x
      sta hitboxes__object_id_l
      lda note_id_high, x
      ora note_is_selected, x  ; maybe we could do this in startNoteHitbox and save the note_is_selected buffer? Let's see if we'll need them separate at all.
      sta hitboxes__object_id_h

      ; append the entry
      phx
      jsr hitboxes__add_hitbox
      plx
      rts
   .endproc

   ; Given a hitbox' object id (inclusive the selected bit in the high byte), return the pointer to the respective entry
   ; Expects the hitbox id in v40b::value_0/v40b::value_1 (low/high) (not preserved!)
   ; Returns the entry pointer in .A/.X/.Y
   .proc getEntryFromHitboxObjectId
      lda v40b::value_1
      bmi @load_selected
   @load_unselected:
      ldy unselected_events_vector
      ldx unselected_events_vector+1
      bra @continue
   @load_selected:
      ldy selected_events_vector
      ldx selected_events_vector+1
      and #$7F ; remove the selected bit
   @continue:
      sta v40b::value_1
      tya
      jsr v40b::convert_vector_and_index_to_direct_pointer
      rts
   .endproc

   ; Given the pointer to a note-on event, finds the corresponding note-off event by linear search.
   ; If no matching note-off is found, carry will be set, otherwise clear.
   .proc findNoteOff
      pitch = temp_variable_a
      ; This function could become a bottleneck!
      ; TODO: to make it faster, read only the data we truly need, instead of using v40b::read_entry
      pha
      phx
      phy
      jsr v40b::read_entry
      lda note_pitch
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
      lda note_pitch
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
.endscope




change_song_tempo = timing::recalculate_rhythm_values ; TODO: actually recalculate ALL time stamps (lossy for sub-1/32 values)


; Sets up a clip with some notes for testing.
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
   sta unselected_events_vector
   stx unselected_events_vector+1
   ; note-on
   lda #(3*test_quarter_ticks)
   sta events::event_time_stamp_l
   stz events::event_time_stamp_h
   lda #events::event_type_note_on
   sta events::event_type
   lda #50
   sta note_pitch
   stz events::event_data_2
   lda unselected_events_vector
   ldx unselected_events_vector+1
   jsr v40b::append_new_entry
   ; note-off
   lda #(3*test_quarter_ticks+5)
   sta events::event_time_stamp_l
   lda #events::event_type_note_off
   sta events::event_type
   lda #50
   sta note_pitch
   stz events::event_data_2
   lda unselected_events_vector
   ldx unselected_events_vector+1
   jsr v40b::append_new_entry
   ; note-on
   lda #<(3*test_quarter_ticks+test_first_eighth_ticks)
   sta events::event_time_stamp_l
   lda #>(3*test_quarter_ticks+test_first_eighth_ticks)
   sta events::event_time_stamp_h
   lda #events::event_type_note_on
   sta events::event_type
   lda #50
   sta note_pitch
   stz events::event_data_2
   lda unselected_events_vector
   ldx unselected_events_vector+1
   jsr v40b::append_new_entry
   ; note-off
   lda #<(3*test_quarter_ticks+2*test_first_eighth_ticks)
   sta events::event_time_stamp_l
   lda #>(3*test_quarter_ticks+2*test_first_eighth_ticks)
   sta events::event_time_stamp_h
   lda #events::event_type_note_off
   sta events::event_type
   lda #50
   sta note_pitch
   stz events::event_data_2
   lda unselected_events_vector
   ldx unselected_events_vector+1
   jsr v40b::append_new_entry
   ; note-on
   lda #<(4*test_quarter_ticks)
   sta events::event_time_stamp_l
   lda #>(4*test_quarter_ticks)
   sta events::event_time_stamp_h
   lda #events::event_type_note_on
   sta events::event_type
   lda #52
   sta note_pitch
   stz events::event_data_2
   lda unselected_events_vector
   ldx unselected_events_vector+1
   jsr v40b::append_new_entry
   ; note-off
   lda #<(4*test_quarter_ticks+80)
   sta events::event_time_stamp_l
   lda #>(4*test_quarter_ticks+80)
   sta events::event_time_stamp_h
   lda #events::event_type_note_off
   sta events::event_type
   lda #52
   sta note_pitch
   stz events::event_data_2
   lda unselected_events_vector
   ldx unselected_events_vector+1
   jsr v40b::append_new_entry

   ; create selected vector
   jsr v40b::new
   sta selected_events_vector
   stx selected_events_vector+1
   ; note-on
   lda #<(4*test_quarter_ticks+test_first_eighth_ticks)
   sta events::event_time_stamp_l
   lda #>(4*test_quarter_ticks+test_first_eighth_ticks)
   sta events::event_time_stamp_h
   lda #events::event_type_note_on
   sta events::event_type
   lda #55
   sta note_pitch
   stz events::event_data_2
   lda selected_events_vector
   ldx selected_events_vector+1
   jsr v40b::append_new_entry
   ; note-off
   lda #<(4*test_quarter_ticks+2*test_first_eighth_ticks)
   sta events::event_time_stamp_l
   lda #>(4*test_quarter_ticks+2*test_first_eighth_ticks)
   sta events::event_time_stamp_h
   lda #events::event_type_note_off
   sta events::event_type
   lda #55
   sta note_pitch
   stz events::event_data_2
   lda selected_events_vector
   ldx selected_events_vector+1
   jsr v40b::append_new_entry
   ; note-on
   lda #<(5*test_quarter_ticks+1)
   sta events::event_time_stamp_l
   lda #>(5*test_quarter_ticks+1)
   sta events::event_time_stamp_h
   lda #events::event_type_note_on
   sta events::event_type
   lda #48
   sta note_pitch
   stz events::event_data_2
   lda selected_events_vector
   ldx selected_events_vector+1
   jsr v40b::append_new_entry
   ; note-off
   lda #<(5*test_quarter_ticks+80)
   sta events::event_time_stamp_l
   lda #>(5*test_quarter_ticks+80)
   sta events::event_time_stamp_h
   lda #events::event_type_note_off
   sta events::event_type
   lda #48
   sta note_pitch
   stz events::event_data_2
   lda selected_events_vector
   ldx selected_events_vector+1
   jsr v40b::append_new_entry

   rts
.endproc


; Draws the editing area of notes within a clip. (Later perhaps effects, too)
; Expects pointer to unselected events in unselected_events_vector, selected events in selected_events_vector
.proc draw
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

   ; running time stamp and column starting point
   lda window_time_stamp+1
   sta running_time_stamp_h
   ldx window_time_stamp
   stx running_time_stamp_l
   jsr timing::disassemble_time_stamp
   stx thirtysecondth_count

   ; column stride
   ldx temporal_zoom
   jsr timing::get_note_duration_thirtysecondths
   sta thirtysecondth_stride

   ; clear the column buffer (don't need to clear the hitbox buffers because if the column_buffer is cleared, the others won't get read)
   ldx #(detail::event_edit_height-1)
@clear_column_buffer_loop:
   stz detail::column_buffer, x
   dex
   bpl @clear_column_buffer_loop

   ; event sources: unselected and selected events
   lda unselected_events_vector
   sta item_selection::unselected_events
   lda unselected_events_vector+1
   sta item_selection::unselected_events+1
   lda selected_events_vector
   sta item_selection::selected_events
   lda selected_events_vector+1
   sta item_selection::selected_events+1
   jsr item_selection::reset_stream

   ; initialize the hitbox list
   lda #dragables__ids__notes
   sta dragables__active_hitbox_type
   jsr hitboxes__clear_hitboxes

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
   lda running_time_stamp_h ; running time stamp is kept at the left border's time stamp during pre-parsing
   cmp events::event_time_stamp_h
   bcc @end_pre_parsing_loop ; if time stamp's high is bigger than reference, we must end
   bne @continue_pre_parsing_loop ; if they're not equal, (and implicitly not bigger), it must be smaller -> we can continue
   lda events::event_time_stamp_l ; high bytes are equal --> need to check low byte
   cmp running_time_stamp_l
   bcs @end_pre_parsing_loop ; if time stamp's low byte is equal or higher than threshold, we end
@continue_pre_parsing_loop:
   ; interpret current event
   ; we assume the current event is already in the API variables
   ; calculate row (before knowing the event type, to reduce code duplication, could be optimized for speed)
   jsr detail::calculateRowAndCheckBounds
   bcc @pre_parsing_next_event ; when outside the view vertically, continue to next event
   ; check event type
   lda events::event_type
   beq @pre_parsing_note_off
   cmp #events::event_type_note_on
   bne @pre_parsing_next_event
@pre_parsing_note_on:
   jsr detail::startNoteHitbox
   lda #2 ; for the purpose of pre-parsing, this is much simpler than in the actual parsing (just toggle on-off). Set to 2 so they won't look like they start at the left border of the time window
   bra @pre_parsing_write_to_buffer
@pre_parsing_note_off:
   lda #column_buffer_no_note ; as the hitbox already ends off-screen, we don't need to register it at all, just switch the row "off"
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
   lda temporal_zoom ; zoom level
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
   lda events::event_time_stamp_h
   cmp running_time_stamp_h
   bcc @time_stamp_within_column ; if carry is clear this means event time stamp is lower than column's border
   bne @end_parse_events ; if the time stamps aren't equal (and also event time stamp is not lower), the event time stamp is higher --> quit event parsing
   lda events::event_time_stamp_l ; high time stamps are equal, need to check low time stamp
   cmp running_time_stamp_l
   bcs @end_parse_events ; if carry is clear this means event time stamp is lower than column's border
@time_stamp_within_column:
   ; interpret event type
   lda events::event_type
   beq @handle_note_off
   cmp #events::event_type_note_on
   beq @handle_note_on

@handle_note_on:
   jsr detail::calculateRowAndCheckBounds
   bcc @parse_next_event ; if outside our view (vertically), skip the event
   jsr detail::startNoteHitbox
   lda detail::column_buffer, x ; check what's inside the current row
   cmp #column_buffer_short_note
   beq @crowded_on
   cmp #column_buffer_multiple_last_off
   beq @crowded_on
   ; in all other cases, we do a note on ... even when they don't make sense (e.g. note-on on top of an already running note)
@new_note:
   lda #1 ; active note, minimum length 1
   bra @write_to_column_buffer
@crowded_on:
   lda #column_buffer_multiple_last_on
   bra @write_to_column_buffer
@handle_note_off:
   ; handle different cases
   ; write to column buffer
   jsr detail::calculateRowAndCheckBounds
   bcc @parse_next_event ; if outside our view (vertically), skip the event
   jsr detail::finishNoteHitbox
   lda detail::column_buffer, x ; check what's inside the current row
   cmp #column_buffer_multiple_last_on
   beq @crowded_off
   cmp #1 ; note started this column
   beq @short_note
   ; we have a note running over at least one full column
   lda #0
   bra @write_to_column_buffer ; could be optimized to stz and direct branch
@crowded_off:
   lda #column_buffer_multiple_last_off
   bra @write_to_column_buffer
@short_note:
   lda #column_buffer_short_note
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
   lda detail::note_is_selected, x
   beq :+
   lda #(16*detail::event_edit_note_color_selected)
   bra :++
:  lda #(16*detail::event_edit_note_color_unselected)
:  ora #(detail::event_edit_note_border_color)
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


; lookup table values
hitbox_height = 2
px = 2 * detail::event_edit_pos_x
py = 2 * detail::event_edit_pos_y
width = 2 * detail::event_edit_width
height = 2 * detail::event_edit_height

; Needs input:
; * new position do drag to (x,y)
; * object id
; Outputs:
; * new actual position of object (x,y). Reason: hitbox update!
.proc drag
   ; TODO
   rts
.endproc


.endscope

.endif ; .ifndef ::GUI_DRAG_AND_DROP_NOTES_ASM
