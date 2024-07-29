; Copyright 2023 Carl Georg Biermann

.ifndef ::SONG_DATA_TIMING_ASM
::SONG_DATA_TIMING_ASM = 1

.scope timing


; After changing one or several of the following variables, you MUST call change_song_tempo
beats_per_bar:
   .byte 4 ; must stay below 32 (max. 31)
; Song tempo, defined by the number of ticks in the first and second eighths (allowing for shuffle/swing effect)
; Their sum must not exceed 255!
first_eighth_ticks:
   .byte 32
second_eighth_ticks:
   .byte 32


; Variable which is used by some functions
time_stamp_parameter:
   .word 0

.scope detail
   ; number of ticks for various note values
   quarter_ticks:
      .res 1
   ; eighths are given already
   sixteenth_ticks:
      .res 4
   thirtysecondth_ticks:
      .res 8

   ; When changing song tempo, the new values of the timing variables will be put here until re-tempo of the song is complete.
   .scope new_timing
      .linecont +
      .define NEW_TIMING_SCRATCHPAD \
         beats_per_bar, 1, \
         first_eighth_ticks, 1, \
         second_eighth_ticks, 1, \
         quarter_ticks, 1, \
         sixteenth_ticks, 4, \
         thirtysecondth_ticks, 16, \
         thirtysecondths_per_bar, 1
      .linecont -
      SCRATCHPAD_VARIABLES NEW_TIMING_SCRATCHPAD
   .endscope

   temp_variable_a:
      .res 2
   temp_variable_b:
      .res 2
   temp_variable_c:
      .res 1

   ; this function splits the value in .A in two halves, which are returned in .A and .X. If necessary, .A is rounded up and .X is rounded down.
   ; .Y is preserved
   .proc split_value
      lsr ; divide by 2 (rounding down)
      tax ; that's already half of the job done
      adc #0 ; if .A was uneven, the LSR instruction will have set the carry flag, which we will add back here to "round up"
      rts
   .endproc

   ; From new beats_per_bar and the eighth ticks, calculates the new rhythm values.
   ; They are kept in the "new_timing" scope as long as we still need the old timing values for re-timing of the event data to their new time stamps.
   ; Before control is handed away to other parts of the software, commitNewTempo should be called. Otherwise the new timing values will get lost.
   .proc recalculateTimingValues
      ; bars (number of thirtysecondths in a bar)
      lda new_timing::beats_per_bar
      asl
      asl
      asl
      sta new_timing::thirtysecondths_per_bar
      ; quarter note
      lda new_timing::first_eighth_ticks
      ; clc ; carry should still be clear from above
      adc new_timing::second_eighth_ticks
      sta new_timing::quarter_ticks
      ; sixteenth notes
      lda new_timing::first_eighth_ticks
      jsr split_value
      sta new_timing::sixteenth_ticks
      stx new_timing::sixteenth_ticks+1
      lda second_eighth_ticks
      jsr split_value
      sta new_timing::sixteenth_ticks+2
      stx new_timing::sixteenth_ticks+3
      ; thirtysecondth notes
      ldx #0
      ldy #0
   @loop:
      lda new_timing::sixteenth_ticks, x
      phx
      jsr split_value
      sta new_timing::thirtysecondth_ticks, y
      iny
      txa
      sta new_timing::thirtysecondth_ticks, y
      iny
      plx
      inx
      cpx #4
      bne @loop
      rts
   .endproc

   ; Moves the newly calculated rhythm values to the main variables.
   .proc commitNewTiming
      ; #optimize-for-size by putting all the variables next to each other and copy with a single loop
      lda new_timing::beats_per_bar
      sta beats_per_bar
      lda new_timing::quarter_ticks
      sta quarter_ticks
      lda new_timing::first_eighth_ticks
      sta first_eighth_ticks
      lda new_timing::second_eighth_ticks
      sta second_eighth_ticks
      ldx #0
   @thirtysecondths_loop:
      lda new_timing::thirtysecondth_ticks, x
      sta thirtysecondth_ticks, x
      cpx #4
      bcs :+ ; skip copying sixteenths when above 3
      lda new_timing::sixteenth_ticks, x
      sta sixteenth_ticks, x
   :  inx
      cpx #8
      bne @thirtysecondths_loop
      rts
   .endproc

   ; Assembles the number of thirtysecondth notes and remaining ticks into a 16-bit time stamp. (Untested!)
   ; Uses the new (uncommitted) timing to allow recalculating event time stamps (disassemble with old time stamp, assemble with new one).
   ; It expects the number of thirtysecondth-notes in .A (high) / .X (low) and the number of remaining ticks in .Y
   ; The 16-bit time stamp is returned in .A (high) / .X (low)
   ; Involves multiplication, so it is quite costly
   .proc assembleTimeStamp
      timestamp = temp_variable_a
      quarter_counter = temp_variable_b
      stz timestamp+1
      sty timestamp
      ; backup the thirtysecondth count
      stx quarter_counter
      sta quarter_counter+1
      ; add the sub-quarter duration
      txa
      and #%00000111
      tax
      lda #0
      jsr subQuartersToTicks ; could be optimized to be inline
      clc
      adc timestamp
      sta timestamp
      bne :+
      inc timestamp+1
   :
      ; add the quarters
      ; ----------------
      ; get the quarter-count from thirtysecondths-count by dividing by 8
      ldx #3
   :  lsr quarter_counter+1
      ror quarter_counter
      dex
      bne :-

   @quarter_loop_high:
      lda timestamp+1
      clc
      adc new_timing::quarter_ticks
      sta timestamp+1
      dec quarter_counter+1
      bne @quarter_loop_high

   @quarter_loop_low: ; this loop can potentially run very often
      lda timestamp
      clc
      adc new_timing::quarter_ticks
      sta timestamp
      bcc :+
      inc timestamp+1
   :  dec quarter_counter
      bne @quarter_loop_low

      lda timestamp+1
      ldx timestamp
      rts

      ; Given a number of thirtysecondth notes in .X, relative to the previous grid-aligned beat,
      ; and a number of ticks in .A, calculates the number of ticks since the previous grid-aligned beat.
      ; Total tick number returned in .A
      ; Preserves .Y
      .proc subQuartersToTicks
         clc
      @loop:
         cpx #0
         beq @end_loop
         dex
         adc new_timing::thirtysecondth_ticks, x
         bra @loop
      @end_loop:
         rts
      .endproc
   .endproc
