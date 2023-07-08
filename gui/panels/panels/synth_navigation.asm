; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_SYNTH_NAV_ASM

::GUI_PANELS_PANELS_SYNTH_NAV_ASM = 1

.include "common.asm"

; synth navigation/tool panel ... it sits in the background of the synth.
.scope synth_navigation
   px = 10
   py = 0
   wd = 70
   hg = 60
   ; text input position
   ti_x = 66
   ti_y = 5
   ti_l = 8 ; maximum length
   comps:
      .byte 3, 41, 1, 0, N_TIMBRES-1, 0 ; arrowed edit (timbre selection)
      .byte 1, 66, 0, 13, (<load_preset_lb), (>load_preset_lb) ; load preset button
      .byte 1, 52, 0, 13, (<save_preset_lb), (>save_preset_lb) ; save preset button
      .byte 1, 34, 2, 6, (<copy_preset_lb), (>copy_preset_lb) ; copy preset button
      .byte 1, 41, 2, 7, (<paste_preset_lb), (>paste_preset_lb) ; paste preset button
      .byte 1, 52, 4, 13, (<file_lb), (>file_lb) ; set file name button
      .byte 4, 43, 5, %00000000, 0, 63, 63, 0 ; note volume
      .byte 1, 66, 2, 13, (<load_bank_lb), (>load_bank_lb) ; load bank button
      .byte 1, 52, 2, 13, (<save_bank_lb), (>save_bank_lb) ; save bank button
      .byte 0
   capts:
      .byte CCOLOR_CAPTION, 34, 1
      .word timbre_lb
      .byte CCOLOR_CAPTION, ti_x, ti_y
      .word concerto_synth::timbres::file_name
      .byte CCOLOR_CAPTION, 34, 5
      .word velocity_lb
      .byte 0
   ; data specific to the synth-navigation panel
   timbre_lb: STR_FORMAT "timbre"
   load_preset_lb: STR_FORMAT " load preset"
   save_preset_lb: STR_FORMAT " save preset"
   load_bank_lb: STR_FORMAT "  load bank"
   save_bank_lb: STR_FORMAT "  save bank"
   copy_preset_lb: STR_FORMAT " copy"
   paste_preset_lb: STR_FORMAT " paste"
   file_lb: STR_FORMAT "  file name"
   velocity_lb: STR_FORMAT "velocity"
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_SYNTH_NAV_ASM
