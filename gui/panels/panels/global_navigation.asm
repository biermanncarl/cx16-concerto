; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_GLOBAL_NAVIGATION_ASM

::GUI_PANELS_PANELS_GLOBAL_NAVIGATION_ASM = 1

.include "common.asm"

; global navigation panel
.scope global_navigation
   px = 0
   py = 12
   wd = 3
   hg = 60-py
   comps:
      .byte 7 ; dummy component, to catch click events (without it, the panel wouldn't receive any click events!)
      .byte 0
   capts:
      .byte 0
   ; data specific to the synth-navigation panel
   active_tab: .byte 2

   .proc draw
      lda panels_luts::global_navigation::active_tab
      sta guiutils::draw_data1
      jsr guiutils::draw_globalnav
      rts
   .endproc

   .proc write
      lda mouse_definitions::curr_data_2 ; y position in multiples of 8 pixels
      ; tabs start at row 12 and are 16 high each
      sec
      sbc #12
      lsr
      lsr
      lsr
      lsr
      sta panels_luts::global_navigation::active_tab
      cmp #0
      beq @load_arrangement_view
      cmp #1
      beq @load_clip_view
      jsr load_synth_gui
      bra @end
   @load_arrangement_view:
      jsr load_arrangement_gui
      bra @end
   @load_clip_view:
      jsr load_clip_gui
   @end:
      rts
   .endproc


   refresh = panel_common::dummy_subroutine

.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_GLOBAL_NAVIGATION_ASM