.endscope


; Expects zoom level in .X
; Returns thirtysecondths stride in .A (i.e. how many thirtysecondth notes a grid stride is on a given zoom level)
; Preserves .X and .Y
.proc get_note_duration_thirtysecondths
   lda thirtysecondths_notes_zoom, x
   rts
thirtysecondths_notes_zoom:
   .byte 0,1,2,4,8,32 ; tick, thirtysecondth, sixteenth, eighth, quarter(beat), bar
.endproc
thirtysecondths_per_bar = get_note_duration_thirtysecondths::thirtysecondths_notes_zoom+5


; Given a number of ticks in .A, which is the temporal distance to the previous grid-aligned beat (quarter note),
; this routine figures out what the sub-values are.
; Returns the number of thirtysecondth notes according to the current timing grid in .X
; Returns the number of ticks since the last full thirtysecondth note in .A
; Preserves .Y
.proc ticks_to_sub_quarters
   ldx #0
@loop:
   sec
   sbc detail::thirtysecondth_ticks, x
   beq @exact_match
   bcc @overshoot
   inx
   cpx #8
   bne @loop
   ldx #0
   bra @loop
@overshoot:
   clc
   adc detail::thirtysecondth_ticks, x
   rts
@exact_match:
   inx
   rts
.endproc



; This function is an extension of ticks_to_sub_quarters.
; It expects a time stamp in .A (high) / .X (low).
; It returns the number of thirtysecondth-notes in .A (high) / .X (low) and the number of remaining ticks in .Y
; As this involves division by the number of ticks in a quarter note, it is quite costly.
.proc disassemble_time_stamp
   quarter_counter = detail::temp_variable_a
   time_stamp = detail::temp_variable_b

   ldy #255
   sec
@quarters_high_loop:
   iny
   sbc detail::quarter_ticks
   bcs @quarters_high_loop

   adc detail::quarter_ticks
   sta time_stamp+1 ; store the remaining number of ticks
   stx time_stamp
   sty quarter_counter+1 ; that's the high part of quarter_counter done

   ldy #255
   inc time_stamp+1 ; we end when we get zero, not when we overflow. hence offsetting for this here
