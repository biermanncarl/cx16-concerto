; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_ENVELOPE_ASM

::GUI_PANELS_PANELS_ENVELOPE_ASM = 1

.include "common.asm"

; envelope settings panel
.scope envelopes
   px = synth_global::px
   py = psg_oscillators::py+psg_oscillators::hg
   wd = 24
   hg = 8
   comps:
      .byte 2, px, py, 3, 0 ; tab selector
      .byte 4, px+4 , py+4, %00000001, 0, 127, 0, 0 ; drag edit - attack
      .byte 4, px+9 , py+4, %00000001, 0, 127, 0, 0 ; drag edit - decay
      .byte 4, px+14, py+4, %00000000, 0, ENV_PEAK, 0, 0 ; drag edit - sustain
      .byte 4, px+18, py+4, %00000001, 0, 127, 0, 0 ; drag edit - release
      .byte 0
   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word cp
      .byte CCOLOR_CAPTION, px+4, py+3
      .word panel_common::lb_attack
      .byte CCOLOR_CAPTION, px+9, py+3
      .word lb_decay
      .byte CCOLOR_CAPTION, px+14, py+3
      .word lb_sustain
      .byte CCOLOR_CAPTION, px+18, py+3
      .word panel_common::lb_release
      .byte 0
   ; data specific to the envelope panel
   active_tab: .byte 0
   cp: STR_FORMAT "envelopes" ; caption of panel
   lb_decay: STR_FORMAT "dec"
   lb_sustain: STR_FORMAT "sus"
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_ENVELOPE_ASM
