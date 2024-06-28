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
   .scope comps
      COMPONENT_DEFINITION arrowed_edit, timbre_select, 41, 1, 0, N_TIMBRES-1, 0
      COMPONENT_DEFINITION button, load_preset, 66, 0, 13, A load_preset_lb
      COMPONENT_DEFINITION button, save_preset, 52, 0, 13, A save_preset_lb
      COMPONENT_DEFINITION button, copy_preset, 34, 2, 6, A copy_preset_lb
      COMPONENT_DEFINITION button, paste_preset, 41, 2, 7, A paste_preset_lb
      COMPONENT_DEFINITION button, set_filename, 52, 4, 13, A file_lb
      COMPONENT_DEFINITION drag_edit, keyboard_volume, 43, 5, %00000000, 0, 63, 63, 0
      COMPONENT_DEFINITION button, load_bank, 66, 2, 13, A load_bank_lb
      COMPONENT_DEFINITION button, save_bank, 52, 2, 13, A save_bank_lb
      COMPONENT_LIST_END
   .endscope
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

   ; No special action required (yet)
   draw = panel_common::dummy_subroutine

   .proc write
      ; prepare component string offset
      lda mouse_variables::curr_component_ofs
      clc
      adc #4 ; currently, we're reading only arrowed edits and drag edits
      tay
      ; prepare jump
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @timbre_selector
      .word @load_preset
      .word @save_preset
      .word @copy_preset
      .word @paste_preset
      .word @change_file_name
      .word @set_play_volume
      .word @load_bank
      .word @save_bank
   @timbre_selector:
      ; read data from component string and write it to the Timbre setting
      lda comps, y
      sta gui_variables::current_synth_timbre
      jsr gui_routines__refresh_gui
      rts
   @load_preset:
      sei
      jsr concerto_synth::voices::panic
      ldx gui_variables::current_synth_timbre
      jsr concerto_synth::timbres::load_timbre
      jsr gui_routines__refresh_gui
      cli
      rts
   @save_preset:
      ldx gui_variables::current_synth_timbre
      jsr concerto_synth::timbres::save_timbre
      rts
   @copy_preset:
      lda gui_variables::current_synth_timbre
      sta concerto_synth::timbres::copying
      rts
   @paste_preset:
      sei
      jsr concerto_synth::voices::panic
      ldx gui_variables::current_synth_timbre
      jsr concerto_synth::timbres::copy_paste
      jsr gui_routines__refresh_gui
      cli
      rts
   @change_file_name:
      ; open the file browser popup on the GUI stack
      ldx panels__panels_stack_pointer
      lda #panels__ids__file_browser_popup
      sta panels__panels_stack, x
      inc panels__panels_stack_pointer
      jsr gui_routines__draw_gui
      rts

      ; clear string
      ;ldy #MAX_FILENAME_LENGTH
      ;lda #' '
   ; :  sta concerto_synth::timbres::file_name,y
      ;dey
      ;bpl :-
      ; do input string
      lda #ti_x
      sta r2L
      lda #ti_y
      sta r2H
      lda #<concerto_synth::timbres::file_name
      sta r0L
      lda #>concerto_synth::timbres::file_name
      sta r0H
      ldx #CCOLOR_CAPTION
      ldy #MAX_FILENAME_LENGTH
      jsr guiutils::vtui_input_str
      rts
   @set_play_volume:
      iny
      lda comps, y
      sta play_volume
      rts
   @load_bank:
      sei
      jsr concerto_synth::voices::panic
      jsr concerto_synth::timbres::load_bank
      jsr gui_routines__refresh_gui
      cli
      rts
   @save_bank:
      jsr concerto_synth::timbres::save_bank
      rts
   .endproc


   refresh = panel_common::dummy_subroutine
   
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_SYNTH_NAV_ASM