@quarters_low_loop:
   iny
   lda time_stamp ; low
   sec
   sbc detail::quarter_ticks
   sta time_stamp
   bcs @quarters_low_loop ; no overflow: just continue subtracting

   ; overflow: decrement high ticks
   dec time_stamp+1
   bne @quarters_low_loop

   ; we reached zero time stamp. need to add back to the low part what we had subtracted
   clc ; could be optimized away
   adc detail::quarter_ticks ; this gives us the remainder of ticks
   pha

   ; now convert quarter_counter to a thirtysecondth_counter by multiplying with 8
   tya
   asl
   rol quarter_counter+1
   asl
   rol quarter_counter+1
   asl
   rol quarter_counter+1
   sta quarter_counter

   pla ; recall remaining number of ticks
   jsr ticks_to_sub_quarters
   tay
   txa
   clc
   adc quarter_counter
   tax
   lda quarter_counter+1

   rts
.endproc


; Given a number of thirtysecondth notes, returns the number of bars and the remaining thirtysecondths.
; Expects the number of thirtysecondth-notes in .A (high) / .X (low)  (output of disassemble_time_stamp).
; Returns Residual thirtysecondths in .A, number of bars in .Y (high) and .X (low)
; Note: because this routine involves division, it is quite expensive.
.proc thirtysecondthsToBarsAndResidual
   low = detail::temp_variable_a
   high = detail::temp_variable_b

   stx low

   ldy #255
@high_loop:
   sec
   sbc thirtysecondths_per_bar
   iny
   bcs @high_loop
   adc thirtysecondths_per_bar
   inc ; offset of one for low_loop
   sta high
   ; result's high byte in .Y

   ldx #255
   lda low
@low_loop:
   inx
   sec
   sbc thirtysecondths_per_bar
   bcs @low_loop ; no overflow
   ; overflow
   dec high
   bne @low_loop
   ; result's low byte in .X

   adc thirtysecondths_per_bar ; carry should be clear from last subtraction
   ; Residual in .A
   rts
.endproc


; Given an 8-bit number of thirtysecondth notes (which is assumed to be relative to a whole quarter note -- true after disassemble_time_stamp),
; returns the length of the quantization cell of specified (zoom) level the time stamp is part of (left inclusive, right exclusive).
; Returns the length of the next time interval in ticks in .A
; Expects the low byte of the number of thirtysecondth notes of the disassembled time stamp
; (output of disassemble_time_stamp) in .X.
; Expects the "zoom level" in .A (0: single tick resolution, 1: thirtysecondths, 2: sixteenths, 3: eighths, 4: quarters)
; Bars are not supported because their length can go above 255 ticks (requires 16 bit return).
; (The registers in which each of these functions passes or expects arguments could be optimized)
; Preserves .Y
.proc get_note_duration_ticks
   phx
   asl
   tax
   pla
   and #$07
   jmp (@jmp_tbl, x)
@jmp_tbl:
   .word @single_ticks
   .word @thirtysecondths
   .word @sixteenths
   .word @eighths
   .word @quarters
   .word @bars

@single_ticks:
   lda #1
   rts
@thirtysecondths:
   tax
   lda detail::thirtysecondth_ticks, x
   rts
@sixteenths:
   lsr
   tax
   lda detail::sixteenth_ticks, x
   rts
@eighths:
   lsr
   lsr
   tax
   lda first_eighth_ticks, x
   rts
@quarters:
   lda detail::quarter_ticks
   rts
@bars:
   ; TODO
   rts
.endproc


; Takes a time stamp and other parameters and calculates the relative motion to the grid.
; Expects the time stamp in time_stamp_parameter.
; Expects the grid/quantization level in .Y and the signed distance in grid cells in .A.
; The snapping mode is contained in .X (0 is no snapping to grid, 1 is snap to left, other modes to be added)
; The signed time stamp delta is returned in time_stamp_parameter, which needs to be added manually by the caller.
; The current implementation assumes that all quantization levels of 1 and above are powers of 2 numbers of thirtysecondth notes
; and the max quantization level is 4 (quarter notes, which will never exceed 255 ticks)
.proc move_along_grid
   thirtysecondths = detail::temp_variable_a
   quantization_level = detail::temp_variable_c
   pha ; store the drag distance
   phx ; store the snap mode
   sty quantization_level ; store quantization level

   lda time_stamp_parameter+1
   ldx time_stamp_parameter
   jsr disassemble_time_stamp
   sta thirtysecondths+1
   stx thirtysecondths

   ; Initialize the time diff to zero
   stz time_stamp_parameter
   stz time_stamp_parameter+1

   plx ; recall the snap mode
   beq @end_quantization ; no snap means no quantization

   ; do the quantization
   ldx quantization_level ; recall quantization level
   beq @end_quantization ; at quantization level 0 (single tick resolution), quantization is a no-op
   ; we do quantization ... negate the excess ticks
   tya
   eor #$ff
   inc
   sta time_stamp_parameter
   beq :+ ; even though we quantize, the number of excess ticks can still be zero
   dec time_stamp_parameter+1
