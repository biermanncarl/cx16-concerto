; Copyright 2021 Carl Georg Biermann

; This file is part of Concerto.

; Concerto is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;*****************************************************************************


; compile time macro: converts an ascii string to a zero-terminated string that can be displayed directly on the VERA
; currently supports characters, spaces, digits, and maybe more but untested.
; obviously cannot support "@", because that's character 0 on the VERA
.macro STR_FORMAT stf_arg
   .repeat  .strlen(stf_arg), i
   .if (.strat(stf_arg, i)=32)
      .byte 32
   .else
      .if (.strat(stf_arg, i)>64) && (.strat(stf_arg, i)<91)
         .byte .strat(stf_arg, i)-64
      .else
         .byte .strat(stf_arg, i)
      .endif
   .endif
   .endrepeat
   .byte 0
.endmacro

; performs an indexed JSR. Paramters are the jump table address and the desired return address.
.macro INDEXED_JSR ej_jmp_tbl, ej_return
   lda #(>(ej_return-1))
   pha
   lda #(<(ej_return-1))
   pha
   jmp (ej_jmp_tbl,x)
.endmacro

; unused?
.macro ADD16 add_a, add_b ; stores result in a, 26 cycles
   clc
   lda add_b
   adc add_a
   sta add_a
   lda add_b+1
   adc add_a+1
   sta add_a+1
.endmacro

; unused?
.macro SUB16 sub_a, sub_b ; stores result in a, 26 cycles
   sec
   lda sub_a
   sbc sub_b
   sta sub_a
   lda sub_a+1
   sbc sub_b+1
   sta sub_a+1
.endmacro

; I think this is unused ATM?
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
; ---> this format saves multiplication when accessing with arbitrary timbre indices
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
; ---> this format saves multiplication when accessing with arbitrary timbre indices
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