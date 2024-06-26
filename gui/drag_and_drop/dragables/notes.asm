; Copyright 2023-2024 Carl Georg Biermann

; This contains implementation of drag and drop of notes within clips.

.ifndef ::GUI_DRAG_AND_DROP_NOTES_ASM
::GUI_DRAG_AND_DROP_NOTES_ASM = 1

.include "../../../common/x16.asm"
.include "../../../dynamic_memory/vector_5bytes.asm"
.include "common.asm"

.scope notes

; Starting time (left border) of the visualzation area
window_time_stamp:
   .word 0
; Starting pitch (bottom border) of the visualization area, lowest on-screen pitch
window_pitch:
   .byte 30
; Temporal zoom level (0 to 4)
; 0 means single-tick precision, 1 means 1/32 grid, 2 means 1/16, 3 means 1/8, 4 means 1/4 and so forth
temporal_zoom:
   .byte 2
max_temporal_zoom = 4


.pushseg
.zeropage
unselected_events_vector: ; todo: remove ownership of note data from this file (so that these pointers only help processing music data, not storing it)
   .res 2
selected_events_vector:
   .res 2
; argument_y:
;    .res 1
; argument_z:
;    .res 1
.popseg


.scope detail
   selection_min_pitch:
      .res 1
   selection_max_pitch:
      .res 1
   selection_min_time_stamp:
      .res 2
   selection_shortest_note_length = selection_min_time_stamp ; used in the same way during note resize operations

   pointed_at_event: ; which event is the mouse pointer pointing at
      .res 3

   ; Temporary variables
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
   temp_variable_w:
      .res 1
   temp_variable_v:
      .res 1

   ; Editing area rectangle
   event_edit_width = 50
   event_edit_height = 45
   event_edit_pos_x = (80-event_edit_width) / 2 - 3
   event_edit_pos_y = (60-event_edit_height) / 2
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
      sbc song_engine::events::note_pitch
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
   ; Basically just copies the event index into the buffer.
   ; preserves .X and .Y
   .proc startNoteHitbox
      lda song_engine::event_selection::last_event_source
      sta note_is_selected, x
      bne @selected
   @unselected:
      lda song_engine::event_selection::last_unselected_id
      ldy song_engine::event_selection::last_unselected_id+1
      bra @store_id
   @selected:
      lda song_engine::event_selection::last_selected_id
      ldy song_engine::event_selection::last_selected_id+1
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
   ; Expects the hitbox id in v5b::value_0/v5b::value_1 (low/high) (not preserved!)
   ; Returns the entry pointer in .A/.X/.Y
   .proc getEntryFromHitboxObjectId
      lda v5b::value_1
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
      sta v5b::value_1
      tya
      jsr v5b::convert_vector_and_index_to_direct_pointer
      rts
   .endproc


   ; Given an event, grid motion and maximal allowed left motion, figures out the number of ticks the event is shifted.
   ; Also updates the maximum left-motion based on the determined value.
   ; In .A/.X/.Y, expects the pointer to the event that is being dragged.
   ; In selection_min_time_stamp, expects the maximum number of ticks that the events may be moved left.
   ; In delta_x, expects the signed chargrid distance, the event is moved.
   ; Returns the time stamp delta in time_shift_l/time_shift_h.
   .proc determineTimeShift
      ; Find delta time
      ; ---------------
      ; The delta time is applied to all selected events equally.
      ; This might move some events "off-grid" because eighths and smaller time values don't necessarily have equal length (in ticks).
      ; The alternative would be to separate off the sub-thirtysecondths ticks, add the actual note (grid) values, and then add the sub-thirtysecondths ticks
      ; back ("grid-centered approach").
      ; Despite the disadvantage of potentially de-quantizing events, the "uniform ticks delta" approach was chosen because of its advantages:
      ; * It is lossless. Thirtysecondth notes can be of unequal length, 
      ;   so there has to be a mapping between sub-thirtysecondth ticks from between longer and shorter time intervals.
      ;   This conversion would be lossy, which could unintentionally move precisely timed off-grid events.
      ; * In the grid-centered approach, due to its lossy nature, events which were originally at different time stamps
      ;   could fall onto the same time stamp. This is undesirable. For example, short notes could become zero-length, or a note-on and note-off of two different
      ;   notes could fall onto the same time stamp, at which time they might need to be swapped (because within a time stamp, note-offs must come before note-offs).
      ; * "uniform ticks delta" is faster. Once the tick delta is determined, it can be blindly applied to every selected event.
      ; * Dequantization isn't too bad, since it only comes into effect when notes are moved by less than quarter notes.
      time_shift_l = detail::temp_variable_a
      time_shift_h = detail::temp_variable_b
      delta_x = detail::temp_variable_z
      lda song_engine::events::event_time_stamp_h
      ldx song_engine::events::event_time_stamp_l
      sta song_engine::timing::time_stamp_parameter+1
      stx song_engine::timing::time_stamp_parameter
      ldx #0 ; no snap to grid -- could be changed e.g. with modifier key
      ldy temporal_zoom
      lda delta_x
      jsr song_engine::timing::move_along_grid
      lda song_engine::timing::time_stamp_parameter
      sta time_shift_l
      lda song_engine::timing::time_stamp_parameter+1
      sta time_shift_h
      bpl @finish_determine_time_delta
   @clamp_time_left:
      ; check time_shift_h
      lda time_shift_h
      eor #$ff
      ; these two cancel each other out:
      ; inc ; .A contains negated time_shift_h
      ; dec ; account for the fact that decrement of high byte by 1 is factually no decrement in high byte if you account for the carry from the low byte
      cmp detail::selection_min_time_stamp+1 ; need to carry on with check if this is smaller than negated time_shift_h, i.e. if carry is set
      beq :+
      bcs @set_delta_tick_to_zero ; time_shift_h is larger than min time stamp --> need to clamp
      bra @finish_determine_time_delta
   :  ; check time_shift_l
      lda time_shift_l
      eor #$ff
      ; these two cancel each other out:
      ; inc ; .A contains negated time_shift_l
      ; dec ; convert the carry flag from cmp instruction from (.A >= mem) to (.A > mem)
      cmp detail::selection_min_time_stamp
      bcc @finish_determine_time_delta
   @set_delta_tick_to_zero:
      stz time_shift_h
      stz time_shift_l
   @finish_determine_time_delta:
      lda detail::selection_min_time_stamp
      clc
      adc time_shift_l
      sta detail::selection_min_time_stamp
      lda detail::selection_min_time_stamp+1
      adc time_shift_h
      sta detail::selection_min_time_stamp+1
   @end_determine_time_delta:
      rts
   .endproc

   ; * In select_action, expects the action to be done on the original event (one of selectEvent::action options).
   .proc selectWithHitboxId
      jsr detail::getEntryFromHitboxObjectId
      sta detail::pointed_at_event
      stx detail::pointed_at_event+1
      sty detail::pointed_at_event+2
      jsr song_engine::event_selection::selectEvent
      rts
   .endproc
