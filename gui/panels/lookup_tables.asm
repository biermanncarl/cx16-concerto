; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_LOOKUP_TABLES_ASM

::GUI_PANELS_LOOKUP_TABLES_ASM = 1

; panels lookup tables
.scope panels_luts

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
   .define ALL_PANEL_SCOPES synth_global, psg_oscillators, envelopes, synth_navigation, listbox_popup, lfo, synth_info, fm_general, fm_operators, global_navigation, clip_editing
   ; TODO: try line continuation on ALL_PANEL_SCOPES
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
 



   ; TODO: move jump tables here

.endscope

.endif ; .ifndef ::GUI_PANELS_LOOKUP_TABLES_ASM
