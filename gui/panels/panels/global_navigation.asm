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
   .scope comps
      COMPONENT_DEFINITION dummy, click_catcher
      COMPONENT_DEFINITION text_field, concerto_banner, 1, 1, 19, 6, A vram_assets::concerto_banner
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte 0
   ; data specific to the synth-navigation panel
   active_tab: .byte 2

   .proc draw
      lda active_tab
      sta guiutils::draw_data1
      jsr guiutils::draw_globalnav
      rts
   .endproc

   .proc write
      lda mouse_variables::curr_data_2 ; y position in multiples of 8 pixels
      ; tabs start at row 12 and are 16 high each
      sec
      sbc #12
      lsr
      lsr
      lsr
      lsr
      sta active_tab
      cmp #0
      beq @load_arrangement_view
      cmp #1
      beq @load_clip_view
      jsr gui_routines__load_synth_gui
      bra @end
   @load_arrangement_view:
      jsr gui_routines__load_arrangement_gui
      bra @end
   @load_clip_view:
      jsr gui_routines__load_clip_gui
   @end:
      rts
   .endproc


   refresh = panel_common::dummy_subroutine

.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_GLOBAL_NAVIGATION_ASM
