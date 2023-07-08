; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_GLOBAL_ASM

::GUI_PANELS_PANELS_GLOBAL_ASM = 1

.include "common.asm"

; global synth settings panel
.scope synth_global
   px = 11
   py = 8
   wd = 12
   hg = 24
   comps:
      .byte 3, px+3, py+3, 0, MAX_OSCS_PER_VOICE, 1 ; number of oscillators
      .byte 3, px+3, py+6, 1, 3, 1 ; number of envelopes
      .byte 5, px+2, py+8, 8, 1 ; LFO activate checkbox
      .byte 5, px+2, py+12, 8, 1 ; retrigger checkbox
      .byte 5, px+2, py+14, 8, 0 ; porta checkbox
      .byte 4, px+2, py+16, %00000000, 0, 255, 0, 0 ; porta rate edit
      .byte 4, px+7, py+19, %00000000, 0, 76, 0, 0 ; vibrato amount edit
      .byte 0
   capts:
      .byte CCOLOR_CAPTION, px+3, py
      .word cp
      .byte (COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND), px+2, py+2 ; number of oscillators label
      .word nosc_lb
      .byte (COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND), px+2, py+5 ; number of envelopes label
      .word nenv_lb
      .byte (COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND), px+4, py+8 ; number of envelopes label
      .word panel_common::lfo_lb
      .byte CCOLOR_CAPTION, px+4, py+12 ; porta checkbox label
      .word panel_common::retr_lb
      .byte CCOLOR_CAPTION, px+5, py+14 ; porta checkbox label
      .word porta_active_lb
      .byte CCOLOR_CAPTION, px+6, py+16 ; porta rate label
      .word panel_common::rate_lb
      .byte CCOLOR_CAPTION, px+2, py+19 ; vibrato amount label
      .word vibrato_lb
      .byte 0
   cp: STR_FORMAT "global" ; caption of panel
   nosc_lb: STR_FORMAT "n. oscs"
   nenv_lb: STR_FORMAT "n. envs"
   porta_active_lb: STR_FORMAT "porta" ; portamento activate label
   vibrato_lb: STR_FORMAT "vib."
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_GLOBAL_ASM



