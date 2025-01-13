; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_SYNTH_INFO_ASM

::GUI_PANELS_PANELS_SYNTH_INFO_ASM = 1

.include "common.asm"

; help/info panel
.scope synth_info
   px = psg_oscillators::px+psg_oscillators::wd+1
   py = synth_global::py
   wd = 16
   hg = psg_oscillators::hg+envelopes::hg+1
   comps:
   .scope comps
      COMPONENT_DEFINITION text_field, synth_help, px+2, py+2, wd-4, hg-4, A vram_assets::help_text_synth
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte CCOLOR_CAPTION, px+6, py
      .word panel_common::lb_help
      .byte 0

   .proc draw
      lda #px
      sta guiutils::draw_x
      lda #py
      sta guiutils::draw_y
      lda #wd
      sta guiutils::draw_width
      lda #hg
      sta guiutils::draw_height
      lda #0
      sta guiutils::draw_data1
      jsr guiutils::draw_frame
      rts
   .endproc

   write = panel_common::dummy_subroutine

   refresh = panel_common::dummy_subroutine

   keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_SYNTH_INFO_ASM
