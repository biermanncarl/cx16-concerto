; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_ASM

::GUI_PANELS_PANELS_ASM = 1

; panels lookup tables
.scope panels
   .include "../mouse_definitions.asm"

   .include "panels/synth_global.asm"
   .include "panels/psg_oscillators.asm"
   .include "panels/clip_editing.asm"
   .include "panels/envelopes.asm"
   .include "panels/fm_general.asm"
   .include "panels/fm_operators.asm"
   .include "panels/global_navigation.asm"
   .include "panels/lfo.asm"
   .include "panels/listbox_popup.asm"
   .include "panels/synth_info.asm"
   .include "panels/synth_navigation.asm"

   ; ==========
   ; ATTENTION!
   ; ==========
   ;
   ; The following definitions have to be maintained when new panels are added.
   ; Add the scope of your new panel in the ALL_PANEL_SCOPES definition at the end.
   ; Also define a new constant with the name of your scope and assign to it the
   ; zero-based index of your scope inside the ALL_PANEL_SCOPES list.
   ; If there are more panels than arguments in PANEL_PARAMETER_LIST, that has to be
   ; adjusted, too.
   
   .linecont + ; switch on line continuation with "\"
   .define ALL_PANEL_SCOPES \
      clip_editing, \
      synth_global, \
      psg_oscillators, \
      envelopes, \
      synth_navigation, \
      listbox_popup, \
      lfo, \
      synth_info, \
      fm_general, \
      fm_operators, \
      global_navigation, \

   ; p1 is left away intentionally, as in some cases it is needed (where it is mentioned explicitly), in cases some not.
   .define PANEL_PARAMETER_LIST p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20
   .linecont - ; switch off line continuation with "\" (default)

   ; ==============
   ; END ATTENTION!
   ; ==============


   ; Panel id definitions
   ; ====================
   ; From ALL_PANEL_SCOPES, we automatically define a list of constants with the name of the panels inside the scope ids (e.g. ids::envelopes)
   ; and the value according to the zero-based index within ALL_PANEL_SCOPES.
   ; Most importantly, every id is unique and can be used to index into the panel property arrays and jump tables.

   .macro PANEL_ID_GENERATOR index, p1, PANEL_PARAMETER_LIST
      .ifblank p1
         ; First parameter is empty
         .exitmacro
      .endif
      p1 = index ; TODO: if this does not work, use a name space instead: ids::panel_name
      ; call this macro recursively without p1
      PANEL_ID_GENERATOR {index+1}, PANEL_PARAMETER_LIST
   .endmacro
   ; generate id constants to be used in other code
   .scope ids
      PANEL_ID_GENERATOR 0, ALL_PANEL_SCOPES
   .endscope


   ; Panel property lookup tables
   ; ============================
   ;
   ; Here we generate data arrays with one entry (byte or word) per panel.

   .macro PANEL_MEMBER_BYTE_FIELD member, p1, PANEL_PARAMETER_LIST
      .ifblank p1
         ; First parameter is empty
         .exitmacro
      .endif
      .byte p1::member
      ; call this macro recursively without p1
      PANEL_MEMBER_BYTE_FIELD member, PANEL_PARAMETER_LIST
   .endmacro

   .macro PANEL_MEMBER_WORD_FIELD member, p1, PANEL_PARAMETER_LIST
      .ifblank p1
         ; First parameter is empty
         .exitmacro
      .endif
      .word p1::member
      ; call this macro recursively without p1
      PANEL_MEMBER_WORD_FIELD member, PANEL_PARAMETER_LIST
   .endmacro

   ; X positions
   px: PANEL_MEMBER_BYTE_FIELD px, ALL_PANEL_SCOPES
   ; Y positions
   py: PANEL_MEMBER_BYTE_FIELD py, ALL_PANEL_SCOPES
   ; widths
   wd: PANEL_MEMBER_BYTE_FIELD wd, ALL_PANEL_SCOPES
   ; heights
   hg: PANEL_MEMBER_BYTE_FIELD hg, ALL_PANEL_SCOPES
   ; GUI component strings
   comps: PANEL_MEMBER_WORD_FIELD comps, ALL_PANEL_SCOPES
   ; GUI captions
   capts: PANEL_MEMBER_WORD_FIELD capts, ALL_PANEL_SCOPES
 
   ; jump tables for panel specific routines
   jump_table_draw: PANEL_MEMBER_WORD_FIELD draw, ALL_PANEL_SCOPES
   jump_table_write: PANEL_MEMBER_WORD_FIELD write, ALL_PANEL_SCOPES
   jump_table_refresh: PANEL_MEMBER_WORD_FIELD refresh, ALL_PANEL_SCOPES



   ; returns the panel index the mouse is currently over. Bit 7 set means none
   ; panel index returned in mouse_definitions::curr_panel
   .proc mouse_get_panel
      ; grab those zero page variables for this routine
      gp_cx = mzpwa
      gp_cy = mzpwd
      ; determine position in characters (divide by 8)
      lda mouse_definitions::curr_x+1
      lsr
      sta gp_cx+1
      lda mouse_definitions::curr_x
      ror
      sta gp_cx
      lda gp_cx+1
      lsr
      ror gp_cx
      lsr
      ror gp_cx
      ; (high byte is uninteresting, thus not storing it back)
      lda mouse_definitions::curr_y+1
      lsr
      sta gp_cy+1
      lda mouse_definitions::curr_y
      ror
      sta gp_cy
      lda gp_cy+1
      lsr
      ror gp_cy
      lsr
      ror gp_cy
      ; now check panels from top to bottom
      lda stack::sp
      tax
   @loop:
      dex
      bmi @end_loop
      ldy stack::stack, x ; y will be panel's index
      ;lda px, y
      ;dec
      ;cmp gp_cx
      ;bcs @loop ; gp_cx is smaller than panel's x
      lda gp_cx
      cmp panels::px, y
      bcc @loop ; gp_cx is smaller than panel's x
      lda panels::px, y
      clc
      adc panels::wd, y
      dec
      cmp gp_cx
      bcc @loop ; gp_cx is too big
      lda gp_cy
      cmp panels::py, y
      bcc @loop ; gp_cy is smaller than panel's y
      lda panels::py, y
      clc
      adc panels::hg, y
      dec
      cmp gp_cy
      bcc @loop ; gp_cy is too big
      ; we're inside! return index
      tya
      sta mouse_definitions::curr_panel
      rts
   @end_loop:
      ; found no match
      lda #255
      sta mouse_definitions::curr_panel
      rts
   .endproc


.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_ASM
