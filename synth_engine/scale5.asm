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


scale5_mantissa_lut:
   .byte %00000000, %00100000, %01000000, %10000000, %11000000


; The following two routines map between scale5 and normal binary
; the binary value can assume values from 1 to 76, or the negative values -76 to -1 (NOT zero!)
scale5_temp_number: .byte 0
; Preserves .X
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

; human readable conversion:
; let X be the binary number (only positive for the sake of this formula)
; then the high nibble of the result is the number of the sub-level (X-1) mod 5
; and the low nibble of the result is the number of right-shifts 15 - (X-1) // 5
; so that the resulting byte looks like
; $ ((X-1) mod 5) (15 - (X-1)//5)
; Preserves .Y
map_twos_complement_to_scale5:
   stz scale5_temp_number
   cmp #0
   bpl :+
   eor #%11111111
   inc
   ldx #128
   stx scale5_temp_number
:  ldx #15
   dec
   sec
@loop:
   sbc #5
   bcc @end_loop
   dex
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
   txa
   clc
   adc scale5_temp_number
   rts
