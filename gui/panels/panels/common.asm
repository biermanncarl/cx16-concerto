; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_COMMON_ASM

::GUI_PANELS_PANELS_COMMON_ASM = 1

.include "../../gui_macros.asm"

.scope panel_common
   ; Recurring Labels
   vol_lb: STR_FORMAT "vol"
   pitch_lb: STR_FORMAT "pitch"
   semi_lb: STR_FORMAT "st"
   fine_lb: STR_FORMAT "fn"
   track_lb: STR_FORMAT "track"
   waveform_lb: STR_FORMAT "waveform"
   lfo_lb: STR_FORMAT "lfo"
   retr_lb: STR_FORMAT "retrig"
   rate_lb: STR_FORMAT "rate"
   lb_attack: STR_FORMAT "att"
   lb_release: STR_FORMAT "rel"
   channel_lb: .byte 12, 47, 18, 0 ; L/R

   modsources_none_option_lb:
      .byte 32, 45, 45, 0
   modsources_lb: 
      STR_FORMAT "env1"
      STR_FORMAT "env2"
      STR_FORMAT "env3"
      STR_FORMAT "lfo"
   channel_select_lb:
      .byte 32, 45, 0
      STR_FORMAT " l"
      STR_FORMAT " r"
      .byte 12, 43, 18, 0

.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_COMMON_ASM