.endscope




change_song_tempo = song_engine::timing::recalculate_rhythm_values ; TODO: actually recalculate ALL time stamps (lossy for sub-1/32 values)


; Sets up a clip with some notes for testing.
.proc setup_test_clip
   test_first_eighth_ticks = 20
   test_second_eighth_ticks = 15
   test_quarter_ticks = test_first_eighth_ticks + test_second_eighth_ticks
   start_time_stamp = 8*test_quarter_ticks
   ; make sure all the ticks are properly populated
   lda #test_first_eighth_ticks
   sta song_engine::timing::first_eighth_ticks
   lda #test_second_eighth_ticks
   sta song_engine::timing::second_eighth_ticks
   jsr song_engine::timing::recalculate_rhythm_values
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
   thirtysecondth_count = detail::temp_variable_y ; how many thirtysecondth notes since a grid-aligned quarter. Only its mod 8 value matters.
   column_index = detail::temp_variable_x
   ticks_since_last_full_thirtysecondth = detail::temp_variable_w ; only relevant at zoom level 0
   piano_roll_offset = detail::temp_variable_v

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
   jsr song_engine::timing::disassemble_time_stamp
   stx thirtysecondth_count
   sty ticks_since_last_full_thirtysecondth

   ; column stride
   ldx temporal_zoom
   jsr song_engine::timing::get_note_duration_thirtysecondths
   sta thirtysecondth_stride

   ; clear the column buffer (don't need to clear the hitbox buffers because if the column_buffer is cleared, the others won't get read)
   ldx #(detail::event_edit_height-1)
@clear_column_buffer_loop:
   stz detail::column_buffer, x
   dex
   bpl @clear_column_buffer_loop

   ; event sources: unselected and selected events
   SET_SELECTED_VECTOR selected_events_vector
   SET_UNSELECTED_VECTOR unselected_events_vector
   jsr song_engine::event_selection::resetStream

   ; initialize the hitbox list
   lda #dragables__ids__notes
   sta dragables__active_hitbox_type
   jsr hitboxes__clear_hitboxes

   ; calculate offset of piano roll of topmost note in the view
   lda window_pitch
   clc
   adc #(detail::event_edit_height - 1)
   sec
@divide_by_twelve_loop:
   sbc #12
   bcs @divide_by_twelve_loop
   adc #12
   sta piano_roll_offset

   stz end_of_data

   ; get first entry
   jsr song_engine::event_selection::streamGetNextEvent
   bcs @pre_parsing_end_of_data
@clip_is_not_empty:
   ; we have at least one event. get that event's time stamp
   jsr v5b::read_entry


   ; PARSING EVENTS BEFORE THE DISPLAYED TIME WINDOW
   ; This serves two purposes:
   ; 1. finding the first events in the unselected and selected event vector, respectively, that are relevant for the current view
   ; 2. register any notes which begin off-screen but continue into the view
   ; =============================================================================================================================
