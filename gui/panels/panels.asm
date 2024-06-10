; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_ASM

::GUI_PANELS_PANELS_ASM = 1

.scope panels
   .include "../../common/utility_macros.asm"
   .include "utils.asm"
   .include "../mouse_variables.asm"

   .ifdef ::concerto_full_daw
      .include "configs/full_daw_gui.asm"
   .else
      .include "configs/only_synth_gui.asm"
   .endif

   ; Panel id definitions
   ; ====================
   ;
   ; From ALL_PANEL_SCOPES, we automatically define a list of constants with the name of the panels inside the scope ids (e.g. ids::envelopes)
   ; and the value according to the zero-based index within ALL_PANEL_SCOPES.
   ; Most importantly, every id is unique and can be used to index into the panel property arrays and jump tables.
   .scope ids
      ID_GENERATOR 0, ALL_PANEL_SCOPES
   .endscope


   ; Panel property lookup tables
   ; ============================
   ;
   ; Here we generate data arrays with one entry (byte or word) per panel.

   ; X positions
   px: SCOPE_MEMBER_BYTE_FIELD px, ALL_PANEL_SCOPES
   ; Y positions
   py: SCOPE_MEMBER_BYTE_FIELD py, ALL_PANEL_SCOPES
   ; widths
   wd: SCOPE_MEMBER_BYTE_FIELD wd, ALL_PANEL_SCOPES
   ; heights
   hg: SCOPE_MEMBER_BYTE_FIELD hg, ALL_PANEL_SCOPES
   ; GUI component strings
   comps: SCOPE_MEMBER_WORD_FIELD comps, ALL_PANEL_SCOPES
   ; GUI captions
   capts: SCOPE_MEMBER_WORD_FIELD capts, ALL_PANEL_SCOPES
 
   ; jump tables for panel specific routines
   jump_table_draw: SCOPE_MEMBER_WORD_FIELD draw, ALL_PANEL_SCOPES
   jump_table_write: SCOPE_MEMBER_WORD_FIELD write, ALL_PANEL_SCOPES
   jump_table_refresh: SCOPE_MEMBER_WORD_FIELD refresh, ALL_PANEL_SCOPES



   ; Panels Stack
   ; ============
   ;
   ; This stack holds all currently active panels. Panels higher up in the stack have higher priority for receiving events (mouse or keyboard).
   panels_stack: .res ids::end_id ; panels stack is end_id elements big
   panels_stack_pointer: .byte 0 ; number of panels currently at the stack


   ; goes through a GUI component string and draws all components in it
   ; expects panel ID in register A
   .proc draw_components
      dc_pointer = gui_variables::mzpwa
      asl
      tax
      lda panels::comps, x
      sta dc_pointer
      lda panels::comps+1, x
      sta dc_pointer+1
      ldy #0
   @loop:
   @return_addr:
      lda (dc_pointer), y
      bmi @end_loop ; end on type 255
      iny
      asl
      tax
      INDEXED_JSR components::jump_table_draw, @return_addr
   @end_loop:
      rts
   .endproc


   ; draws all captions from the caption string of a panel
   ; expects panel ID in register A
   .proc draw_captions
      dcp_pointer = gui_variables::mzpwa
      asl
      tax
      lda panels::capts, x
      sta dcp_pointer
      lda panels::capts+1, x
      sta dcp_pointer+1
      ldy #0
   @loop:
      lda (dcp_pointer), y
      beq @end_loop
      sta guiutils::color
      iny
      lda (dcp_pointer), y
      sta guiutils::cur_x
      iny
      lda (dcp_pointer), y
      sta guiutils::cur_y
      iny
      lda (dcp_pointer), y
      sta guiutils::str_pointer
      iny
      lda (dcp_pointer), y
      sta guiutils::str_pointer+1
      iny
      phy
      jsr guiutils::print
      ply
      jmp @loop
   @end_loop:
      rts
   .endproc


   ; Returns the index of the panel the mouse is currently over in mouse_variables::curr_panel.
   ; Bit 7 set means the mouse isn't over any panel.
   .proc mouse_get_panel
      ; grab those zero page variables for this routine
      characters_x = gui_variables::mzpwa
      characters_y = gui_variables::mzpwa+1
      ; determine position in characters (mouse position divided by 8)
      lda mouse_variables::curr_x_downscaled
      lsr
      sta characters_x
      lda mouse_variables::curr_y_downscaled
      lsr
      sta characters_y
      ; now check panels from top to bottom
      lda panels_stack_pointer
      tax
   @loop:
      dex
      bmi @end_loop
      ldy panels::panels_stack, x ; y will be panel's index
      ;lda px, y
      ;dec
      ;cmp characters_x
      ;bcs @loop ; characters_x is smaller than panel's x
      lda characters_x
      cmp panels::px, y
      bcc @loop ; characters_x is smaller than panel's x
      lda panels::px, y
      clc
      adc panels::wd, y
      dec
      cmp characters_x
      bcc @loop ; characters_x is too big
      lda characters_y
      cmp panels::py, y
      bcc @loop ; characters_y is smaller than panel's y
      lda panels::py, y
      clc
      adc panels::hg, y
      dec
      cmp characters_y
      bcc @loop ; characters_y is too big
      ; we're inside! return index
      tya
      sta mouse_variables::curr_panel
      rts
   @end_loop:
      ; found no match
      lda #255
      sta mouse_variables::curr_panel
      rts
   .endproc


   ; given the panel, where the mouse is currently at,
   ; this subroutine finds which GUI component is being clicked
   .proc mouse_get_component
      ; panel number in mouse_variables::curr_panel
      ; mouse x and y coordinates in mouse_variables::curr_x and mouse_variables::curr_y
      ; zero page variables:
      gc_pointer = gui_variables::mzpwa
      gc_counter = gui_variables::mzpbe
      ; copy pointer to component string to ZP
      lda mouse_variables::curr_panel
      asl
      tax
      lda panels::comps, x
      sta gc_pointer
      lda panels::comps+1, x
      sta gc_pointer+1
      ; iterate over gui elements
      lda #255
      sta gc_counter
      lda #0
   @check_gui_loop:
      tay
      ; increment control element identifier
      inc gc_counter
      ; look up which component type is next (type 255 is end of GUI component list)
      lda (gc_pointer), y
      bmi @no_hit ; if component is 255, go end
      pha ; remember component type
      asl
      tax
      iny
      phy ; remember .Y incase it's a hit
      ; jump to according component check
      INDEXED_JSR components::jump_table_check_mouse, @return_addr
   @return_addr:
      ply ; recall .Y prior to component check
      plx ; recall component type
      bcs @hit
      ; no hit ... move on to the next component
      tya
      adc components::component_sizes, x ; carry is clear as per BCS above
      bra @check_gui_loop
   @hit:
      tya
      sta mouse_variables::curr_component_ofs
      lda gc_counter
      sta mouse_variables::curr_component_id
      rts
   @no_hit:
      ; 255 still in .A
      sta mouse_variables::curr_component_id
      rts
   .endproc

.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_ASM
