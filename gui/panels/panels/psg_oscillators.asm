; Copyright 2021, 2023 Carl Georg Biermann

.ifndef GUI_PANELS_PANELS_PSG_OSCILLATORS_ASM

GUI_PANELS_PANELS_PSG_OSCILLATORS_ASM = 1

.include "common.asm"

; oscillator settings panel
.scope psg_oscillators
   px = synth_global::px+synth_global::wd
   py = synth_global::py
   wd = 34
   hg = synth_global::hg
   ; positions of sub-sections inside the panel
   modsecx = px + 4
   modsecy = py + 16
   pitsecx = px + 4
   pitsecy = py + 9
   pwsecx = px + 19
   pwsecy = py + 4
   wfsecx = px + 4
   wfsecy = py + 2
   ampsecx = px + 22
   ampsecy = pitsecy

   comps:
      .byte 2, px, py, MAX_OSCS_PER_VOICE, 0 ; tabselector
      .byte 6, wfsecx, wfsecy+2, 8, 4, (<waveforms_lb), (>waveforms_lb), 0 ; waveform listbox
      .byte 4, pwsecx, pwsecy+2, %00000000, 0, 63, 0, 0 ; pulse width drag edit
      .byte 6, ampsecx, ampsecy+1, 8, N_TOT_MODSOURCES, (<panel_common::modsources_lb), (>panel_common::modsources_lb), 0 ; amp listbox
      .byte 4, ampsecx, ampsecy+4, %00000000, 0, 64, 0, 0 ; volume drag edit
      .byte 6, ampsecx+4, ampsecy+4, 5, 4, (<panel_common::channel_select_lb), (>panel_common::channel_select_lb), 0 ; channel listbox
      .byte 4, pitsecx+3, pitsecy+2, %00000100, 128, 127, 0, 0 ; semitone edit ... signed range
      .byte 4, pitsecx+3, pitsecy+4, %00000100, 128, 127, 0, 0 ; fine tune edit ... signed range
      .byte 5, pitsecx+8, pitsecy+2, 7, 0 ; pitch tracking checkbox
      .byte 6, modsecx+7, modsecy+2, 8, N_TOT_MODSOURCES+1, (<panel_common::modsources_none_option_lb), (>panel_common::modsources_none_option_lb), 0 ; pitch mod select 1
      .byte 6, modsecx+7, modsecy+3, 8, N_TOT_MODSOURCES+1, (<panel_common::modsources_none_option_lb), (>panel_common::modsources_none_option_lb), 0 ; pitch mod select 2
      .byte 6, modsecx+7, modsecy+4, 8, N_TOT_MODSOURCES+1, (<panel_common::modsources_none_option_lb), (>panel_common::modsources_none_option_lb), 0 ; pw mod select
      .byte 6, modsecx+7, modsecy+5, 8, N_TOT_MODSOURCES+1, (<panel_common::modsources_none_option_lb), (>panel_common::modsources_none_option_lb), 0 ; volume mod select
      .byte 4, modsecx+15, modsecy+2, %10000100, 256-76, 76, 0, 0 ; drag edit - pitch mod depth 1 range
      .byte 4, modsecx+15, modsecy+3, %10000100, 256-76, 76, 0, 0 ; drag edit - pitch mod depth 2 range
      .byte 4, modsecx+15, modsecy+4, %00000100, 256-127, 127, 0, 0 ; drag edit - pw mod depth range
      .byte 4, modsecx+15, modsecy+5, %00000100, 256-127, 127, 0, 0 ; drag edit - volume mod depth range
      .byte 0

   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word cp
      .byte CCOLOR_CAPTION, wfsecx, wfsecy
      .word panel_common::waveform_lb
      .byte CCOLOR_CAPTION, pwsecx, pwsecy
      .word pulsewidth_lb
      .byte CCOLOR_CAPTION, ampsecx, ampsecy
      .word amp_lb
      .byte CCOLOR_CAPTION, ampsecx, ampsecy+3
      .word panel_common::vol_lb
      .byte CCOLOR_CAPTION, ampsecx+5, ampsecy+3
      .word panel_common::channel_lb
      .byte CCOLOR_CAPTION, pitsecx, pitsecy
      .word panel_common::pitch_lb
      .byte CCOLOR_CAPTION, pitsecx, pitsecy+2
      .word panel_common::semi_lb
      .byte CCOLOR_CAPTION, pitsecx, pitsecy+4
      .word panel_common::fine_lb
      .byte CCOLOR_CAPTION, pitsecx+10, pitsecy+2
      .word panel_common::track_lb
      .byte CCOLOR_CAPTION, modsecx, modsecy
      .word modulation_lb
      .byte CCOLOR_CAPTION, modsecx, modsecy+2
      .word panel_common::pitch_lb
      .byte CCOLOR_CAPTION, modsecx, modsecy+4
      .word pw_lb
      .byte CCOLOR_CAPTION, modsecx, modsecy+5
      .word panel_common::vol_lb
      .byte 0

   ; data specific to the oscillator panel
   active_tab: .byte 0
   cp: STR_FORMAT "psg oscillators" ; caption of panel
   amp_lb: STR_FORMAT "amp env"
   pulsewidth_lb: STR_FORMAT "pulse width"
   pw_lb: STR_FORMAT "pw"
   modulation_lb: STR_FORMAT "modulation"
   ; stringlist for modsource listboxes
   waveforms_lb:
      STR_FORMAT "pulse"
      STR_FORMAT "saw"
      STR_FORMAT "tri"
      STR_FORMAT "noise"
.endscope

.endif ; .ifndef GUI_PANELS_PANELS_PSG_OSCILLATORS_ASM



