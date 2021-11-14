; Copyright 2021 Carl Georg Biermann

; This file contains code related to the scale5 number format.
; Other code, however, is spread across the project as needed.
; The multiplication routine: synth_macros.asm


; Pitch modulation depth is defined by a different format that saves some CPU
; cycles (because it is a 16 bit modulation it's worth it).
; That format is termed Scale5, which is
; intended to be a cheap approximation of exponential
; scaling.
; An ordinary binary number N and a Scale5 number
; are multiplied the following way.
; The Scale5 number format is as follows. The 8 bits are assigned as
; SLLLHHHH
; S is the sign of the modulation depth
; HHHH is a binary number indicating how many
; times N gets right shifted.
; LLL is a binary number that must assume a value from 0 to 4.
; It is one of five sub-levels between powers of 2.
; Since the right shifts can only produce divisions by powers of 2,
; these sub-levels are intended to fill in the gaps between powers of 2
; as evenly as possible.
; Beware: HHHH denotes how much N is scaled DOWN
; LLL denotes how much N is scaled UP (but only just below the next power of 2)
; I know ... a bit complicated. Sorry pals.
; Believe me, it's faster than plain 8 bit multiplication.
; Basically, you can multiply with one of the five binary numbers
; %1.000
; %1.001
; %1.010
; %1.100
; %1.110
; and right shift the result up to 15 times. (only in practice, the right shift is done first)
; These values are chosen to be distributed relatively evenly on a logarithmic scale.



; The following two routines map between scale5 and normal binary
; the binary value can assume values from 1 to 75, or the negative values -75 to -1 (NOT zero!)
; These subroutines preserve .X, but not .A and .Y
scale5_temp_number: .byte 0

map_scale5_to_twos_complement:
   sta scale5_temp_number
   and #%01110000
   lsr
   lsr
   lsr
   lsr
   pha
   lda scale5_temp_number
   and #%00001111
   eor #%00001111 ; higher number means lower magnitude (because more rightshifts)
   tay
   pla
   clc
   dey
@loop:
   bmi @end_loop
   adc #5
   dey
   bra @loop
@end_loop:
   inc ; lift by one, because 0 is forbidden (scale5 doesn't support 0 modulation depth, so GUI shouldn't show it either)
   ldy scale5_temp_number
   bpl :+
   eor #%11111111
   inc
:  rts

map_twos_complement_to_scale5:
   stz scale5_temp_number
   cmp #0
   bpl :+
   eor #%11111111
   inc
   ldy #128
   sty scale5_temp_number
:  ldy #15
   dec
   sec
@loop:
   sbc #5
   bcc @end_loop
   dey
   bra @loop
@end_loop:
   ; carry IS clear
   adc #5
   asl
   asl
   asl
   asl
   adc scale5_temp_number
   sta scale5_temp_number
   tya
   clc
   adc scale5_temp_number
   rts
