; Copyright 2021, 2023 Carl Georg Biermann

.ifndef GUI_PANELS_PANELS_FM_GENERAL_ASM

GUI_PANELS_PANELS_FM_GENERAL_ASM = 1

.include "common.asm"

; FM general setup (everything that isn't operators)
.scope fm_gen
   px = synth_global::px
   py = env::py+env::hg+1
   wd = 29
   hg = 17
   comps:
      .byte 3, px+13, py+4, 0, 7, 0 ; connection scheme number (arrowed edit)
      .byte 4, px+14, py+6, %0, 0, 7, 0, 0 ; feedback level (drag edit)
      .byte 5, px+15, py+2, 2, 0 ; activate operator 1 checkbox
      .byte 5, px+18, py+2, 2, 0 ; activate operator 2 checkbox
      .byte 5, px+21, py+2, 2, 0 ; activate operator 3 checkbox
      .byte 5, px+24, py+2, 2, 0 ; activate operator 4 checkbox
      .byte 6, px+13, py+8, 5, 4, (<panel_common::channel_select_lb), (>panel_common::channel_select_lb), 0 ; L/R listbox
      .byte 4, px+5, py+13, %00000100, 128, 127, 0, 0 ; semitone edit ... signed range
      .byte 4, px+5, py+14, %00000100, 128, 127, 0, 0 ; fine tune edit ... signed range
      .byte 5, px+13, py+11, 7, 0 ; pitch tracking checkbox
      .byte 6, px+13, py+13, 8, N_TOT_MODSOURCES+1, (<panel_common::modsources_none_option_lb), (>panel_common::modsources_none_option_lb), 0 ; pitch mod select
      .byte 4, px+21, py+13, %10000100, 256-76, 76, 0, 0 ; drag edit - pitch mod depth
      .byte 0
   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word cp
      .byte CCOLOR_CAPTION, px+2, py+4
      .word con_select_lb
      .byte CCOLOR_CAPTION, px+2, py+6
      .word lb_feedback
      .byte COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND, px+2, py+2
      .word lb_op_en
      .byte CCOLOR_CAPTION, px+16, py+2
      .word lb_op1
      .byte CCOLOR_CAPTION, px+19, py+2
      .word lb_op2
      .byte CCOLOR_CAPTION, px+22, py+2
      .word lb_op3
      .byte CCOLOR_CAPTION, px+25, py+2
      .word lb_op4
      .byte CCOLOR_CAPTION, px+2, py+8
      .word panel_common::channel_lb
      .byte CCOLOR_CAPTION, px+2, py+11
      .word panel_common::pitch_lb
      .byte CCOLOR_CAPTION, px+15, py+11
      .word panel_common::track_lb
      .byte CCOLOR_CAPTION, px+2, py+13
      .word panel_common::semi_lb
      .byte CCOLOR_CAPTION, px+2, py+14
      .word panel_common::fine_lb
      .byte 0
   cp: STR_FORMAT "fm general"
   con_select_lb: STR_FORMAT "connection"
   lb_feedback: STR_FORMAT "feedback"
   lb_op_en: STR_FORMAT "activate op."
   lb_op1: STR_FORMAT "1"
   lb_op2: STR_FORMAT "2"
   lb_op3: STR_FORMAT "3"
   lb_op4: STR_FORMAT "4"
.endscope

.endif ; .ifndef GUI_PANELS_PANELS_FM_GENERAL_ASM