@pre_parsing_loop:
   lda running_time_stamp_h ; running time stamp is kept at the left border's time stamp during pre-parsing
   cmp song_engine::events::event_time_stamp_h
   bcc @end_pre_parsing_loop ; if time stamp's high is bigger than reference, we must end
   bne @continue_pre_parsing_loop ; if they're not equal, (and implicitly not bigger), it must be smaller -> we can continue
   lda song_engine::events::event_time_stamp_l ; high bytes are equal --> need to check low byte
   cmp running_time_stamp_l
   bcs @end_pre_parsing_loop ; if time stamp's low byte is equal or higher than threshold, we end
@continue_pre_parsing_loop:
   ; interpret current event
   ; we assume the current event is already in the API variables
   ; calculate row (before knowing the event type, to reduce code duplication, could be optimized for speed)
   jsr detail::calculateRowAndCheckBounds
   bcc @pre_parsing_next_event ; when outside the view vertically, continue to next event
   ; check event type
   lda song_engine::events::event_type
   beq @pre_parsing_note_off
   cmp #song_engine::events::event_type_note_on
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
   jsr song_engine::event_selection::streamGetNextEvent
   bcs @pre_parsing_end_of_data
   jsr v5b::read_entry
   bra @pre_parsing_loop

@pre_parsing_end_of_data:
   inc end_of_data
@end_pre_parsing_loop:



   ; DRAWING THE TIME WINDOW
   ; =======================
   lda #detail::event_edit_pos_x
   sta column_index
@columns_loop:
   ; 1. decide whether to draw a temporal grid line
   ; 2. calculate the time stamp up to which events are registered in this column
   ; 3. loop over events relevant for the current column, update the column buffer (skip if end of data), meanwhile update drag&drop hitboxes
   ; 4. draw column


   ; Decide whether to draw a temporal grid line
   ; ===========================================
   ldx temporal_zoom
   beq @decide_full_thirtysecondth
@decide_resolution_times_four: ; if zoom level is at least 1, we simply look at the thirtysecondth count
   jsr song_engine::timing::get_note_duration_thirtysecondths
   ; grid resolution times 4 minus 1 --> bit mask to check for exact multiple of 4.
   asl
   asl
   dec
   and thirtysecondth_count
   bne @grid_line_off
@grid_line_on:
   lda #101 ; line character
   bra @select_background_character
@decide_full_thirtysecondth: ; at zoom level 0, we need to look at single ticks to decide whether we are at a full thirtysecondth note
   ; additionally to finding the grid line position, this section advances the thirtysecondth_count variable correctly at zoom level 0
   lda ticks_since_last_full_thirtysecondth
   bne :+
   ; it's zero. advance and activate grid line
   inc ticks_since_last_full_thirtysecondth
   bra @grid_line_on
:  ; not zero. advance, check for equality to thirtysecondth note and do rollover. fall through to deactivate grid line
   inc ticks_since_last_full_thirtysecondth
   lda #1
   ldx thirtysecondth_count
   jsr song_engine::timing::get_note_duration_ticks
   ; got length of thirtysecondth note in .A
   cmp ticks_since_last_full_thirtysecondth
   bne :+
   stz ticks_since_last_full_thirtysecondth
   inc thirtysecondth_count
:
@grid_line_off:
   lda #32 ; space character
@select_background_character:
   ; store the character in the code that draws the column
   sta @draw_space+1


   ; Calculate relevant end time stamp for current column (up to which point do we need to register events for the current column)
   ; ====================================================
   ; get the length of the next column in ticks
   ; add it to the running time stamp (TODO: keep copy of it, but use a time stamp that was only advanced by half the column duration to achieve "nearest neighbor rounding")

   lda thirtysecondth_count
   clc
   adc thirtysecondth_stride ; At zoom level 0, this has no effect -- the correct advancement of thirtysecondth_count is done by the temporal grid code, instead.
   sta thirtysecondth_count
   tax
   lda temporal_zoom ; zoom level
   jsr song_engine::timing::get_note_duration_ticks
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
   lda song_engine::events::event_time_stamp_h
   cmp running_time_stamp_h
   bcc @time_stamp_within_column ; if carry is clear this means event time stamp is lower than column's border
   bne @end_parse_events ; if the time stamps aren't equal (and also event time stamp is not lower), the event time stamp is higher --> quit event parsing
   lda song_engine::events::event_time_stamp_l ; high time stamps are equal, need to check low time stamp
   cmp running_time_stamp_l
   bcs @end_parse_events ; if carry is clear this means event time stamp is lower than column's border
@time_stamp_within_column:
   ; interpret event type
   lda song_engine::events::event_type
   beq @handle_note_off
   cmp #song_engine::events::event_type_note_on
   beq @handle_note_on
   ; neither note-on nor note-off
   bra @parse_next_event
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
   jsr song_engine::event_selection::streamGetNextEvent
   bcs :+ ; new data available?
   ; new data available.
   jsr v5b::read_entry
   jmp @main_parse_events_loop
:  inc end_of_data
@end_parse_events:

   ; COLUMN DRAWING LOOP
   ; -------------------
@start_drawing_and_buffer_update:
   ldy piano_roll_offset
   ; .X is Y position
   ; column_index is X position
   ; .Y is piano roll index
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
   lda column_index
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
   lda #101 ; the character here is subject to self-modifying code for efficient temporal grid drawing
   sta VERA_data0
   lda piano_roll_lut, y
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
   dey
   bpl :+
   ldy #11
