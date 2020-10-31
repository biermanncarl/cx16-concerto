.ifndef GLOBAL_DEFS_INC
GLOBAL_DEFS_INC = 1

; compiler level definitions
.define N_VOICES 16
.define N_TIMBRES 8
.define MAX_OSCS_PER_VOICE 8
.define N_OSCILLATORS 16 ; total number of PSG voices, which correspond to oscillators


; string constants
message:
   .byte $0D, "controls", $0D
   .byte "--------", $0D, $0D
   .byte "a,w,s,...   play notes", $0D
   .byte "z,x         toggle octaves", $0D
   .byte "q           quit", $0D
end_message:

; keyboard variables
Octave:
   .byte 60
Note:
   .byte 0

; utility macros
.macro ADD16 add_a, add_b ; stores result in a, 26 cycles
   clc
   lda add_b
   adc add_a
   sta add_a
   lda add_b+1
   adc add_a+1
   sta add_a+1
.endmacro

.macro SUB16 sub_a, sub_b ; stores result in a, 26 cycles
   sec
   lda sub_a
   sbc sub_b
   sta sub_a
   lda sub_a+1
   sbc sub_b+1
   sta sub_a+1
.endmacro

.macro MUL8x8_MP mul_a, mul_b, mul_result ; stores result in a 16 bit variable, uses ZP variables in the process
   ; convention here is that MSB comes first
   ; initialization
   lda mul_a
   sta mzpba
   lda mul_b
   sta mzpwa+1
   stz mzpwa
   stz mul_result+1
   stz mul_result

   ; multiplication
   bbr0 mzpba, :+
   lda mzpwa+1
   sta mul_result+1
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr1 mzpba, :+
   clc
   lda mzpwa+1
   adc mul_result+1
   sta mul_result+1
   lda mzpwa
   adc mul_result
   sta mul_result
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr2 mzpba, :+
   clc
   lda mzpwa+1
   adc mul_result+1
   sta mul_result+1
   lda mzpwa
   adc mul_result
   sta mul_result
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr3 mzpba, :+
   clc
   lda mzpwa+1
   adc mul_result+1
   sta mul_result+1
   lda mzpwa
   adc mul_result
   sta mul_result
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr4 mzpba, :+
   clc
   lda mzpwa+1
   adc mul_result+1
   sta mul_result+1
   lda mzpwa
   adc mul_result
   sta mul_result
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr5 mzpba, :+
   clc
   lda mzpwa+1
   adc mul_result+1
   sta mul_result+1
   lda mzpwa
   adc mul_result
   sta mul_result
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr6 mzpba, :+
   clc
   lda mzpwa+1
   adc mul_result+1
   sta mul_result+1
   lda mzpwa
   adc mul_result
   sta mul_result
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr7 mzpba, @end_macro
   clc
   lda mzpwa+1
   adc mul_result+1
   sta mul_result+1
   lda mzpwa
   adc mul_result
   sta mul_result
@end_macro:
.endmacro

.macro VOICE_BYTE_FIELD
   .repeat N_VOICES, I
      .byte 0
   .endrep
.endmacro

.macro VOICE_WORD_FIELD
   .repeat N_VOICES, I
      .word 0
   .endrep
.endmacro

.macro TIMBRE_BYTE_FIELD
   .repeat N_TIMBRES, I
      .byte 0
   .endrep
.endmacro

.macro TIMBRE_WORD_FIELD
   .repeat N_TIMBRES, I
      .word 0
   .endrep
.endmacro

.endif