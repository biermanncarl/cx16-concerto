; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_FM_OPERATORS_ASM

::GUI_PANELS_PANELS_FM_OPERATORS_ASM = 1

.include "common.asm"

; FM operators setup
.scope fm_operators
   px = fm_general::px+fm_general::wd
   py = fm_general::py
   wd = fm_general::wd
   hg = 17
   comps:
      .byte 2, px, py, N_OPERATORS, 0 ; tabselector
      .byte 4, px+4 , py+12, %0, 0, 31, 0, 0 ; drag edit - attack
      .byte 4, px+9, py+12, %0, 0, 31, 0, 0 ; drag edit - decay1
      .byte 4, px+14, py+12, %0, 0, 15, 0, 0 ; drag edit - decay level
      .byte 4, px+19, py+12, %0, 0, 31, 0, 0 ; drag edit - decay2
      .byte 4, px+24, py+12, %0, 0, 15, 0, 0 ; drag edit - release
      .byte 4, px+10, py+7, %0, 0, 15, 0, 0 ; drag edit - mul
      .byte 4, px+15, py+7, %00000100, 253, 3, 0, 0 ; drag edit - fine
      .byte 4, px+20, py+7, %0, 0, 3, 0, 0 ; drag edit - coarse
      .byte 4, px+4, py+3, %0, 0, 127, 0, 0 ; drag edit - level (vol)
      .byte 4, px+17, py+14, %00000000, 0, 3, 0, 0 ; drag edit - key scaling
      .byte 5, px+10, py+3, 2, 0 ; checkbox - volume sensitivity
      .byte 0
   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word cp
      .byte CCOLOR_CAPTION, px+4, py+11
      .word panel_common::lb_attack
      .byte CCOLOR_CAPTION, px+9, py+11
      .word lb_decay_1
      .byte CCOLOR_CAPTION, px+14, py+11
      .word lb_decay_level
      .byte CCOLOR_CAPTION, px+19, py+11
      .word lb_decay_2
      .byte CCOLOR_CAPTION, px+24, py+11
      .word panel_common::lb_release
      .byte CCOLOR_CAPTION, px+4, py+6
      .word lb_tuning
      .byte CCOLOR_CAPTION, px+10, py+6
      .word lb_mul
      .byte CCOLOR_CAPTION, px+15, py+6
      .word lb_dt1
      .byte CCOLOR_CAPTION, px+20, py+6
      .word lb_dt2
      .byte CCOLOR_CAPTION, px+4, py+2
      .word panel_common::vol_lb
      .byte CCOLOR_CAPTION, px+4, py+14
      .word lb_ks
      .byte CCOLOR_CAPTION, px+12, py+3
      .word lb_vol_sens
      .byte 0
   active_tab: .byte 0
   cp: STR_FORMAT "fm operators"
   lb_decay_1: STR_FORMAT "dec1"
   lb_decay_2: STR_FORMAT "dec2"
   lb_decay_level: STR_FORMAT "lev"
   lb_tuning: STR_FORMAT "tune"
   lb_mul: STR_FORMAT "mul"
   lb_dt1: STR_FORMAT "fine"
   lb_dt2: STR_FORMAT "coarse"
   lb_ks: STR_FORMAT "key scaling"
   lb_vol_sens: STR_FORMAT "vol sens"
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FM_OPERATORS_ASM
