; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_GUI_MACROS_ASM

::GUI_GUI_MACROS_ASM = 1

; GUI definitions
; colors
.ifdef ::concerto_full_daw
   .define COLOR_BACKGROUND 11
   .define COLOR_FRAME 15
   .define COLOR_ARROWED_EDIT_BG 0
   .define COLOR_ARROWED_EDIT_FG 3
   .define COLOR_COMBOBOX_BG 0
.else
   .define COLOR_BACKGROUND 0
   .define COLOR_FRAME 1
   .define COLOR_ARROWED_EDIT_BG 6
   .define COLOR_ARROWED_EDIT_FG 5
   .define COLOR_COMBOBOX_BG 6
.endif

.define COLOR_CAPTION 15
.define COLOR_IMPORTANT_CAPTION 5; 13 is too bright
.define COLOR_TABS 1
.define COLOR_ARROWED_EDIT_ARROWS 1
.define COLOR_CHECKBOX 1
.define COLOR_COMBOBOX_FG 15
.define COLOR_COMBOBOX_ARROW 1
.define COLOR_COMBOBOX_POPUP_BG 0
.define COLOR_COMBOBOX_POPUP_FG 7 ; or better 3?
.define COLOR_ALG_CONNECTION 15
; combined colors (foreground & background)
.define CCOLOR_CAPTION 16*COLOR_BACKGROUND+COLOR_CAPTION
.define CCOLOR_CHECKBOX_CLEAR 16*COLOR_CHECKBOX + COLOR_BACKGROUND
.define CCOLOR_CHECKBOX_TICK 16*COLOR_CHECKBOX + 0
.define CCOLOR_BUTTON 16*1 + 0
.define CCOLOR_ALG_OP_NUMBERS 16*0+13
.define CCOLOR_ALG_CONNECTION 16*COLOR_BACKGROUND+COLOR_ALG_CONNECTION

.macro PETSCII_TO_SCREEN str_arg
   .repeat  .strlen(str_arg), i
   .if (.strat(str_arg, i)=32)
      .byte 32
   .else
      .if (.strat(str_arg, i)>64) && (.strat(str_arg, i)<91)
         .byte .strat(str_arg, i)-64
      .else
         .byte .strat(str_arg, i)
      .endif
   .endif
   .endrepeat
.endmacro

; compile time macro: converts an ascii string to a zero-terminated string that can be displayed directly on the VERA
; currently supports characters, spaces, digits, and maybe more but untested.
; obviously cannot support "@", because that's character 0 on the VERA
.macro STR_FORMAT stf_arg
   PETSCII_TO_SCREEN stf_arg
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

.endif ; .ifndef ::GUI_GUI_MACROS_ASM
