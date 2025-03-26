; Copyright 2021-2025 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_SYNTH_NAV_ASM

::GUI_PANELS_PANELS_SYNTH_NAV_ASM = 1

.include "common.asm"

; synth navigation/tool panel ... it sits in the background of the synth.
.scope synth_navigation
   px = 10
   py = 0
   wd = 70
   hg = 10
   comps:
   .scope comps
      COMPONENT_DEFINITION arrowed_edit, instrument_select, 45, 1, 0, N_INSTRUMENTS-1, 0
      COMPONENT_DEFINITION button, load_preset, 66, 0, 13, A load_preset_lb
      COMPONENT_DEFINITION button, save_preset, 52, 0, 13, A save_preset_lb
      COMPONENT_DEFINITION button, copy_preset, 37, 2, 6, A copy_preset_lb
      COMPONENT_DEFINITION button, paste_preset, 44, 2, 7, A paste_preset_lb
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte CCOLOR_CAPTION, 34, 1
      .word panel_common::lb_instrument
      .byte 0
   ; data specific to the synth-navigation panel
   load_preset_lb: STR_FORMAT " load preset"
   save_preset_lb: STR_FORMAT " save preset"
   copy_preset_lb: STR_FORMAT " copy"
   paste_preset_lb: STR_FORMAT " paste"

   ; No special action required (yet)
   draw = panel_common::dummy_subroutine

   .proc write
      ; prepare jump
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @instrument_selector
      .word @load_preset
      .word @save_preset
      .word @copy_preset
      .word @paste_preset
   @instrument_selector:
      ; read data from component string and write it to the Instrument setting
      LDA_COMPONENT_MEMBER_ADDRESS arrowed_edit, instrument_select, value
      sta gui_variables::current_synth_instrument
      sta song_engine::multitrack_player::musical_keyboard::instrument
      stz song_engine::multitrack_player::musical_keyboard::drum
      jsr gui_routines__refresh_gui
      jmp panels__global_navigation__redrawMusicalKeyboardSettings
   @load_preset:
      ; open the file browser popup on the GUI stack
      lda #file_browsing::file_type::instrument
      sta file_browsing::current_file_type
      ; TODO: factor out the GUI stack operation
      ldx panels__panels_stack_pointer
      lda #panels__ids__file_load_popup
      sta panels__panels_stack, x
      inc panels__panels_stack_pointer
      jsr gui_routines__draw_gui
      rts

   @save_preset:
      ; open the file browser popup on the GUI stack
      lda #file_browsing::file_type::instrument
      sta file_browsing::current_file_type
      ; TODO: factor out the GUI stack operation
      ldx panels__panels_stack_pointer
      lda #panels__ids__file_save_popup
      sta panels__panels_stack, x
      inc panels__panels_stack_pointer
      jsr gui_routines__draw_gui
      rts

   @copy_preset:
      lda gui_variables::current_synth_instrument
      sta concerto_synth::instruments::detail::copying
      rts
   @paste_preset:
      php
      sei
      jsr concerto_synth::voices::panic
      ldx gui_variables::current_synth_instrument
      jsr concerto_synth::instruments::copy_paste
      jsr gui_routines__refresh_gui
      plp
      rts
   .endproc


   .proc refresh
      lda gui_variables::current_synth_instrument
      STA_COMPONENT_MEMBER_ADDRESS arrowed_edit, instrument_select, value
      rts
   .endproc

   keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_SYNTH_NAV_ASM
