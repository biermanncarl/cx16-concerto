.ifndef GLOBAL_DEFS_INC
GLOBAL_DEFS_INC = 1

; Synth engine definitions
.define N_VOICES 16
.define N_TIMBRES 8
.define N_OSCILLATORS 16 ; total number of PSG voices, which correspond to oscillators
.define MAX_OSCS_PER_VOICE 6
.define MAX_ENVS_PER_VOICE 3
.define MAX_LFOS_PER_VOICE 1

; GUI definitions
.define COLOR_BACKGROUND 11
.define COLOR_FRAME 1
.define COLOR_CAPTION 1
.define N_PANELS 3   ; number of panels 


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

.macro TIMBRE_BYTE_FIELD
   .repeat N_TIMBRES, I
      .byte 0
   .endrep
.endmacro

.macro OSCILLATOR_BYTE_FIELD
   .repeat N_OSCILLATORS, I
      .byte 0
   .endrep
.endmacro

; osc1: timbre1 timbre2 timbre3 ... osc2: timbre1 timbre2 timbre3 ... 
; ---> this format saves multiplication when accessing with arbitrary timbre indes
.macro OSCILLATOR_TIMBRE_BYTE_FIELD
   .repeat MAX_OSCS_PER_VOICE*N_TIMBRES
      .byte 0
   .endrep
.endmacro

; osc1: voice1 voice2 voice3 ... osc2: voice1 voice2 voice3 ...
.macro OSCILLATOR_VOICE_BYTE_FIELD
   .repeat MAX_OSCS_PER_VOICE*N_VOICES
      .byte 0
   .endrep
.endmacro

; env1: timbre1 timbre2 timbre3 ... env2: timbre1 timbre2 tibre3 ...
; ---> this format saves multiplication when accessing with arbitrary timbre indes
.macro ENVELOPE_TIMBRE_BYTE_FIELD
   .repeat MAX_ENVS_PER_VOICE*N_TIMBRES
      .byte 0
   .endrep
.endmacro

; env1: voice1 voice2 voice3 ... env2: voice1 voice2 voice3 ...
.macro ENVELOPE_VOICE_BYTE_FIELD
   .repeat MAX_ENVS_PER_VOICE*N_VOICES
      .byte 0
   .endrep
.endmacro

; lfo1: timbre1 timbre2 timbre3 ... lfo2: timbre1 timbre2 tibre3 ...
; ---> this format saves multiplication when accessing with arbitrary timbre indes
.macro LFO_TIMBRE_BYTE_FIELD
   .repeat MAX_LFOS_PER_VOICE*N_TIMBRES
      .byte 0
   .endrep
.endmacro

; lfo1: voice1 voice2 voice3 ... lfo2: voice1 voice2 voice3 ...
.macro LFO_VOICE_BYTE_FIELD
   .repeat MAX_LFOS_PER_VOICE*N_VOICES
      .byte 0
   .endrep
.endmacro

.macro PANEL_BYTE_FIELD
   .repeat N_PANELS
      .byte 0
   .endrep
.endmacro

.endif