:
   inx
   cpx #detail::event_edit_height
   beq :+
   jmp @rows_loop
:

   inc column_index
   lda column_index
   cmp #(detail::event_edit_pos_x+detail::event_edit_width)
   beq @end_column_loop
   jmp @columns_loop
@end_column_loop:

   ; finish off unfinished notes by creating their hitboxes
   ldx #0
@finish_hitboxes_loop:
   lda detail::column_buffer, x
   beq :+
   jsr detail::finishNoteHitbox
:  inx
   cpx #detail::event_edit_height
   bne @finish_hitboxes_loop

   rts

piano_roll_lut:
   ; black and white key & grid color
   @wk = 16+15
   @bk = 16*15+12
   .byte @wk, @bk, @wk, @bk, @wk, @wk, @bk, @wk, @bk, @wk, @bk, @wk
.endproc


; lookup table values
hitbox_height = 2
px = 2 * detail::event_edit_pos_x
py = 2 * detail::event_edit_pos_y
width = 2 * detail::event_edit_width
height = 2 * detail::event_edit_height

; Do we need this function?
; Needs input:
; * new position do drag to (x,y)
; * object id
; Outputs:
; * new actual position of object (x,y). Reason: hitbox update!
.proc drag
   ; TODO
   rts
.endproc

; expects the horizontal distance in terms of grid positions in .A
.proc moveTimeWindow
   pha ; store horizontal scroll distance to the stack

   lda window_time_stamp
   sta song_engine::timing::time_stamp_parameter
   lda window_time_stamp+1
   sta song_engine::timing::time_stamp_parameter+1
   ldy temporal_zoom
   ldx #1 ; snap to grid
   pla ; scroll distance
   eor #$ff
   inc
   jsr song_engine::timing::move_along_grid ; calculate the time stamp delta
   ; now add the delta to the time stamp
   lda window_time_stamp
   clc
   adc song_engine::timing::time_stamp_parameter
   sta window_time_stamp
   lda window_time_stamp+1
   adc song_engine::timing::time_stamp_parameter+1
   sta window_time_stamp+1
   ; check if we overshot over t=0
   bcs :+
   lda song_engine::timing::time_stamp_parameter+1
   bpl :+
   ; set back to t=0
   stz window_time_stamp
   stz window_time_stamp+1
:
   rts
.endproc


; Expect signed delta x in .A and delta y in .X
.proc doScrollNormal
   ; First, see where we are situated on the time axis
   phx ; store vertical scroll distance to the stack
   jsr moveTimeWindow

   ; VERTICAL SCROLL
   pla ; get vertical scroll distance from stack
   eor #$ff ; negate because mouse up means displayed pitch goes down
   inc
   bmi @down
@up:
   clc
   adc window_pitch
   bcs @clamp_top
   cmp #(256 - detail::event_edit_height)
   bcs @clamp_top
   sta window_pitch
   rts
@clamp_top:
   lda #(256 - detail::event_edit_height)
   sta window_pitch
   rts

@down:
   clc
   adc window_pitch
   bcs :+
   lda #0
:  sta window_pitch
   rts
.endproc




; Figures out the vertical (pitch) min and max note values, as well as the leftmost (first) event
; so that we can clamp drag operations and move events without danger.
.proc dragNoteStart
   SET_SELECTED_VECTOR selected_events_vector
   stz detail::selection_max_pitch
   lda #255
   sta detail::selection_min_pitch

   ; get time stamp of the first event
   jsr song_engine::event_selection::resetStreamSelectedOnly
   jsr song_engine::event_selection::streamGetNextEvent
   bcc :+
   rts
:  jsr v5b::read_entry
   lda song_engine::events::event_time_stamp_l
   sta detail::selection_min_time_stamp
   lda song_engine::events::event_time_stamp_h
   sta detail::selection_min_time_stamp+1
   ; get min & max note pitch
   jsr song_engine::event_selection::resetStreamSelectedOnly
@next_event:
   jsr song_engine::event_selection::streamGetNextEvent
   bcc :+
   rts
:  jsr v5b::read_entry
   lda song_engine::events::event_type
   cmp #song_engine::events::event_type_note_on
   bne @next_event
   lda song_engine::events::note_pitch
   cmp detail::selection_max_pitch
   bcc :+
   sta detail::selection_max_pitch
:  cmp detail::selection_min_pitch
   bcs :+
   sta detail::selection_min_pitch
:  bra @next_event
.endproc


.proc noteDrag
   jsr mouse__getMouseChargridMotion
   ; check if we actually do anything (could be moved into getMouseChargridMotion and returned in carry flag)
   cmp #0
   bne @do_drag
   cpx #0
   bne @do_drag
   rts

@do_drag:
   delta_x = detail::determineTimeShift::delta_x
   delta_y = detail::temp_variable_y
   sta delta_x
   stx delta_y

   ; Find delta pitch
   ; ----------------
   ; clamp delta_y so that we don't drag any notes above/below the valid range
   lda delta_y
   bmi @clamp_downwards
