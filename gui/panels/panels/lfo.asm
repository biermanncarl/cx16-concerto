; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_LFO_ASM

::GUI_PANELS_PANELS_LFO_ASM = 1

.include "common.asm"

; LFO settings panel
.scope lfo
   px = envelopes::px+envelopes::wd
   py = psg_oscillators::py+psg_oscillators::hg
   wd = (synth_global::wd+psg_oscillators::wd-envelopes::wd)
   hg = envelopes::hg
   comps:
      .byte 6, px+2, py+3, 8, 5, (<lfo_waveform_lb), (>lfo_waveform_lb), 0 ; waveform listbox
      .byte 5, px+12, py+2, 8, 0 ; LFO retrigger checkbox
      .byte 4, px+7 , py+5, %00000001, 0, 128, 10, 0 ; drag edit - LFO rate
      .byte 4, px+14 , py+5, %00000000, 0, 255, 0, 0 ; drag edit - LFO phase offset
      .byte 0
   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word panel_common::lfo_lb
      .byte CCOLOR_CAPTION, px+2, py+2
      .word panel_common::waveform_lb
      .byte CCOLOR_CAPTION, px+14, py+2
      .word panel_common::retr_lb
      .byte CCOLOR_CAPTION, px+2, py+5
      .word panel_common::rate_lb
      .byte CCOLOR_CAPTION, px+14, py+4
      .word phase_lb
      .byte 0
   ; data specific to the LFO panel
   phase_lb: STR_FORMAT "phase"
   lfo_waveform_lb:
      STR_FORMAT "tri"
      STR_FORMAT "squ"
      STR_FORMAT "saw up"
      STR_FORMAT "saw dn"
      STR_FORMAT "s'n'h"
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_LFO_ASM
