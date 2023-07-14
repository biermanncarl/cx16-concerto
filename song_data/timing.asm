; Copyright 2023 Carl Georg Biermann

.ifndef ::SONG_DATA_TIMING_ASM
::SONG_DATA_TIMING_ASM = 1

.scope timing

; Song tempo, defined by the number of ticks in the first and second eighths (allowing for shuffle/swing effect)
; Their sum must not exceed 255!
; After changing these, you MUST call change_song_tempo
first_eighth_ticks:
   .byte 32
second_eighth_ticks:
   .byte 32
; TODO: number of beats per bar ?

.scope detail
; number of ticks for various note values
quarter_ticks:
   .res 1
; eighths are given already
sixteenth_ticks:
   .res 4
thirdysecondth_ticks:
   .res 8

temp_variable_a:
   .res 2
temp_variable_b:
   .res 2
temp_variable_c:
   .res 2

; this function splits the value in .A in two halves, which are returned in .A and .X. If necessary, .A is rounded up and .X is rounded down.
; .Y is preserved
.proc split_value
   lsr ; divide by 2 (rounding down)
   tax ; that's already half of the job done
   adc #0 ; if .A was uneven, the LSR instruction will have set the carry flag, which we will add back here to "round up"
   rts
.endproc
.endscope


.proc recalculate_rhythm_values
   ; quarter note
   lda first_eighth_ticks
   clc
   adc second_eighth_ticks
   sta detail::quarter_ticks
   ; sixteenth notes
   lda first_eighth_ticks
   jsr detail::split_value
   sta detail::sixteenth_ticks
   stx detail::sixteenth_ticks+1
   lda second_eighth_ticks
   jsr detail::split_value
   sta detail::sixteenth_ticks+2
   stx detail::sixteenth_ticks+3
   ; thirtysecondth notes
   ldx #0
   ldy #0
@loop:
   lda detail::sixteenth_ticks, x
   phx
   jsr detail::split_value
   sta detail::thirdysecondth_ticks, y
   iny
   txa
   sta detail::thirdysecondth_ticks, y
   iny
   plx
   inx
   cpx #4
   bne @loop
   rts
.endproc


; Given a number of ticks in .A, which ,must be the temporal distance to the previous grid-aligned beat (quarter note),
; this routine figures out what the sub-values are.
; Returns the number of thirtysecondth notes according to the current timing grid in .X
; Returns the number of ticks since the last full thirtysecondth note in .A
; Preserves .Y
.proc ticks_to_sub_quarters
   ldx #0
@loop:
   sec
   sbc detail::thirdysecondth_ticks, x
   beq @exact_match
   bcc @overshoot
   inx
   cpx #8
   bne @loop
   ldx #0
   bra @loop
@overshoot:
   clc
   adc detail::thirdysecondth_ticks, x
   rts
@exact_match:
   inx
   rts
.endproc

; Given a number of thirtysecondth notes in .X, relative to the previous grid-aligned beat,
; and a number of ticks in .A, calculates the number of ticks since the previous grid-aligned beat.
; Total tick number returned in .A
; Preserves .Y
.proc sub_quarters_to_ticks
   clc
@loop:
   cpx #0
   beq @end_loop
   dex
   adc detail::thirdysecondth_ticks, x
   bra @loop
@end_loop:
   rts
.endproc


; This function is an extension of ticks_to_sub_quarters.
; It expects a time stamp in .A (high) / .X (low).
; It returns the number of thirtysecondth-notes in .A (high) / .X (low) and the number of remaining ticks in .Y
; As this involves division by the number of ticks in a quarter note, it is quite costly.
.proc disassemble_time_stamp
   quarter_counter = detail::temp_variable_a
   time_stamp = detail::temp_variable_b
   divisor_shifter = detail::temp_variable_c
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


; Expects the low number of thirtysecondth notes (output of disassemble_time_stamp) in .X.
; Expects the "zoom level" in .A (0: single tick resolution, 1: thirtysecondths, 2: sixteenths, 3: eighths, 4: quarters, 5: bars)
; Returns the length of the next interval in ticks in .A
; (This function is mainly intended to be used by the drawing routine of notes)
; (The registers in which each of these functions passes or expects arguments could be optimized)
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
   lda detail::thirdysecondth_ticks, x
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


; Expects zoom level in .X
; Returns thirtysecondths stride in .A
.proc get_note_duration_thirtysecondths
   lda @thirtysecondths_notes_zoom, x
   rts
@thirtysecondths_notes_zoom:
   .byte 0,1,2,4,8 ; TODO: bars. could be updated with external, referenceable LUT and must be updated in recalculate_rhythm_values
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