@clamp_upwards:
   clc
   adc detail::selection_max_pitch
   bcc @finish_vertical_clamp
   ; overflow - do clamping
   ; set to zero for now, TODO: more elaborate clamping (if needed)
   stz delta_y
   bra @finish_vertical_clamp
@clamp_downwards:
   clc
   adc detail::selection_min_pitch
   bcs @finish_vertical_clamp
   ; overflow - do clamping
   ; set to zero for now, TODO: more elaborate clamping (if needed)
   stz delta_y
@finish_vertical_clamp:
   ; add delta_y to min/max
   lda detail::selection_min_pitch
   clc
   adc delta_y
   sta detail::selection_min_pitch
   lda detail::selection_max_pitch
   clc
   adc delta_y
   sta detail::selection_max_pitch

   ; Find delta time
   ; ---------------
   time_shift_l = detail::determineTimeShift::time_shift_l
   time_shift_h = detail::determineTimeShift::time_shift_h
   stz time_shift_l
   stz time_shift_h
   lda delta_x
   beq @end_determine_time_delta
   lda detail::pointed_at_event
   ldx detail::pointed_at_event+1
   ldy detail::pointed_at_event+2
   jsr v5b::read_entry
   jsr detail::determineTimeShift
@end_determine_time_delta:


   ; iterate over events
   ; -------------------
   jsr song_engine::event_selection::resetStreamSelectedOnly
@next_event:
   jsr song_engine::event_selection::streamGetNextEvent
   bcs @events_loop_end
   pha
   phx
   phy
   jsr v5b::read_entry

   ; horizontal: shift the time
   lda song_engine::events::event_time_stamp_l
   clc
   adc time_shift_l
   sta song_engine::events::event_time_stamp_l
   lda song_engine::events::event_time_stamp_h
   adc time_shift_h
   sta song_engine::events::event_time_stamp_h

   ; pitch editing (vertical) -- only for note-on and note-off
   lda song_engine::events::event_type
   beq @do_pitch_update ; comparing to song_engine::events::event_type_note_off
   cmp #song_engine::events::event_type_note_on
   bne @end_pitch_update ; if neither note-on nor note-off, skip
@do_pitch_update:
   lda song_engine::events::note_pitch
   clc
   adc delta_y
   sta song_engine::events::note_pitch
@end_pitch_update:

   ply
   plx
   pla
   jsr v5b::write_entry

   bra @next_event
@events_loop_end:

   inc gui_variables::request_components_redraw
   rts
.endproc


; Figures out the minimum note length of all selected notes
; so that we can clamp note-resize operations (i.e. not make notes shorter than 0)
.proc resizeNoteStart
   time_stamp_temp_l = detail::temp_variable_a
   time_stamp_temp_h = detail::temp_variable_b
   SET_SELECTED_VECTOR selected_events_vector
   lda #255
   sta detail::selection_shortest_note_length
   sta detail::selection_shortest_note_length+1

   jsr song_engine::event_selection::resetStreamSelectedOnly
@event_loop_start:
   jsr song_engine::event_selection::streamGetNextEvent ; todo: use streamPeekNextSelectedEvent ?
   bcc @process_next_event
   rts
