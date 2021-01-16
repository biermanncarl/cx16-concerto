.ifndef GLOBAL_DEFS_INC ; include protector ...
GLOBAL_DEFS_INC = 1

; Synth engine definitions
.define N_VOICES 16
.define N_TIMBRES 32
.define N_OSCILLATORS 16 ; total number of PSG voices, which correspond to oscillators
.define MAX_OSCS_PER_VOICE 6
.define MAX_ENVS_PER_VOICE 3
.define MAX_LFOS_PER_VOICE 1
.define N_TOT_MODSOURCES MAX_ENVS_PER_VOICE+MAX_LFOS_PER_VOICE

; GUI definitions
; colors
.define COLOR_BACKGROUND 11
.define COLOR_FRAME 15
.define COLOR_CAPTION 15
.define COLOR_IMPORTANT_CAPTION 5; 13 is too bright
.define COLOR_TABS 1
.define COLOR_ARROWED_EDIT_BG 0
.define COLOR_ARROWED_EDIT_FG 3
.define COLOR_ARROWED_EDIT_ARROWS 1
.define COLOR_CHECKBOX 1
.define COLOR_LISTBOX_BG 0
.define COLOR_LISTBOX_FG 15
.define COLOR_LISTBOX_ARROW 1
.define COLOR_LISTBOX_POPUP_BG 0
.define COLOR_LISTBOX_POPUP_FG 7 ; or better 3?
; combined colors (foreground & background)
.define CCOLOR_CAPTION 16*COLOR_BACKGROUND+COLOR_CAPTION
.define CCOLOR_CHECKBOX_CLEAR 16*COLOR_CHECKBOX + COLOR_BACKGROUND
.define CCOLOR_CHECKBOX_TICK 16*COLOR_CHECKBOX + 0
.define CCOLOR_BUTTON 16*1 + 0
; others
.define N_PANELS 6   ; number of panels 



; keyboard variables
Octave:
   .byte 60
Note:
   .byte 0

; currently active timbre (in Synth GUI and keyboard)
Timbre:
   .byte 0

; debug variable
debug_a: .byte 0

; mouse variables
ms_status: .byte 0
; reference values
ms_ref_x: .word 0
ms_ref_y: .word 0
ms_ref_buttons: .byte 0
ms_ref_panel: .byte 0
ms_ref_component_id: .byte 0  ; component ID (from 0 to ...)
ms_ref_component_ofs: .byte 0 ; component offset (in a panel's component string)
; current values
ms_curr_x: .word 0
ms_curr_y: .word 0
ms_curr_buttons: .byte 0
ms_curr_panel: .byte 0
ms_curr_component_id: .byte 0
ms_curr_component_ofs: .byte 0
ms_curr_data: .byte 0 ; used to store the current tab selected, which arrow is clicked etc.
ms_curr_data2: .byte 0 ; used to store dragging distance (y direction)
ms_gui_write: .byte 0 ; used to determine whether or not an action has caused a value was changed.



; utility macros

; compile time macro: converts an ascii string to a zero-terminated string that can be displayed directly as petscii
; currently supports characters, spaces, digits, and maybe more but untested.
; obviously cannot support "@", because that's petscii 0
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

.endif