:
   ; create bit shift mask according to the quantization level
   ; goal: count how many thirtysecondths we have to move left in order to be quantized
   ; We assume the result of this call is a power of two, so subtracting 1 will give a nice bitmask
   jsr get_note_duration_thirtysecondths
   dec
   ; apply quantization mask
   and thirtysecondths
   ; We have the number of thirtysecondths to move left in .A.
   ; Let's do it.
   tay
   iny ; to cause it to become zero when decremented once
@quantization_steps_loop:
   dey
   beq @end_quantization_steps_loop
   ldx thirtysecondths
   lda #1 ; want duration of one thirtysecondth note, hence quantization level 1
   jsr get_note_duration_ticks; .X offset in 1/32s, .A quantization level
   eor #$ff ; negate and then add to accumulated time stamp diff
   inc
   clc
   adc time_stamp_parameter
   sta time_stamp_parameter
   bcs :+ ; weird carry for subtraction
   dec time_stamp_parameter+1
:  dec thirtysecondths
   bra @quantization_steps_loop
@end_quantization_steps_loop:
@end_quantization:

   ; Do the actual motion
   ply ; recall the distance
   bmi @move_left

@move_right:
   iny
@move_right_loop:
   ; do loop things
   dey
   beq @end_move
   ; add quantization value to delta time stamp
   lda quantization_level
   ldx thirtysecondths
   jsr get_note_duration_ticks
   clc
   adc time_stamp_parameter
   sta time_stamp_parameter
   bcc :+
   inc time_stamp_parameter+1
:  ; advance the thirtysecondths counter
   ldx quantization_level
   jsr get_note_duration_thirtysecondths
   clc
   adc thirtysecondths
   sta thirtysecondths
   bra @move_right_loop

@move_left:
   ; we are interested in the ticks-length of notes to the left of the current position, so we need to move the thirtysecondths counter to the left in advance.
   ; That's why we jump into the bottom portion of below loop with one extra iteration.
   dey
   bra @move_left_loop_bottom_half
@move_left_loop:
   ; subtract the quantization value from delta time stamp
   lda quantization_level
   ldx thirtysecondths
   jsr get_note_duration_ticks
   eor #$ff
   inc
   clc
   adc time_stamp_parameter
   sta time_stamp_parameter
   bcs :+
   dec time_stamp_parameter+1
:
@move_left_loop_bottom_half:
   ; advance the thirtysecondths counter
   ldx quantization_level
   jsr get_note_duration_thirtysecondths
   eor #$ff
   inc
   clc
   adc thirtysecondths
   sta thirtysecondths
   ; do loop things
   iny
   bne @move_left_loop

@end_move:
   rts
.endproc


; TODO functions to move time stamps by certain time values
; When sub-thirtysecondth values are moved, they may need to be scaled up or down, depending
; on whether they end up in a bigger or smaller thirtysecondth note.
; Ideally, one would have a separate number telling the relative position inside a thirtysecondth note.
; However, we do everything in absolute ticks.
; There are different ways to do this scaling:
; * When moving to a smaller interval, crop any excess ticks so the note still ends up in the same thirtysecondth note. On upscaling, do nothing.
; * Move the "crop zone" to the middle of the note, so that offsets by one or two ticks from a full thirtysecondth note can be preserved.
; * Preserve left and right side of a thirtysecondth note, but also have a dedicated spot for the middle of the note, which can also be preserved.
; * Do full-on linear rescaling (very expensive)


.endscope

.endif ; .ifndef ::SONG_DATA_TIMING_ASM