@process_next_event:
   ; save current event pointer
   pha
   phx
   phy
   jsr v5b::read_entry
   ; recall part of event pointer (don't recall .A yet because we still work with it)
   ply
   plx
   lda song_engine::events::event_type
   cmp #song_engine::events::event_type_note_on
   beq @process_note_on
   ; no note-on, skip event
   pla ; tidy up stack
   bra @event_loop_start
@process_note_on:
   ; store time stamp of note-on
   lda song_engine::events::event_time_stamp_l
   sta time_stamp_temp_l
   lda song_engine::events::event_time_stamp_h
   sta time_stamp_temp_h
   ; get note-off
   pla ; recall last byte of the note-on pointer
   jsr song_engine::event_selection::findNoteOff
   jsr v5b::read_entry
   ; get note length and compare with minimum
   lda song_engine::events::event_time_stamp_l
   clc ; clc instead of sec is intentional here: we want to "shorten" the note by 1 tick in order to prevent zero-length notes
   sbc time_stamp_temp_l
   sta time_stamp_temp_l
   lda song_engine::events::event_time_stamp_h
   sbc time_stamp_temp_h
   sta time_stamp_temp_h
   cmp detail::selection_shortest_note_length+1
   beq @compare_low_bytes
   bcs @event_loop_start ; not equal --> current note is longer --> go to next
   bra @save_note_length ; not bigger & not equal --> must be smaller
@compare_low_bytes:
   lda time_stamp_temp_l
   cmp detail::selection_shortest_note_length
   bcs @event_loop_start
@save_note_length:
   lda time_stamp_temp_l
   sta detail::selection_shortest_note_length
   lda time_stamp_temp_h
   sta detail::selection_shortest_note_length+1
   bra @event_loop_start
.endproc


.proc noteResize
   jsr mouse__getMouseChargridMotion
   ; check if we actually do anything (could be moved into getMouseChargridMotion and returned in carry flag)
   cmp #0
   bne @do_resize
   rts

@do_resize:
   delta_x = detail::determineTimeShift::delta_x
   sta delta_x

   ; Find delta time
   ; ---------------
   time_shift_l = detail::determineTimeShift::time_shift_l
   time_shift_h = detail::determineTimeShift::time_shift_h
   lda detail::pointed_at_event
   ldx detail::pointed_at_event+1
   ldy detail::pointed_at_event+2
   jsr song_engine::event_selection::findNoteOff
   jsr v5b::read_entry
   jsr detail::determineTimeShift

   ; iterate over events
   ; -------------------
   jsr song_engine::event_selection::resetStreamSelectedOnly
@next_event:
   jsr song_engine::event_selection::streamPeekNextSelectedEvent
   bcs @events_loop_end
   jsr v5b::read_entry

   lda song_engine::events::event_type
   bne @no_note_off ; #song_engine::events::event_type_note_off
@note_off:
   ; cut the event from the original vector (since the order of events may change)
   jsr song_engine::event_selection::streamDeleteNextSelectedEvent
   ; move the time stamp
   lda song_engine::events::event_time_stamp_l
   clc
   adc time_shift_l
   sta song_engine::events::event_time_stamp_l
   lda song_engine::events::event_time_stamp_h
   adc time_shift_h
   sta song_engine::events::event_time_stamp_h
   ; add the note-off to the temporary vector
   lda temp_events
   ldx temp_events+1
   jsr v5b::append_new_entry
   bra @next_event
@no_note_off:
   ; actually advance to next event if it isn't a note-off
   jsr song_engine::event_selection::streamGetNextEvent
   bra @next_event
@events_loop_end:

   ; now merge the moved note-off events back into the selected_events_vector
   SET_UNSELECTED_VECTOR temp_events
   jsr song_engine::event_selection::selectAllEvents

   inc gui_variables::request_components_redraw
   rts
.endproc



.proc doScroll
   jsr mouse__getMouseChargridMotion
   ; check if we actually do anything
   cmp #0
   bne @do_scroll
   cpx #0
   bne @do_scroll
   rts
@do_scroll:
   ; check for fast scroll
   ldy kbd_variables::ctrl_key_pressed
   beq :+
   ; multiply relative distance by 4
   asl
   asl
   tay
   txa
   asl
   asl
   tax
   tya
:
   inc gui_variables::request_components_redraw
   jmp doScrollNormal ; TODO: jump to hitbox type specific scroll routine
.endproc

.proc doZoom
   jsr mouse__getMouseChargridMotion
   ; check Y coordinate
   txa
   bne @do_zoom
   rts
@do_zoom:
   pha ; save delta y

   ; make mouse position the "left side of the window" (trick to make zoom magnify what's at the mouse position)
   lda mouse_variables::curr_x_downscaled
   lsr
   sec
   sbc #detail::event_edit_pos_x
   eor #$ff
   inc
   jsr moveTimeWindow

   ; the relative change in zoom level is in .A
   pla ; recall delta y
   eor #$ff
   sec ; combined inc & sec
   adc temporal_zoom
   bpl :+
   lda #0
:  sta temporal_zoom
   bcc @check_top
   bra @move_time_window
@check_top:
   cmp #(max_temporal_zoom+1)
   bcc @move_time_window
   lda #max_temporal_zoom
   sta temporal_zoom
@move_time_window:
   ; move what was previously at the mouse position back to mouse (2nd half of trick to make zoom magnify what's at the mouse position)
   lda mouse_variables::curr_x_downscaled
   lsr
   sec
   sbc #detail::event_edit_pos_x
   jsr moveTimeWindow

   jsr gui_routines__refresh_gui
   inc gui_variables::request_components_redraw
   rts
.endproc


.proc addNewNote
   ; grid position
   lda mouse_variables::curr_x_downscaled
   lsr
   eor #$ff
   inc
   clc
   adc #detail::event_edit_pos_x
   pha ; save grid position, so we can revert it later
   jsr moveTimeWindow ; abusing the viewing window time stamp here
   ; copy time stamp
   lda window_time_stamp
   sta song_engine::events::event_time_stamp_l
   lda window_time_stamp+1
   sta song_engine::events::event_time_stamp_h
   ; get note pitch
   lda mouse_variables::curr_y_downscaled
   lsr
   eor #$ff
   clc
   adc #(detail::event_edit_pos_y + detail::event_edit_height)
   clc
   adc window_pitch
   sta song_engine::events::note_pitch
   ; add note-on
   lda #song_engine::events::event_type_note_on
   sta song_engine::events::event_type
   lda selected_events_vector
   ldx selected_events_vector+1
   jsr v5b::append_new_entry
   ; move time stamp over by one chargrid position
   lda #$ff
   jsr moveTimeWindow
   ; copy time stamp
   lda window_time_stamp
   sta song_engine::events::event_time_stamp_l
   lda window_time_stamp+1
   sta song_engine::events::event_time_stamp_h
   ; add note-off
   lda #song_engine::events::event_type_note_off
   sta song_engine::events::event_type
   lda selected_events_vector
   ldx selected_events_vector+1
   jsr v5b::append_new_entry
   ; restore viewing window
   pla
   dec
   eor #$ff
   inc
   jsr moveTimeWindow

   rts
.endproc


.scope drag_action
   ID_GENERATOR 0, none, scroll, zoom, box_select, drag, resize
.endscope

.proc commonLeftClick
   ; duplicate?
   lda kbd_variables::ctrl_key_pressed
   beq @check_delete
   lda selected_events_vector
   ldx selected_events_vector+1
   jsr v5b::get_first_entry ; since we just selected an event, I don't deal with the case that there's nothing in this vector
@duplicate_loop:
   pha
   phx
   phy
   jsr v5b::read_entry
   lda temp_events
   ldx temp_events+1
   jsr v5b::append_new_entry
   ply
   plx
   pla
   jsr v5b::get_next_entry
   bcc @duplicate_loop
@end_duplicate:
   SET_SELECTED_VECTOR temp_events
   jsr song_engine::event_selection::unSelectAllEvents
   lda #drag_action::drag
   sta drag_action_state
   rts

@check_delete:
   ; delete?
   lda kbd_variables::alt_key_pressed
   bne @do_delete
   rts
@do_delete:
   lda selected_events_vector
   ldx selected_events_vector+1
   jsr v5b::clear
   rts
.endproc

; This routine does all the stuff necessary at the start of a drag operation.
; It has to distinguish between all the different things one can do with the mouse in the notes DnD area.
.proc dragStart
   ; start of a dragging operation. figure out what we're actually doing
   lda mouse_variables::curr_buttons
   and #1 ; check for left button
   bne @left_button
   lda mouse_variables::curr_buttons
   and #2 ; check for right button
   beq :+
   jmp @right_button
:  lda mouse_variables::curr_buttons
   and #4 ; check for middle button
   beq :+
   jmp @middle_button
:  stz dnd::drag_action_state ; #drag_action::none
   rts
@left_button:
   ; LMB down: mostly selection / unselection stuff
   inc gui_variables::request_components_redraw
   lda mouse_variables::curr_data_1
   bne @lmb_event_clicked
      ; no event clicked.
      lda kbd_variables::ctrl_key_pressed
      beq :+ ; if CTRL is pressed, add a new note
         jsr song_engine::event_selection::unSelectAllEvents
         jsr addNewNote
         lda #drag_action::resize
         sta dnd::drag_action_state
         rts
      :
      lda kbd_variables::shift_key_pressed
      bne :+ ; if SHIFT is pressed, skip unselection of all
         jsr song_engine::event_selection::unSelectAllEvents
      :
      lda #drag_action::box_select
      sta dnd::drag_action_state
      jsr guiutils::showBoxSelectFrame
      rts
   @lmb_event_clicked:
      ; after whatever we do here, it's either a drag or resize operation afterwards
      lda #drag_action::drag
      ldx mouse_variables::curr_data_1
      cpx #hitboxes__hitbox_handle__right_end
      bne :+
      lda #drag_action::resize
   :  sta dnd::drag_action_state

      ; selection logic
      lda mouse_variables::curr_data_2
      sta v5b::value_0
      lda mouse_variables::curr_data_3
      sta v5b::value_1
      bmi @already_selected
      @not_yet_selected:
         lda kbd_variables::shift_key_pressed
         beq :+
         ; SHIFT was pressed --> allow multiple selection
         SET_SELECTED_VECTOR selected_events_vector
         stz song_engine::event_selection::select_action ; #event_selection::selectEvent::action::delete_original
         jsr detail::selectWithHitboxId
         rts
      :
         ; event wasn't selected yet --> we want to unselect all, and select the clicked-at one
         ; This is difficult because the moment we unselect all events, the pointer to the clicked-at event becomes unusable.
         ; Therefore, we first need to select the clicked-at event into temp, before unselecting all others.
         SET_SELECTED_VECTOR temp_events
         stz song_engine::event_selection::select_action ; #event_selection::selectEvent::action::delete_original
         jsr detail::selectWithHitboxId
         SET_SELECTED_VECTOR selected_events_vector
         jsr song_engine::event_selection::unSelectAllEvents
         ; now, swap selected with temp vector, as they have the correct contents already
         SWAP_VECTORS temp_events, selected_events_vector
         jmp commonLeftClick
      @already_selected:
         lda kbd_variables::shift_key_pressed
         beq :+
         SET_SELECTED_VECTOR selected_events_vector
         jsr detail::getEntryFromHitboxObjectId
         stz song_engine::event_selection::select_action ; #event_selection::selectEvent::action::delete_original
         jsr song_engine::event_selection::unselectEvent
      :  jmp commonLeftClick
@right_button:
   lda mouse_variables::curr_data_1
   beq @scroll ; only scroll when the mouse did not point at any note (?)
   stz dnd::drag_action_state ; #drag_action::none
   rts
@middle_button:
   lda #drag_action::zoom
   sta dnd::drag_action_state
   rts
@scroll:
   lda #drag_action::scroll
   sta dnd::drag_action_state
   rts
.endproc


.proc doDrag
   ; preparations
   SET_SELECTED_VECTOR selected_events_vector
   SET_UNSELECTED_VECTOR unselected_events_vector

   lda mouse_variables::drag_start
   beq @drag_continue
   jsr dragStart
   ; if we're starting a drag operation, we need to figure out a bunch of things
   lda dnd::drag_action_state
   cmp #drag_action::drag
   bne :+
   jsr dragNoteStart
   bra @drag_continue
:  cmp #drag_action::resize
   bne @drag_continue
   jsr resizeNoteStart ; TODO: resizeNoteStart

; do the actual drag operation
@drag_continue:
   lda dnd::drag_action_state
   asl
   tax
   jmp (@jump_table_drag, x)
@jump_table_drag:
   .word components_common::dummy_subroutine ; none
   .word doScroll
   .word doZoom
   .word guiutils::updateBoxSelectFrame
   .word noteDrag
   .word noteResize
.endproc


; This routine is mainly needed for box selection
.proc doDragEnd
   lda dnd::drag_action_state
   cmp #drag_action::box_select
   beq :+
   rts
:
   ; hide "box"
   jsr guiutils::hideBoxSelectFrame

   ; DO BOX SELECTION
   ; ================

   ; determine the box borders in multiples of 4 pixels
   lda guiutils::box_select_left+1
   lsr
   ror guiutils::box_select_left
   lsr
   ror guiutils::box_select_left

   lda guiutils::box_select_top+1
   lsr
   ror guiutils::box_select_top
   lsr
   ror guiutils::box_select_top

   ; for the right and bottom sides, we "round up" while dividing by 4 to get inclusive box
   clc
   lda guiutils::box_select_right
   adc #(4-1)
   lsr guiutils::box_select_right+1
   ror
   lsr guiutils::box_select_right+1
   ror
   sta guiutils::box_select_right

   clc
   lda guiutils::box_select_bottom
   adc #(4-1)
   lsr guiutils::box_select_bottom+1
   ror
   lsr guiutils::box_select_bottom+1
   ror
   sta guiutils::box_select_bottom

   ; now the box boundaries are contained in the low bytes of each variable, respectively

   ; We must be careful to not invalidate hitbox ids before we use them.
   ; * First, put all events inside the box into the temp vector.
   ; * Then, depending on whether shift has held or not, unselect all selected events.
   ; * Merge all temp events into selected.

   ; Don't need to set the unselected events vector as the selectEvent routine doesn't require the source vector to be set.
   SET_SELECTED_VECTOR temp_events

   jsr hitboxes__load_hitbox_list
   jsr v5b::get_first_entry
   bcc @hitbox_loop
   rts
@hitbox_loop:
   pha
   phx
   phy

   jsr v5b::read_entry

   ; check bounds.
   ; check bottom
   lda hitboxes__hitbox_pos_y
   cmp guiutils::box_select_bottom
   bcs @go_to_next_hitbox
   ; check top
   inc ; account for the fact that notes have height 2
   cmp guiutils::box_select_top
   bcc @go_to_next_hitbox
   ; check right
   lda hitboxes__hitbox_pos_x
   cmp guiutils::box_select_right
   bcs @go_to_next_hitbox
   ; check left
   adc hitboxes__hitbox_width ; carry is clear as per previous jump condition
   dec
   cmp guiutils::box_select_left
   bcc @go_to_next_hitbox

   ; we're in. select the event
@select_hitbox:
   ; here, we copy selected events to the selected events vector and then invalidate the originals.
   ; This is in order to preserve the addresses of all events as long as we still need the ids
   ; to stay unchanged. We will delete all invalidated events later on.
   lda #song_engine::event_selection::selectEvent::action::invalidate_original
   sta song_engine::event_selection::select_action
   jsr detail::selectWithHitboxId

@go_to_next_hitbox:
   ply
   plx
   pla
   jsr v5b::get_next_entry
   bcc @hitbox_loop
   ; end of loop

   ; clean up invalidated events
   lda unselected_events_vector
   ldx unselected_events_vector+1
   jsr song_engine::event_selection::deleteAllInvalidEvents
   lda selected_events_vector
   ldx selected_events_vector+1
   jsr song_engine::event_selection::deleteAllInvalidEvents

   ; get rid of invalid hitboxes for safety (will be re-generated when redraw happens)
   jsr hitboxes__clear_hitboxes

   ; move all events which were previously selected.
   ; Normally move them into the unselected events vector,
   ; but if SHIFT is pressed, we move them into the temp vector, which will eventually become the new selected vector.
   SET_UNSELECTED_VECTOR unselected_events_vector
   SET_SELECTED_VECTOR selected_events_vector
   lda kbd_variables::shift_key_pressed
   beq :+
   SET_UNSELECTED_VECTOR temp_events
:  jsr song_engine::event_selection::unSelectAllEvents

   SWAP_VECTORS selected_events_vector, temp_events

   inc gui_variables::request_components_redraw
   rts
.endproc




.endscope

.endif ; .ifndef ::GUI_DRAG_AND_DROP_NOTES_ASM
