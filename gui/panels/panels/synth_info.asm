; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_SYNTH_INFO_ASM

::GUI_PANELS_PANELS_SYNTH_INFO_ASM = 1

.include "common.asm"

; help/info panel
.scope synth_info
   px = psg_oscillators::px+psg_oscillators::wd+1
   py = synth_global::py
   wd = 16
   hg = psg_oscillators::hg+envelopes::hg
   comps:
   .scope comps
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte CCOLOR_CAPTION, px+6, py
      .word cp
      .byte CCOLOR_CAPTION, px+2, py+2
      .word help_1_lb
      .byte CCOLOR_CAPTION, px+2, py+4
      .word help_2_lb
      .byte CCOLOR_CAPTION, px+3, py+5
      .word help_3_lb
      .byte CCOLOR_CAPTION, px+2, py+7
      .word help_4_lb
      .byte CCOLOR_CAPTION, px+3, py+8
      .word help_5_lb
      .byte 0
   ; data specific to the synth info panel
   cp: STR_FORMAT "help"
   help_1_lb: STR_FORMAT "controls:"
   help_2_lb: STR_FORMAT "left drag:"
   help_3_lb: STR_FORMAT "coarse edit"
   help_4_lb: STR_FORMAT "right drag:"
   help_5_lb: STR_FORMAT "fine edit"

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

.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_SYNTH_INFO_ASM
