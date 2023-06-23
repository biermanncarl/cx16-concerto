; Copyright 2023 Carl Georg Biermann

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

; this function splits the value in .A in two halves, which are returned in .A and .X. If necessary, .A is rounded up and .X is rounded down.
; .Y is preserved
.proc split_value
stack_address = $0100
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
   lda sixteenth_ticks, x
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


; Given a number of ticks in .A, which is the duration to the previous grid-aligned beat,
; figure out what the sub-values are.
; Returns the number of thirtysecondth notes according to the current timing grid in .X
; Returns the number of ticks since the last full thirtysecondth note in .A
; Preserves .Y
.proc ticks_to_sub_quarters
   ldx #0
@loop:
   sec
   sbc detail::thirdysecondth_ticks, x
   beq @exact_match
   bcs @overshoot
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


; TODO functions to move time stamps by certain time values


.endscope
